// microsoft_graph_excel_service.dart — Gate 4. Plain HTTPS wrapper over
// Microsoft Graph's Shares and Workbook APIs, same role/shape as
// GoogleSheetsService in this codebase.
//
// FETCHED AND READ BEFORE WRITING — see microsoft_oauth_service.dart's
// header for the exact source URLs. Two real, documented constraints
// this file works around rather than assumes:
//
//   1. A Google Sheets URL carries the spreadsheet's own stable id
//      (`/spreadsheets/d/<id>/`) — CatalogRowMapper's sibling,
//      GoogleSheetsAdapter, just regexes it out. A OneDrive/SharePoint
//      SHARING URL carries no such id; it must be exchanged with Graph's
//      /shares/{encoded}/driveItem endpoint for a real (driveId, itemId)
//      pair. [resolveShareUrl] is that exchange — it needs a valid
//      access token and therefore ONLY runs at connect-time
//      (ConnectorEndpoint.setExcelFileTarget), never inside the sync
//      loop, where (driveId, itemId) is already known and stored.
//   2. The workbook API's own docs state it is "Not supported" for
//      personal Microsoft accounts — see MicrosoftOAuthService's header
//      on why this connector requests tenant 'organizations' to keep an
//      owner from reaching this failure at all.
//
// AUTH MODEL: same as GoogleSheetsService — every call takes a fresh
// access token as an argument, nothing cached here.

import 'dart:convert';
import 'package:http/http.dart' as http;

/// What a resolved share link becomes: the two ids every subsequent
/// Graph call on this file actually needs, plus the file's own name for
/// a safe-to-show connector-card detail.
class ResolvedDriveItem {
  const ResolvedDriveItem({
    required this.driveId,
    required this.itemId,
    required this.name,
  });

  final String driveId;
  final String itemId;
  final String name;
}

class MicrosoftGraphExcelService {
  const MicrosoftGraphExcelService();

  static const _baseUrl = 'https://graph.microsoft.com/v1.0';

  /// Turns a OneDrive/SharePoint sharing URL into the (driveId, itemId)
  /// pair Graph's item-scoped APIs actually take. The encoding is
  /// Microsoft's own documented scheme, not invented here: base64 the
  /// URL, convert to unpadded base64url (`+`→`-`, `/`→`_`, strip `=`),
  /// prefix `u!`. See this file's header for the source.
  Future<ResolvedDriveItem> resolveShareUrl({
    required String shareUrl,
    required String accessToken,
  }) async {
    final encoded = _encodeSharingUrl(shareUrl);
    final uri = Uri.parse('$_baseUrl/shares/$encoded/driveItem').replace(
      queryParameters: {'\$select': 'id,name,parentReference'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Microsoft Graph could not resolve that link (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final itemId = decoded['id'] as String?;
    final name = decoded['name'] as String?;
    final parentReference = decoded['parentReference'] as Map<String, dynamic>?;
    final driveId = parentReference?['driveId'] as String?;
    if (itemId == null || driveId == null) {
      throw Exception('Microsoft Graph returned a share without a driveItem id.');
    }
    return ResolvedDriveItem(driveId: driveId, itemId: itemId, name: name ?? 'Untitled');
  }

  /// Every value on the file's FIRST worksheet — deliberately no
  /// worksheet-name parameter, matching GoogleSheetsService's own "the
  /// whole first visible sheet" default: an owner sharing one price list
  /// does not also want to be asked which tab. Multi-tab support is a
  /// real future improvement, not built here because nothing in this
  /// pass's scope needs it yet.
  ///
  /// Returns raw rows as Graph serializes a workbook Range's `values`
  /// field: `List<List<dynamic>>`, rectangular (unlike Sheets, Excel's
  /// usedRange pads every row to the same width with empty strings, not
  /// omission — CatalogRowMapper.mapRows already treats an empty string
  /// cell and a missing one identically, so this difference needs no
  /// special handling there).
  Future<List<List<dynamic>>> getValues({
    required String driveId,
    required String itemId,
    required String accessToken,
  }) async {
    final headers = {'Authorization': 'Bearer $accessToken'};

    final worksheetsUri = Uri.parse(
      '$_baseUrl/drives/$driveId/items/$itemId/workbook/worksheets',
    ).replace(queryParameters: {'\$select': 'id,name'});
    final worksheetsResponse = await http.get(worksheetsUri, headers: headers);
    if (worksheetsResponse.statusCode < 200 || worksheetsResponse.statusCode >= 300) {
      throw Exception('Could not list worksheets (${worksheetsResponse.statusCode}): ${worksheetsResponse.body}');
    }
    final worksheets = (jsonDecode(worksheetsResponse.body) as Map<String, dynamic>)['value'] as List<dynamic>?;
    if (worksheets == null || worksheets.isEmpty) return const [];
    final firstWorksheetId = (worksheets.first as Map<String, dynamic>)['id'] as String;

    final rangeUri = Uri.parse(
      '$_baseUrl/drives/$driveId/items/$itemId/workbook/worksheets/$firstWorksheetId/usedRange(valuesOnly=true)',
    ).replace(queryParameters: {'\$select': 'values'});
    final rangeResponse = await http.get(rangeUri, headers: headers);
    if (rangeResponse.statusCode < 200 || rangeResponse.statusCode >= 300) {
      throw Exception('Could not read the sheet (${rangeResponse.statusCode}): ${rangeResponse.body}');
    }
    final values = (jsonDecode(rangeResponse.body) as Map<String, dynamic>)['values'] as List<dynamic>?;
    if (values == null) return const [];
    return values.map((row) => (row as List<dynamic>)).toList();
  }

  /// Cheap, side-effect-free authenticated check — same role as
  /// GoogleSheetsService.probe.
  Future<void> probe({
    required String driveId,
    required String itemId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/drives/$driveId/items/$itemId').replace(
      queryParameters: {'\$select': 'id'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OneDrive/Excel probe failed (${response.statusCode}): ${response.body}');
    }
  }

  static String _encodeSharingUrl(String url) {
    final base64Value = base64.encode(utf8.encode(url));
    final unpadded = base64Value.replaceAll('=', '');
    final urlSafe = unpadded.replaceAll('/', '_').replaceAll('+', '-');
    return 'u!$urlSafe';
  }
}
