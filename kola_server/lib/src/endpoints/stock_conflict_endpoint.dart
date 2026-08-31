// stock_conflict_endpoint.dart
//
// Phase 11g-e — the resolution half of DESIGN_BRIEF_COMMERCE.md §1's
// conflict requirement. See stock_conflict.spy.yaml's header for what
// creates a row here (SaleEndpoint.ringUpSale, via
// ProductRepository.adjustStock's oversell signal) and why. This
// endpoint only lists and resolves — nothing here decides whether a
// conflict happened, that decision is made once, at detection time.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/stock_conflict_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/kola_logger.dart';

class StockConflictEndpoint extends Endpoint {
  StockConflictRepository get _conflicts => getIt<StockConflictRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();

  /// Open conflicts for this workspace — till_page.dart's own small
  /// banner reads this, since a conflict only ever comes from a sale
  /// made there. Deliberately not folded into WorkspaceFinding's
  /// deterministic sweep (Phase 12b): a finding is present-or-absent,
  /// recomputed fresh on every read; a stock conflict is a specific
  /// incident with a plain-language DECISION to make ("backorder or
  /// adjust the count"), not a fact to dismiss.
  Future<List<StockConflict>> listOpen(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await _require(accessToken, workspaceId);
    return _conflicts.listOpen(workspaceId);
  }

  /// [resolution] is 'backordered' | 'adjusted' | 'dismissed' — the
  /// owner's own words from the brief's example ("mark one as a
  /// backorder, or adjust the count") turned into the two real choices,
  /// plus a plain dismiss for "never mind, I've already sorted it."
  /// Neither choice touches Product.stock: it is already at zero (see
  /// adjustStock's own clamp), which IS the adjusted count in the
  /// "adjust the count" case, and a backorder is a promise to the
  /// customer, not a stock number — there is nothing this endpoint
  /// needs to write to Product either way. This is deliberately a
  /// smaller action than it might sound: it closes the open question,
  /// it does not move inventory.
  Future<StockConflict> resolve(
    Session session,
    String accessToken,
    int workspaceId,
    int conflictId,
    String resolution,
  ) async {
    final member = await _require(accessToken, workspaceId);

    const validResolutions = {'backordered', 'adjusted', 'dismissed'};
    if (!validResolutions.contains(resolution)) {
      throw KolaException(
        message: 'Unknown resolution "$resolution" — must be one of: ${validResolutions.join(", ")}',
      );
    }

    final existing = await _conflicts.findByIdScoped(conflictId, workspaceId);
    if (existing == null) {
      throw KolaException(message: 'Stock conflict $conflictId not found in workspace $workspaceId');
    }
    if (existing.status != 'open') {
      throw KolaException(message: 'This has already been resolved.');
    }

    final resolved = await _conflicts.resolve(
      id: conflictId,
      status: resolution,
      // No email lookup at this layer — same documented limitation
      // CustomerEndpoint.resolveMergeProposal already accepts; the
      // acting user's own id is still real audit evidence.
      resolvedByEmail: member.userId,
    );

    Log.success(
      'Stock conflict resolved',
      data: {'workspaceId': workspaceId, 'conflictId': conflictId, 'resolution': resolution},
      session: session,
    );

    return resolved;
  }

  /// Same gate SaleEndpoint._require applies — a stock conflict only
  /// ever exists because of a sale rung up through the till, so it's
  /// gated on the same two flags rather than introducing a third.
  Future<WorkspaceMember> _require(String accessToken, int workspaceId) async {
    final member = await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
    }
    if (!await _features.isEnabled(FeatureKeys.commerceCore, workspace) ||
        !await _features.isEnabled(FeatureKeys.commercePos, workspace)) {
      throw KolaException(message: 'The sales counter is not available on this workspace yet.');
    }
    return member;
  }
}
