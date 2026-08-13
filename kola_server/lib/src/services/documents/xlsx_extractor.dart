// xlsx_extractor.dart — reading a spreadsheet into text kola can learn.
//
// ── WHY A SPREADSHEET IS WORTH DOING AND A PDF IS NOT (YET) ──────────
//
// FileIntake's refusal message for spreadsheets is right about the
// problem: "spreadsheets need to keep their rows and columns to mean
// anything". A price list flattened into a wall of words is worse than
// useless — "Red Ankara fabric Fabric 4500 42" reads as one sentence and
// a bot will quote from it wrongly.
//
// But an .xlsx is not a layout, it is a ZIP OF XML with the rows and
// columns written down explicitly. Recovering them is deterministic.
// A PDF is the opposite: text position is not text structure, and a
// two-column price list extracts as interleaved nonsense unless the
// layout is reconstructed. That one needs a model; this one needs a
// parser.
//
// ── TWO REAL-WORLD SHAPES, BOTH HANDLED ──────────────────────────────
//
// This was written against actual generated files rather than from the
// spec, which immediately turned up a variant the spec reading would
// have missed:
//
//   sharedStrings   Excel, LibreOffice and Google Sheets exports put
//                   every string in xl/sharedStrings.xml and reference
//                   it by index: <c r="A2" t="s"><v>4</v></c>
//   inlineStr       openpyxl (and several export tools) write the text
//                   into the cell: <c r="A2" t="inlineStr"><is><t>…
//
// A parser that only knew the first would return a sheet of empty cells
// for the second — no error, just nothing, which is the worst failure
// mode there is.
//
// ── WHY REGEX AND NOT AN XML PARSER ──────────────────────────────────
//
// A deliberate, narrow trade. The two documents read here have a fixed,
// simple grammar defined by the OOXML spec, and the alternative is
// another dependency in the server. It would NOT be an acceptable trade
// for arbitrary XML.
//
// The parsing rules were verified against generated files from two
// different writers before this was written, including the awkward
// cases: skipped columns, rows that stop early, rich-text runs split
// across <r> elements, and escaped entities.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// One sheet: a list of rows, each a list of cell values as text.
typedef SheetRows = List<List<String>>;

