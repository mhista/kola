// webhook_errand_executor.dart
//
// Phase 3c's first non-builtin fulfillment type (SRS.md §7.2): a
// business's own HTTP endpoint gets POSTed the Errand's input as JSON
// and is expected to return a JSON result. Lower-trust-required than
// dbCredential (SRS.md §7.2 lists these "in increasing order of
// platform trust required") since Kola never touches the business's
// data directly — it's their own endpoint's problem to validate/
// authorize the call, we just carry whatever auth header they told us
// to send (see webhook_errand_credential.dart).
//
// Same "every invocation logged, always" contract as
// BuiltinErrandExecutor — this file's execute() shape deliberately
// mirrors that one's structure (validate source, time it, log success
// or failure unconditionally, rethrow on failure) so the two are easy
// to read side by side.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/errand_credential_repository.dart';
import 'package:kola_server/src/services/repository/errand_execution_log_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'webhook_errand_credential.dart';

/// Thrown when an Errand isn't a properly-configured 'webhook' Errand
/// (wrong source, or no credential collected yet) — a configuration
/// error, not an execution outcome, so it's thrown BEFORE any log row
/// is written, same convention as UnknownBuiltinErrandException.
class InvalidWebhookErrandException implements Exception {
  final String message;
  const InvalidWebhookErrandException(this.message);

  @override
  String toString() => 'InvalidWebhookErrandException: $message';
}

class WebhookErrandExecutor {
  WebhookErrandExecutor({
    required ErrandCredentialRepository credentials,
    required ErrandExecutionLogRepository executionLogs,
  }) : _credentials = credentials,
       _executionLogs = executionLogs;

  final ErrandCredentialRepository _credentials;
  final ErrandExecutionLogRepository _executionLogs;

  /// POSTs [input] as JSON to [errand]'s registered webhook URL and
  /// returns the parsed JSON response body. Logs every attempt
  /// (success or failure) via ErrandExecutionLogRepository, same as
  /// BuiltinErrandExecutor.
  Future<Map<String, dynamic>> execute({
    required Errand errand,
    required Map<String, dynamic> input,
  }) async {
    if (errand.source != 'webhook') {
      throw InvalidWebhookErrandException(
        'Errand ${errand.id} has source "${errand.source}", not "webhook"',
      );
    }

    final credentialRow = await _credentials.findByErrandId(errand.id!);
    if (credentialRow == null) {
      throw InvalidWebhookErrandException(
        'Errand ${errand.id} has no webhook credential registered yet.',
      );
    }

    final decrypted = ChannelCredentialEncryptionService.decrypt(
      credentialRow.encryptedCredential,
    );
    final credential = WebhookErrandCredential.decode(decrypted);

    final stopwatch = Stopwatch()..start();
    try {
      final headers = <String, String>{'content-type': 'application/json'};
      if (credential.authHeaderName != null && credential.authHeaderValue != null) {
        headers[credential.authHeaderName!] = credential.authHeaderValue!;
      }

      final response = await http.post(
        Uri.parse(credential.url),
        headers: headers,
        body: jsonEncode(input),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Webhook returned HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final Map<String, dynamic> result;
      try {
        result = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Webhook response was not a JSON object: $e');
      }

      stopwatch.stop();
      await _executionLogs.logExecution(
        errand: errand,
        input: input,
        result: result,
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      Log.error('Webhook errand execution failed (errandId: ${errand.id})', error: e);
      await _executionLogs.logExecution(
        errand: errand,
        input: input,
        success: false,
        errorMessage: e.toString(),
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      rethrow;
    }
  }
}
