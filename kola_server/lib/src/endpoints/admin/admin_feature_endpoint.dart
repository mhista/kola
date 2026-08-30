// admin_feature_endpoint.dart — kola_admin, step 3 of ADMIN_APP_SPEC.md's
// build order ("the reason this app exists now rather than later").
//
// Release control (§3.1): list every flag with its reconciliation
// status, move a flag between states, flip a whole wave, grant/revoke a
// per-workspace override. Every mutating method here does three things,
// always in this order:
//   1. capture the before-value
//   2. apply the change (FeatureFlagRepository/WorkspaceFeatureOverrideRepository)
//   3. FeatureFlagService.invalidate() — so the change is live in
//      seconds, not up to 30s later. Skipping this turns a kill switch
//      into a kill request — see feature_flag_service.dart's header.
//   4. AdminAuditLogRepository.record(...) — non-negotiable per
//      ADMIN_APP_SPEC.md §2/§5; there is no mutating method below that
//      doesn't end with a record() call.
//
// AUTH SHAPE: every method takes `adminToken` as a plain parameter, same
// convention workspace_access.dart established for `accessToken` and
// for the identical reason — an admin endpoint method's signature makes
// its own auth requirement visible; there's no way to accidentally ship
// one that forgot to check.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/admin_audit_log.dart';
import 'package:kola_server/src/services/admin/admin_user.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/repository/admin_audit_log_repository.dart';
import 'package:kola_server/src/services/repository/feature_flag_repository.dart';
import 'package:kola_server/src/services/repository/workspace_feature_override_repository.dart';

class AdminFeatureEndpoint extends Endpoint {
  FeatureFlagRepository get _flags => getIt<FeatureFlagRepository>();
  WorkspaceFeatureOverrideRepository get _overrides =>
      getIt<WorkspaceFeatureOverrideRepository>();
  FeatureFlagService get _resolver => getIt<FeatureFlagService>();
  AdminAuditLogRepository get _audit => getIt<AdminAuditLogRepository>();

  /// Every flag, raw platform state — NOT resolved per-workspace (that's
  /// FeatureFlagService.isEnabled's job, for the customer-facing side).
  /// Support level and above: read-only, safe for anyone with admin
  /// access at all.
  Future<List<FeatureFlag>> listFlags(Session session, String adminToken) async {
    await requireAdminLevel(adminToken: adminToken);
    return _flags.listAll();
  }

  /// The reconciliation banner's two halves — see FeatureFlagService
  /// .reconcile()'s own doc comment on why drift in either direction
  /// matters. Split into two methods rather than one record-returning
  /// method: Serverpod's RPC layer serializes declared model types and
  /// primitives cleanly; a bare Dart record is neither, so this avoids
  /// needing a new wire type for a two-list result.
  Future<List<String>> listMissingFeatureKeys(Session session, String adminToken) async {
    await requireAdminLevel(adminToken: adminToken);
    final result = await _resolver.reconcile();
    return result.missingInDb;
  }

  Future<List<String>> listOrphanedFeatureKeys(Session session, String adminToken) async {
    await requireAdminLevel(adminToken: adminToken);
    final result = await _resolver.reconcile();
    return result.orphanedInDb;
  }

  /// Moves one feature between states. `released` requires Owner; every
  /// other transition — including the kill switch, any state → `locked`
  /// — requires only Operator, per ADMIN_APP_SPEC.md §2/§3.1: "the
  /// ability to stop something breaking must never be gated behind
  /// finding a specific person at 2am."
  ///
  /// [note] is required for the audit trail, same "no unexplained
  /// change" posture WorkspaceFeatureOverride.note already enforces at
  /// the schema level for overrides — this table has no such column, so
  /// the check is here instead.
  Future<FeatureFlag> setFeatureState(
    Session session,
    String adminToken,
    String key,
    String newState,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required for every state change.');
    }

