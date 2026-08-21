// connector_sync_log_repository.dart — Gate 1. The shared dead-letter +
// observability trail every connector adapter writes to. See migration
// 036's header for the full reasoning and connector_retry.dart for the
// code that calls [record] from inside the shared retry/backoff wrapper.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/connector_sync_log_dto.dart';
import 'supabase_client.dart';

final _log = Logger('ConnectorSyncLogRepository');

const _dto = ConnectorSyncLogDto();

class ConnectorSyncLogRepository {
  const ConnectorSyncLogRepository();

  /// Appends one attempt. Never throws on its own failure past logging
  /// it — a broken observability write must not be the reason a real
  /// sync/health attempt's own error is lost. See connector_retry.dart
  /// for the caller that wraps this with exactly that guarantee.
  Future<void> record({
    required int workspaceId,
    required String connectorKey,
    required String store,
    required String kind,
    required bool success,
    int? recordsSeen,
    int? recordsChanged,
    String? errorMessage,
  }) async {
    _log.fine('record($workspaceId, $connectorKey, kind=$kind, success=$success)');
    try {
      await supabase.from('connector_sync_log').insert({
        'workspace_id': workspaceId,
        'connector_key': connectorKey,
        'store': store,
        'kind': kind,
        'status': success ? 'success' : 'error',
        'records_seen': recordsSeen,
        'records_changed': recordsChanged,
        'error_message': errorMessage,
        'ran_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      _log.warning('Failed to write connector_sync_log row for $connectorKey: $e');
    }
  }

  /// Most recent attempts for one connector, newest first — the
  /// observability query the contract's "visible to the owner"
  /// requirement is for. Not yet surfaced on any endpoint (no dashboard
  /// screen asks for it today); kept here so that surface is a read, not
  /// a new table, when it is.
  Future<List<ConnectorSyncLog>> recentFor({
    required int workspaceId,
    required String connectorKey,
    int limit = 20,
  }) async {
    _log.fine('recentFor($workspaceId, $connectorKey)');
    final response = await supabase
        .from('connector_sync_log')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('connector_key', connectorKey)
        .order('ran_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
