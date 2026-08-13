// csv_template.dart — a starting file an owner can actually fill in.
//
// ── WHY A TEMPLATE AND NOT JUST A LIST OF COLUMN NAMES ───────────────
//
// The import screen already accepts almost anything: every column except
// `name` is optional and headers are matched through an alias table. That
// is the right behaviour for a file someone ALREADY has, exported from a
// POS or a previous system.
//
// It does nothing for the owner who has their products written in a
// notebook. For them the blank page is the obstacle, and "upload a CSV"
// is advice, not help. A template turns it into a form: open it in
// sheets.new, type down the columns, download as CSV, bring it back.
//
// ── WHAT MAKES THIS FILE WORTH DOWNLOADING ───────────────────────────
//
// Two example rows, not zero.
//
// A header-only file leaves every real question unanswered: does price
// take the ₦? do I write "40" or "40 units"? what goes in a column that
// does not apply? The examples answer all three by demonstration, which
// is how people read a spreadsheet — they copy the row above.
//
// The two rows are deliberately DIFFERENT KINDS of thing:
//
//   a stocked product   every column filled in
//   a service           blank price and blank stock, which is how you say
//                       "by quote" and "not something I keep in stock"
//
// That second row is the one that earns its place. Blank-means-unknown is
// impossible to guess and the alternative — typing 0 — is a false fact:
// the catalog would show the service as out of stock and kola would tell
// customers it cannot be bought.
//
// ── A NOTE ROW WOULD BREAK THE FILE ──────────────────────────────────
//
// The instructions live in the page, not in a leading "# fill this in"
// line. A comment row is data to a CSV parser, so it would import as a
// product named "# fill this in" — and this file's own parser would be
// right to do that.

import 'dom_files.dart';
import 'product_csv.dart';

abstract class CsvTemplate {
  /// The headers, taken from the importer's OWN field labels.
  ///
  /// ── WHY NOT JUST TYPE THEM OUT ──────────────────────────────────────
  ///
  /// Because I did, and one was wrong. A hand-written "Low stock alert"
  /// and the importer's "Low-stock alert" are the same words to a person
  /// and two different strings to an alias table — and the second one
  /// did not resolve either, which is how the collision below got found.
  ///
  /// Reading csvTargetFields means the file we hand an owner is by
  /// construction the file the importer expects. Renaming a field can no
  /// longer silently break the template.
  ///
  /// (Order comes from csvTargetFields too: name first because it is the
  /// only required column, so someone filling this in left to right can
  /// stop anywhere and still have a usable file.)
  static List<String> get headers =>
      [for (final f in csvTargetFields) f.label];

  /// Example values, keyed by FIELD ID rather than by position.
  ///
  /// Position would silently misalign the moment a field is inserted
  /// into csvTargetFields — prices would appear under Category and the
  /// template would teach the wrong thing.
  static const _examples = <Map<String, String>>[
    {
      'name': 'Ankara headwrap',
      'category': 'Accessories',
      'description': 'Cotton wax print, 2 yards. Holds colour after washing.',
      'price': '4500',
      'cost': '2100',
      'stock': '24',
      'lowStock': '5',
      'sku': 'AHW-001',
    },
    {
      'name': 'Custom tailoring',
      'category': 'Services',
      'description': 'Measured and sewn to order. Turnaround depends on '
          'the week.',
      // price and stock DELIBERATELY ABSENT, not '0'.
      //
      // Blank price means "by quote" and blank stock means "not
      // something I keep in stock". Typing 0 in either is a false fact:
      // the catalog would show this service as free and out of stock,
      // and kola would tell customers it cannot be bought. This row
      // exists to demonstrate exactly that, because it is the one thing
      // an owner cannot guess from a header.
      'sku': 'TAI-001',
    },
  ];

  static String build() {
    final ids = [for (final f in csvTargetFields) f.id];
    final rows = <List<String>>[
      headers,
      for (final example in _examples)
        [for (final id in ids) example[id] ?? ''],
    ];
    // CRLF, which is what RFC 4180 specifies and what Excel expects.
    // Sheets and LibreOffice accept either.
    return rows.map((r) => r.map(_field).join(',')).join('\r\n');
  }

  /// Quotes only when a field would otherwise change meaning.
  ///
  /// Quoting everything is valid CSV and looks wrong in a spreadsheet
  /// preview, which matters here — this file is read by a person before
  /// it is read by a parser.
  static String _field(String value) {
    final needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  /// Triggers the browser download.
  ///
  /// The interop lives in dom_files.dart, which is where every DOM type
  /// this app touches is declared explicitly. Reaching for
  /// `createElement('a') as HTMLAnchorElement` here instead would be a
  /// second place to get the same cast wrong.
  static void download({String fileName = 'kola-products-template.csv'}) =>
      downloadText(build(), fileName: fileName);
}
