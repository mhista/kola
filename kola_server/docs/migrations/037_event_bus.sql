-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 037 — event bus: Gate 2)
--
-- Apply AFTER 036.
--
-- Backs docs/Kolaa_Connections_Backbone_Direction_v5.pdf PART V, "The
-- event bus": "Every ingestion, every webhook, every action becomes a
-- timestamped event against a graph entity... Events are stored
-- permanently and are replayable." Confirmed MISSING before this
-- migration by reading every migration through 036 and grepping the
-- whole `lib/src` tree for an events table, an EventBus class, or
-- anything resembling one — nothing existed. PART II's own gap table
-- says the same thing: "Event bus — MISSING — Blocks four designed
-- Overview sections and all cross-source correlation."
--
-- ── SCOPE: WHAT GATE 2 ACTUALLY BUILDS ────────────────────────────────────────
--
-- Gate 2's bar (PART VIII): "Event bus ingests, deduplicates by
-- fingerprint, replays. Outbound webhook delivery worker actually
-- fires." Not the full business graph (Gate 3) — this table has no
-- entity-linking columns yet, deliberately. It is the permanent,
-- replayable, deduplicated LOG that Gate 3's graph will read from and
-- correlate against, built first because the graph has nothing to
-- correlate without it.
--
-- ── FOUR EVENT TYPES, MATCHING THE EXISTING PUBLIC-API SURFACE ───────────────
--
-- platform_endpoint.dart already declares the design's EVENT_TYPES as a
-- Dart constant (`PlatformEndpoint.eventTypes`) for webhook_endpoints.events
-- to subscribe against — that constant predates this migration and is
-- updated alongside it (bot_published -> agent_published, plus
-- agent_drafted/agent_paused for the same lifecycle's other two phases,
-- product-facing "bot" -> "agent" rename; see event.spy.yaml's header
-- for why this is a NAMING change only — the underlying `bots` table,
-- `Bot` class and `bot_id` foreign keys are untouched, matching this
-- project's own kola-vs-kolaa precedent for internal identifiers).
--
-- ── FINGERPRINT DEDUPLICATION ─────────────────────────────────────────────────
--
-- Reuses the exact discipline migration 034's workspace_findings already
-- proved out: a stable fingerprint of `kind:subject`, unique per
-- workspace. Ingesting the same underlying occurrence twice (a retried
-- webhook, an at-least-once delivery from some upstream system) must
-- converge to one row, not accumulate duplicates — PART VIII's own
-- testing requirement ("ingest the same payload twice and assert one
-- entity, not two") applied to the event log itself, not just to
-- messages (migration 036 already did that for the message-level case).
--
-- ── WHY payload_json AND NOT SEPARATE COLUMNS PER EVENT TYPE ──────────────────
--
-- Four event types today, an open-ended list of subsystems that will
-- emit more (Gate 3's graph, Gate 8's outbound sends) — a fixed column
-- set would mean a migration per new event shape. jsonb keeps this
-- table's schema stable while what's inside varies; EventBus's own Dart
-- side is what actually knows each event type's shape, same division of
-- responsibility connector_catalog.dart already draws between "the
-- server enforces structure" and "the database stores the result."
--
-- ── RLS ──────────────────────────────────────────────────────────────────────
-- Enabled, no policies — deny-all to PostgREST, matching every table in
-- this project since migration 001. kola_server reaches Supabase over
-- the direct postgres connection as table owner, which RLS does not
-- apply to.

create table if not exists events (
    id             bigserial   primary key,
    workspace_id   bigint      not null references workspaces (id) on delete cascade,

    -- 'new_conversation' | 'errand_executed' | 'agent_published' |
    -- 'agent_drafted' | 'agent_paused' | 'payment_confirmed' — matches
    -- PlatformEndpoint.eventTypes.
    event_type     text        not null,

    -- kind:subject, e.g. 'errand_executed:412' or 'agent_published:7'.
    -- See header — this is what makes emit() idempotent.
    fingerprint    text        not null,

    -- The event's own data — shape owned by whichever Dart call site
    -- built it (EventBus.emit's callers), not by this schema.
    payload        jsonb       not null default '{}'::jsonb,

    -- When the underlying thing actually happened, vs ingested_at (when
    -- this row was written) — usually the same instant for a
    -- synchronously-emitted event, kept distinct because [replay] may
    -- one day re-ingest something after the fact, and PART V explicitly
    -- separates "timestamped" from "stored" for exactly this reason.
    occurred_at    timestamptz not null default now(),
    ingested_at    timestamptz not null default now()
);

-- The idempotency guarantee. One event per (workspace, fingerprint),
-- ever — Postgres's ON CONFLICT DO NOTHING (see event_repository.dart's
-- emit()) is what turns a duplicate emission into a silent no-op instead
-- of a second row.
create unique index if not exists event_workspace_fingerprint_idx
    on events (workspace_id, fingerprint);

-- The two read patterns this table exists to serve: "everything for
-- this workspace, in order" (the Timeline, Gate 3's correlation
-- queries) and "everything of this type since some point" (replay,
-- and a future webhook re-delivery sweep).
create index if not exists event_workspace_occurred_idx
    on events (workspace_id, occurred_at desc);
create index if not exists event_workspace_type_occurred_idx
    on events (workspace_id, event_type, occurred_at desc);

alter table events enable row level security;
-- ─────────────────────────────────────────────────────────────────────────────
