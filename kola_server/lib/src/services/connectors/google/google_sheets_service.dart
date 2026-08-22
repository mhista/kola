// google_sheets_service.dart — Gate 4. Plain HTTPS wrapper over Google
// Sheets API v4, same role/shape as PaystackService/FlutterwaveService
// in this codebase: everything that needs to read a business's sheet
// does it THROUGH this, never builds a sheets.googleapis.com URL
// directly. Read-only, deliberately — matches the OAuth scope this
// connector actually requests (spreadsheets.readonly, see
// google_oauth_service.dart) and PART IV of the PDF's catalog-ownership
// rule: a connected source is a read-only mirror, never edited back.
//
// AUTH MODEL: every call takes a fresh ACCESS token as an argument
// rather than storing one — see GoogleOAuthService.refreshAccessToken's
// own doc comment on why this service never caches a token across
// calls; GoogleSheetsAdapter refreshes once per sync run and passes the
// result straight through.

import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSheetsService {
  const GoogleSheetsService();

  static const _baseUrl = 'https://sheets.googleapis.com/v4/spreadsheets';

  /// Every value in [range] (default: the whole first visible sheet, up
  /// to column ZZ and row 100,000 — generous enough for any real price
  /// list without pulling an unbounded read). Returns raw rows exactly
  /// as Sheets serializes them: `List<List<dynamic>>`, ragged (a row
  /// shorter than its header is normal — a trailing empty cell is
  /// simply omitted, not sent as `""`), numbers as `num`, everything
  /// else as `String`. [catalog_row_mapper.dart] is what turns this into
  /// something a product upsert can use.
  Future<List<List<dynamic>>> getValues({
    required String spreadsheetId,
    required String accessToken,
    String range = 'A1:ZZ100000',
  }) async {
    final uri = Uri.parse('$_baseUrl/$spreadsheetId/values/$range');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Sheets read failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final values = decoded['values'] as List<dynamic>?;
    if (values == null) return const [];
    return values.map((row) => (row as List<dynamic>)).toList();
  }

  /// Cheap, side-effect-free authenticated check — confirms the access
  /// token is still valid and the spreadsheet is still reachable,
  /// without pulling any actual data. Used by
  /// [GoogleSheetsAdapter.health].
  Future<void> probe({required String spreadsheetId, required String accessToken}) async {
    final uri = Uri.parse('$_baseUrl/$spreadsheetId').replace(
      queryParameters: {'fields': 'spreadsheetId'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Sheets probe failed (${response.statusCode}): ${response.body}');
    }
  }
}
