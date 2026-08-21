// workspace_connector_dto.dart
//
// Translates between:
//   Serverpod model  → WorkspaceConnector  (generated/workspace_connector.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: workspace_connectors
// Schema: docs/migrations/025_workspace_connectors.sql
//
// NOTE: encrypted_config is ciphertext only — see
//       workspace_connector.spy.yaml's header. This DTO never decrypts
//       and never encrypts; that happens one layer up, in the endpoint
//       that actually has a plaintext credential in hand.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class WorkspaceConnectorDto extends BaseDto<WorkspaceConnector> {
  const WorkspaceConnectorDto();

  @override
  WorkspaceConnector fromRow(Map<String, dynamic> row) {
    return WorkspaceConnector(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      connectorKey: row['connector_key'] as String,
      status: row['status'] as String,
      encryptedConfig: row['encrypted_config'] as String?,
      displayDetail: row['display_detail'] as String?,
      lastSyncedAt: row['last_synced_at'] == null
          ? null
          : DateTime.parse(row['last_synced_at'] as String),
      lastError: row['last_error'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      // Migration 036 — Gate 1 connector contract.
      lastSyncRecordsSeen: row['last_sync_records_seen'] as int?,
      lastSyncRecordsChanged: row['last_sync_records_changed'] as int?,
      lastSyncErrorCount: row['last_sync_error_count'] as int? ?? 0,
      retentionPolicy:
          row['retention_policy'] as String? ?? 'retain_on_disconnect',
    );
  }

  @override
  Map<String, dynamic> toRow(
    WorkspaceConnector model, {
    bool includeId = false,
  }) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'connector_key': model.connectorKey,
      'status': model.status,
      'encrypted_config': model.encryptedConfig,
      'display_detail': model.displayDetail,
      'last_synced_at': model.lastSyncedAt?.toIso8601String(),
      'last_error': model.lastError,
      'updated_at': model.updatedAt.toIso8601String(),
      'last_sync_records_seen': model.lastSyncRecordsSeen,
      'last_sync_records_changed': model.lastSyncRecordsChanged,
      'last_sync_error_count': model.lastSyncErrorCount ?? 0,
      'retention_policy': model.retentionPolicy ?? 'retain_on_disconnect',
    };
  }
}
