-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 025 — workspace connectors)
--
-- Apply AFTER 024. APPLIED AND VERIFIED against Supabase.
--
-- ── WHY THIS FILE WAS WRITTEN LATE ───────────────────────────────────────────
--
-- The DDL below was applied to the live database on 2026-08-08 (recorded in
-- Supabase's migration history as `workspace_connectors`) but the .sql file
-- was never committed. docs/migrations/ ended at 024, so a rebuild from this
-- directory produced a database WITHOUT this table, and ConnectorService
-- would have failed at runtime against it.
--
-- This file is reconstructed from the live schema — columns, constraints and
-- indexes read back out of information_schema and pg_indexes, not from
-- memory. It is written to match what is actually deployed, so applying it to
-- a fresh database yields the same structure that production has.
--
-- The lesson is worth keeping: a migration applied through an MCP tool is not
-- a migration that exists. The database remembers it; the repository does
-- not, and the repository is what a new environment is built from.
--
-- ── WHAT THIS TABLE IS FOR ───────────────────────────────────────────────────
--
-- Per-workspace connector STATE only. Which connectors exist, what they are
-- called and what each needs to connect is product definition and lives in
-- connector_catalog.dart — adding a connector is a deploy, not an INSERT, and
-- a workspace can never hold a row for a connector the server does not
-- understand.
--
-- ── THREE STORES, NOT ONE ────────────────────────────────────────────────────
--
-- This table is the "everything else" store. Two connector families keep
-- their own tables because both predate this layer and both carry genuine
-- domain behaviour that a generic key/value row cannot express:
--
--   channels                       WhatsApp, Telegram. Message routing,
--                                  webhook registration, bot registries that
--                                  bootstrap from these rows at startup.
--   payment_gateway_credentials    Paystack, Flutterwave, Stripe. Charge-time
--                                  behaviour, webhook secrets, probe-before-
--                                  persist on connect.
--   workspace_connectors           Everything else.
--
-- ConnectorService merges all three into the single list the design's
-- marketplace draws. See connector_catalog.dart's header for how the four
-- visible states (connected / available / soon / error) come out of that
-- merge.
--
-- ── STATUS IS STORED STATE, NOT THE DESIGN'S FOUR STATES ─────────────────────
--
-- The CHECK below allows connected / error / disconnected. Those are the
-- states a ROW can be in. The design's `available` and `soon` are computed
-- and deliberately unstorable here:
--
--   available   no row exists for this workspace + connector
--   soon        the capability is not released to this workspace
--
-- `disconnected` is a real stored state distinct from having no row: an owner
-- who disconnects Dropbox but whose credentials we still hold pending cleanup
-- is not the same as one who never connected it.
--
-- ── encrypted_config ─────────────────────────────────────────────────────────
--
-- Ciphertext ONLY, produced by ChannelCredentialEncryptionService (AES-256-
-- GCM, see lib/src/services/security/channel_credential_encryption_service
-- .dart). Nothing writes to this column yet — the first writer will be the
-- Google OAuth work, which is the first connector family to use this store.
--
-- Do not write plaintext here. The column name is a promise, and a column
-- named encrypted_config holding a readable token is worse than one named
-- config, because the next reader will trust the name.
--
-- ── RLS ──────────────────────────────────────────────────────────────────────
--
-- Enabled with no policies, matching channels, payment_gateway_credentials,
-- feature_flags and knowledge_documents. That is deny-all to PostgREST; the
-- server reaches this table over Serverpod's direct postgres connection as
-- the table owner, which is not subject to RLS. Verified as the existing
-- pattern across all five tables, not assumed.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists workspace_connectors (
    id             bigserial primary key,
    workspace_id   bigint      not null references workspaces (id) on delete cascade,

    -- Matches ConnectorDefinition.key in connector_catalog.dart. Never
    -- rename a key once shipped: it orphans every existing row silently,
    -- because an unknown key is reported, not failed on.
    connector_key  text        not null,

    status         text        not null default 'connected'
                   check (status in ('connected', 'error', 'disconnected')),

    -- Ciphertext only. See the header.
    encrypted_config text,

    -- Safe-to-show identifier for the connected account — a masked key tail,
    -- a sheet name, an account email. Never a secret: this is read straight
    -- onto the connector card.
    display_detail text,

    last_synced_at timestamptz,
    last_error     text,

    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now()
);

-- One row per connector per workspace. Connecting twice is a rotation, not a
-- second connection — the endpoint upserts on this constraint.
create unique index if not exists workspace_connector_unique_idx
    on workspace_connectors (workspace_id, connector_key);

-- The marketplace's own query: every connector for one workspace, in one
-- read, drawn alongside the catalog.
create index if not exists workspace_connector_workspace_idx
    on workspace_connectors (workspace_id);

alter table workspace_connectors enable row level security;
