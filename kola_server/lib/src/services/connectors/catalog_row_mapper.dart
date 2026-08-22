// catalog_row_mapper.dart — Gate 4. The header-alias/fuzzy-matching
// logic behind Google Sheets' product sync.
//
// THIS IS A DELIBERATE, DOCUMENTED DUPLICATE, NOT A DIVERGENT
// REIMPLEMENTATION: kola_dashboard/lib/services/product_csv.dart already
// has this exact alias table and fuzzy-matching order (including the
// load-bearing "low-stock before stock" ordering — read that file's
// comment on why the order is the whole rule) for the CSV upload path.
// It cannot be imported directly here — it's pure Dart with zero
// dependencies, but it lives in the DASHBOARD package, and kola_server
// has no dependency on kola_dashboard (nor should it gain one just for
// this). Porting the mapping table verbatim keeps behavior identical
// TODAY; the two tables WILL drift the next time either one is edited
// without the other. The correct long-term fix is extracting both into
// a small shared package both kola_server and kola_dashboard depend on
// — flagged here rather than done silently, because that's a
// repo-structure change, not a Gate 4 change.
//
// WHY THIS FILE ONLY HAS THE MAPPING, NOT THE CSV TABLE PARSER:
// product_csv.dart's `_parseTable` turns raw CSV TEXT into rows —
// Google Sheets' API already returns parsed `List<List<dynamic>>` rows
// (see google_sheets_service.dart), so there is nothing to re-parse
// here, only header names to interpret and values to normalize.

/// One column of the sheet, and which product field it maps to.
class SheetColumnMapping {
  const SheetColumnMapping({required this.index, required this.field});
  final int index;
  final String? field; // null means "not imported"
}

/// One parsed row, before it becomes a product upsert.
class SheetProductRow {
  const SheetProductRow({
    required this.rowNumber,
    required this.name,
    this.category,
    this.archetype,
    this.sku,
    this.price,
    this.cost,
    this.stock,
    this.lowStock,
    this.unit,
    this.description,
  });

  final int rowNumber; // 1-based, header counted as row 1 — matches what the owner sees in Sheets
  final String name;
  final String? category;
  final String? archetype;
  final String? sku;
  final String? price;
  final String? cost;
  final String? stock;
  final String? lowStock;
  final String? unit;
  final String? description;
}

abstract class CatalogRowMapper {
  // Verbatim from product_csv.dart's _aliases — see this file's header
  // on why it is a copy, not a shared import.
  static const _aliases = <String, String>{
    'name': 'name',
    'product': 'name',
    'productname': 'name',
    'title': 'name',
    'item': 'name',
    'description': 'description',
    'desc': 'description',
    'details': 'description',
    'category': 'category',
    'cat': 'category',
    'type': 'category',
    'group': 'category',
    'archetype': 'archetype',
    'kind': 'archetype',
    'sku': 'sku',
    'code': 'sku',
    'itemcode': 'sku',
    'barcode': 'sku',
    'price': 'price',
    'sellingprice': 'price',
    'amount': 'price',
    'unitprice': 'price',
    'cost': 'cost',
    'costprice': 'cost',
    'buyingprice': 'cost',
    'whatitcostsyou': 'cost',
    'stock': 'stock',
    'quantity': 'stock',
    'qty': 'stock',
    'instock': 'stock',
    'lowstock': 'lowStock',
    'lowstockthreshold': 'lowStock',
    'lowstockalert': 'lowStock',
    'reorderlevel': 'lowStock',
    'reorderpoint': 'lowStock',
    'unit': 'unit',
    'priceunit': 'unit',
    'measure': 'unit',
  };

  static String _normalise(String header) =>
      header.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '').trim();

  // Verbatim ordering from product_csv.dart's _fuzzy — low-stock BEFORE
  // stock is load-bearing, see that file's own comment on why.
  static String? _fuzzy(String normalised) {
    if (normalised.contains('name') || normalised.contains('product')) return 'name';
    if (normalised.contains('cost') || normalised.contains('buy')) return 'cost';
    if (normalised.contains('price') || normalised.contains('amount')) return 'price';
    if (normalised.contains('stock') &&
        (normalised.contains('low') ||
            normalised.contains('reorder') ||
            normalised.contains('threshold') ||
            normalised.contains('alert') ||
            normalised.contains('min'))) {
      return 'lowStock';
    }
    if (normalised.contains('reorder') || normalised.contains('threshold')) return 'lowStock';
    if (normalised.contains('qty') || normalised.contains('stock') || normalised.contains('quantity')) {
      return 'stock';
    }
    if (normalised.contains('categor') || normalised.contains('group')) return 'category';
    if (normalised.contains('desc')) return 'description';
    if (normalised.contains('sku') || normalised.contains('code')) return 'sku';
    return null;
  }

  static List<SheetColumnMapping> mapHeader(List<dynamic> headerRow) {
    final out = <SheetColumnMapping>[];
    for (var i = 0; i < headerRow.length; i++) {
      final raw = headerRow[i]?.toString().trim() ?? '';
      if (raw.isEmpty) continue;
      final normalised = _normalise(raw);
      final field = _aliases[normalised] ?? _fuzzy(normalised);
      out.add(SheetColumnMapping(index: i, field: field));
    }
    return out;
  }

  /// Maps every data row (everything after the header) against
  /// [mappings]. Rows with no resolvable name are skipped, same rule as
  /// the CSV path — a product import cannot proceed without one.
  static List<SheetProductRow> mapRows(
    List<List<dynamic>> rows, {
    required List<SheetColumnMapping> mappings,
  }) {
    final out = <SheetProductRow>[];

    String? at(List<dynamic> cells, String field) {
      for (final m in mappings) {
        if (m.field == field && m.index < cells.length) {
          final v = cells[m.index]?.toString().trim();
          return (v == null || v.isEmpty) ? null : v;
        }
      }
      return null;
    }

    for (var r = 1; r < rows.length; r++) {
      final cells = rows[r];
      if (cells.every((c) => c == null || c.toString().trim().isEmpty)) continue;

      final name = at(cells, 'name');
      if (name == null) continue;

      out.add(SheetProductRow(
        rowNumber: r + 1,
        name: name,
        category: at(cells, 'category'),
        archetype: _archetypeFrom(at(cells, 'archetype'), at(cells, 'category')),
        sku: at(cells, 'sku'),
        price: at(cells, 'price'),
        cost: at(cells, 'cost'),
        stock: at(cells, 'stock'),
        lowStock: at(cells, 'lowStock'),
        unit: at(cells, 'unit'),
        description: at(cells, 'description'),
      ));
    }
    return out;
  }

  // Verbatim from product_csv.dart's _archetypeFrom.
  static String _archetypeFrom(String? archetype, String? category) {
    final a = archetype?.toLowerCase().trim();
    if (a == 'packaged' || a == 'variants' || a == 'services') return a!;
    if (a != null) {
      if (a.contains('service')) return 'services';
      if (a.contains('variant') || a.contains('size')) return 'variants';
    }
    final c = category?.toLowerCase().trim();
    if (c != null && c.contains('service')) return 'services';
    return 'packaged';
  }
}
