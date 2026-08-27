// broadcast_recipient_repository.dart — Gate 9. All database read/write
// operations for BroadcastRecipient (per-recipient durable state)
// records. This is the table broadcast_sweep_service.dart re-reads on
// every tick instead of holding any worklist in memory — see that
// model's header on why that's what makes a broadcast resumable.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/broadcast_recipient_dto.dart';
import 'supabase_client.dart';

final _log = Logger('BroadcastRecipientRepository');

const _dto = BroadcastRecipientDto();

class BroadcastRecipientRepository {
  const BroadcastRecipientRepository();

  /// A batch of not-yet-attempted recipients for one broadcast — the
  /// unit broadcast_sweep_service.dart works through per tick.
  /// `order by id` (insertion order), not random, so a paced broadcast
  /// sends in a predictable, reproducible order rather than whatever a
  /// given query planner feels like.
  Future<List<BroadcastRecipient>> nextQueuedBatch({
    required int broadcastId,
    required int limit,
  }) async {
    _log.fine('nextQueuedBatch(broadcastId=$broadcastId, limit=$limit)');
    final response = await supabase
        .from('broadcast_recipients')
        .select()
        .eq('broadcast_id', broadcastId)
        .eq('state', 'queued')
        .order('id', ascending: true)
        .limit(limit);

    return (response as List).map((row) => _dto.fromRow(row as Map<String, dynamic>)).toList();
  }

  /// Aggregate counts for progress reporting ("sent, delivered, failed,
  /// remaining" — spec). Selects only `id` and counts client-side rather
  /// than PostgREST's `.count()` — the exact pattern
  /// knowledge_document_repository.dart's countByWorkspace already uses
  /// in this codebase (see that method's header on why: no existing call
  /// site here relies on `.count()`, and a broadcast's recipient count
  /// is bounded by whatever list the caller supplied at creation, not
  /// millions of rows).
  Future<Map<String, int>> countsByState(int broadcastId) async {
    final states = ['queued', 'sending', 'sent', 'failed', 'skipped'];
    final counts = <String, int>{};
    for (final state in states) {
      final response = await supabase
          .from('broadcast_recipients')
          .select('id')
          .eq('broadcast_id', broadcastId)
          .eq('state', state);
      counts[state] = (response as List).length;
    }
    return counts;
  }

  /// Bulk-insert every recipient for a freshly created broadcast in one
  /// round trip. Rows carrying a [to] already present for this
  /// broadcastId are silently dropped by the caller before this runs
  /// (see broadcast_endpoint.dart's createBroadcast) — this method does
  /// a plain insert, not an upsert, so a genuine duplicate here is a
  /// caller bug, not a condition to paper over.
  Future<void> createMany({
    required int broadcastId,
    required int workspaceId,
    required List<String> recipients,
  }) async {
    if (recipients.isEmpty) return;
    _log.info('createMany broadcastId=$broadcastId count=${recipients.length}');
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = recipients
        .map((to) => {
              'broadcast_id': broadcastId,
              'workspace_id': workspaceId,
              'to': to,
              'state': 'queued',
              'attempt_count': 0,
              'created_at': now,
              'updated_at': now,
            })
        .toList();

    await supabase.from('broadcast_recipients').insert(rows);
  }

  /// Claims a batch — 'queued' -> 'sending' — before broadcast_sweep_
  /// service.dart attempts to send them, so a second overlapping tick
  /// (see model header) can never pick up the same row twice.
  Future<void> markSending(List<int> ids) async {
    if (ids.isEmpty) return;
    await supabase
        .from('broadcast_recipients')
        .update({'state': 'sending', 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .inFilter('id', ids);
  }

  Future<void> markSent({required int id, required int messageId, required int attemptCount}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await supabase.from('broadcast_recipients').update({
      'state': 'sent',
      'message_id': messageId,
      'attempt_count': attemptCount,
      'last_attempted_at': now,
      'updated_at': now,
    }).eq('id', id);
  }

  /// [terminal] = true writes state 'failed' (retries exhausted);
  /// false puts the row back to 'queued' so a later tick retries it —
  /// still incrementing attemptCount either way, since both are a real
  /// attempt.
  Future<void> markFailedAttempt({
    required int id,
    required String error,
    required int attemptCount,
    required bool terminal,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await supabase.from('broadcast_recipients').update({
      'state': terminal ? 'failed' : 'queued',
      'last_error': error,
      'attempt_count': attemptCount,
      'last_attempted_at': now,
      'updated_at': now,
    }).eq('id', id);
  }

  Future<void> markSkipped({required int id, required String reason}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await supabase.from('broadcast_recipients').update({
      'state': 'skipped',
      'last_error': reason,
      'last_attempted_at': now,
      'updated_at': now,
    }).eq('id', id);
  }

  Future<List<BroadcastRecipient>> listByBroadcast(int broadcastId) async {
    final response =
        await supabase.from('broadcast_recipients').select().eq('broadcast_id', broadcastId).order('id');
    return (response as List).map((row) => _dto.fromRow(row as Map<String, dynamic>)).toList();
  }
}
