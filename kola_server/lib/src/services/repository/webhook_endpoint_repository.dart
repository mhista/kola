// webhook_endpoint_repository.dart
//
// Storage for `webhook_endpoints` (migration 026).
//
// Stores whatever ciphertext it is handed in [encryptedSecret]; it never
// encrypts or decrypts. Same discipline as every other credential
// repository here.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/webhook_endpoint_dto.dart';
import 'supabase_client.dart';

final _log = Logger('WebhookEndpointRepository');

const _dto = WebhookEndpointDto();

class WebhookEndpointRepository {
  const WebhookEndpointRepository();

  Future<List<WebhookEndpoint>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('webhook_endpoints')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every endpoint in the workspace subscribed to [event] and healthy
  /// enough to try.
  ///
  /// `paused` and `failing` are both excluded from delivery, but they
  /// mean different things: paused is the owner's choice, failing is
  /// kola's observation. Only the second gets retried once the delivery
  /// worker exists.
  Future<List<WebhookEndpoint>> listActiveForEvent(
    int workspaceId,
    String event,
  ) async {
    _log.fine('listActiveForEvent($workspaceId, $event)');
    final response = await supabase
        .from('webhook_endpoints')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('status', 'active')
        .contains('events', [event]);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Registers or updates. Upserts on (workspace_id, url) — the unique
  /// index from 026 — because the same URL registered twice is an edit,
  /// not a second subscription.
  Future<WebhookEndpoint> upsert({
    required int workspaceId,
    required String url,
    required List<String> events,
    String? encryptedSecret,
  }) async {
    _log.fine('upsert($workspaceId, $url, ${events.length} events)');
    final row = <String, dynamic>{
      'workspace_id': workspaceId,
      'url': url,
      'events': events,
      'status': 'active',
      // Clearing the error on re-registration is deliberate: an owner
      // fixing a broken endpoint and saving it again should not keep
      // seeing yesterday's failure.
      'last_error': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (encryptedSecret != null) 'encrypted_secret': encryptedSecret,
    };

    final response = await supabase
        .from('webhook_endpoints')
        .upsert(row, onConflict: 'workspace_id,url')
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Deletes outright, unlike an API key revoke.
  ///
  /// The asymmetry is intentional. A revoked key is a security record —
  /// it may have leaked, and when it stopped working matters. A removed
  /// webhook is just a URL the owner no longer wants posted to; keeping
  /// a tombstone would clutter the list with nothing to learn from.
  Future<void> delete(int workspaceId, int endpointId) async {
    _log.fine('delete($workspaceId, $endpointId)');
    await supabase
        .from('webhook_endpoints')
        .delete()
        .eq('id', endpointId)
        .eq('workspace_id', workspaceId);
  }

  /// Records a failed delivery.
  Future<void> markFailing(int endpointId, String message) async {
    _log.fine('markFailing($endpointId)');
    await supabase
        .from('webhook_endpoints')
        .update({
          'status': 'failing',
          'last_error': message,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', endpointId);
  }
}
