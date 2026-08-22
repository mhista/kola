// google_sheets_adapter.dart — Gate 4. First implementation of
// ConnectorAdapter for the GENERIC store — every prior adapter
// (Paystack, Flutterwave) was paymentGateway-store. Lands rows into the
// SAME `products` table the catalog CSV import and the product editor
// already write to, using the read-only-mirror rule PART IV's catalog-
// ownership section states: a connected source is a mirror, never
// two-way, so a product this adapter creates or updates is exactly as
// editable in kolaa as one typed in by hand — nothing marks it
// "connector-owned" or locks its fields. Re-syncing is what keeps it
// current, not a sync lock.
//
// MATCHING KEY: SKU first, product name second. A sheet WITH a SKU
// column re-syncs deterministically forever. A sheet with only a name
// column (the common case — see product_csv.dart's header on why name
// is the only required field) matches on exact, case-insensitive name
// within the workspace; a genuine rename in the sheet creates a second
// product rather than silently overwriting the wrong one, which is the
// safer failure mode for a live business's price list.
//
// KNOWN SIMPLIFICATION: priceCurrency defaults to 'NGN' rather than
// reusing ProductEndpoint's own region-aware _currencyFor(workspaceId)
// — that helper is private to the endpoint and this is a background
// service, not a request handler. Matches every other adapter's
// Nigeria-first default in this pass; worth revisiting if/when a
// non-Nigerian workspace connects a sheet.

import 'dart:convert';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/product_repository.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';
import 'package:kola_server/src/services/connectors/catalog_row_mapper.dart';
import 'google_oauth_service.dart';
import 'google_sheets_service.dart';

class GoogleSheetsAdapter implements ConnectorAdapter {
  GoogleSheetsAdapter({
    required this.workspaceId,
    required this.refreshToken,
    required this.spreadsheetId,
    required GoogleOAuthService oauth,
    GoogleSheetsService? sheets,
  })  : _oauth = oauth,
        _sheets = sheets ?? const GoogleSheetsService();

  final int workspaceId;
  final String refreshToken;
  final String spreadsheetId;
  final GoogleOAuthService _oauth;
  final GoogleSheetsService _sheets;

  ProductRepository get _products => getIt<ProductRepository>();

  @override
  String get connectorKey => 'google_sheets';

  @override
  ConnectorCapabilities get capabilities => const ConnectorCapabilities(
        // No cheap "since" filter exists for a spreadsheet the way a
        // REST API offers `from`/page tokens — every sync run reads the
        // whole sheet. supportsIncrementalSync stays false rather than
        // faked; [sync_cursor] is still written (see below) but only to
        // record WHEN a sync last ran, not to skip re-reading anything.
        supportsIncrementalSync: false,
        supportsPagination: false,
        isPushDriven: false,
      );

  @override
  String get retentionPolicy => RetentionPolicy.retainOnDisconnect;

