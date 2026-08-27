// google_drive_adapter.dart — Gate 11 (breadth). First implementation of
// ConnectorAdapter for a pure KNOWLEDGE source — every prior adapter
// either mapped to the product catalog (Paystack transactions,
// GoogleSheetsAdapter's row-matching half) or both mapped AND ingested
// (GoogleSheetsAdapter's other half). This one only ever calls
// DocumentIngestionService — there is no product-catalog side, because
// "pull policy and catalog documents straight from Drive" (this
// connector's own catalog description, connector_catalog.dart) describes
// documents, not a price list shape CatalogRowMapper could parse.
//
// v1 SCOPE — TWO MIME TYPES ONLY: native Google Docs and real `text/plain`
// files. See GoogleDriveService.listIngestableFiles's own doc comment for
// why PDFs/Word docs are a real, named cut rather than a silent gap — no
// PDF/DOCX text-extraction dependency exists in this codebase yet.
//
// NO FOLDER/FILE PICKER, UNLIKE GoogleSheetsAdapter: a spreadsheet picker
// exists because syncing the WRONG sheet writes wrong prices into a live
// catalog — a real mistake worth preventing. Ingesting the wrong Google
// Doc just means the AI can cite a document nobody asked it to; annoying,
// never destructive, and reversible by disconnecting. So v1 syncs every
// eligible file the connected account can see, capped (see
// [_maxFilesPerSync]), rather than requiring a picker step before a
// business gets any value at all — same "connect and go" bias
// GoogleSheetsAdapter itself does NOT get to have, for the opposite
// reason.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';
import 'package:kola_server/src/services/memory/document_ingestion_service.dart';
import 'google_oauth_service.dart';
import 'google_drive_service.dart';

class GoogleDriveAdapter implements ConnectorAdapter {
  GoogleDriveAdapter({
    required this.workspaceId,
    required this.refreshToken,
    required GoogleOAuthService oauth,
    GoogleDriveService? drive,
  })  : _oauth = oauth,
        _drive = drive ?? const GoogleDriveService();

  final int workspaceId;
  final String refreshToken;
  final GoogleOAuthService _oauth;
  final GoogleDriveService _drive;

  DocumentIngestionService get _ingestion => getIt<DocumentIngestionService>();

  /// A business's whole Drive can be thousands of files — this caps one
  /// sync run's worth of ingestion work, same "cap it, don't pretend a
  /// huge source is small" instinct as GoogleSheetsAdapter's own
  /// _maxIngestedRows. Newest-edited files win (see
  /// GoogleDriveService.listIngestableFiles's orderBy) — the ones most
  /// likely to still be current policy, not an old draft nobody deleted.
  static const _maxFilesPerSync = 50;

  /// Per-file character cap — same reasoning as
  /// GoogleSheetsAdapter._maxIngestedChars, applied per document instead
  /// of to one concatenated blob, since each file becomes its own
  /// ingested Document (see [sync]) rather than one combined text.
  static const _maxCharsPerFile = 20000;

  @override
  String get connectorKey => 'google_drive';

  @override
  ConnectorCapabilities get capabilities => const ConnectorCapabilities(
        // Drive's changes.list API supports real incremental sync via a
        // page token, but this v1 pass doesn't implement it — see this
        // file's header on scope. Every run re-lists and re-ingests
        // everything eligible; DocumentIngestionService.ingestFromConnector
        // is idempotent by sourceRef (reindexes rather than duplicating),
        // so a re-sync is wasted API calls, not wrong data.
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

    final files = await _drive.listIngestableFiles(accessToken: accessToken);
    if (files.isEmpty) return const SyncResult.empty();

    final capped = files.take(_maxFilesPerSync).toList();
    var changed = 0;
    final errors = <String>[];

    for (final file in capped) {
      try {
        final text = await _readFile(file, accessToken);
        if (text == null || text.trim().isEmpty) continue;

        final truncated = text.length > _maxCharsPerFile ? text.substring(0, _maxCharsPerFile) : text;

        await _ingestion.ingestFromConnector(
          workspaceId: workspaceId,
          title: file.name,
          text: truncated,
          // Stable per-file id, not per-sync — this is what makes a
          // re-sync of the same file a reindex (DocumentIngestionService
          // .ingestFromConnector's findBySourceRef check) rather than a
          // duplicate Document every run.
          sourceRef: 'google_drive:${file.id}',
        );
        changed++;
      } catch (e) {
        errors.add('${file.name}: $e');
        Log.warning('GoogleDriveAdapter: failed to ingest file ${file.id} (${file.name}): $e');
      }
    }

    return SyncResult(
      recordsSeen: capped.length,
      recordsChanged: changed,
      errors: errors,
    );
  }

  /// Native Google Docs need [GoogleDriveService.exportGoogleDoc]; a real
  /// `text/plain` file needs [GoogleDriveService.downloadPlainText] — the
  /// two Drive endpoints are genuinely different (export vs. media
  /// download), not two names for the same call. [GoogleDriveFile
  /// .mimeType] (populated by listIngestableFiles's `fields` query) is
  /// what tells them apart without a second per-file metadata lookup.
  Future<String?> _readFile(GoogleDriveFile file, String accessToken) {
    if (file.mimeType == 'application/vnd.google-apps.document') {
      return _drive.exportGoogleDoc(fileId: file.id, accessToken: accessToken);
    }
    if (file.mimeType == 'text/plain') {
      return _drive.downloadPlainText(fileId: file.id, accessToken: accessToken);
    }
    // Shouldn't happen — listIngestableFiles already filtered to these
    // two mime types — but a defensive skip beats a crash on a file
    // Google's own query somehow still returned.
    Log.warning('GoogleDriveAdapter: unexpected mime type for file ${file.id}: ${file.mimeType}');
    return Future.value(null);
  }

  @override
  Future<ConnectorHealth> health() async {
    try {
      final tokens = await _oauth.refreshAccessToken(refreshToken);
      final accessToken = tokens['access_token'] as String?;
      if (accessToken == null) {
        return const ConnectorHealth.unhealthy('Google did not return a valid access token.');
      }
      // A real, cheap probe — the same "actually attempt something"
      // discipline the contract requires (see connector_adapter.dart's
      // header), not just a token-refresh check. Any successful list
      // call (even zero results) proves the drive.readonly grant is
      // live.
      await _drive.listIngestableFiles(accessToken: accessToken);
      return const ConnectorHealth.healthy();
    } catch (e) {
      return ConnectorHealth.unhealthy(
        'Could not read this Drive — the Google account may have revoked access, or the '
        'drive.readonly grant may be missing (reconnect if this workspace connected before '
        'Gate 11 shipped). ($e)',
      );
    }
  }
}
