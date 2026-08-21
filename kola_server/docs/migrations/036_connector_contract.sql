-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 036 — connector contract: Gate 1)
--
-- Apply AFTER 035.
--
-- Backs docs/Kolaa_Connections_Backbone_Direction_v5.pdf PART III, "What
-- the contract still needs": incremental sync (cursor/watermark), retry
-- and backoff with a dead-letter path, connection health, deletion and
-- retention, provenance on every record, and sync observability. None of
-- this existed anywhere in the schema before this migration — verified
-- by reading connector_catalog.dart, connector_service.dart and every
-- migration through 035 directly, not assumed.
--
-- ── SCOPE: WHAT THIS MIGRATION ACTUALLY TOUCHES ──────────────────────────────
--
-- Gate 1 migrates the two SHIPPED connectors (WhatsApp, Telegram — see
-- connector_catalog.dart) onto the contract. Both are message-delivery
-- channels, not pull-and-paginate sources, so this migration's shape
-- follows what genuinely applies to them:
--
--   messages              provenance + idempotent replay (see below)
--   channels              a generic sync-cursor slot + health-check
--                         timestamp + an explicit retention policy
--   workspace_connectors  sync-observability counters + an explicit
--                         retention policy, for the generic store's
--                         future pull-based adapters (Gate 4)
--   connector_sync_log    NEW — the shared dead-letter/observability
--                         trail every adapter (channel, payment gateway,
--                         or generic) writes to, regardless of which of
--                         the three credential stores it belongs to
--
-- ── PROVENANCE + IDEMPOTENCY ON messages ─────────────────────────────────────
--
-- Before this migration, message_repository.dart's create() stored no
-- external identifier at all — replaying the same WhatsApp/Telegram
-- webhook payload (a real thing both platforms do on retry) created a
-- second row, not zero. That is the exact gap PART VIII's testing
-- section calls out: "ingest the same payload twice and assert one
-- entity, not two."
--
-- source_platform / external_message_id / fetched_at / permission_scope
-- are the contract's "provenance on every record" (source, source ID,
-- fetched-at, permission scope) applied to the one ingestion path Gate 1
-- actually touches. external_message_id is WhatsApp's wamid or
-- Telegram's message id — nullable, because a human-typed reply
-- (sender_type: 'human') or the bot's own outbound text has no external
-- id to carry.
--
-- The unique index below is what makes replay idempotent. Standard
-- Postgres behaviour: a UNIQUE index treats NULL as distinct from every
-- other NULL, so rows with no external_message_id (every message that
-- predates this migration, plus every human/bot-authored outbound
-- message) are never considered duplicates of each other. Only two rows
-- that both carry the SAME conversation_id AND the SAME
-- external_message_id collide — which is exactly and only the "this
-- exact inbound message arrived twice" case.
alter table messages
    add column if not exists source_platform     text,
    add column if not exists external_message_id text,
    add column if not exists fetched_at           timestamptz,
    add column if not exists permission_scope     text;

create unique index if not exists message_conversation_external_id_idx
    on messages (conversation_id, external_message_id);

-- ── channels ──────────────────────────────────────────────────────────────────
--
-- sync_cursor: an adapter-opaque watermark (see contract/sync_types.dart's
-- SyncCursor) — stored as text (JSON-encoded when an adapter needs more
-- than one field) rather than jsonb, matching encrypted_config's own
-- text-not-jsonb precedent in workspace_connectors and keeping this
-- migration's shape uniform with the store it is closest to. Nothing
-- writes a non-null value here yet for WhatsApp/Telegram specifically —
-- see whatsapp_bot_registry.dart / telegram_bot_registry.dart's header
-- comments on why a push-driven channel's "cursor" is close to
-- vestigial today and becomes load-bearing once a pull-based adapter
-- (Gate 4) needs it.
--
-- last_health_check_at: when ChannelHealthCheckService last actually
-- attempted this channel, regardless of outcome — distinct from
-- updated_at, which also changes on unrelated edits (a display name
-- rename) and therefore cannot answer "when did we last actually check."
--
-- retention_policy: RetentionPolicy.retainOnDisconnect by default,
-- matching the existing, already-shipped behavior of
-- ChannelRepository.markDisconnected — which has never deleted a
-- message or conversation, only cleared the live credential. This
-- column makes that an explicit, documented policy instead of an
-- accident of how markDisconnected happened to be written.
alter table channels
    add column if not exists sync_cursor          text,
    add column if not exists last_health_check_at  timestamptz,
    add column if not exists retention_policy      text
        not null default 'retain_on_disconnect'
        check (retention_policy in ('retain_on_disconnect', 'delete_on_disconnect'));