abstract class XlsxExtractor {
  static final _row = RegExp(r'<row\b[^>]*>(.*?)</row>', dotAll: true);
  static final _cell =
      RegExp(r'<c\b([^>]*)(?:/>|>(.*?)</c>)', dotAll: true);
  static final _ref = RegExp(r'r="([A-Z]+)\d+"');
  static final _type = RegExp(r't="([^"]+)"');
  static final _value = RegExp(r'<v>(.*?)</v>', dotAll: true);
  static final _text = RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true);
  static final _si = RegExp(r'<si>(.*?)</si>', dotAll: true);

  /// Turns .xlsx bytes into readable text, or null if it is not a
  /// spreadsheet this can read.
  ///
  /// Returns null rather than throwing so the caller can say "kola could
  /// not read that" in its own words instead of leaking a parse error.
  static String? extract(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      String? read(String name) {
        for (final file in archive) {
          if (file.name == name && file.isFile) {
            final data = file.readBytes();
            if (data == null) return null;
            return utf8.decode(data, allowMalformed: true);
          }
        }
        return null;
      }

      final sharedXml = read('xl/sharedStrings.xml');
      final shared = sharedXml == null ? const <String>[] : _shared(sharedXml);

      // Sheet order matters — sheet1 is the one the owner was looking at
      // when they saved. Sorted by name so it is at least deterministic;
      // resolving true order needs workbook.xml.rels, which is more
      // machinery than the gain justifies for a text extraction.
      final sheetNames = <String>[
        for (final f in archive)
          if (f.isFile &&
              f.name.startsWith('xl/worksheets/') &&
              f.name.endsWith('.xml'))
            f.name,
      ]..sort();

      if (sheetNames.isEmpty) return null;

      final out = StringBuffer();
      for (final name in sheetNames) {
        final xml = read(name);
        if (xml == null) continue;
        final rows = _rows(xml, shared);
        if (rows.isEmpty) continue;

        if (sheetNames.length > 1) {
          out.writeln('--- ${_sheetLabel(name)} ---');
        }
        out.write(_render(rows));
        out.writeln();
      }

      final text = out.toString().trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  /// Renders rows as "Header: value" lines, one block per row.
  ///
  /// NOT as a comma-joined table. The point of extracting a spreadsheet
  /// is that the columns MEAN something, and a retrieval system chunks
  /// on text — "Selling Price: ₦4,500" survives chunking as a fact,
  /// where a row of bare values does not. This is also what makes a
  /// citation readable when a bot quotes it back.
  ///
  /// The first row is treated as headers when it looks like headers:
  /// every cell non-empty and none of them numeric. A sheet that starts
  /// straight into data keeps its values, labelled by column letter.
  static String _render(SheetRows rows) {
    if (rows.isEmpty) return '';

    final first = rows.first;
    final looksLikeHeaders = first.isNotEmpty &&
        first.every((c) => c.trim().isNotEmpty) &&
        first.every((c) => double.tryParse(c.trim()) == null);

    final headers = looksLikeHeaders
        ? first
        : [for (var i = 0; i < _widest(rows); i++) 'Column ${_letters(i)}'];
    final body = looksLikeHeaders ? rows.skip(1) : rows;

    final out = StringBuffer();
    for (final row in body) {
      if (row.every((c) => c.trim().isEmpty)) continue;
      for (var i = 0; i < row.length; i++) {
        final value = row[i].trim();
        // Empty cells are SKIPPED, not written as "Price: ". A blank in
        // a price column means "no price recorded", and printing the
        // label with nothing after it invites a bot to answer with an
        // empty price.
        if (value.isEmpty) continue;
        final label = i < headers.length ? headers[i].trim() : _letters(i);
        out.writeln('$label: $value');
      }
      out.writeln();
    }
    return out.toString();
  }

  static int _widest(SheetRows rows) =>
      rows.fold(0, (m, r) => r.length > m ? r.length : m);

  static List<String> _shared(String xml) => [
        for (final si in _si.allMatches(xml))
          // Rich text splits one string across several <r><t> runs.
          // Joined, because they are one value to the person who typed
          // it — the split is formatting, not meaning.
          _unescape(
            _text.allMatches(si.group(1) ?? '').map((m) => m.group(1) ?? '').join(),
          ),
      ];

  static SheetRows _rows(String xml, List<String> shared) {
    final rows = <List<String>>[];

    for (final rowMatch in _row.allMatches(xml)) {
      final body = rowMatch.group(1) ?? '';
      final cells = <int, String>{};

      for (final cellMatch in _cell.allMatches(body)) {
        final attrs = cellMatch.group(1) ?? '';
        final inner = cellMatch.group(2) ?? '';

        final ref = _ref.firstMatch(attrs);
        // A cell with no r="" has no column, so there is nowhere to put
        // it. Skipped rather than guessed at — appending it would shift
        // every value after it into the wrong column.
        if (ref == null) continue;
        final column = _columnIndex(ref.group(1)!);

        final type = _type.firstMatch(attrs)?.group(1) ?? 'n';

        if (type == 's') {
          final v = _value.firstMatch(inner)?.group(1);
          final index = v == null ? -1 : (int.tryParse(v) ?? -1);
          cells[column] =
              (index >= 0 && index < shared.length) ? shared[index] : '';
        } else if (type == 'inlineStr' || type == 'str') {
          cells[column] = _unescape(
            _text.allMatches(inner).map((m) => m.group(1) ?? '').join(),
          );
        } else {
          final v = _value.firstMatch(inner)?.group(1);
          cells[column] = v == null ? '' : _unescape(v);
        }
      }

      if (cells.isEmpty) {
        rows.add(const []);
        continue;
      }
      // Rebuilt by index, so a spreadsheet that skips column B still
      // puts column C's value in position 2 rather than 1.
      final width = cells.keys.reduce((a, b) => a > b ? a : b) + 1;
      rows.add([for (var i = 0; i < width; i++) cells[i] ?? '']);
    }
    return rows;
  }

  /// "A" → 0, "Z" → 25, "AA" → 26.
  static int _columnIndex(String letters) {
    var n = 0;
    for (final code in letters.codeUnits) {
      n = n * 26 + (code - 64); // 'A' is 65
    }
    return n - 1;
  }

  static String _letters(int index) {
    var n = index + 1;
    final out = StringBuffer();
    while (n > 0) {
      final rem = (n - 1) % 26;
      out.write(String.fromCharCode(65 + rem));
      n = (n - 1) ~/ 26;
    }
    return out.toString().split('').reversed.join();
  }

  /// XML entities, with `&amp;` LAST.
  ///
  /// Order is load-bearing: replacing `&amp;` first turns the encoded
  /// text `&amp;lt;` into `&lt;` and then into `<`, inventing markup
  /// that was never in the owner's data.
  static String _unescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  static String _sheetLabel(String path) {
    final file = path.split('/').last.replaceAll('.xml', '');
    return file.isEmpty ? 'Sheet' : file;
  }
}
