-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 040 — payment gateway sync: Gate 4)
--
-- Apply AFTER 039.
--
-- Backs docs/Kolaa_Connections_Backbone_Direction_v5.pdf's Gate 4 bar:
-- "Paystack + Google Sheets connect, sync, and land in the graph." Gate 1
-- (migration 036) gave the CHANNEL store (`channels`) and the GENERIC
-- store (`workspace_connectors`) a sync-cursor slot and observability
-- counters. It deliberately did not touch `payment_gateway_credentials`,
-- because at Gate 1 nothing pulled from a payment gateway — Paystack and
-- Flutterwave were reactive-webhook only (PaymentWebhookHandler). Gate 4
-- is the first PULL-based use of the connector contract's third store,
-- and this migration is that store's missing half of the same contract
-- migration 036 already gave the other two.
--
-- ── sync_cursor / last_synced_at ─────────────────────────────────────────────
--
-- Same shape and same reasoning as channels.sync_cursor /
-- last_health_check_at (migration 036): an adapter-opaque watermark
-- (PaystackAdapter stores the ISO timestamp of the newest transaction it
-- has processed) plus a distinct "when did a sync actually last run"
-- timestamp, kept apart from updated_at because that column also changes
-- on an unrelated credential rotation.
--
-- ── WHY THIS LIVES ON THE CREDENTIAL ROW, NOT A NEW TABLE ────────────────────
--
-- One row per (workspaceId, gateway) already exists and already is the
-- unique thing a sync run is "for" — the same one-cursor-per-connector
-- shape as channels, just on the paymentGateway store's own table
-- instead of invented as a fourth table connector_sync_log's own
-- per-attempt log already makes unnecessary for observability (this
-- migration only adds STATE, not history — attempt history already has
-- a home in connector_sync_log since migration 036).
--
-- ── RLS ──────────────────────────────────────────────────────────────────────
-- No new table — nothing to enable RLS on. payment_gateway_credentials
-- already has RLS enabled, no policies, since it was created.

alter table payment_gateway_credentials
  add column if not exists sync_cursor    text,
  add column if not exists last_synced_at timestamptz;

comment on column payment_gateway_credentials.sync_cursor is
  'Adapter-opaque watermark for the pull-based sync engine (Gate 4) — PaystackAdapter stores the newest processed transaction''s created_at as an ISO timestamp. Null means never synced.';
comment on column payment_gateway_credentials.last_synced_at is
  'When ConnectorSyncSweepService last actually attempted a sync for this credential, regardless of outcome — distinct from updated_at, which also changes on a key rotation.';
-- ─────────────────────────────────────────────────────────────────────────────
