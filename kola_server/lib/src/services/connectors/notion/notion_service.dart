// notion_service.dart — Gate 11 (breadth), fifth and final connector
// named in the Rev 6 addendum (Monnify, Fincra, Instagram, Google
// Drive, Notion — Instagram intentionally last/unbuilt, see this
// codebase's own status docs on why it's architecturally a different
// kind of connector). Plain HTTPS wrapper via package:http around
// Notion's REST API.
//
// AUTH MODEL — INTERNAL INTEGRATION TOKEN, NOT OAUTH: Notion offers
// three auth modes (confirmed against
// https://developers.notion.com/docs/authorization on 2026-08-27):
// internal-connection static tokens, personal access tokens (also
// static), and full OAuth 2.0 for PUBLIC connections distributed to
// other workspaces. kolaa is not distributing a public Notion app — a
// business connects ITS OWN workspace, exactly the "internal
// connection" use case Notion's own docs describe. That means a single
// static Bearer token (no client_id/secret, no authorize/redirect/
// token-exchange dance, no refresh) is the CORRECT auth model here, not
// a cut-down version of OAuth — building the full public-connection
// OAuth flow for a single-workspace-owner product would be needless
// machinery, the same reasoning that keeps Paystack/Monnify/Fincra on
// static-key auth instead of OAuth. This is why NotionAdapter's
// ConnectorDefinition uses `auth: ConnectorAuth.fields` (one field,
// `integrationToken`) and `store: ConnectorStore.generic` — the exact
// shape BumpaService already established for "single static secret,
// generic store" — not the Google/Microsoft OAuth machinery.
//
// ONE MANUAL STEP THIS CONNECTOR CANNOT AUTOMATE: an internal
// integration's token has access to NOTHING until the workspace owner
// manually shares each page/database with the connection from Notion's
// own UI (visit the page → ••• menu → Add connections). This is a real
// Notion product constraint, not a gap in this build — see this file's
// header note reflected in connector_catalog.dart's helpText for the
// 'notion' entry.
//
// SEARCH — LISTS EVERYTHING SHARED WITH THE INTEGRATION: POST
// /v1/search, confirmed against
// https://developers.notion.com/reference/post-search on 2026-08-27.
// This build filters `{"property": "object", "value": "page"}` —
// PAGES ONLY, not databases/data sources. See notion_adapter.dart's
// header for why that's a real, named v1 scope cut, not an oversight.
//
// BLOCK CHILDREN — PAGE CONTENT: GET /v1/blocks/{id}/children,
// confirmed against
// https://developers.notion.com/reference/get-block-children on
// 2026-08-27. A page IS a block in Notion's model, so this endpoint
// works directly on a page's id — no separate "get page content" call
// exists or is needed. Only paragraph/heading_1/heading_2/heading_3/
// bulleted_list_item/numbered_list_item blocks are read for their
// `rich_text[].plain_text` — every other block type (tables, images,
// embeds, toggles, code blocks, callouts) is silently skipped. This
// mirrors GoogleDriveAdapter's "two mime types only" scope cut: enough
// to make a text-heavy Notion page (meeting notes, an SOP, a policy
// doc) useful to ingest, not full-fidelity Notion rendering.
//
// API VERSION: sent as the required `Notion-Version` header — pinned
// to a fixed date string so Notion's own API evolution doesn't silently
// change this service's response shapes underneath it. Confirmed
// current per the docs fetched for this build.

import 'dart:convert';
import 'package:http/http.dart' as http;

class NotionPage {
  const NotionPage({required this.id, required this.title, this.lastEditedTime});
  final String id;
  final String title;
  final DateTime? lastEditedTime;
}

class NotionService {
  NotionService({required this.integrationToken});

  final String integrationToken;

