-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 041 — generic connector sync: Gate 4)
--
-- Apply AFTER 040.
--
-- Migration 036 (Gate 1) gave `workspace_connectors` sync-observability
-- COUNTERS (last_sync_records_seen/changed, last_sync_error_count,
-- retention_policy) but never a cursor column — its own header said so
-- explicitly: "Nothing writes these yet... These columns exist now so
-- the first Gate 4 pull-based adapter (Paystack, Google Sheets) has
-- somewhere to report to." Migration 040 closed that gap for the
-- paymentGateway store (Paystack). This closes the same gap for the
-- generic store, whose first real pull-based adapter is Google Sheets.
--
-- Same shape and reasoning as migration 040's sync_cursor: an
-- adapter-opaque watermark, persisted by the caller (ConnectorSyncSweepService),
-- never interpreted by this table.

alter table workspace_connectors
  add column if not exists sync_cursor text;

comment on column workspace_connectors.sync_cursor is
  'Adapter-opaque watermark for the pull-based sync engine (Gate 4) — GoogleSheetsAdapter stores the sheet''s last-seen revision/etag or row-count marker here. Null means never synced.';
-- ─────────────────────────────────────────────────────────────────────────────
