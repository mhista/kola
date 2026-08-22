// bumpa_adapter.dart — Gate 4. The first ConnectorAdapter that writes
// into Sale/SaleLine (the Till, sale_repository.dart) rather than
// payment_transaction (Paystack/Flutterwave) or products alone (Google
// Sheets/OneDrive Excel). Bumpa orders carry real line items against a
// real product catalog, which is what Sale/SaleLine was built to hold —
// see sale.spy.yaml's header on why a till sale becomes an Order entity
// on a customer timeline; a synced Bumpa order is exactly that, just
// arriving from a storefront instead of a register.
//
// TWO SEPARATE SYNC PASSES IN ONE sync() CALL: products (into the same
// `products` table google_sheets_adapter.dart already writes to — see
// that file's header on the read-only-mirror rule this follows too) and
// orders (into sales/sale_lines). Kept as one adapter, not two, because
// Bumpa is one connection an owner makes once; splitting it into two
// catalog entries would ask them to connect "Bumpa products" and "Bumpa
// orders" separately for no real benefit.
//
// ONLY PAID ORDERS BECOME SALES — same rule PaystackAdapter already
// applies to `status != 'success'`. An OPEN/UNPAID Bumpa order is a cart
// that never became a real transaction; recording it as a completed
// till sale would put money in the ledger that was never actually
// collected.
//
// KNOWN LIMITATION, RECORDED RATHER THAN HIDDEN: SaleRepository has no
// update-by-clientReference path today — only create, setCustomer, and
// addLines. A live test run against a real Bumpa store during this
// adapter's build showed an order's own status can genuinely change
// between polls (order #00004 was COMPLETED/DELIVERED on one read and
// OPEN/UNFULFILLED on a later one against the same id). Once
// [SaleRepository.findByClientReference] finds a prior sync already
// recorded an order, this adapter treats it as done and does not touch
// it again — a Bumpa order that later gets refunded or its fulfillment
// status changes will not be reflected in kolaa's Till until
// SaleRepository grows a real update path. Worth doing before this
// connector is relied on for refund accounting; not blocking for the
// first version, which only needs "a paid order becomes a till sale
// exactly once."
//
// AMOUNT PARSING — see bumpa_service.dart's header for the full field-
// by-field breakdown of why every amount here goes through num.parse
// rather than being trusted as a specific Dart type.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/sale_repository.dart';
import 'package:kola_server/src/services/repository/product_repository.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';
import 'bumpa_service.dart';

class BumpaAdapter implements ConnectorAdapter {
  BumpaAdapter({required this.workspaceId, required BumpaService service}) : _service = service;

  final int workspaceId;
  final BumpaService _service;

  SaleRepository get _sales => getIt<SaleRepository>();
  ProductRepository get _products => getIt<ProductRepository>();
  CustomerIdentityResolver get _customerIdentity => getIt<CustomerIdentityResolver>();
  EventBus get _events => getIt<EventBus>();

  static const _pageSize = 100;
  // Same bounded-loop discipline as PaystackAdapter — a hard ceiling on
  // pages per run, not an expectation of hitting it.
  static const _maxPages = 200;

  @override
  String get connectorKey => 'bumpa';

  @override
  ConnectorCapabilities get capabilities => const ConnectorCapabilities(
        // No confirmed "since"/created_at filter parameter exists on
        // Bumpa's List Orders endpoint — only `page` and `limit` were
        // ever documented or observed. Newest-first ordering was
        // observed in a live test but is not a documented guarantee, so
        // this does not rely on it for an early-exit cursor. Left false
        // rather than faked, same posture as GoogleSheetsAdapter.
        supportsIncrementalSync: false,
        supportsPagination: true,
        isPushDriven: false,
      );

  @override
  String get retentionPolicy => RetentionPolicy.retainOnDisconnect;

  @override
  Future<SyncResult> sync({SyncCursor cursor = SyncCursor.none}) async {
    var seen = 0;
    var changed = 0;
    final errors = <String>[];

    changed += await _syncProducts(errors: errors, seenCounter: (n) => seen += n);
    changed += await _syncOrders(errors: errors, seenCounter: (n) => seen += n);

    return SyncResult(
      recordsSeen: seen,
      recordsChanged: changed,
      // No incremental cursor yet — see [capabilities]. Still written so
      // recordSyncRun has a "last run" watermark to show, matching
      // GoogleSheetsAdapter's own nextCursor usage.
      nextCursor: SyncCursor('synced'),
      errors: errors,
    );
  }

  // ── Products ─────────────────────────────────────────────────────────

  Future<int> _syncProducts({
    required List<String> errors,
    required void Function(int) seenCounter,
  }) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    while (page <= _maxPages) {
      final result = await _service.listProducts(page: page, perPage: _pageSize);
      final pageRows = (result['data'] as List?) ?? const [];
      rows.addAll(pageRows.cast<Map<String, dynamic>>());
      if (pageRows.length < _pageSize) break;
      page++;
    }
    if (rows.isEmpty) return 0;
    seenCounter(rows.length);

