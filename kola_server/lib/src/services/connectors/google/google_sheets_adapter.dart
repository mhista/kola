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
import 'package:kola_server/src/services/memory/document_ingestion_service.dart';
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
  DocumentIngestionService get _ingestion => getIt<DocumentIngestionService>();

  /// Caps how much of a sheet gets embedded into the knowledge base per
  /// sync — a 10,000-row sheet must not blow the free embedding budget
  /// (Gemini's free tier: 1,500 requests/day, see document_ingestion_
  /// service.dart's header) in one run. Same "cap it, don't pretend a
  /// huge source is small" instinct as WorkspaceAnswerService's own
  /// _catalogDigestLimit.
  static const _maxIngestedRows = 400;
  static const _maxIngestedChars = 12000;

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

    // Knowledge ingestion runs BEFORE the catalog-mapping check below and
    // regardless of its outcome — a sheet with no resolvable product-name
    // column (a FAQ table, a price list in an unrecognized shape, notes)
    // still deserves to be summarizable/searchable, it just isn't a
    // catalog. Best-effort: a failure here must never break the catalog
    // sync this method exists primarily to do.
    await _ingestIntoKnowledgeBase(rows);

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

  /// Renders the raw sheet [rows] as plain text and hands it to
  /// [DocumentIngestionService.ingestFromConnector] so the sheet becomes
  /// summarizable/searchable knowledge, independent of whether it also
  /// maps to a product catalog. Best-effort: any failure is logged and
  /// swallowed, never rethrown, so a knowledge-ingestion problem can
  /// never break the catalog sync in [sync].
  ///
  /// KNOWN SIMPLIFICATION: the title is derived from [spreadsheetId]
  /// rather than the sheet's real display name — the Sheets API call this
  /// adapter already makes (getValues) does not return the spreadsheet's
  /// title, and fetching it would mean a second API call on every sync
  /// purely for a nicer label. Matches this file's own header precedent
  /// of naming and flagging such trade-offs rather than hiding them.
  Future<void> _ingestIntoKnowledgeBase(List<List<dynamic>> rows) async {
    try {
      final capped = rows.take(_maxIngestedRows).toList();
      final buffer = StringBuffer();
      for (final row in capped) {
        buffer.writeln(row.map((cell) => cell?.toString() ?? '').join(' | '));
        if (buffer.length >= _maxIngestedChars) break;
      }

      var text = buffer.toString();
      if (text.length > _maxIngestedChars) {
        text = text.substring(0, _maxIngestedChars);
      }
      if (text.trim().isEmpty) return;

      await _ingestion.ingestFromConnector(
        workspaceId: workspaceId,
        title: 'Google Sheet ($spreadsheetId)',
        text: text,
        sourceRef: 'google_sheets:$spreadsheetId',
      );
    } catch (e) {
      // Best-effort only — see this method's doc comment. The catalog
      // sync in [sync] must proceed regardless of what happens here.
      Log.warning('GoogleSheetsAdapter: knowledge ingestion failed, continuing with catalog sync: $e');
    }
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
