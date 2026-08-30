# Gate 11 — Breadth: Notion connector

Status: **BUILT** — fourth of the five connectors named in the Rev 6
addendum to actually ship (after Google Drive, Monnify, Fincra).
Instagram remains the one deliberately not built — see its own note at
the bottom of this file.

## What was verified before writing anything

Same discipline as every connector this session — real docs fetched
and cited, not assumed. Two large OpenAPI-derived reference dumps
(Notion's `POST /v1/search` and `GET /v1/blocks/{id}/children`) were
fetched and read in full via a subagent (they exceeded this session's
direct fetch size limit) before any code was written.

- **Auth** — confirmed against
  https://developers.notion.com/docs/authorization on 2026-08-27:
  Notion offers three modes — internal-connection static tokens,
  personal access tokens (also static), and full OAuth 2.0 for PUBLIC
  connections meant to be installed across many workspaces kolaa
  doesn't own. A business connecting its own Notion workspace is
  exactly Notion's own "internal connection" use case, so this build
  uses a single static Bearer token — no client_id/secret, no
  authorize/redirect/exchange dance, no refresh token. This is the
  *correct* auth model for this use case, not a shortcut past a harder
  OAuth build — the same reasoning that already keeps Paystack/Monnify/
  Fincra on static keys instead of OAuth.
- **Search (list pages)** — confirmed against
  https://developers.notion.com/reference/post-search on 2026-08-27:
  `POST /v1/search`, filterable to `{"property": "object", "value":
  "page"}`, sortable by `last_edited_time`. A page's title lives at
  `properties.<PropName>.title[].plain_text` for whichever property's
  own `type` is `"title"` — NOT a fixed key name, since a workspace
  owner can rename that column — so `NotionService._pageFromSearchResult`
  walks every property looking for the one whose type matches.
- **Page content (block children)** — confirmed against
  https://developers.notion.com/reference/get-block-children on
  2026-08-27: `GET /v1/blocks/{id}/children` works directly on a page's
  own id (a page IS a block in Notion's data model — no separate
  "get page content" endpoint exists or is needed). Text sits at
  `block[block.type].rich_text[].plain_text` for the handful of
  block types this build reads.

## What was built

1. **`NotionService`** (new, `lib/src/services/connectors/notion/`) —
   `listPages` (paginated search, pages only), `readPageText` (one
   page's direct block children, text-block types only), `probe`.
2. **`NotionAdapter`** (new, implements `ConnectorAdapter`) — second
   pure-knowledge adapter after `GoogleDriveAdapter` (no product-catalog
   side): lists pages, reads each one, hands it to
   `DocumentIngestionService.ingestFromConnector` keyed by
   `notion:$pageId` so a re-sync reindexes rather than duplicating.
3. **`connector_catalog.dart`** — new `'notion'` entry, one field
   (`integrationToken`), `category: 'know'`, `auth: fields`,
   `store: generic`, reuses `FeatureKeys.connectorsStorage` (same flag
   Drive/OneDrive already gate on). `helpText` explicitly walks the
   owner through the one manual step Notion itself requires (see
   below) — a connector that silently returns zero pages because
   nothing was shared would look broken, not merely empty.
4. **`connector_sync_sweep_service.dart`** — new `_sweepNotion()`,
   same generic-store/single-secret shape as `_sweepBumpa` (Bumpa
   needed two config fields; Notion needs one).

**No migration, no dashboard changes, no client changes.** Unlike every
payment-gateway connector this session, Notion's `store: generic` +
`auth: fields` combination is already fully handled by
`ConnectorEndpoint.connectConnector` and the dashboard's existing
generic connector form (the same plumbing Bumpa already proved out) —
this build only adds a new catalog entry, service, adapter, and sweep
call, nothing structural.

## Real, named scope cuts

- **Pages only, not databases/data sources.** Notion's current API
  (Notion-Version 2026-03-11) splits the old "database" object into
  `database` + `data_source`; reading actual row data out of a data
  source needs a differently-shaped query endpoint this pass didn't
  build. A business whose knowledge lives in a structured Notion
  database (e.g. a row-per-FAQ table) will see this connector find
  nothing today — a page's own content is a much simpler, uniform shape
  than a data source's schema-plus-rows, which is why v1 stops there.
- **Text-block allowlist only, no recursion.** Only paragraph/
  heading_1/2/3/bulleted_list_item/numbered_list_item blocks are read,
  and only a page's own DIRECT children — a nested sub-list, a toggle's
  contents, tables, images, embeds, and code blocks are all silently
  skipped. Same "enough to be useful, not exhaustive" cut
  `GoogleDriveAdapter` makes for mime types.
- **No incremental sync.** Every run re-lists and re-reads everything
  shared, same trade-off Drive's connector already makes — wasteful on
  API calls at scale, not wrong, since ingestion is idempotent by
  `sourceRef`.
- **The manual per-page share step is a Notion product constraint, not
  a build gap.** An internal integration's token grants access to
  NOTHING until the workspace owner explicitly shares each page with it
  from Notion's own UI. This build cannot automate that step — it can
  only make the requirement visible (the catalog entry's `helpText`
  spells it out) rather than let a business connect the token and be
  confused why nothing synced.

## Instagram — still not built, on purpose

The fifth connector named in the Rev 6 addendum. Left for last across
this whole Gate 11 pass because it isn't really a `ConnectorAdapter`/
`sync()` case at all — Instagram DMs are push-driven (a business
receives messages, it doesn't poll for a list of past ones the way
Paystack/Monnify/Fincra/Drive/Notion all do), which is architecturally
closer to this codebase's existing bot-registry-style channel
connectors (WhatsApp/Telegram) than to anything in
`connector_sync_sweep_service.dart`. Building it as a real channel
(inbound webhook receiver, conversation threading, outbound send) is a
materially different and larger piece of work than any connector in
this pass — worth its own scoping conversation rather than a rushed
sync()-shaped adapter that wouldn't fit Instagram's actual message
model.

## Verification note

Same limitation as every gate this session: no Dart toolchain here, so
none of this compiled locally. `dart pub get` alone is sufficient
before this connector can be connected (no `serverpod generate` step —
no server model or generated-protocol field changed, since `notion`
reuses `WorkspaceConnector`'s existing generic `encryptedConfig` blob
the same way Bumpa/Sheets/Drive/OneDrive all do). No migration was
needed or applied.
