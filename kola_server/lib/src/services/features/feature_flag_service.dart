// feature_flag_service.dart
//
// PHASE 10 — THE RESOLVER. The single place that answers "can this
// workspace see this feature right now?"
//
// Nothing else in this codebase should read feature_flags or
// workspace_feature_overrides directly, and nothing should re-implement
// the precedence rules below. There is exactly one resolution order and
// it lives in [isEnabled].
//
// ── RESOLUTION ORDER, most-decisive first ────────────────────────────────
//
//   0. UNKNOWN KEY → false, loudly.
//      A key with no row in the database is a deployment error, not a
//      disabled feature. It fails closed AND logs at severe, because the
//      silent version of this bug — a shipped feature nobody can see and
//      nobody knows is missing — is the single worst outcome this system
//      can produce.
//
//   1. EXPLICIT DISABLE always wins.
//      An override with enabled=false disables the feature for that
//      workspace no matter what, including a fully released feature.
//      This exists so one workspace hitting a bug can be switched off
//      individually instead of the whole platform being killed.
//
//   2. EXTERNALLY GATED features cannot be switched ON early.
//      If externallyGated is true and the feature is not yet 'released',
//      no override can enable it. These are features blocked on
//      something outside the product — an auditor's report, a signed
//      BAA, a Meta App Review approval. An admin should not be able to
//      cheerfully switch on SSO-for-enterprise because a prospect asked.
//
//   3. EXPLICIT ENABLE wins for everything else.
//      The design-partner mechanism.
//
//   4. Otherwise, the platform-wide state decides:
//        locked   → false
//        internal → only workspaces marked internal
//        beta     → false (beta means "override-only"; no override, no
//                   feature — this is why beta is opt-in per workspace
//                   rather than a percentage rollout)
//        released → true, subject to minimumPlan
//
//   5. MINIMUM PLAN is checked last, and only for released features.
//      A beta feature reaches its workspace regardless of plan — a
//      design partner on the free tier is still a design partner.
//
// ── WHY THERE IS A CACHE, AND WHY IT IS SHORT ────────────────────────────
//   isEnabled sits on the inbound-message path. An uncached
//   implementation would add two database round trips to every customer
//   WhatsApp message, which is unacceptable for a table that changes a
//   few times a month.
//
//   TTL is deliberately SHORT (30s) rather than long, because this
//   system's most urgent operation is the kill switch: flipping a broken
//   feature to 'locked' at 2am must take effect in seconds, not minutes.
//   30s is the compromise between that and the round trips. [invalidate]
//   exists so kola_admin can make an unlock take effect immediately
//   rather than waiting out the TTL.

import 'package:logging/logging.dart';

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/billing/trial_state_machine.dart';
import 'package:kola_server/src/services/repository/feature_flag_repository.dart';
import 'package:kola_server/src/services/repository/workspace_feature_override_repository.dart';

import 'feature_keys.dart';

final _log = Logger('FeatureFlagService');

/// Thrown by [FeatureFlagService.require] when a gated feature is off.
/// A distinct exception type so endpoints and the dashboard can tell
/// "this feature isn't available to you" apart from a real error — the
/// two need completely different treatment in the UI.
class FeatureDisabledException implements Exception {
  const FeatureDisabledException(this.featureKey, this.message);

  final String featureKey;
  final String message;

  @override
  String toString() => message;
}

class FeatureFlagService {
  FeatureFlagService({
    required FeatureFlagRepository flags,
    required WorkspaceFeatureOverrideRepository overrides,
    required TrialStateMachine trialStateMachine,
    Duration cacheTtl = const Duration(seconds: 30),
  })  : _flags = flags,
        _overrides = overrides,
        _trialStateMachine = trialStateMachine,
        _cacheTtl = cacheTtl;

  final FeatureFlagRepository _flags;
  final WorkspaceFeatureOverrideRepository _overrides;
  final TrialStateMachine _trialStateMachine;
  final Duration _cacheTtl;

  // Global flag cache — one entry per feature, ~45 rows total. Bounded
  // and tiny, so it is held whole rather than per-key.
  Map<String, FeatureFlag>? _flagCache;
  DateTime? _flagCacheAt;

  // Per-workspace override cache. Bounded by ACTIVE workspace count
  // within one TTL window, not by total workspaces — an idle workspace
  // never enters it. Entries are evicted lazily on read rather than by a
  // timer, so an idle server holds nothing.
  final Map<int, _OverrideCacheEntry> _overrideCache = {};

  /// Clears every cache. Called by kola_admin immediately after any flag
  /// or override change so the change takes effect now rather than
  /// within the TTL — the difference that makes a kill switch a kill
  /// switch.
  void invalidate() {
    _log.info('Feature flag cache invalidated');
    _flagCache = null;
    _flagCacheAt = null;
    _overrideCache.clear();
  }

