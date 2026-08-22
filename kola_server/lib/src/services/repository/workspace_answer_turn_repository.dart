// workspace_answer_turn_repository.dart — Connect Gate, subphase 4g.
// Storage for the owner dashboard's short-term conversational memory.
// See workspace_answer_turn.spy.yaml / migration 043's headers.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/workspace_answer_turn_dto.dart';
import 'supabase_client.dart';

final _log = Logger('WorkspaceAnswerTurnRepository');
const _dto = WorkspaceAnswerTurnDto();

class WorkspaceAnswerTurnRepository {
  const WorkspaceAnswerTurnRepository();

  /// How many turns (user + assistant messages combined) are kept per
  /// workspace before older ones are dropped — see [trimToRecent]. 40
  /// turns is ~20 question/answer pairs, comfortably more than the
  /// window [WorkspaceAnswerService] actually injects into a prompt
  /// (see that file's _recentTurnsLimit) — kept a bit deeper than what's
  /// used so a slightly larger window is a prompt-side constant change,
  /// not a second migration.
  static const maxStoredPerWorkspace = 40;

  Future<WorkspaceAnswerTurn> create({
    required int workspaceId,
    required String role,
    required String content,
  }) async {
    final inserted = await supabase
        .from('workspace_answer_turns')
        .insert({
          'workspace_id': workspaceId,
          'role': role,
          'content': content,
        })
        .select()
        .single();
    return _dto.fromRow(inserted);
  }

  /// The most recent [limit] turns for [workspaceId], in CHRONOLOGICAL
  /// (oldest-first) order — the order a transcript reads in, not the
  /// order they were fetched in. Supabase has no "last N ascending" in
  /// one query, so this fetches newest-first and reverses locally.
  Future<List<WorkspaceAnswerTurn>> listRecent(int workspaceId, {int limit = 6}) async {
    _log.fine('listRecent($workspaceId, limit=$limit)');
    final response = await supabase
        .from('workspace_answer_turns')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false)
        .limit(limit);
    final turns = (response as List)
        .map((r) => _dto.fromRow(r as Map<String, dynamic>))
        .toList();
    return turns.reversed.toList();
  }

  /// Deletes every turn for [workspaceId] beyond the most recent
  /// [maxStoredPerWorkspace] — called after every [create] so this
  /// table stays a bounded window, not an ever-growing transcript
  /// archive (see migration 043's header on why that's the intent).
  /// Best-effort: a failed trim leaves a few extra rows, never breaks
  /// the turn that was just saved.
  Future<void> trimToRecent(int workspaceId) async {
    try {
      final overflow = await supabase
          .from('workspace_answer_turns')
          .select('id')
          .eq('workspace_id', workspaceId)
          .order('created_at', ascending: false)
          .range(maxStoredPerWorkspace, maxStoredPerWorkspace + 200);
      final staleIds = [
        for (final row in (overflow as List)) (row as Map<String, dynamic>)['id'] as int,
      ];
      if (staleIds.isEmpty) return;
      await supabase.from('workspace_answer_turns').delete().inFilter('id', staleIds);
    } catch (e) {
      _log.warning('trimToRecent($workspaceId) failed, leaving extra rows: $e');
    }
  }
}
