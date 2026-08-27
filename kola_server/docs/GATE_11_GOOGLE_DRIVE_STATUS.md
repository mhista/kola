# Gate 11 — Breadth: Google Drive connector

Status: **BUILT**, first of five connectors named in the Rev 6 addendum
as still unbuilt (Monnify, Fincra, Instagram, Google Drive, Notion).
Picked first because it was, by a wide margin, the cheapest of the five —
it reuses the existing Google OAuth plumbing and Drive metadata service
built for Gate 4's Sheets connector, rather than needing a new provider
integration from scratch.

## What was built

1. **`GoogleOAuthService.scopeDriveReadonly`** (new scope constant) —
   `drive.readonly`, distinct from the existing `scopeDriveMetadataReadonly`
   (metadata-only, used by the Sheets picker). This one can actually read
   file content.
2. **`GoogleDriveService`** extended with `listIngestableFiles`,
   `exportGoogleDoc`, `downloadPlainText` — listing/reading native Google
   Docs and plain-text files specifically (see scope cut below).
   `GoogleDriveFile` gained a `mimeType` field so the adapter can tell the
   two apart without a second lookup per file.
3. **`GoogleDriveAdapter`** (new, implements `ConnectorAdapter`) — pure
   knowledge ingestion, no product-catalog mapping (unlike
   `GoogleSheetsAdapter`, which does both): lists eligible files, reads
   each one, and hands it to `DocumentIngestionService.ingestFromConnector`
   keyed by `google_drive:$fileId` so a re-sync reindexes rather than
   duplicating.
4. **`ConnectorEndpoint._googleScopesFor`** — `'google_drive'` now maps to
   `[scopeDriveReadonly]`. The OAuth callback route already handled an
   unrecognized (non-Sheets) connectorKey generically ("Connected", no
   follow-up step), so no callback changes were needed.
5. **`ConnectorSyncSweepService._sweepGoogleDrive`** — new sweep method,
   called from `sweepOnce()` alongside the other generic-store connectors.

The `google_drive` catalog entry itself already existed in
`connector_catalog.dart` before this pass (`category: 'know'`, `auth:
oauth`, `featureKey: FeatureKeys.connectorsStorage`) — it had a
definition but no adapter behind it, exactly the gap this closes.

## Real, named scope cuts

- **Only two mime types read: native Google Docs and `text/plain`.** PDFs,
  Word docs, and every other binary/rich format are NOT read — this
  codebase has no PDF/DOCX text-extraction dependency yet, and adding one
  (or OCR, for scanned PDFs) is its own piece of work. A business whose
  policy documents live only as PDFs in Drive will see this connector
  find nothing today.
- **No file/folder picker.** Every eligible file the connected account can
  see gets synced (capped at 50 files, 20,000 characters each, newest-
  edited first) — no "choose which folder" step, unlike Sheets, where
  syncing the wrong sheet corrupts a live price list. Ingesting the wrong
  Google Doc is a much lower-stakes mistake (the AI can cite it; nothing
  is overwritten), so this pass chose "connect and get value immediately"
  over building a picker UI before the connector even proves useful.
- **No incremental sync.** `capabilities.supportsIncrementalSync` is
  `false` — every sync run re-lists and re-reads everything eligible.
  Wasteful on API calls at scale, not wrong: ingestion is idempotent by
  `sourceRef`, so a re-sync reindexes rather than duplicating.

## Verification note

Same limitation as every gate this session: no Dart toolchain in this
environment, so none of this was compiled. `dart pub get && serverpod
generate` plus a `kola_server` redeploy are required before this
connector can be connected in the dashboard — no new migration is needed,
since `google_drive`'s catalog entry and `connectors.storage` feature
flag already existed.