  static const _baseUrl = 'https://api.notion.com/v1';
  static const _apiVersion = '2026-03-11';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $integrationToken',
        'Notion-Version': _apiVersion,
        'Content-Type': 'application/json',
      };

  /// Lists every page this integration has been shared with (see this
  /// file's header on why that sharing step is manual and outside this
  /// service's control), paginated via `start_cursor`. Returns
  /// [NotionPage]s only — data sources/databases are filtered out
  /// server-side by the `filter` in the request body, not client-side,
  /// so this never wastes a page of results on objects [NotionAdapter]
  /// would just discard.
  Future<List<NotionPage>> listPages({String? startCursor, int pageSize = 50}) async {
    final body = <String, dynamic>{
      'filter': {'property': 'object', 'value': 'page'},
      'sort': {'timestamp': 'last_edited_time', 'direction': 'descending'},
      'page_size': pageSize,
      if (startCursor != null) 'start_cursor': startCursor,
    };
    final response = await http.post(
      Uri.parse('$_baseUrl/search'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Notion search failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List? ?? const [];
    return results.whereType<Map<String, dynamic>>().map(_pageFromSearchResult).whereType<NotionPage>().toList();
  }

  /// A page's title lives under `properties.<PropName>` where that
  /// property's own `type` is `"title"` — the property NAME is not
  /// fixed to "Name"/"Title" (a database's title column can be renamed
  /// by the workspace owner), so this walks every property looking for
  /// the one whose type matches, rather than guessing a key. Confirmed
  /// against https://developers.notion.com/reference/post-search on
  /// 2026-08-27.
  static NotionPage? _pageFromSearchResult(Map<String, dynamic> row) {
    if (row['object'] != 'page') return null;
    final id = row['id'] as String?;
    if (id == null) return null;

    final properties = row['properties'] as Map<String, dynamic>? ?? const {};
    String title = 'Untitled';
    for (final prop in properties.values) {
      if (prop is Map<String, dynamic> && prop['type'] == 'title') {
        final richText = prop['title'] as List? ?? const [];
        final text = richText
            .whereType<Map<String, dynamic>>()
            .map((r) => r['plain_text'] as String? ?? '')
            .join();
        if (text.trim().isNotEmpty) title = text.trim();
        break;
      }
    }

    final lastEdited = row['last_edited_time'] as String?;
    return NotionPage(
      id: id,
      title: title,
      lastEditedTime: lastEdited == null ? null : DateTime.tryParse(lastEdited),
    );
  }

  /// Reads a page's own top-level content blocks as plain text — see
  /// this file's header on the block-type allowlist. Does NOT recurse
  /// into nested blocks (a bulleted item's own sub-list, a toggle's
  /// contents) — v1 reads a page's direct content only, matching
  /// GoogleDriveAdapter's "enough to be useful, not exhaustive"
  /// scope cut. Paginates via `start_cursor` up to [_maxBlockPages] to
  /// bound one page's read cost.
  Future<String> readPageText(String pageId) async {
    final buffer = StringBuffer();
    String? cursor;
    var pages = 0;

    do {
      final uri = Uri.parse('$_baseUrl/blocks/$pageId/children').replace(
        queryParameters: {
          'page_size': '100',
          if (cursor != null) 'start_cursor': cursor,
        },
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Notion block-children read failed (${response.statusCode}): ${response.body}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List? ?? const [];
      for (final block in results.whereType<Map<String, dynamic>>()) {
        final text = _plainTextFromBlock(block);
        if (text != null && text.isNotEmpty) {
          buffer.writeln(text);
        }
      }
      cursor = decoded['has_more'] == true ? decoded['next_cursor'] as String? : null;
      pages++;
    } while (cursor != null && pages < _maxBlockPages);

    return buffer.toString();
  }

  static const _maxBlockPages = 10; // bounds one page's read cost (≤1,000 blocks)

  static const _textBlockTypes = {
    'paragraph',
    'heading_1',
    'heading_2',
    'heading_3',
    'bulleted_list_item',
    'numbered_list_item',
  };

  static String? _plainTextFromBlock(Map<String, dynamic> block) {
    final type = block['type'] as String?;
    if (type == null || !_textBlockTypes.contains(type)) return null;
    final content = block[type] as Map<String, dynamic>?;
    final richText = content?['rich_text'] as List? ?? const [];
    final text = richText
        .whereType<Map<String, dynamic>>()
        .map((r) => r['plain_text'] as String? ?? '')
        .join();
    return text;
  }

  /// Cheap, side-effect-free authenticated probe — same role as every
  /// other service's probe() in this directory: validate the token
  /// before persisting it (ConnectorEndpoint.connectConnector doesn't
  /// currently probe generic-store connectors — see that file's own
  /// comment on Bumpa needing none either — but this is here for
  /// [NotionAdapter.health] and any future connect-time check).
  /// Zero-result search (no pages shared yet) is still a SUCCESSFUL
  /// probe — an empty result means "token valid, nothing shared yet,"
  /// not "token invalid."
  Future<void> probe() async {
    await listPages(pageSize: 1);
  }
}