    final requiredLevel =
        newState == 'released' ? AdminLevel.owner : AdminLevel.operator_;
    final adminSession = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: requiredLevel,
    );

    final existing = await _flags.findByKey(key);
    if (existing == null) {
      throw KolaException(message: 'No feature flag with key "$key".');
    }

    // Server-enforced, not just a UI restriction — ADMIN_APP_SPEC.md
    // §3.1: "externally_gated features cannot be moved past beta until
    // the gate is cleared — the server enforces this, not just the UI."
    if (existing.externallyGated &&
        newState == 'released' &&
        existing.state != 'released') {
      throw KolaException(
        message: '"${existing.name}" is blocked on something outside the '
            'product (Meta App Review, an auditor, a signed BAA) — it '
            'cannot be released from here even by an Owner. Clear the '
            'external gate first.',
      );
    }

    await _flags.setState(key, newState);
    _resolver.invalidate();

    await _audit.record(AdminAuditLogEntry(
      actorEmail: adminSession.email,
      actorLevel: adminSession.level,
      action: 'feature.state_change',
      targetFeatureKey: key,
      beforeValue: existing.state,
      afterValue: newState,
      note: note,
    ));

    return (await _flags.findByKey(key))!;
  }

  /// Flips every not-yet-released, not-externally-gated flag in [wave]
  /// (e.g. 'R2') to `released`, in one audited action — "with a
  /// confirmation listing every feature it contains" is the dashboard's
  /// job (§3.1); this method is what it calls after that confirmation.
  /// Owner-only, same as any individual `released` transition, since a
  /// wave release affects every customer at once same as one flag does
  /// — just more of them in one motion.
  Future<List<FeatureFlag>> releaseWave(
    Session session,
    String adminToken,
    String wave,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required for a wave release.');
    }
    final adminSession = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.owner,
    );

    final all = await _flags.listAll();
    final inWave = all.where((f) => f.releasePhase == wave).toList();
    if (inWave.isEmpty) {
      throw KolaException(message: 'No features are tagged release phase "$wave".');
    }

    final released = <FeatureFlag>[];
    for (final flag in inWave) {
      if (flag.state == 'released') continue;
      if (flag.externallyGated) {
        // Skipped, not failed — a wave release moves everything it
        // CAN move; an externally-gated feature inside a wave stays
        // wherever it was until its own gate clears, exactly like a
        // single setFeatureState call would refuse it.
        continue;
      }
      await _flags.setState(flag.key, 'released');
      await _audit.record(AdminAuditLogEntry(
        actorEmail: adminSession.email,
        actorLevel: adminSession.level,
        action: 'feature.wave_release',
        targetFeatureKey: flag.key,
        beforeValue: flag.state,
        afterValue: 'released',
        note: '$note (wave $wave)',
      ));
      released.add(flag);
    }

    _resolver.invalidate();
    final updated = await _flags.listAll();
    return updated.where((f) => f.releasePhase == wave).toList();
  }

  /// Grants (enabled=true, the beta/design-partner mechanism) or revokes
  /// access (enabled=false, the per-workspace kill switch) for one
  /// workspace on one feature. Operator level — this is exactly the
  /// "grant/revoke beta overrides" capability ADMIN_APP_SPEC.md §2's
  /// table lists for Operator, not Owner.
  Future<WorkspaceFeatureOverride> setOverride(
    Session session,
    String adminToken,
    int workspaceId,
    String featureKey,
    bool enabled,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required for every override.');
    }
    final adminSession = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.operator_,
    );

    final flag = await _flags.findByKey(featureKey);
    if (flag == null) {
      throw KolaException(message: 'No feature flag with key "$featureKey".');
    }

    // Same server-enforced rule as setFeatureState — an override cannot
    // do what a direct state change also cannot: switch on something
    // blocked outside the product. feature_flag_service.dart's resolver
    // already ignores such an override at read time (step 2 of its
    // precedence order), but refusing to WRITE one here is the more
    // honest behaviour — an admin looking at the override list should
    // never see one sitting there that quietly does nothing.
    if (enabled && flag.externallyGated && flag.state != 'released') {
      throw KolaException(
        message: '"${flag.name}" is externally gated and not yet released — '
            'no override can switch it on early for this workspace.',
      );
    }

    final override = WorkspaceFeatureOverride(
      workspaceId: workspaceId,
      featureKey: featureKey,
      enabled: enabled,
      note: note,
      createdBy: adminSession.email,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    await _overrides.upsert(override);
    _resolver.invalidate();

    await _audit.record(AdminAuditLogEntry(
      actorEmail: adminSession.email,
      actorLevel: adminSession.level,
      action: enabled ? 'feature.override_grant' : 'feature.override_disable',
      targetWorkspaceId: workspaceId,
      targetFeatureKey: featureKey,
      afterValue: enabled.toString(),
      note: note,
    ));

    return override;
  }

  /// Removes an override entirely, returning the workspace to whatever
  /// the platform-wide state says — distinct from setOverride(enabled:
  /// false), which is an active decision to keep a feature off for this
  /// workspace even after general release. See
  /// WorkspaceFeatureOverrideRepository.remove's own doc comment.
  Future<void> removeOverride(
    Session session,
    String adminToken,
    int workspaceId,
    String featureKey,
  ) async {
    final adminSession = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.operator_,
    );

    await _overrides.remove(workspaceId, featureKey);
    _resolver.invalidate();

    await _audit.record(AdminAuditLogEntry(
      actorEmail: adminSession.email,
      actorLevel: adminSession.level,
      action: 'feature.override_remove',
      targetWorkspaceId: workspaceId,
      targetFeatureKey: featureKey,
      note: 'Override removed — workspace now follows platform state.',
    ));
  }

  /// "Who is in this beta?" — every workspace with an override for one
  /// feature. Support level: read-only.
  Future<List<WorkspaceFeatureOverride>> listOverridesForFeature(
    Session session,
    String adminToken,
    String featureKey,
  ) async {
    await requireAdminLevel(adminToken: adminToken);
    return _overrides.listByFeature(featureKey);
  }
}
