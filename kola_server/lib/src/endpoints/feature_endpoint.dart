// feature_endpoint.dart
//
// PHASE 10. The customer-facing read side of release control — the ONLY
// feature-flag surface kola_dashboard can reach.
//
// READ-ONLY, DELIBERATELY AND COMPLETELY. There is no method here that
// changes a flag or creates an override. All of that lives in
// kola_admin, behind separate auth, in a separate deployable. A
// customer-reachable write path into this table would let a workspace
// unlock the entire unreleased roadmap, which would make the release
// system decorative.
//
// WHY listEnabledFeatures RETURNS A LIST AND NOT A PER-FEATURE CHECK:
// the dashboard needs to know what to render BEFORE it renders — which
// nav items exist, which pages route, which cards appear. Asking
// per-component would be dozens of round trips to build one page. One
// call on load, cached client-side for that session.
//
// WHAT THIS DELIBERATELY DOES NOT LEAK: only ENABLED keys come back.
// A locked feature is absent from the response entirely — not present
// with `false`. The locked set is an unreleased product roadmap, and a
// customer inspecting network traffic should not be able to read it.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';

class FeatureEndpoint extends Endpoint {
  FeatureFlagService get _features => getIt<FeatureFlagService>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();

  /// Every feature key currently available to this workspace.
  ///
  /// The dashboard calls this once on load and renders navigation and
  /// routes from the result. Keys absent from the list do not exist as
  /// far as that session is concerned — see this file's header on why
  /// absence rather than `false`.
  Future<List<String>> listEnabledFeatures(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw Exception('Workspace $workspaceId not found.');
    }

    final enabled = await _features.enabledFeatures(workspace);
    return enabled.toList()..sort();
  }

  /// Whether one specific feature is available. Exists for the case
  /// where a page needs to re-check after a plan upgrade without
  /// reloading the whole set — not as the general mechanism.
  ///
  /// Returns false for an unknown key rather than throwing, matching
  /// FeatureFlagService's fail-closed posture: a dashboard built against
  /// a newer server should degrade to hiding a feature, never to an
  /// error screen.
  Future<bool> isFeatureEnabled(
    Session session,
    String accessToken,
    int workspaceId,
    String featureKey,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) return false;

    return _features.isEnabled(featureKey, workspace);
  }
}
