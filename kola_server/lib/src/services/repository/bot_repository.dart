// bot_repository.dart
//
// All database read/write operations for Bot records.
//
// MULTI-TENANCY: every method here takes or filters by workspaceId — a Bot
// is never fetched by its bare id alone in a context where the caller
// hasn't already established which workspace they're allowed to touch.
// findById exists for the rare internal case (e.g. a background job that
// already trusts its input); endpoint-facing code should prefer
// findByIdScoped so a workspace can never accidentally read another
// workspace's bot by guessing an id.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/bot_dto.dart';
import 'supabase_client.dart';

final _log = Logger('BotRepository');

const _dto = BotDto();

class BotRepository {
  const BotRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Internal-only lookup by bare id — see class-level note on why
  /// endpoint code should prefer [findByIdScoped] instead.
  Future<Bot?> findById(int id) async {
    _log.fine('findById($id)');
    final response = await supabase
        .from('bots')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Workspace-scoped lookup — returns null both when the bot doesn't
  /// exist AND when it exists but belongs to a different workspace. The
  /// caller can't distinguish the two cases from this method alone, which
  /// is intentional: leaking "this id exists, just not for you" is its
  /// own small information disclosure worth avoiding.
  Future<Bot?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, workspaceId=$workspaceId)');
    final response = await supabase
        .from('bots')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every bot belonging to a workspace.
  Future<List<Bot>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('bots')
        .select()
        .eq('workspace_id', workspaceId);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Create a new bot inside a workspace. Starts life as 'draft' —
  /// Bot Mother/the onboarding wizard flips it to 'live' once a channel
  /// is actually connected (Phase 2).
  Future<Bot> create({
    required int workspaceId,
    required String name,
    required String archetype,
  }) async {
    final now = DateTime.now().toUtc();
    _log.info('Creating bot workspaceId=$workspaceId name=$name');

    final bot = Bot(
      workspaceId: workspaceId,
      name: name,
      archetype: archetype,
      status: 'draft',
      createdAt: now,
      updatedAt: now,
    );

    final row = _dto.toRow(bot, includeId: false);
    row['created_at'] = now.toIso8601String();

    final response = await supabase.from('bots').insert(row).select().single();

    return _dto.fromRow(response);
  }

  /// Update mutable fields (name, archetype). Matches on id — callers
  /// must have already confirmed workspace ownership via findByIdScoped
  /// before calling this.
  Future<Bot> update(Bot bot) async {
    _log.info('Updating bot id=${bot.id}');
    final row = _dto.toRow(bot, includeId: false);
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await supabase
        .from('bots')
        .update(row)
        .eq('id', bot.id!)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Transition a bot's lifecycle status ('draft' | 'live' | 'paused').
  Future<Bot> setStatus(int botId, String status) async {
    _log.info('setStatus botId=$botId status=$status');
    final response = await supabase
        .from('bots')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', botId)
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
