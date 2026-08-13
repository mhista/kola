// product_csv.dart — turning a spreadsheet into products.
//
// ── WHY CSV AND NOT PDF ──────────────────────────────────────────────
//
// A CSV has a structure the machine can trust. A PDF price list has a
// LAYOUT, which is a different thing — reading one correctly needs a
// model that can tell a column from a coincidence, and a wrong guess
// there writes wrong prices into a live catalog silently. So this parses
// what can be parsed deterministically, and PDF stays out until there is
// something that can be checked.
//
// ── IT DOES NOT USE A CSV PACKAGE ────────────────────────────────────
//
// kola_dashboard has no CSV dependency and adding one to the browser
// bundle for this is not worth it. The parser below handles the parts of
// RFC 4180 that real spreadsheets emit: quoted fields, commas inside
// quotes, doubled quotes as an escape, and CRLF. It does not handle
// alternative delimiters or embedded nulls, and says so rather than
// pretending.
//
// ── EVERY COLUMN EXCEPT `name` IS OPTIONAL ───────────────────────────
//
// Someone exporting from another platform will not have kola's headers.
// A file with one `name` column imports fifty named products with no
// prices, which is a better outcome than refusing the file — the owner
// can fill the rest in afterwards, and they can SEE their products
// exist. Refusing on a missing column is how an import tool becomes
// something people give up on.

/// One parsed row, before it becomes a product.
class CsvProductRow {
  CsvProductRow({
    required this.rowNumber,
    required this.name,
    this.description,
    this.category,
    this.archetype,
    this.sku,
    this.price,
    this.cost,
    this.stock,
    this.lowStock,
    this.unit,
    this.imageUrl,
  });

  /// 1-based, counting the header as row 1 — so it matches what the
  /// owner sees in their spreadsheet when something is wrong.
  final int rowNumber;

  final String name;
  final String? description;
  final String? category;
  final String? archetype;
  final String? sku;

  /// Raw text, parsed to minor units later by Money.parse, which knows
  /// the currency. Kept as typed here so the importer can report "row 12:
  /// price isn't a number" against the row the owner can find.
  final String? price;
  final String? cost;
  final String? stock;
  final String? lowStock;
  final String? unit;
  final String? imageUrl;
}

class CsvParseResult {
  const CsvParseResult({
    required this.rows,
    required this.skipped,
    required this.recognisedHeaders,
    required this.unknownHeaders,
  });

  final List<CsvProductRow> rows;

  /// Row numbers dropped for having no name, with the reason. Surfaced
  /// rather than silently ignored — a file that imports 47 of 50 rows
  /// must say which three and why.
  final List<({int row, String reason})> skipped;

  final List<String> recognisedHeaders;

  /// Columns kola did not understand. Shown so the owner knows what was
  /// ignored instead of assuming it came through.
  final List<String> unknownHeaders;
}

abstract class ProductCsv {
  /// Header aliases, so an export from somewhere else usually just works.
  ///
  /// Lowercased and stripped of spaces/underscores before lookup, which
  /// is why 'Low Stock', 'low_stock' and 'lowstock' all land here.
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
    'stock': 'stock',
    'quantity': 'stock',
    'qty': 'stock',
    'instock': 'stock',
    'lowstock': 'lowStock',
    'lowstockthreshold': 'lowStock',
    'reorderlevel': 'lowStock',
    'unit': 'unit',
    'priceunit': 'unit',
    'measure': 'unit',
    'imageurl': 'imageUrl',
    'image': 'imageUrl',
    'photo': 'imageUrl',
    'photourl': 'imageUrl',
    'picture': 'imageUrl',
  };

  static String _normalise(String header) =>
      header.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '').trim();

  static CsvParseResult parse(String content) {
    final table = _parseTable(content);
    if (table.isEmpty) {
      return const CsvParseResult(
        rows: [],
        skipped: [],
        recognisedHeaders: [],
        unknownHeaders: [],
      );
    }

    final header = table.first;
    final map = <int, String>{};
    final recognised = <String>[];
    final unknown = <String>[];

    for (var i = 0; i < header.length; i++) {
      final raw = header[i].trim();
      if (raw.isEmpty) continue;
      final field = _aliases[_normalise(raw)];
      if (field == null) {
        unknown.add(raw);
      } else {
        map[i] = field;
        recognised.add(raw);
      }
    }

    final rows = <CsvProductRow>[];
    final skipped = <({int row, String reason})>[];

    for (var r = 1; r < table.length; r++) {
      final cells = table[r];
      // A trailing newline produces one empty row in almost every file.
      // Silently ignored rather than reported, because it is an artifact
      // of the format and not something the owner did.
      if (cells.every((c) => c.trim().isEmpty)) continue;

      String? at(String field) {
        for (final e in map.entries) {
          if (e.value == field && e.key < cells.length) {
            final v = cells[e.key].trim();
            return v.isEmpty ? null : v;
          }
        }
        return null;
      }

      final name = at('name');
      if (name == null) {
        skipped.add((row: r + 1, reason: 'no product name'));
        continue;
      }

      rows.add(CsvProductRow(
        rowNumber: r + 1,
        name: name,
        description: at('description'),
        category: at('category'),
        archetype: _archetypeFrom(at('archetype'), at('category')),
        sku: at('sku'),
        price: at('price'),
        cost: at('cost'),
        stock: at('stock'),
        lowStock: at('lowStock'),
        unit: at('unit'),
        imageUrl: at('imageUrl'),
      ));
    }

    return CsvParseResult(
      rows: rows,
      skipped: skipped,
      recognisedHeaders: recognised,
      unknownHeaders: unknown,
    );
  }

  /// Maps whatever the file said to one of kola's three archetypes.
  ///
  /// Falls back to 'packaged', which is the safe default: it is the one
  /// that tracks stock and shows a price, so a mis-mapped row looks
  /// ordinary rather than becoming an untracked service nobody can buy.
  ///
  /// A category naming a service is honoured, because a file with a
  /// "Services" category and no archetype column is the common shape.
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

  /// RFC 4180-ish. See the header for what is and is not covered.
  static List<List<String>> _parseTable(String content) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    // Normalising line endings first means the state machine below only
    // ever sees \n — Windows-authored files are the common case here and
    // handling \r inline would double every branch.
    final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];

      if (inQuotes) {
        if (ch == '"') {
          // "" inside a quoted field is a literal quote.
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
        continue;
      }

      switch (ch) {
        case '"':
          inQuotes = true;
        case ',':
          row.add(field.toString());
          field.clear();
        case '\n':
          row.add(field.toString());
          field.clear();
          rows.add(row);
          row = <String>[];
        default:
          field.write(ch);
      }
    }

    // Whatever is left when the file ends without a trailing newline.
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
