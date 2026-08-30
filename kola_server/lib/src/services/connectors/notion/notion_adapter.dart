// notion_adapter.dart — Gate 11 (breadth), fifth connector. Second pure
// KNOWLEDGE-only adapter after GoogleDriveAdapter (see that file's
// header on what "pure knowledge, no product-catalog side" means) —
// this one only ever calls DocumentIngestionService.
//
// v1 SCOPE — PAGES ONLY, NOT DATABASES/DATA SOURCES: Notion's newer API
// (Notion-Version 2026-03-11, confirmed against
// https://developers.notion.com/reference/post-search on 2026-08-27)
// splits what used to be one "database" object into `database` +
// `data_source`, with the data_source carrying a `properties` SCHEMA
// (column definitions) rather than row values — reading actual row
// DATA out of a data source needs a separate, differently-shaped query
// endpoint this pass didn't build. A page's content (its own text
// blocks) is a much simpler, uniform shape regardless of whether the
// page lives standalone or as a data-source row, which is why this v1
// only ingests pages. A business whose knowledge lives in a Notion
// database's row properties (e.g. a structured FAQ database) will see
// this connector find nothing today — same category of real, named cut
// as GoogleDriveAdapter's two-mime-type limit.
//
// TEXT-BLOCK ALLOWLIST ONLY: see notion_service.dart's header — tables,
// images, embeds, toggles, code blocks, and callouts are silently
// skipped, and nested blocks are not recursed into. A text-heavy page
// (notes, an SOP) still ingests well; a page built mostly of toggles or
// a database view will read as mostly empty.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';
import 'package:kola_server/src/services/memory/document_ingestion_service.dart';
import 'notion_service.dart';

class NotionAdapter implements ConnectorAdapter {
  NotionAdapter({required this.workspaceId, required NotionService service}) : _service = service;

  final int workspaceId;
  final NotionService _service;

  DocumentIngestionService get _ingestion => getIt<DocumentIngestionService>();

  /// Same "cap a whole-workspace read, newest first" instinct as
  /// GoogleDriveAdapter._maxFilesPerSync — a workspace's shared pages
  /// could number in the hundreds; this bounds one sync run's cost.
  /// NotionService.listPages already sorts newest-edited-first, so a
  /// capped run still favours current content over stale pages nobody
  /// deleted.
  static const _maxPagesPerSync = 50;

  static const _maxCharsPerPage = 20000; // same per-document cap as GoogleDriveAdapter

  @override
  String get connectorKey => 'notion';

  @override
  ConnectorCapabilities get capabilities => const ConnectorCapabilities(
        // Notion's search endpoint has no confirmed "changed since"
        // filter for this pass — every run re-lists and re-reads
        // everything shared. DocumentIngestionService.ingestFromConnector
        // is idempotent by sourceRef, so this is wasted API calls on a
        // re-sync, not wrong data — same trade-off GoogleDriveAdapter
        // makes for the same reason.
        supportsIncrementalSync: false,
        supportsPagination: true,
        isPushDriven: false,
      );

  @override
  String get retentionPolicy => RetentionPolicy.retainOnDisconnect;

  @override
  Future<SyncResult> sync({SyncCursor cursor = SyncCursor.none}) async {
    final pages = await _service.listPages(pageSize: _maxPagesPerSync);
    if (pages.isEmpty) return const SyncResult.empty();

    var changed = 0;
    final errors = <String>[];

    for (final page in pages) {
      try {
        final text = await _service.readPageText(page.id);
        if (text.trim().isEmpty) continue;

        final truncated = text.length > _maxCharsPerPage ? text.substring(0, _maxCharsPerPage) : text;

        await _ingestion.ingestFromConnector(
          workspaceId: workspaceId,
          title: page.title,
          text: truncated,
          // Stable per-page id — makes a re-sync of the same page a
          // reindex (ingestFromConnector's findBySourceRef check)
          // rather than a duplicate Document every run.
          sourceRef: 'notion:${page.id}',
        );
        changed++;
      } catch (e) {
        errors.add('${page.title}: $e');
        Log.warning('NotionAdapter: failed to ingest page ${page.id} (${page.title}): $e');
      }
    }

    return SyncResult(
      recordsSeen: pages.length,
      recordsChanged: changed,
      errors: errors,
    );
  }

  @override
  Future<ConnectorHealth> health() async {
    try {
      await _service.probe();
      return const ConnectorHealth.healthy();
    } catch (e) {
      // NOTE: a zero-pages-shared workspace is NOT an error case — see
      // NotionService.probe's own doc comment — so reaching this catch
      // means the request itself failed (bad/revoked token, workspace
      // deauthorized the integration), not "nothing shared yet."
      return ConnectorHealth.unhealthy(
        'Could not authenticate with Notion using the stored integration token — it may have '
        'been revoked, or the integration removed from the workspace. ($e)',
      );
    }
  }
}
