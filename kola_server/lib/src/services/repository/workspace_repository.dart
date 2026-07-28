// workspace_repository.dart
//
// All database read/write operations for Workspace records — the tenant
// root every other domain model hangs off of (SRS.md §5/§6).
//
// PATTERN:
//   Every method speaks only in Serverpod model types (Workspace).
//   Supabase JSON is handled entirely inside this file via WorkspaceDto.
//   Callers (endpoints, services) never see raw Maps.
//
// MULTI-TENANCY NOTE:
//   Workspace itself has no parent to scope by — it IS the isolation
//   boundary. Every OTHER repository in this project (bot, channel,
//   workspace_member, and everything added in later phases) must filter
//   by workspaceId on every query. This repository is where that
//   boundary starts.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/workspace_dto.dart';
import 'supabase_client.dart';

final _log = Logger('WorkspaceRepository');

const _dto = WorkspaceDto();

class WorkspaceRepository {
  const WorkspaceRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Find a workspace by its Supabase integer PK.
  /// Returns null if no workspace exists with this id.
  Future<Workspace?> findById(int id) async {
    _log.fine('findById($id)');
    final response = await supabase
        .from('workspaces')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Get every workspace currently in the given [status] — used by the
  /// Phase 5 trial state machine to find workspaces whose trial window
  /// has just crossed the 48-hour or 14-day mark.
  Future<List<Workspace>> listByStatus(String status) async {
    _log.fine('listByStatus($status)');
    final response = await supabase
        .from('workspaces')
        .select()
        .eq('status', status);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Create a new workspace, computing its trial window from [now].
  ///
  /// This is the ONLY place trial dates get computed from scratch — every
  /// other read of trialFullAccessEndsAt/trialEndsAt is a plain column
  /// read, never re-derived, so the trial window can never silently drift
  /// if this method is called at a slightly different time than the
  /// workspace's actual createdAt.
  Future<Workspace> create({
    required String name,
    String? industryTag,
    DateTime? now,
  }) async {
    final createdAt = now ?? DateTime.now().toUtc();
    _log.info('Creating workspace name=$name');

    final workspace = Workspace(
      name: name,
      industryTag: industryTag,
      plan: 'free',
      status: 'trialing',
      trialStartedAt: createdAt,
      trialFullAccessEndsAt: createdAt.add(const Duration(hours: 48)),
      trialEndsAt: createdAt.add(const Duration(days: 14)),
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final row = _dto.toRow(workspace, includeId: false);
    row['created_at'] = createdAt.toIso8601String();

    final response = await supabase
        .from('workspaces')
        .insert(row)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Update mutable fields on an existing workspace. Matches on id.
  Future<Workspace> update(Workspace workspace) async {
    _log.info('Updating workspace id=${workspace.id}');
    final row = _dto.toRow(workspace, includeId: false);
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await supabase
        .from('workspaces')
        .update(row)
        .eq('id', workspace.id!)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Transition a workspace's lifecycle status (see workspace.spy.yaml for
  /// the 'trialing' | 'active' | 'paused' values). Kept as a dedicated
  /// method rather than a generic update so every status change is easy
  /// to grep for and audit later — this is the single most consequential
  /// field on the model (it decides whether a bot responds to customers).
  Future<Workspace> setStatus(int workspaceId, String status) async {
    _log.info('setStatus workspaceId=$workspaceId status=$status');
    final response = await supabase
        .from('workspaces')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Task #148 — the one write KolaBillingWebhookHandler makes on a
  /// confirmed Kola subscription payment: flips both plan and status
  /// together, atomically, since "paid but still shown as trialing" (or
  /// the reverse) is exactly the kind of half-updated state a generic
  /// two-call update() would risk if the second call ever failed. Same
  /// "dedicated method for the most consequential fields" reasoning as
  /// [setStatus] above.
  Future<Workspace> setPlanAndStatus({
    required int workspaceId,
    required String plan,
    required String status,
  }) async {
    _log.info('setPlanAndStatus workspaceId=$workspaceId plan=$plan status=$status');
    final response = await supabase
        .from('workspaces')
        .update({
          'plan': plan,
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
