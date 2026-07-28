// errand_execution_log_repository.dart
//
// All database read/write operations for ErrandExecutionLog records —
// see errand_execution_log.spy.yaml's header for why this exists and why
// workspaceId is denormalized onto it.
//
// REDACTION HAPPENS HERE, NOT AT THE CALL SITE: logExecution() is the
// ONE place that turns a raw input Map into the JSON actually persisted,
// so every caller (BuiltinErrandExecutor today, webhook/dbCredential
// executors once Phase 3c ships) gets SRS.md §7.3's "inputs redacted per
// scope" guarantee for free, without having to remember to redact
// correctly every time it logs something.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/errand_execution_log_dto.dart';
import 'supabase_client.dart';

final _log = Logger('ErrandExecutionLogRepository');

const _dto = ErrandExecutionLogDto();

const _redactedValue = '[redacted]';

class ErrandExecutionLogRepository {
  const ErrandExecutionLogRepository();

  /// Records one Errand invocation. [errand] is passed in whole (not
  /// just its id) specifically so this method can read
  /// sensitiveInputKeysJson and redact [input] before it's ever
  /// serialized — see file header.
  Future<ErrandExecutionLog> logExecution({
    required Errand errand,
    required Map<String, dynamic> input,
    Map<String, dynamic>? result,
    required bool success,
    String? errorMessage,
    required int latencyMs,
  }) async {
    final redactedInput = _redact(input, errand.sensitiveInputKeysJson);

    _log.info(
      'Logging errand execution errandId=${errand.id} success=$success latencyMs=$latencyMs',
    );

    final response = await supabase
        .from('errand_execution_logs')
        .insert({
          'errand_id': errand.id,
          'workspace_id': errand.workspaceId,
          'input_json': jsonEncode(redactedInput),
          'result_json': result != null ? jsonEncode(result) : null,
          'success': success,
          'error_message': errorMessage,
          'latency_ms': latencyMs,
          'executed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Every execution log for one Errand, most recent first — for a
  /// future "recent activity" panel on the Errand's dashboard page.
  Future<List<ErrandExecutionLog>> listByErrand(int errandId) async {
    _log.fine('listByErrand($errandId)');
    final response = await supabase
        .from('errand_execution_logs')
        .select()
        .eq('errand_id', errandId)
        .order('executed_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every execution log across a workspace's Errands, most recent
  /// first — used by health checks/diagnostics and, eventually, the
  /// Phase 3-of-the-product-roadmap fraud/abuse engine (SRS.md §6).
  Future<List<ErrandExecutionLog>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('errand_execution_logs')
        .select()
        .eq('workspace_id', workspaceId)
        .order('executed_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Replaces the value of every key in [input] that appears in
  /// [sensitiveInputKeysJson] (a jsonEncode'd List<String>, see
  /// errand.spy.yaml) with a fixed placeholder — never throws on
  /// malformed JSON, since a logging path failing should never be what
  /// breaks an Errand invocation; it just redacts nothing in that case
  /// and the malformed value is a data-entry bug to fix separately.
  Map<String, dynamic> _redact(Map<String, dynamic> input, String sensitiveInputKeysJson) {
    List<String> sensitiveKeys;
    try {
      sensitiveKeys = (jsonDecode(sensitiveInputKeysJson) as List).cast<String>();
    } catch (_) {
      sensitiveKeys = const [];
    }
    if (sensitiveKeys.isEmpty) return input;

    return {
      for (final entry in input.entries)
        entry.key: sensitiveKeys.contains(entry.key) ? _redactedValue : entry.value,
    };
  }
}
