// onedrive_excel_adapter.dart — Gate 4. Second generic-store,
// OAuth-backed ConnectorAdapter, near-identical in shape to
// GoogleSheetsAdapter — read that file's header first; this one only
// calls out where OneDrive/Excel differs.
//
// SAME MATCHING KEY, SAME MIRROR RULE, SAME NULL-PRICE DISCIPLINE as
// GoogleSheetsAdapter — see that file's header. CatalogRowMapper is
// shared verbatim between the two; nothing about the mapping or the
// products-table write path is provider-specific.
//
// WHAT IS DIFFERENT FROM GOOGLE SHEETS:
//   - Config holds {refreshToken, driveId, itemId} rather than
//     {refreshToken, spreadsheetId} — see
//     MicrosoftGraphExcelService.resolveShareUrl's header on why a
//     OneDrive/SharePoint sharing URL needs a real Graph call to become
//     stable ids, unlike a Google Sheets URL which already carries one.
//   - supportsIncrementalSync is false for the same reason as Sheets: no
//     cheap "since" filter exists for a spreadsheet.

import 'dart:convert';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/product_repository.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';
import 'package:kola_server/src/services/connectors/catalog_row_mapper.dart';
import 'microsoft_oauth_service.dart';
import 'microsoft_graph_excel_service.dart';

class OneDriveExcelAdapter implements ConnectorAdapter {
  OneDriveExcelAdapter({
    required this.workspaceId,
    required this.refreshToken,
    required this.driveId,
    required this.itemId,
    required MicrosoftOAuthService oauth,
    MicrosoftGraphExcelService? excel,
  })  : _oauth = oauth,
        _excel = excel ?? const MicrosoftGraphExcelService();

  final int workspaceId;
  final String refreshToken;
  final String driveId;
  final String itemId;
  final MicrosoftOAuthService _oauth;
  final MicrosoftGraphExcelService _excel;

  ProductRepository get _products => getIt<ProductRepository>();

  @override
  String get connectorKey => 'onedrive_excel';

  @override
  ConnectorCapabilities get capabilities => const ConnectorCapabilities(
        supportsIncrementalSync: false,
        supportsPagination: false,
        isPushDriven: false,
      );

  @override
  String get retentionPolicy => RetentionPolicy.retainOnDisconnect;

  @override
  Future<SyncResult> sync({SyncCursor cursor = SyncCursor.none}) async {
    final tokens = await _oauth.refreshAccessToken(
      refreshToken,
      scopes: const [MicrosoftOAuthService.scopeFilesReadWrite],
    );
    final accessToken = tokens['access_token'] as String?;
    if (accessToken == null) {
      throw Exception('Microsoft token refresh returned no access_token');
    }

    final rows = await _excel.getValues(
      driveId: driveId,
      itemId: itemId,
      accessToken: accessToken,
    );
    if (rows.isEmpty) return const SyncResult.empty();

    final mappings = CatalogRowMapper.mapHeader(rows.first);
    if (!mappings.any((m) => m.field == 'name')) {
      return SyncResult(
        recordsSeen: 0,
        recordsChanged: 0,
        errors: const ['No column in this file could be read as a product name.'],
      );
    }

    final parsed = CatalogRowMapper.mapRows(rows, mappings: mappings);
    if (parsed.isEmpty) return const SyncResult.empty();

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
            priceCurrency: 'NGN', // see google_sheets_adapter.dart's header — same Nigeria-first default
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
        Log.warning('OneDriveExcelAdapter: failed to upsert row ${row.rowNumber}: $e');
      }
    }

    return SyncResult(
      recordsSeen: parsed.length,
      recordsChanged: changed,
      nextCursor: SyncCursor(jsonEncode({'rowsLastSynced': parsed.length})),
      errors: errors,
    );
  }

  @override
  Future<ConnectorHealth> health() async {
    try {
      final tokens = await _oauth.refreshAccessToken(
        refreshToken,
        scopes: const [MicrosoftOAuthService.scopeFilesReadWrite],
      );
      final accessToken = tokens['access_token'] as String?;
      if (accessToken == null) {
        return const ConnectorHealth.unhealthy('Microsoft did not return a valid access token.');
      }
      await _excel.probe(driveId: driveId, itemId: itemId, accessToken: accessToken);
      return const ConnectorHealth.healthy();
    } catch (e) {
      return ConnectorHealth.unhealthy(
        'Could not read this file — the Microsoft account may have revoked access, or the file may have been deleted or moved. ($e)',
      );
    }
  }

  /// Same parsing rules as GoogleSheetsAdapter's own — see that file's
  /// header on why a blank price/stock cell stays null rather than 0.
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
