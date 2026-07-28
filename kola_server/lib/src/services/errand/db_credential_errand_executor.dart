// db_credential_errand_executor.dart
//
// Phase 3c's higher-trust fulfillment type (SRS.md §7.2): a read-only
// (default) or read/write connection to a business-supplied Postgres
// database, restricted to running exactly one pre-approved,
// named-parameter query template per Errand (Errand.queryTemplateSql) —
// never an open SQL console, never string-concatenated SQL. Named
// parameters (package:postgres's Sql.named + @paramName syntax) are
// what make this safe: the customer-facing "input" can only ever fill
// in placeholders the template already declared, the same guarantee
// a parameterized query gives any SQL-injection-conscious codebase.
//
// POSTGRES ONLY, DELIBERATELY, FOR NOW: SRS.md §7.2 says "business-
// supplied Postgres/MySQL/Supabase instance" — Postgres (which Supabase
// itself is) covers the large majority of that set with one driver
// dependency, and MySQL support is a separate driver/executor entirely,
// not a small extension of this one. Deferred explicitly, same "build
// one real path, defer the rest with an honest note" pattern as
// SmsOwnerNotifier — not a stub pretending otherwise.
//
// Same "every invocation logged, always" contract and execute() shape
// as BuiltinErrandExecutor/WebhookErrandExecutor.

import 'package:postgres/postgres.dart';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/errand_credential_repository.dart';
import 'package:kola_server/src/services/repository/errand_execution_log_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'db_credential_errand_credential.dart';

/// Thrown when an Errand isn't a properly-configured 'dbCredential'
/// Errand (wrong source, no credential, no query template) — a
/// configuration error, not an execution outcome, thrown BEFORE any
/// log row is written.
class InvalidDbCredentialErrandException implements Exception {
  final String message;
  const InvalidDbCredentialErrandException(this.message);

  @override
  String toString() => 'InvalidDbCredentialErrandException: $message';
}

/// Thrown when a 'readOnly' Errand's queryTemplateSql doesn't start
/// with SELECT — the defense-in-depth guard described in
/// errand.spy.yaml's queryTemplateSql header. Never thrown for a
/// 'readWrite' Errand, which is an explicit, separately-confirmed
/// upgrade per SRS.md §7.3.
class UnsafeQueryTemplateException implements Exception {
  final String message;
  const UnsafeQueryTemplateException(this.message);

  @override
  String toString() => 'UnsafeQueryTemplateException: $message';
}

class DbCredentialErrandExecutor {
  DbCredentialErrandExecutor({
    required ErrandCredentialRepository credentials,
    required ErrandExecutionLogRepository executionLogs,
  }) : _credentials = credentials,
       _executionLogs = executionLogs;

  final ErrandCredentialRepository _credentials;
  final ErrandExecutionLogRepository _executionLogs;

  /// Runs [errand]'s approved query template with [input] supplying the
  /// named parameters, and returns `{'rows': [...]}` — a list of
  /// column-name-keyed maps, one per result row. Opens a fresh
  /// connection per call and always closes it, even on failure —
  /// simplest-correct choice for an Errand invoked occasionally per
  /// conversation turn, not a high-frequency hot path that would justify
  /// a pool (`Pool.withUrl`, which this same package also supports, is
  /// the natural upgrade if that ever changes).
  Future<Map<String, dynamic>> execute({
    required Errand errand,
    required Map<String, dynamic> input,
  }) async {
    if (errand.source != 'dbCredential') {
      throw InvalidDbCredentialErrandException(
        'Errand ${errand.id} has source "${errand.source}", not "dbCredential"',
      );
    }
    final template = errand.queryTemplateSql;
    if (template == null || template.trim().isEmpty) {
      throw InvalidDbCredentialErrandException(
        'Errand ${errand.id} has no queryTemplateSql registered.',
      );
    }
    if (errand.permissionScope == 'readOnly' &&
        !template.trim().toLowerCase().startsWith('select')) {
      throw UnsafeQueryTemplateException(
        'Errand ${errand.id} is readOnly but its queryTemplateSql does not '
        'start with SELECT. Upgrade permissionScope to readWrite if this '
        'query is intentional.',
      );
    }

    final credentialRow = await _credentials.findByErrandId(errand.id!);
    if (credentialRow == null) {
      throw InvalidDbCredentialErrandException(
        'Errand ${errand.id} has no database credential registered yet.',
      );
    }

    final decrypted = ChannelCredentialEncryptionService.decrypt(
      credentialRow.encryptedCredential,
    );
    final credential = DbCredentialErrandCredential.decode(decrypted);

    final stopwatch = Stopwatch()..start();
    Connection? conn;
    try {
      conn = await Connection.openFromUrl(credential.connectionString);

      final result = await conn.execute(Sql.named(template), parameters: input);
      final rows = result.map((row) => row.toColumnMap()).toList();
      final response = {'rows': rows};

      stopwatch.stop();
      await _executionLogs.logExecution(
        errand: errand,
        input: input,
        result: response,
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      return response;
    } catch (e) {
      stopwatch.stop();
      Log.error('DB-credential errand execution failed (errandId: ${errand.id})', error: e);
      await _executionLogs.logExecution(
        errand: errand,
        input: input,
        success: false,
        errorMessage: e.toString(),
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      rethrow;
    } finally {
      await conn?.close();
    }
  }
}
