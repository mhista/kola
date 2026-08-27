// google_drive_service.dart — Connect Gate, subphase 4d (multi-sheet).
//
// WHY THIS EXISTS: google_sheets_service.dart can already READ any
// spreadsheet the signed-in account can open — spreadsheets.readonly is
// an account-wide scope, not a per-file one — but it has no way to
// DISCOVER what spreadsheets exist without being told a specific id.
// That's what forced the old "paste a link" step even though the OAuth
// grant already covered every sheet in the Drive. This service closes
// exactly that gap: list the account's spreadsheets so the dashboard can
// offer a picker instead of a paste box.
//
// SCOPE: drive.metadata.readonly, not drive.readonly or the bare drive
// scope — same "narrowest scope that does the job" discipline as
// google_oauth_service.dart's scopeCalendarEvents comment. Listing a
// file's id/name/link is metadata; nothing here ever reads or writes a
// file's actual content — that stays GoogleSheetsService's job, under
// its own separate scope.
//
// PLAIN HTTPS, NOT A GOOGLE SDK PACKAGE — same convention as every other
// provider wrapper in this codebase.

import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleDriveFile {
  const GoogleDriveFile({
    required this.id,
    required this.name,
    this.webViewLink,
    this.mimeType,
  });

  final String id;
  final String name;
  final String? webViewLink;

  /// Gate 11 — only populated when the caller's `fields` query asked for
  /// it (see [GoogleDriveService.listIngestableFiles]). This is how
  /// google_drive_adapter.dart tells a native Google Doc (export API)
  /// from a plain-text file (direct download) apart without a second
  /// per-file lookup.
  final String? mimeType;

  factory GoogleDriveFile.fromJson(Map<String, dynamic> json) {
    return GoogleDriveFile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled spreadsheet',
      webViewLink: json['webViewLink'] as String?,
      mimeType: json['mimeType'] as String?,
    );
  }
}

class GoogleDriveService {
  const GoogleDriveService();

  static const _baseUrl = 'https://www.googleapis.com/drive/v3/files';

  /// Every Google Sheets file the signed-in account can see, newest-
  /// edited first — the picker's data source. Trashed files are
  /// excluded (Drive returns them by default otherwise, which would
  /// dangle a "connect" button pointed at a file the owner already
  /// deleted). Not paginated: Drive returns up to 1000 files per page
  /// and a business realistically has far fewer spreadsheets than that;
  /// revisit with a pageToken loop only if that assumption ever breaks.
  Future<List<GoogleDriveFile>> listSpreadsheets({required String accessToken}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false",
      'fields': 'files(id,name,webViewLink)',
      'orderBy': 'modifiedTime desc',
      'pageSize': '1000',
    });
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Drive list failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final files = decoded['files'] as List<dynamic>? ?? const [];
    return files
        .map((f) => GoogleDriveFile.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  /// Single-file metadata lookup — just the display name, for callers
  /// that already have a spreadsheetId (from stored config, not the
  /// picker) and want a human-readable label instead of the opaque id.
  /// One small GET, `fields=id,name` only, matching this file's own
  /// "metadata, never content" scope note above. Callers that treat a
  /// failure here as fatal are using this wrong — see
  /// GoogleSheetsAdapter._ingestIntoKnowledgeBase for the intended
  /// best-effort usage.
  Future<GoogleDriveFile> getFile({
    required String fileId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/$fileId').replace(
      queryParameters: {'fields': 'id,name'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Drive file lookup failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return GoogleDriveFile.fromJson(decoded);
  }

  /// Gate 11 — every file google_drive_adapter.dart can actually turn
  /// into knowledge, newest-edited first. Deliberately narrow to the two
  /// mime types this pass can read as plain text: native Google Docs
  /// (`application/vnd.google-apps.document`, exportable as text/plain —
  /// see [exportGoogleDoc]) and real plain-text files (`text/plain`).
  ///
  /// PDFs, Word docs, and every other binary format are a REAL, NAMED
  /// SCOPE CUT, not an oversight: reading them means either a PDF/DOCX
  /// text-extraction library this codebase does not currently depend on,
  /// or (for a scanned PDF) OCR — either is its own piece of work,
  /// deserving its own pass rather than being bolted on here. A business
  /// whose policy documents live only as PDFs in Drive will see this
  /// connector list nothing today; that is the honest current behavior,
  /// not a silent partial success.
  Future<List<GoogleDriveFile>> listIngestableFiles({required String accessToken}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': "(mimeType='application/vnd.google-apps.document' or mimeType='text/plain') "
          'and trashed=false',
      'fields': 'files(id,name,webViewLink,mimeType)',
      'orderBy': 'modifiedTime desc',
      'pageSize': '1000',
    });
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Drive list failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final files = decoded['files'] as List<dynamic>? ?? const [];
    return files
        .map((f) => GoogleDriveFile.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  /// A native Google Doc has no downloadable "file bytes" of its own —
  /// Drive's `files.export` endpoint is how you ask Google to render one
  /// into a real format, here plain text. Requires [scopeDriveReadonly]
  /// (google_oauth_service.dart) — [scopeDriveMetadataReadonly] alone
  /// 403s this call, since exporting content is not metadata.
  Future<String> exportGoogleDoc({
    required String fileId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/$fileId/export').replace(
      queryParameters: {'mimeType': 'text/plain'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Doc export failed (${response.statusCode}): ${response.body}');
    }
    return response.body;
  }

  /// A real `text/plain` file's actual bytes — `alt=media`, Drive's
  /// download-the-content query param (distinct from every other call in
  /// this file, which asks for JSON metadata). Same [scopeDriveReadonly]
  /// requirement as [exportGoogleDoc].
  Future<String> downloadPlainText({
    required String fileId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/$fileId').replace(
      queryParameters: {'alt': 'media'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Drive file download failed (${response.statusCode}): ${response.body}');
    }
    return response.body;
  }
}