  @override
  Future<SyncResult> sync({SyncCursor cursor = SyncCursor.none}) async {
    final tokens = await _oauth.refreshAccessToken(refreshToken);
    final accessToken = tokens['access_token'] as String?;
    if (accessToken == null) {
      throw Exception('Google token refresh returned no access_token');
    }

    final rows = await _sheets.getValues(
      spreadsheetId: spreadsheetId,
      accessToken: accessToken,
    );
    if (rows.isEmpty) return const SyncResult.empty();

    final mappings = CatalogRowMapper.mapHeader(rows.first);
    if (!mappings.any((m) => m.field == 'name')) {
      // No column resolved to a product name at all — same "cannot
      // proceed without one" rule as the CSV path, reported as an error
      // rather than a silent zero-row sync so the owner finds out from
      // the connector card, not by noticing their catalog never grew.
      return SyncResult(
        recordsSeen: 0,
        recordsChanged: 0,
        errors: const ['No column in this sheet could be read as a product name.'],
      );
    }

    final parsed = CatalogRowMapper.mapRows(rows, mappings: mappings);
    if (parsed.isEmpty) return const SyncResult.empty();

    // One read, not one per row — a sheet of 500 products must not cost
    // 500 findBySku round trips. Indexed by sku and by lowercased name,
    // matching this adapter's own two-tier matching rule (see header).
    final existing = await _products.listByWorkspace(workspaceId, includeArchived: false);
    final bySku = <String, Product>{for (final p in existing) if (p.sku != null) p.sku!: p};
    final byName = <String, Product>{
      for (final p in existing) p.name.toLowerCase().trim(): p,
    };

    var changed = 0;
    final errors = <String>[];

    for (final row in parsed) {
      try {
        final match = (row.sku != null ? bySku[row.sku] : null) ??
            byName[row.name.toLowerCase().trim()];

        final priceMinor = _parseMinorUnits(row.price);
        final costMinor = _parseMinorUnits(row.cost);
        final stock = _parseInt(row.stock);
        final lowStock = _parseInt(row.lowStock) ?? 5;
        final now = DateTime.now().toUtc();

        if (match == null) {
          await _products.create(Product(
            workspaceId: workspaceId,
            name: row.name,
            description: row.description,
            archetype: row.archetype ?? 'packaged',
            sku: row.sku,
            category: row.category,
            priceMinor: priceMinor,
            priceCurrency: 'NGN', // see this file's header
            priceUnit: row.unit,
            costMinor: costMinor,
            stock: stock,
            lowStockThreshold: lowStock,
            status: 'active',
            createdAt: now,
            updatedAt: now,
          ));
          changed++;
        } else {
          final updated = Product(
            id: match.id,
            workspaceId: workspaceId,
            name: row.name,
            description: row.description ?? match.description,
            archetype: row.archetype ?? match.archetype,
            sku: row.sku ?? match.sku,
            category: row.category ?? match.category,
            priceMinor: priceMinor ?? match.priceMinor,
            priceCurrency: match.priceCurrency,
            priceUnit: row.unit ?? match.priceUnit,
            costMinor: costMinor ?? match.costMinor,
            stock: stock ?? match.stock,
            lowStockThreshold: lowStock,
            status: match.status,
            createdAt: match.createdAt,
            updatedAt: now,
          );
          await _products.update(updated);
          changed++;
        }
      } catch (e) {
        errors.add('row ${row.rowNumber} (${row.name}): $e');
        Log.warning('GoogleSheetsAdapter: failed to upsert row ${row.rowNumber}: $e');
      }
    }

    return SyncResult(
      recordsSeen: parsed.length,
      recordsChanged: changed,
      // Written but not read back — see [capabilities]. Kept as the
      // sync timestamp's own record of "there were N rows last time",
      // useful context for a future incremental strategy without
      // committing to one now.
      nextCursor: SyncCursor(jsonEncode({'rowsLastSynced': parsed.length})),
      errors: errors,
    );
  }

  @override
  Future<ConnectorHealth> health() async {
    try {
      final tokens = await _oauth.refreshAccessToken(refreshToken);
      final accessToken = tokens['access_token'] as String?;
      if (accessToken == null) {
        return const ConnectorHealth.unhealthy('Google did not return a valid access token.');
      }
      await _sheets.probe(spreadsheetId: spreadsheetId, accessToken: accessToken);
      return const ConnectorHealth.healthy();
    } catch (e) {
      return ConnectorHealth.unhealthy(
        'Could not read this sheet — the Google account may have revoked access, or the sheet may have been deleted or made private. ($e)',
      );
    }
  }

  /// "1,500.00", "₦1500", "1500" → 150000 (kobo). Null/unparseable input
  /// stays null — a blank price cell must remain "ask us" (see
  /// product.spy.yaml's own header on why null price is never coerced
  /// to zero), not silently become free.
  static int? _parseMinorUnits(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null) return null;
    return (value * 100).round();
  }

  static int? _parseInt(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
}
