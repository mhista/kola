// workspace_connector_repository.dart
//
// Per-workspace connector state — the "everything else" store. See
// migration 025's header for why there are three connector stores and
// not one, and connector_catalog.dart for why WHICH connectors exist is
// not a table at all.
//
// This repository stores whatever ciphertext it is given in
// [encryptedConfig]; it never encrypts or decrypts. Same discipline as
// PaymentGatewayCredentialRepository — encryption happens in the
// endpoint that actually holds a plaintext credential, so there is
// exactly one place to audit.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/workspace_connector_dto.dart';
import 'supabase_client.dart';

final _log = Logger('WorkspaceConnectorRepository');

const _dto = WorkspaceConnectorDto();

class WorkspaceConnectorRepository {
  const WorkspaceConnectorRepository();

  /// Every stored connector for one workspace.
  ///
  /// The marketplace's own query: one read, merged against the catalog
  /// by ConnectorService. Connectors with no row are `available` — see
  /// connector_catalog.dart on why absence is a state.
  Future<List<WorkspaceConnector>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('workspace_connectors')
        .select()
        .eq('workspace_id', workspaceId);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<WorkspaceConnector?> findByWorkspaceAndKey(
    int workspaceId,
    String connectorKey,
  ) async {
    _log.fine('findByWorkspaceAndKey($workspaceId, $connectorKey)');
    final response = await supabase
        .from('workspace_connectors')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('connector_key', connectorKey)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Gate 4 — every workspace's row for one [connectorKey], across the
  /// whole platform. ConnectorSyncSweepService's query for the generic
  /// store, same precedent as PaymentGatewayCredentialRepository
  /// .listAllByGateway for the paymentGateway store.
  Future<List<WorkspaceConnector>> listAllByKey(String connectorKey) async {
    _log.fine('listAllByKey($connectorKey)');
    final response = await supabase
        .from('workspace_connectors')
        .select()
        .eq('connector_key', connectorKey)
        .eq('status', 'connected');

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Gate 4 — persists a sync run's watermark plus the observability
  /// counters migration 036 added and nothing wrote until now. Separate
  /// from [upsert] for the same reason PaymentGatewayCredentialRepository
  /// .updateSyncState is separate from its own upsert: a sync run has no
  /// business rewriting encrypted_config or any other connect-time field
  /// it didn't read.
  Future<void> recordSyncRun({
    required int workspaceId,
    required String connectorKey,
    required String? cursor,
    required DateTime syncedAt,
    required int recordsSeen,
    required int recordsChanged,
    required int errorCount,
  }) async {
    _log.fine('recordSyncRun($workspaceId, $connectorKey)');
    await supabase
        .from('workspace_connectors')
        .update({
          'sync_cursor': cursor,
          'last_synced_at': syncedAt.toUtc().toIso8601String(),
          'last_sync_records_seen': recordsSeen,
          'last_sync_records_changed': recordsChanged,
          'last_sync_error_count': errorCount,
        })
        .eq('workspace_id', workspaceId)
        .eq('connector_key', connectorKey);
  }

  /// Connects or rotates. Upserts on (workspace_id, connector_key) —
  /// the unique index from migration 025 — because connecting a
  /// connector twice is a ROTATION, not a second connection. Without
  /// the conflict target this would accumulate duplicate rows that the
  /// marketplace would then have to pick between arbitrarily.
  ///
  /// [encryptedConfig] must already be ciphertext. See the header.
  Future<WorkspaceConnector> upsert({
    required int workspaceId,
    required String connectorKey,
    required String status,
    String? encryptedConfig,
    String? displayDetail,
    DateTime? lastSyncedAt,
    String? lastError,
  }) async {
    _log.fine('upsert($workspaceId, $connectorKey, status=$status)');
    final row = {
      'workspace_id': workspaceId,
      'connector_key': connectorKey,
      'status': status,
      'encrypted_config': encryptedConfig,
      'display_detail': displayDetail,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'last_error': lastError,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await supabase
        .from('workspace_connectors')
        .upsert(row, onConflict: 'workspace_id,connector_key')
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Records a failure without touching stored credentials.
  ///
  /// Separate from [upsert] deliberately: a sync that fails because a
  /// token expired must not clear the token, or the reconnect flow has
  /// nothing to rotate and the owner is silently logged out of a
  /// connector they never disconnected.
  Future<void> markError(
    int workspaceId,
    String connectorKey,
    String message,
  ) async {
    _log.fine('markError($workspaceId, $connectorKey)');
    await supabase
        .from('workspace_connectors')
        .update({
          'status': 'error',
          'last_error': message,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('workspace_id', workspaceId)
        .eq('connector_key', connectorKey);
  }

  /// Disconnects, clearing the stored credential.
  ///
  /// Keeps the ROW rather than deleting it: 'disconnected' and "no row
  /// at all" are different states (migration 025's header), and the row
  /// preserves last_synced_at, which is the only record that this
  /// business ever had this connector working.
  Future<void> disconnect(int workspaceId, String connectorKey) async {
    _log.fine('disconnect($workspaceId, $connectorKey)');
    await supabase
        .from('workspace_connectors')
        .update({
          'status': 'disconnected',
          'encrypted_config': null,
          'display_detail': null,
          'last_error': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('workspace_id', workspaceId)
        .eq('connector_key', connectorKey);
  }
}
