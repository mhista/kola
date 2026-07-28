// errand_execution_log_dto.dart
//
// Translates between:
//   Serverpod model  → ErrandExecutionLog  (generated/errand_execution_log.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: errand_execution_logs
// Schema: docs/migrations/005_errands_and_knowledge_seed.sql (source of
// truth — not duplicated here to avoid the two drifting apart over time).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ErrandExecutionLogDto extends BaseDto<ErrandExecutionLog> {
  const ErrandExecutionLogDto();

  @override
  ErrandExecutionLog fromRow(Map<String, dynamic> row) {
    return ErrandExecutionLog(
      id: row['id'] as int?,
      errandId: row['errand_id'] as int,
      workspaceId: row['workspace_id'] as int,
      inputJson: row['input_json'] as String,
      resultJson: row['result_json'] as String?,
      success: row['success'] as bool,
      errorMessage: row['error_message'] as String?,
      latencyMs: row['latency_ms'] as int,
      executedAt: DateTime.parse(row['executed_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(ErrandExecutionLog model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'errand_id': model.errandId,
      'workspace_id': model.workspaceId,
      'input_json': model.inputJson,
      'result_json': model.resultJson,
      'success': model.success,
      'error_message': model.errorMessage,
      'latency_ms': model.latencyMs,
      'executed_at': model.executedAt.toIso8601String(),
    };
  }
}
