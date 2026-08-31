// till_display_repository.dart
//
// Storage for `till_display_state` (migration 058) — one row per
// workspace, upserted in place. See that migration's own header on why
// this is a real table rather than an in-memory registry like the
// channel bot registries.

import 'package:logging/logging.dart';
import 'supabase_client.dart';

final _log = Logger('TillDisplayRepository');

class TillDisplayRepository {
  const TillDisplayRepository();

  /// Called by TillDisplayEndpoint.pushState — the till's own tab
  /// writes its current cart here on every change. [items] is already
  /// the plain-map shape TillDisplayItem's fields describe (name,
  /// quantity, unitPriceMinor, lineTotalMinor) — the endpoint builds it
  /// from the caller's JSON string, this layer just stores it as jsonb.
  Future<void> upsert({
    required int workspaceId,
    required List<Map<String, dynamic>> items,
    required int subtotalMinor,
    required String currency,
    required String status,
  }) async {
    _log.fine('upsert($workspaceId, status=$status, ${items.length} item(s))');
    await supabase.from('till_display_state').upsert({
      'workspace_id': workspaceId,
      'items_json': items,
      'subtotal_minor': subtotalMinor,
      'currency': currency,
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'workspace_id');
  }

  /// Called by TillDisplayEndpoint.getState — the customer display's
  /// tab polls this. Null means no sale has ever started on this
  /// workspace's till (no row yet), which the endpoint treats as the
  /// same honest 'idle', empty-cart state a fresh row would represent —
  /// see that endpoint's own doc comment.
  Future<Map<String, dynamic>?> findByWorkspace(int workspaceId) async {
    _log.fine('findByWorkspace($workspaceId)');
    return supabase
        .from('till_display_state')
        .select()
        .eq('workspace_id', workspaceId)
        .maybeSingle();
  }
}