    // One bulk read, then local matching — same shape as
    // GoogleSheetsAdapter.sync, same reason: a 500-product catalog must
    // not cost 500 findBySku round trips.
    final existing = await _products.listByWorkspace(workspaceId, includeArchived: false);
    final bySku = <String, Product>{for (final p in existing) if (p.sku != null) p.sku!: p};

    var changed = 0;
    final now = DateTime.now().toUtc();

    for (final row in rows) {
      try {
        // Bumpa's product-summary response has no top-level `sku` field
        // — SKU only exists per-variant (confirmed via the product CSV
        // template, not yet reachable through this API — see
        // bumpa_service.dart's header). `barcode` doubles as a stable
        // per-product code when present; when it's empty (as in every
        // product seen in testing), a synthetic `bumpa-<id>` sku keeps
        // re-syncs matching the same product deterministically without
        // any schema change to Product.
        final barcode = row['barcode'] as String?;
        final sku = (barcode != null && barcode.isNotEmpty) ? barcode : 'bumpa-${row['id']}';

        final match = bySku[sku];
        final name = (row['title'] as String?) ?? (row['name'] as String?) ?? 'Untitled product';
        final stock = row['quantity'] as int?;
        // min_selling_price is a per-variant-aware summary field — the
        // closest single number to "the price" this endpoint gives for
        // a product with variations. See this file's header on why
        // full per-variant pricing is not attempted here.
        final priceMinor = _toMinor(row['min_selling_price']);
        final costMinor = _toMinor(row['cost']);

        if (match == null) {
          await _products.create(Product(
            workspaceId: workspaceId,
            name: name,
            description: row['description'] as String?,
            archetype: 'packaged',
            sku: sku,
            priceMinor: priceMinor,
            priceCurrency: 'NGN',
            priceUnit: row['unit'] as String?,
            costMinor: costMinor,
            stock: stock,
            lowStockThreshold: 5,
            status: (row['status'] == 1) ? 'active' : 'archived',
            createdAt: now,
            updatedAt: now,
          ));
        } else {
          await _products.update(Product(
            id: match.id,
            workspaceId: workspaceId,
            name: name,
            description: (row['description'] as String?) ?? match.description,
            archetype: match.archetype,
            sku: sku,
            category: match.category,
            priceMinor: priceMinor ?? match.priceMinor,
            priceCurrency: match.priceCurrency,
            priceUnit: (row['unit'] as String?) ?? match.priceUnit,
            costMinor: costMinor ?? match.costMinor,
            stock: stock ?? match.stock,
            lowStockThreshold: match.lowStockThreshold,
            status: (row['status'] == 1) ? 'active' : match.status,
            createdAt: match.createdAt,
            updatedAt: now,
          ));
        }
        changed++;
      } catch (e) {
        errors.add('product ${row['id']}: $e');
        Log.warning('BumpaAdapter: failed to upsert product ${row['id']}: $e');
      }
    }
    return changed;
  }

  // ── Orders ───────────────────────────────────────────────────────────

  Future<int> _syncOrders({
    required List<String> errors,
    required void Function(int) seenCounter,
  }) async {
    var changed = 0;
    var page = 1;
    while (page <= _maxPages) {
      final result = await _service.listOrders(page: page, perPage: _pageSize);
      final rows = (result['data'] as List?) ?? const [];
      if (rows.isEmpty) break;
      seenCounter(rows.length);

      for (final row in rows) {
        try {
          final wasNew = await _upsertOrder(row as Map<String, dynamic>);
          if (wasNew) changed++;
        } catch (e) {
          errors.add('order ${row['id']}: $e');
          Log.warning('BumpaAdapter: failed to process order ${row['id']}: $e');
        }
      }

      if (rows.length < _pageSize) break;
      page++;
    }
    return changed;
  }

  /// Returns true if this order was newly recorded as a Sale, false if
  /// it was skipped (unpaid, or already synced — see this file's header
  /// on the no-update-path limitation).
  Future<bool> _upsertOrder(Map<String, dynamic> row) async {
    if (row['payment_status'] != 'PAID') return false; // only real payments belong in the Till

    final bumpaId = row['id'];
    if (bumpaId == null) return false;
    final clientReference = 'bumpa:$bumpaId';

    final already = await _sales.findByClientReference(
      workspaceId: workspaceId,
      clientReference: clientReference,
    );
    if (already != null) return false;

    final customerDetails = (row['customer_details'] as Map<String, dynamic>?) ?? const {};
    final shippingDetails = (row['shipping_details'] as Map<String, dynamic>?) ?? const {};
    // Confirmed live: email lives under shipping_details, NOT
    // customer_details — the two objects are not interchangeable
    // despite carrying the same name/phone fields. See bumpa_service.dart.
    final phone = customerDetails['phone'] as String?;
    final email = shippingDetails['email'] as String?;

    int? customerId;
    if ((phone != null && phone.isNotEmpty) || (email != null && email.isNotEmpty)) {
      final primary = (phone != null && phone.isNotEmpty)
          ? IdentitySignal(
              type: 'phone',
              value: CustomerIdentityResolver.normalizePhone(phone),
              sourceRef: clientReference,
            )
          : IdentitySignal(
              type: 'email',
              value: CustomerIdentityResolver.normalizeEmail(email!),
              sourceRef: clientReference,
            );
      final secondary = (phone != null && phone.isNotEmpty && email != null && email.isNotEmpty)
          ? IdentitySignal(
              type: 'email',
              value: CustomerIdentityResolver.normalizeEmail(email),
              sourceRef: clientReference,
            )
          : null;

      customerId = await _customerIdentity.resolve(
        workspaceId: workspaceId,
        primary: primary,
        secondary: secondary,
        source: 'bumpa',
      );
    }

    final subtotalMinor = _toMinor(row['sub_total']) ?? 0;
    final taxMinor = _toMinor(row['tax']) ?? 0;
    final totalMinor = _toMinor(row['total']) ?? 0;
    final soldAt = DateTime.tryParse(row['created_at'] as String? ?? '');

    final sale = await _sales.create(
      workspaceId: workspaceId,
      customerId: customerId,
      reference: SaleRepository.generateReference(soldAt ?? DateTime.now().toUtc()),
      clientReference: clientReference,
      subtotalMinor: subtotalMinor,
      taxRateBps: 0,
      taxMinor: taxMinor,
      totalMinor: totalMinor,
      currency: (row['currency_code'] as String?) ?? 'NGN',
      // Bumpa's own payment timeline (order.timeline[].event ==
      // 'payment_made') names a gateway (e.g. 'fincra') but never a
      // card-vs-transfer distinction, and Sale.paymentMethod only has
      // four values ('cash'|'transfer'|'card'|'split'). 'transfer' is
      // the closest fit for an online-gateway-collected payment — a
      // simplification, not a guess at a field that does not exist.
      paymentMethod: 'transfer',
      soldAt: soldAt,
    );

    final saleId = sale.id;
    if (saleId == null) return true;

    final items = (row['items'] as List?) ?? const [];
    if (items.isNotEmpty) {
      await _sales.addLines(
        saleId: saleId,
        lines: [
          for (final item in items.cast<Map<String, dynamic>>())
            (
              productId: null, // Bumpa's item id is that connector's product id, not kolaa's — no cross-reference exists to resolve it to a local Product safely without risking a wrong link.
              name: (item['name'] as String?) ?? 'Item',
              unitPriceMinor: _toMinor(item['price']) ?? 0,
              quantity: (item['quantity'] as int?) ?? 1,
              lineTotalMinor: _toMinor(item['total']) ?? 0,
            ),
        ],
      );
    }

    // Same event type and fingerprint shape SaleEndpoint.ringUpSale
    // already emits for a manually rung-up sale — a Bumpa order becoming
    // a Sale IS a sale_completed event, not a distinct connector-only
    // one, so anything already listening (Observation/Recommendation)
    // sees it the same way regardless of where the sale came from.
    await _events.emit(
      workspaceId: workspaceId,
      eventType: 'sale_completed',
      fingerprint: 'sale_completed:$saleId',
      payload: {
        'saleId': saleId,
        'customerId': customerId,
        'totalMinor': totalMinor,
        'currency': sale.currency,
        'source': 'bumpa',
        'bumpaOrderId': bumpaId,
      },
      occurredAt: soldAt ?? DateTime.now(),
    );

    return true;
  }

  @override
  Future<ConnectorHealth> health() async {
    try {
      await _service.probe();
      return const ConnectorHealth.healthy();
    } catch (e) {
      return ConnectorHealth.unhealthy(
        'Could not reach Bumpa with the stored keys — they may have been rotated or revoked on their end. ($e)',
      );
    }
  }

  /// Parses any of the shapes Bumpa actually returns for a money field —
  /// a JSON number (items[].price/total) or a decimal string
  /// ("100.00", "50.0000") — into minor units (kobo). Null/unparseable
  /// input returns null rather than 0, so a genuinely missing amount
  /// stays distinguishable from a real zero. See bumpa_service.dart's
  /// header for why this parsing exists at all.
  static int? _toMinor(dynamic raw) {
    if (raw == null) return null;
    final value = raw is num ? raw : num.tryParse(raw.toString());
    if (value == null) return null;
    return (value * 100).round();
  }
}
