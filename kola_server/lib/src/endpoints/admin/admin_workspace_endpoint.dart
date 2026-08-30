// admin_workspace_endpoint.dart — kola_admin, ADMIN_APP_SPEC.md §3.2,
// build-order step 4.
//
// WHAT THIS PASS COVERS, STATED HONESTLY AGAINST THE SPEC'S FULL LIST:
//   Covered: search by name or exact numeric id, per-workspace detail
//   (plan/status/trial dates/isInternal, bots, channels), change plan,
//   extend trial, reset trial, suspend, reinstate, mark internal — every
//   one of these audited before returning, same discipline as
//   AdminFeatureEndpoint.
//
//   NOT covered, deliberately deferred rather than half-built:
//     - Search by owner email or connected phone number (see
//       WorkspaceRepository.search's header — owner email lives in
//       Supabase Auth's auth.users, phone number lives inside encrypted
//       channel credentials; neither is wired to a searchable index).
//     - Usage against limits, knowledge-document index status,
//       subscription/payment history — no aggregation service exists
//       for any of these yet.
//     - Impersonation — a real, separate feature (needs its own
//       session-issuance design, audit shape, and time-limit mechanism)
//       intentionally not improvised as a rider on this endpoint.
//   kola_admin's workspace page surfaces these as visible "not built"
//   states, not silently missing buttons.
//
// AUTHORISATION, PER THE SPEC'S OWN TABLE (§2):
//   Support:  read-only (listWorkspaces, getWorkspace, listBots,
//             listChannels), extendTrial ("extend a trial" is explicitly
//             a Support-level action).
//   Operator: everything Support can, plus setPlan ("change plans"),
//             suspend/reinstate ("suspend a workspace"), resetTrial (not
//             named explicitly in the table, but strictly more
//             consequential than a plain extension — full trial restart
//             — so held to the same bar as suspend rather than left at
//             Support).
//   Owner:    setInternal — the spec's table doesn't name a level for
//             this explicitly either, but its own reasoning ("a
//             workspace that could mark itself internal could unlock the
//             entire unreleased roadmap") is the same severity class as
//             flipping a feature flag to `released` platform-wide, which
//             IS Owner-only in AdminFeatureEndpoint.setFeatureState — so
//             this follows that precedent rather than inventing a new
//             bar.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/admin_audit_log.dart';
import 'package:kola_server/src/services/admin/admin_user.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';
import 'package:kola_server/src/services/repository/admin_audit_log_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';

class AdminWorkspaceEndpoint extends Endpoint {
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  BotRepository get _bots => getIt<BotRepository>();
  ChannelRepository get _channels => getIt<ChannelRepository>();
  AdminAuditLogRepository get _audit => getIt<AdminAuditLogRepository>();

  /// Search by name substring or exact numeric id — see
  /// WorkspaceRepository.search's header for what's NOT covered yet
  /// (owner email, phone number). Empty [query] returns the most
  /// recently created workspaces. Support level: read-only.
  Future<List<Workspace>> listWorkspaces(
    Session session,
    String adminToken, {
    String? query,
  }) async {
    await requireAdminLevel(adminToken: adminToken);
    return _workspaces.search(query: query);
  }

  /// A single workspace's core record — plan, status, trial dates,
  /// isInternal. Support level: read-only.
  Future<Workspace?> getWorkspace(
    Session session,
    String adminToken,
    int workspaceId,
  ) async {
    await requireAdminLevel(adminToken: adminToken);
    return _workspaces.findById(workspaceId);
  }

  /// Every bot in this workspace — part of §3.2's "per workspace: bots
  /// and their status." Support level: read-only.
  Future<List<Bot>> listBotsForWorkspace(
    Session session,
    String adminToken,
    int workspaceId,
  ) async {
    await requireAdminLevel(adminToken: adminToken);
    return _bots.listByWorkspace(workspaceId);
  }

  /// Every channel connected to one bot — part of §3.2's "connected
  /// channels and health." Support level: read-only. Takes a bot id
  /// (not workspaceId) because Channel is scoped to Bot, not directly to
  /// Workspace — same shape ChannelRepository already uses everywhere
  /// else in this codebase.
  Future<List<Channel>> listChannelsForBot(
    Session session,
    String adminToken,
    int botId,
  ) async {
    await requireAdminLevel(adminToken: adminToken);
    return _channels.listByBot(botId);
  }

