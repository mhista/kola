// connector_sync_log_dto.dart
//
// Translates between:
//   Serverpod model  → ConnectorSyncLog  (generated/connector_sync_log.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: connector_sync_log
// Schema: docs/migrations/036_connector_contract.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ConnectorSyncLogDto extends BaseDto<ConnectorSyncLog> {
  const ConnectorSyncLogDto();

  @override
  ConnectorSyncLog fromRow(Map<String, dynamic> row) {
    return ConnectorSyncLog(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      connectorKey: row['connector_key'] as String,
      store: row['store'] as String,
      kind: row['kind'] as String,
      status: row['status'] as String,
      recordsSeen: row['records_seen'] as int?,
      recordsChanged: row['records_changed'] as int?,
      errorMessage: row['error_message'] as String?,
      ranAt: DateTime.parse(row['ran_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(ConnectorSyncLog model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'connector_key': model.connectorKey,
      'store': model.store,
      'kind': model.kind,
      'status': model.status,
      'records_seen': model.recordsSeen,
      'records_changed': model.recordsChanged,
      'error_message': model.errorMessage,
      'ran_at': model.ranAt.toIso8601String(),
    };
  }
}