-- ── workspace_connectors ──────────────────────────────────────────────────────
--
-- Sync-observability counters for the generic store's future pull-based
-- adapters. last_synced_at already existed (migration 025) but was only
-- ever written once, at connect time — never by an actual sync run,
-- because no sync run has existed until this gate's contract. These
-- three ride alongside it so a future adapter has somewhere to report
-- to without a second migration.
alter table workspace_connectors
    add column if not exists last_sync_records_seen    integer,
    add column if not exists last_sync_records_changed  integer,
    add column if not exists last_sync_error_count      integer not null default 0,
    add column if not exists retention_policy           text
        not null default 'retain_on_disconnect'
        check (retention_policy in ('retain_on_disconnect', 'delete_on_disconnect'));

-- ── connector_sync_log ────────────────────────────────────────────────────────
--
-- The shared dead-letter + observability trail every adapter writes to,
-- one row per sync/health attempt, regardless of which of the three
-- credential stores (channel / paymentGateway / generic) the connector
-- belongs to. Append-only by design — a history of attempts, not just
-- the latest one, is what makes "this connector has failed its last
-- four checks" answerable instead of only "this connector is currently
-- failing."
--
-- store/connector_key mirror ConnectorDefinition.store/.key from
-- connector_catalog.dart rather than a foreign key into
-- workspace_connectors, because a channel-store or paymentGateway-store
-- connector has no workspace_connectors row at all — this table has to
-- be reachable for all three stores, not just the generic one.
create table if not exists connector_sync_log (
    id             bigserial   primary key,
    workspace_id   bigint      not null references workspaces (id) on delete cascade,

    -- Matches ConnectorDefinition.key. See workspace_connectors.connector_key's
    -- own comment on why this is never renamed once shipped.
    connector_key  text        not null,

    -- 'channel' | 'payment_gateway' | 'generic' — ConnectorStore's wire
    -- values, so a row is self-describing without a join back to the
    -- catalog to know which store it came from.
    store          text        not null
                   check (store in ('channel', 'payment_gateway', 'generic')),

    -- 'sync' | 'health' — what kind of attempt this row records. A
    -- health check and a sync run are both "an attempt", and both are
    -- worth a shared dead-letter shape, but they answer different
    -- owner-facing questions ("is it connected" vs "did it move data")
    -- so the kind is kept rather than merged away.
    kind           text        not null check (kind in ('sync', 'health')),

    status         text        not null check (status in ('success', 'error')),

    records_seen     integer,
    records_changed  integer,

    -- Populated only when status = 'error'. Owner-language where
    -- possible, matching workspace_connectors.last_error's own
    -- convention — this is the dead-letter payload the contract's
    -- "a failed sync must be visible, not silent" requirement asks for.
    error_message    text,

    ran_at         timestamptz not null default now()
);

create index if not exists connector_sync_log_workspace_idx
    on connector_sync_log (workspace_id);

-- The observability query this table exists to answer: "the last N
-- attempts for this connector, newest first."
create index if not exists connector_sync_log_workspace_connector_idx
    on connector_sync_log (workspace_id, connector_key, ran_at desc);

-- ── RLS ──────────────────────────────────────────────────────────────────────
-- Enabled, no policies — deny-all to PostgREST, matching every other
-- table in this project. kola_server reaches Supabase over the direct
-- postgres connection as table owner, which RLS does not apply to.
alter table connector_sync_log enable row level security;
-- ─────────────────────────────────────────────────────────────────────────────
