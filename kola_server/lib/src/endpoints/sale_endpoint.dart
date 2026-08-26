// sale_endpoint.dart — the till. PART II's gap table: "Sales counter
// PARTIAL. Migration 035 applied. Model, endpoint and Till page
// outstanding." This is the endpoint half of finishing it. Gate 3b:
// every completed sale resolves/creates a Customer through
// CustomerIdentityResolver and is reachable on that customer's
// timeline via CustomerEndpoint.getCustomerDetail.
//
// Gated on commerce.core + commerce.pos, matching the existing
// /counter nav item in kola_dashboard's nav_model.dart exactly — this
// endpoint does not introduce a new capability flag, it fills in the
// one that was already reserved and locked.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/sale_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/kola_logger.dart';

class SaleEndpoint extends Endpoint {
  SaleRepository get _sales => getIt<SaleRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();
  CustomerIdentityResolver get _identity => getIt<CustomerIdentityResolver>();
  EventBus get _events => getIt<EventBus>();

  /// Rings up one sale. [customerPhone]/[customerName] are optional —
  /// a walk-in cash sale with neither is a complete, normal sale (see
  /// sale.spy.yaml's header); when present they resolve or create a
  /// Customer through the same deterministic matcher every other intake
  /// path uses, so the till participates in the graph rather than
  /// sitting beside it.
  Future<Sale> ringUpSale(
    Session session,
    String accessToken,
    int workspaceId, {
    required List<SaleLineInput> lines,
    required String paymentMethod,
    int? cashReceivedMinor,
    String? clientReference,
    String? customerPhone,
    String? customerName,
  }) async {
    // Entry log — if this line's timestamp is ever missing for a sale
    // attempt that the browser shows as failed, the request never made
    // it past Serverpod's own parameter deserialization (i.e. it died
    // before ringUpSale's body ran at all — see the diagnostic print in
    // generated/protocol.dart's Protocol.deserialize fallback for that
    // case). If this line IS present, the failure is real business
    // logic below, not a wire/serialization problem.
    Log.info(
      'ringUpSale called',
      data: {
        'workspaceId': workspaceId,
        'lineCount': lines.length,
        'paymentMethod': paymentMethod,
        'clientReference': clientReference,
      },
      session: session,
    );
    try {
      await _require(accessToken, workspaceId);

      // Idempotency: the offline till may replay the same queued sale
      // after a lost response. See sale_repository.dart's header.
      if (clientReference != null) {
        final existing = await _sales.findByClientReference(
          workspaceId: workspaceId,
          clientReference: clientReference,
        );
        if (existing != null) return existing;
      }

      if (lines.isEmpty) {
        throw KolaException(message: 'A sale needs at least one line.');
      }

      final workspace = await _workspaces.findById(workspaceId);
      if (workspace == null) {
        throw KolaException(message: 'Workspace $workspaceId not found.');
      }

    final subtotalMinor = lines.fold<int>(
      0,
      (sum, l) => sum + (l.unitPriceMinor * l.quantity),
    );
    final taxRateBps = workspace.taxRateBps;
    final taxMinor = (subtotalMinor * taxRateBps / 10000).round();
    final totalMinor = subtotalMinor + taxMinor;

    int? changeMinor;
    if (paymentMethod == 'cash' && cashReceivedMinor != null) {
      changeMinor = cashReceivedMinor - totalMinor;
      if (changeMinor < 0) {
        throw KolaException(message: 'Cash received is less than the total.');
      }
    }

    // Resolve the customer BEFORE creating the sale so the sale can be
    // written with customerId in one insert rather than a create-then-
    // patch — see CustomerIdentityResolver.resolve's header for the
    // matching/conflict algorithm.
    int? customerId;
    if (customerPhone != null && customerPhone.trim().isNotEmpty) {
      final primary = IdentitySignal(
        type: 'phone',
        value: CustomerIdentityResolver.normalizePhone(customerPhone),
      );
      customerId = await _identity.resolve(
        workspaceId: workspaceId,
        primary: primary,
        source: 'till',
      );
      if (customerId != null && customerName != null && customerName.trim().isNotEmpty) {
        await _identity.attachSignal(
          workspaceId: workspaceId,
          customerId: customerId,
          signal: IdentitySignal(
            type: 'name',
            value: CustomerIdentityResolver.normalizeName(customerName),
          ),
          source: 'till',
        );
      }
    }

    final sale = await _sales.create(
      workspaceId: workspaceId,
      customerId: customerId,
      reference: SaleRepository.generateReference(DateTime.now().toUtc()),
      clientReference: clientReference,
      subtotalMinor: subtotalMinor,
      taxRateBps: taxRateBps,
      taxMinor: taxMinor,
      totalMinor: totalMinor,
      currency: 'NGN',
      paymentMethod: paymentMethod,
      cashReceivedMinor: cashReceivedMinor,
      changeMinor: changeMinor,
    );

    final saleId = sale.id;
    if (saleId != null) {
      await _sales.addLines(
        saleId: saleId,
        lines: [
          for (final l in lines)
            (
              productId: l.productId,
              name: l.name,
              unitPriceMinor: l.unitPriceMinor,
              quantity: l.quantity,
              lineTotalMinor: l.unitPriceMinor * l.quantity,
            ),
        ],
      );

      // Gate 2 substrate, Gate 3b proof: this is the event a future
      // Observation/Recommendation reads, and the fingerprint makes a
      // retried ringUpSale call (same sale, same offline replay) a
      // no-op fan-out rather than a duplicate notification.
      await _events.emit(
        workspaceId: workspaceId,
        eventType: 'sale_completed',
        fingerprint: 'sale_completed:$saleId',
        payload: {
          'saleId': saleId,
          'customerId': customerId,
          'totalMinor': totalMinor,
          'currency': 'NGN',
        },
      );
    }

      Log.success(
        'ringUpSale completed',
        data: {'saleId': sale.id, 'totalMinor': totalMinor},
        session: session,
      );
      return sale;
    } catch (e, st) {
      // Whatever the failure is (validation, DB, downstream service),
      // this guarantees it's timestamped and attributed to ringUpSale
      // specifically in the container log, instead of only surfacing as
      // an anonymous "Internal server error" line from Serverpod's own
      // top-level handler.
      Log.error('ringUpSale failed', error: e, stackTrace: st, session: session);
      rethrow;
    }
  }

  Future<List<Sale>> listSales(
    Session session,
    String accessToken,
    int workspaceId, {
    int limit = 50,
    int offset = 0,
  }) async {
    await _require(accessToken, workspaceId);
    return _sales.listByWorkspace(workspaceId: workspaceId, limit: limit, offset: offset);
  }

  Future<List<SaleLine>> getSaleLines(
    Session session,
    String accessToken,
    int workspaceId,
    int saleId,
  ) async {
    await _require(accessToken, workspaceId);
    return _sales.listLines(saleId);
  }

  Future<void> _require(String accessToken, int workspaceId) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
    }
    if (!await _features.isEnabled(FeatureKeys.commerceCore, workspace) ||
        !await _features.isEnabled(FeatureKeys.commercePos, workspace)) {
      throw KolaException(message: 'The sales counter is not available on this workspace yet.');
    }
  }
}
