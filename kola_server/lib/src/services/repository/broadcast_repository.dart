// broadcast_repository.dart — Gate 9. All database read/write
// operations for Broadcast (job header) records.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/broadcast_dto.dart';
import 'supabase_client.dart';

final _log = Logger('BroadcastRepository');

const _dto = BroadcastDto();

class BroadcastRepository {
  const BroadcastRepository();

  Future<Broadcast?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, workspaceId=$workspaceId)');
    final response = await supabase
        .from('broadcasts')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  Future<List<Broadcast>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('broadcasts')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);

    return (response as List).map((row) => _dto.fromRow(row as Map<String, dynamic>)).toList();
  }

  /// Every broadcast currently 'running' — broadcast_sweep_service.dart's
  /// worklist on each tick. Not workspace-scoped on purpose: the sweep is
  /// a single background process serving every workspace, same shape as
  /// every other sweep in this codebase (TrialSweepService etc.).
  Future<List<Broadcast>> listRunning() async {
    _log.fine('listRunning()');
    final response = await supabase.from('broadcasts').select().eq('status', 'running');

    return (response as List).map((row) => _dto.fromRow(row as Map<String, dynamic>)).toList();
  }

  Future<Broadcast> create({
    required int workspaceId,
    required String platform,
    required String text,
    required int throughputPerMinute,
    required int totalRecipients,
  }) async {
    final now = DateTime.now().toUtc();
    _log.info('Creating broadcast workspaceId=$workspaceId platform=$platform recipients=$totalRecipients');

    final broadcast = Broadcast(
      workspaceId: workspaceId,
      platform: platform,
      text: text,
      status: 'draft',
      throughputPerMinute: throughputPerMinute,
      totalRecipients: totalRecipients,
      createdAt: now,
      updatedAt: now,
      // Gate 10 (migration 050) — a freshly created broadcast has had no
      // replies yet. toRow() below still writes this explicitly rather
      // than relying on the column's DB-level DEFAULT 0, same
      // "don't make an insert's correctness depend on a migration detail"
      // reasoning as every other field here.
      escalatedReplyCount: 0,
      lastDigestSentAt: null,
    );

    final row = _dto.toRow(broadcast, includeId: false);
    row['created_at'] = now.toIso8601String();

    final response = await supabase.from('broadcasts').insert(row).select().single();
    return _dto.fromRow(response);
  }

  /// Transition a broadcast's status. [startedAt]/[completedAt] are only
  /// ever set going forward (draft -> running stamps startedAt; ->
  /// completed stamps completedAt) — callers pass them explicitly rather
  /// than this method inferring from [status], so a re-run/backfill can
  /// never accidentally overwrite a real timestamp with "now".
  Future<Broadcast> setStatus(
    int broadcastId,
    String status, {
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    _log.info('setStatus broadcastId=$broadcastId status=$status');
    final response = await supabase
        .from('broadcasts')
        .update({
          'status': status,
          if (startedAt != null) 'started_at': startedAt.toIso8601String(),
          if (completedAt != null) 'completed_at': completedAt.toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', broadcastId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Gate 10 — bumps escalated_reply_count by 1 and returns the row AS
  /// IT STANDS AFTER the increment — so a result of `escalatedReplyCount
  /// == 1` is how broadcast_reply_digest_service.dart tells "this is the
  /// first escalated reply for this broadcast" from "the Nth", without a
  /// second round trip. Read-then-write rather than a single UPDATE ...
  /// RETURNING with a SQL `+1` expression — PostgREST's `.update()` takes
  /// a value map, not an arbitrary SQL fragment, so an atomic increment
  /// through this client would need `execute_sql`-style raw SQL, which
  /// this repository (like every other one in the project) deliberately
  /// never does. A lost update under real concurrent replies to the same
  /// broadcast would only ever undercount a notification's total by one,
  /// never double-notify or crash — an acceptable v1 trade against adding
  /// this codebase's first raw-SQL repository call.
  Future<Broadcast> incrementEscalatedReplyCount(int broadcastId) async {
    final current = await supabase.from('broadcasts').select().eq('id', broadcastId).single();
    final before = _dto.fromRow(current);
    final response = await supabase
        .from('broadcasts')
        .update({
          'escalated_reply_count': before.escalatedReplyCount + 1,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', broadcastId)
        .select()
        .single();
    return _dto.fromRow(response);
  }

  /// Stamps last_digest_sent_at — called right after
  /// broadcast_reply_digest_service.dart actually sends a notification,
  /// never before, so a failed send doesn't start the cooldown clock on
  /// a notification the owner never received.
  Future<void> markDigestSent(int broadcastId, DateTime at) async {
    await supabase
        .from('broadcasts')
        .update({
          'last_digest_sent_at': at.toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', broadcastId);
  }
}
