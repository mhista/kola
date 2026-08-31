// till_display_endpoint.dart — Phase 11's in-store customer display
// (migration 058), the direct sibling of ProductEndpoint.getPublicCatalog
// (Phase 11's public catalog page, built the same pass) — same two-
// method shape: one authenticated write from staff, one public read for
// a screen with no session.
//
// itemsJson IS A JSON STRING, NOT List<TillDisplayItem> — same reason
// sale_endpoint.dart's ringUpSale/invoice_endpoint.dart's createInvoice/
// broadcast_endpoint.dart's recipientsJson already take their list
// params as a String: this Serverpod install drops the deserializer for
// List<CustomType> parameters on the generated client. See
// sale_endpoint.dart's own header for the full trace.

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/till_display_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/kola_logger.dart';

const _validStatuses = {'idle', 'shopping', 'payment', 'receipt'};

class TillDisplayEndpoint extends Endpoint {
  TillDisplayRepository get _display => getIt<TillDisplayRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();

  /// Called by till_page.dart on every cart mutation and screen
  /// transition — fire-and-forget from the dashboard's side (a failed
  /// push must never block a real sale; see that page's own comment on
  /// its call site). Authenticated: only staff signed into this
  /// workspace can write its display state.
  ///
  /// Deliberately NOT gated on FeatureKeys.commerceCustomerDisplay or
  /// Workspace.customerDisplayEnabled — writing a value nobody is
  /// reading yet is harmless, and gating the WRITE would mean flipping
  /// the toggle on needs the till's next cart change before the display
  /// shows anything, instead of showing already-current state
  /// immediately. getState below is where the real gate lives, same
  /// split ProductEndpoint.getPublicCatalog/its write path already use.
  Future<void> pushState(
    Session session,
    String accessToken,
    int workspaceId,
    String itemsJson,
    int subtotalMinor,
    String currency,
    String status,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    if (!_validStatuses.contains(status)) {
      throw KolaException(
        message: 'Invalid status "$status" — must be one of: ${_validStatuses.join(", ")}',
      );
    }

    List<dynamic> decoded;
    try {
      decoded = jsonDecode(itemsJson) as List<dynamic>;
    } catch (e) {
      throw KolaException(message: 'itemsJson is not valid JSON: $e');
    }

    final items = [
      for (final raw in decoded)
        Map<String, dynamic>.from(raw as Map),
    ];

    await _display.upsert(
      workspaceId: workspaceId,
      items: items,
      subtotalMinor: subtotalMinor,
      currency: currency,
      status: status,
    );
  }

  /// GET-equivalent for /display/<workspaceId>'s page — deliberately NO
  /// accessToken, same "the one method with no session" shape as
  /// ProductEndpoint.getPublicCatalog. Gated on both
  /// FeatureKeys.commerceCustomerDisplay AND Workspace
  /// .customerDisplayEnabled, both failures collapsed into the same
  /// generic error a probe against a random workspaceId cannot use to
  /// learn anything — see getPublicCatalog's own doc comment, same
  /// reasoning applied here.
  ///
  /// A workspace whose till has never pushed a single state (no row in
  /// till_display_state yet) reads as the same honest empty/idle state
  /// a fresh row would represent, rather than an error — the display is
  /// meant to be left open on a screen well before the first sale of
  /// the day, not opened only once a sale is already in progress.
  Future<TillDisplayState> getState(
    Session session,
    int workspaceId,
  ) async {
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'This display is not available.');
    }

    final flag =
        await _features.isEnabled(FeatureKeys.commerceCustomerDisplay, workspace);
    if (!flag || !workspace.customerDisplayEnabled) {
      throw KolaException(message: 'This display is not available.');
    }

    final row = await _display.findByWorkspace(workspaceId);
    if (row == null) {
      return TillDisplayState(
        businessName: workspace.name,
        status: 'idle',
        items: const [],
        subtotalMinor: 0,
        currency: 'NGN',
        updatedAt: DateTime.now().toUtc(),
      );
    }

    final rawItems = row['items_json'] as List<dynamic>? ?? const [];
    final items = [
      for (final raw in rawItems)
        TillDisplayItem(
          name: raw['name'] as String? ?? '',
          quantity: (raw['quantity'] as num?)?.toInt() ?? 0,
          unitPriceMinor: (raw['unitPriceMinor'] as num?)?.toInt() ?? 0,
          lineTotalMinor: (raw['lineTotalMinor'] as num?)?.toInt() ?? 0,
        ),
    ];

    return TillDisplayState(
      businessName: workspace.name,
      status: row['status'] as String? ?? 'idle',
      items: items,
      subtotalMinor: (row['subtotal_minor'] as num?)?.toInt() ?? 0,
      currency: row['currency'] as String? ?? 'NGN',
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
