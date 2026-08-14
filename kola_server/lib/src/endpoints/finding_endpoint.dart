// finding_endpoint.dart — "Needs your attention", served.
//
// ── WHY THE READ RUNS THE SWEEP ──────────────────────────────────────
//
// [listFindings] sweeps and then returns, rather than reading whatever
// the last scheduled pass left behind.
//
// There is no scheduler yet. Serving stale rows from a table nothing
// writes would mean an owner who just restocked still sees the alert,
// and the first thing they would learn about this feature is that it
// lies. A sweep is a handful of indexed reads over one workspace, which
// is the same order of cost as the Overview's other calls.
//
// When a scheduled pass does exist, this becomes a plain read and the
// sweep moves behind it. The seam is already right: the endpoint depends
// on the SERVICE, not on the timing.
//
// EVERY METHOD CALLS requireWorkspaceAccess FIRST, same as every other
// endpoint here.

import 'package:serverpod/serverpod.dart';

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/observation/workspace_sweep_service.dart';
import 'package:kola_server/src/services/repository/workspace_finding_repository.dart';

class FindingEndpoint extends Endpoint {
  WorkspaceSweepService get _sweep => getIt<WorkspaceSweepService>();
  WorkspaceFindingRepository get _findings =>
      getIt<WorkspaceFindingRepository>();

  /// What needs the owner's attention, worst first.
  ///
  /// Never throws for a workspace with nothing wrong — an empty list is
  /// the correct and common answer, and the dashboard renders it as
  /// "all clear" rather than as a failure.
  Future<List<WorkspaceFinding>> listFindings(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );
    return _sweep.sweep(workspaceId);
  }

  /// "I know about this one." Permanent — see migration 034.
  ///
  /// Scoped by workspace inside the repository as well as here. The
  /// access check proves the caller belongs to THIS workspace; it does
  /// not prove the finding does, and a crafted id would otherwise let
  /// one workspace dismiss another's.
  Future<void> dismissFinding(
    Session session,
    String accessToken,
    int workspaceId,
    int findingId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );
    await _findings.dismiss(workspaceId, findingId);
  }
}