  /// The one question this service answers. See the file header for the
  /// full precedence order.
  ///
  /// Never throws. A database failure resolves to the last cached value
  /// if one exists, and false otherwise — see [_loadFlags]. A feature
  /// check must not be able to take down the message path.
  Future<bool> isEnabled(String featureKey, Workspace workspace) async {
    final flags = await _loadFlags();
    final flag = flags[featureKey];

    // 0. Unknown key — deployment error, fail closed, say so loudly.
    if (flag == null) {
      _log.severe(
        'Unknown feature key "$featureKey" — no row in feature_flags. '
        'This feature is INVISIBLE to every workspace. Seed it (see '
        'FeatureKeys.allKeys and migration 018) or remove the check.',
      );
      return false;
    }

    final state = featureStateFromString(flag.state);
    final override = await _overrideFor(workspace.id!, featureKey);

    // 1. Explicit disable always wins, even over 'released'.
    if (override != null && !override.enabled) return false;

    // 2. Externally gated features cannot be switched on early.
    if (flag.externallyGated && state != FeatureState.released) {
      if (override != null && override.enabled) {
        _log.warning(
          'Override tried to enable externally-gated feature '
          '"$featureKey" for workspace ${workspace.id} while it is '
          '"${flag.state}". Ignored — this feature is blocked on '
          'something outside the product, not on a switch.',
        );
      }
      return false;
    }

    // 3. Explicit enable wins for everything else. Deliberately NOT
    //    subject to minimumPlan — a design partner on the free tier is
    //    still a design partner.
    if (override != null && override.enabled) return true;

    // 4. Platform-wide state.
    switch (state) {
      case FeatureState.locked:
        return false;
      case FeatureState.internal:
        return workspace.isInternal;
      case FeatureState.beta:
        // No override reached step 3, so this workspace is not in the
        // beta. Beta means override-only by design.
        return false;
      case FeatureState.released:
        return _meetsMinimumPlan(flag, workspace);
    }
  }

  /// Throws [FeatureDisabledException] when the feature is off. The
  /// endpoint-guard form of [isEnabled] — one line at the top of a
  /// gated endpoint.
  Future<void> require(String featureKey, Workspace workspace) async {
    if (await isEnabled(featureKey, workspace)) return;
    throw FeatureDisabledException(
      featureKey,
      // Deliberately vague about WHY. A customer-facing message should
      // not distinguish "not released yet" from "your plan doesn't
      // include it" from "we switched it off for you after a bug" —
      // the first leaks roadmap, the third is alarming. The admin
      // dashboard shows the real reason; the customer sees this.
      'That feature is not available on this workspace yet.',
    );
  }

  /// Every feature key currently enabled for [workspace]. The dashboard
  /// calls this ONCE on load and renders navigation from the result,
  /// rather than checking flags per component — which would be dozens of
  /// round trips to build one page.
  Future<Set<String>> enabledFeatures(Workspace workspace) async {
    final flags = await _loadFlags();
    final enabled = <String>{};
    for (final key in flags.keys) {
      if (await isEnabled(key, workspace)) enabled.add(key);
    }
    return enabled;
  }

  /// Keys declared in code but absent from the database, and vice versa.
  /// Surfaced by kola_admin on load — see feature_keys.dart on why drift
  /// in either direction is a real problem rather than housekeeping.
  Future<({List<String> missingInDb, List<String> orphanedInDb})>
      reconcile() async {
    final flags = await _loadFlags();
    final dbKeys = flags.keys.toSet();
    const codeKeys = FeatureKeys.allKeys;
    return (
      missingInDb: [for (final k in codeKeys) if (!dbKeys.contains(k)) k],
      orphanedInDb: [for (final k in dbKeys) if (!codeKeys.contains(k)) k],
    );
  }

  // ── internals ─────────────────────────────────────────────────────────

  bool _meetsMinimumPlan(FeatureFlag flag, Workspace workspace) {
    final minimum = flag.minimumPlan;
    if (minimum == null || minimum.isEmpty) return true;

    // Read the EFFECTIVE tier, not workspace.plan directly — a workspace
    // inside its 48-hour full trial should see paid features, and a
    // lapsed one should not, which is exactly what TrialStateMachine
    // already encodes. Reading .plan here would silently bypass the
    // whole trial mechanic.
    final tier = _trialStateMachine.effectiveTier(workspace);
    return switch (tier) {
      EffectiveTier.fullTrial => true,
      EffectiveTier.paid => true,
      EffectiveTier.cappedFree => false,
      EffectiveTier.paused => false,
    };
  }

  Future<Map<String, FeatureFlag>> _loadFlags() async {
    final cached = _flagCache;
    final cachedAt = _flagCacheAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    try {
      final rows = await _flags.listAll();
      final map = {for (final flag in rows) flag.key: flag};
      _flagCache = map;
      _flagCacheAt = DateTime.now();
      return map;
    } catch (e) {
      // Serve stale rather than fail. A database blip must not turn
      // every feature off across the platform — which is precisely what
      // returning an empty map would do, given step 0 fails closed.
      if (cached != null) {
        _log.warning('Feature flag reload failed, serving stale cache: $e');
        return cached;
      }
      _log.severe('Feature flag load failed with no cache to fall back on. '
          'Every gated feature will resolve to disabled until this '
          'recovers: $e');
      return const {};
    }
  }

  Future<WorkspaceFeatureOverride?> _overrideFor(
    int workspaceId,
    String featureKey,
  ) async {
    final entry = _overrideCache[workspaceId];
    if (entry != null && DateTime.now().difference(entry.loadedAt) < _cacheTtl) {
      return entry.byKey[featureKey];
    }

    try {
      final rows = await _overrides.listByWorkspace(workspaceId);
      final byKey = {for (final row in rows) row.featureKey: row};
      _overrideCache[workspaceId] = _OverrideCacheEntry(byKey, DateTime.now());
      return byKey[featureKey];
    } catch (e) {
      // Same posture as _loadFlags: stale beats broken. With no cache,
      // returning null means "no override", which falls through to the
      // platform state — the safe default.
      _log.warning('Override load failed for workspace $workspaceId: $e');
      return entry?.byKey[featureKey];
    }
  }
}

class _OverrideCacheEntry {
  _OverrideCacheEntry(this.byKey, this.loadedAt);
  final Map<String, WorkspaceFeatureOverride> byKey;
  final DateTime loadedAt;
}
