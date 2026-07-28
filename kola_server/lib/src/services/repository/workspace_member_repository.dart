// workspace_member_repository.dart
//
// All database read/write operations for WorkspaceMember records — the
// join between a Supabase Auth user and a Workspace, carrying the role
// that Phase 1d's auth layer checks on every request (SRS.md §5).

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/workspace_member_dto.dart';
import 'supabase_client.dart';

final _log = Logger('WorkspaceMemberRepository');

const _dto = WorkspaceMemberDto();

class WorkspaceMemberRepository {
  const WorkspaceMemberRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Every membership row for a given workspace — used to render the
  /// dashboard's team/member list.
  Future<List<WorkspaceMember>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('workspace_members')
        .select()
        .eq('workspace_id', workspaceId);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every workspace a given Supabase Auth user belongs to — this is what
  /// powers the dashboard's workspace switcher (relevant once the agency/
  /// multi-workspace tier lands, but correct from day one either way).
  Future<List<WorkspaceMember>> listByUser(String userId) async {
    _log.fine('listByUser($userId)');
    final response = await supabase
        .from('workspace_members')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// The specific membership row for (workspaceId, userId), or null if
  /// this user has no access to this workspace. This is the exact check
  /// Phase 1d's auth middleware runs on every workspace-scoped request —
  /// see the multi-tenancy note in supabase_client.dart.
  Future<WorkspaceMember?> findByWorkspaceAndUser(
    int workspaceId,
    String userId,
  ) async {
    _log.fine('findByWorkspaceAndUser($workspaceId, $userId)');
    final response = await supabase
        .from('workspace_members')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Add a user to a workspace with the given [role]. Called once at
  /// workspace creation (the creator becomes 'owner') and again whenever
  /// an owner invites staff or a developer.
  Future<WorkspaceMember> addMember({
    required int workspaceId,
    required String userId,
    required String role,
  }) async {
    _log.info('addMember workspaceId=$workspaceId userId=$userId role=$role');
    final member = WorkspaceMember(
      workspaceId: workspaceId,
      userId: userId,
      role: role,
      createdAt: DateTime.now().toUtc(),
    );

    final row = _dto.toRow(member, includeId: false);
    final response = await supabase
        .from('workspace_members')
        .insert(row)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Change a member's role. Kept separate from a generic update because
  /// role is the one field on this model that actually changes after
  /// creation — createdAt/workspaceId/userId are immutable in practice.
  Future<void> updateRole({
    required int workspaceId,
    required String userId,
    required String role,
  }) async {
    _log.info('updateRole workspaceId=$workspaceId userId=$userId role=$role');
    await supabase
        .from('workspace_members')
        .update({'role': role})
        .eq('workspace_id', workspaceId)
        .eq('user_id', userId);
  }

  /// Remove a user's access to a workspace entirely.
  Future<void> removeMember({
    required int workspaceId,
    required String userId,
  }) async {
    _log.info('removeMember workspaceId=$workspaceId userId=$userId');
    await supabase
        .from('workspace_members')
        .delete()
        .eq('workspace_id', workspaceId)
        .eq('user_id', userId);
  }
}