  /// Changes plan only — see WorkspaceRepository.setPlan's header on why
  /// this is deliberately separate from setPlanAndStatus. Operator level
  /// ("change plans" per the spec's table).
  Future<Workspace> setPlan(
    Session session,
    String adminToken,
    int workspaceId,
    String plan,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required for a plan change.');
    }
    final admin = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.operator_,
    );

    final existing = await _workspaces.findById(workspaceId);
    if (existing == null) {
      throw KolaException(message: 'No workspace with id $workspaceId.');
    }

    final updated = await _workspaces.setPlan(workspaceId, plan);

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'workspace.plan_change',
      targetWorkspaceId: workspaceId,
      beforeValue: existing.plan,
      afterValue: plan,
      note: note,
    ));

    return updated;
  }

  /// Pushes the trial window forward by [days] without changing status
  /// — see WorkspaceRepository.extendTrial's header. Support level
  /// ("extend a trial" per the spec's table — the one mutating action
  /// this table grants below Operator).
  Future<Workspace> extendTrial(
    Session session,
    String adminToken,
    int workspaceId,
    int days,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required for a trial extension.');
    }
    if (days <= 0) {
      throw KolaException(message: 'Extension must be a positive number of days.');
    }
    final admin = await requireAdminLevel(adminToken: adminToken);

    final existing = await _workspaces.findById(workspaceId);
    if (existing == null) {
      throw KolaException(message: 'No workspace with id $workspaceId.');
    }

    final updated = await _workspaces.extendTrial(workspaceId, days);

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'workspace.trial_extend',
      targetWorkspaceId: workspaceId,
      beforeValue: existing.trialEndsAt.toIso8601String(),
      afterValue: updated.trialEndsAt.toIso8601String(),
      note: '$note (+$days day(s))',
    ));

    return updated;
  }

  /// Full trial restart — see WorkspaceRepository.resetTrial's header on
  /// why this is a separate, more consequential action than extendTrial.
  /// Operator level.
  Future<Workspace> resetTrial(
    Session session,
    String adminToken,
    int workspaceId,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required for a trial reset.');
    }
    final admin = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.operator_,
    );

    final existing = await _workspaces.findById(workspaceId);
    if (existing == null) {
      throw KolaException(message: 'No workspace with id $workspaceId.');
    }

    final updated = await _workspaces.resetTrial(workspaceId);

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'workspace.trial_reset',
      targetWorkspaceId: workspaceId,
      beforeValue: 'status=${existing.status}, trialEndsAt=${existing.trialEndsAt.toIso8601String()}',
      afterValue: 'status=${updated.status}, trialEndsAt=${updated.trialEndsAt.toIso8601String()}',
      note: note,
    ));

    return updated;
  }

  /// Sets status to `paused` — §3.2's "suspend." Data is retained, the
  /// bot goes silent (WorkspaceRepository/status semantics unchanged
  /// from the existing trial-pause meaning of `paused`; this endpoint is
  /// just a second, admin-triggered path to the same status value).
  /// Operator level ("suspend a workspace" per the spec's table).
  Future<Workspace> suspend(
    Session session,
    String adminToken,
    int workspaceId,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required to suspend a workspace.');
    }
    final admin = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.operator_,
    );

    final existing = await _workspaces.findById(workspaceId);
    if (existing == null) {
      throw KolaException(message: 'No workspace with id $workspaceId.');
    }

    final updated = await _workspaces.setStatus(workspaceId, 'paused');

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'workspace.suspend',
      targetWorkspaceId: workspaceId,
      beforeValue: existing.status,
      afterValue: 'paused',
      note: note,
    ));

    return updated;
  }

  /// Reverses [suspend]. The target status is inferred rather than
  /// always forced to 'active': a workspace on the free plan goes back
  /// to 'trialing' (it was never paying — restoring it to 'active' would
  /// misrepresent it as a paid account), anything else goes to 'active'.
  /// Operator level, symmetric with suspend.
  Future<Workspace> reinstate(
    Session session,
    String adminToken,
    int workspaceId,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required to reinstate a workspace.');
    }
    final admin = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.operator_,
    );

    final existing = await _workspaces.findById(workspaceId);
    if (existing == null) {
      throw KolaException(message: 'No workspace with id $workspaceId.');
    }

    final targetStatus = existing.plan == 'free' ? 'trialing' : 'active';
    final updated = await _workspaces.setStatus(workspaceId, targetStatus);

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'workspace.reinstate',
      targetWorkspaceId: workspaceId,
      beforeValue: existing.status,
      afterValue: targetStatus,
      note: note,
    ));

    return updated;
  }

  /// The ONLY admin-reachable path to `workspaces.is_internal` — see
  /// workspace.spy.yaml's field comment: no customer-facing endpoint can
  /// ever set this. Owner level — see this file's header for why this
  /// is held to the same bar as flipping a feature to `released`.
  Future<Workspace> setInternal(
    Session session,
    String adminToken,
    int workspaceId,
    bool isInternal,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required to change internal status.');
    }
    final admin = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.owner,
    );

    final existing = await _workspaces.findById(workspaceId);
    if (existing == null) {
      throw KolaException(message: 'No workspace with id $workspaceId.');
    }

    final updated = await _workspaces.setInternal(workspaceId, isInternal);

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'workspace.set_internal',
      targetWorkspaceId: workspaceId,
      beforeValue: existing.isInternal.toString(),
      afterValue: isInternal.toString(),
      note: note,
    ));

    return updated;
  }
}
