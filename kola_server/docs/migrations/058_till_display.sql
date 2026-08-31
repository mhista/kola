-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 058 — Phase 11: the in-store customer
-- display, the second of the two remaining named customer-facing surfaces)
--
-- Apply AFTER 057.
--
-- Backs DESIGN_BRIEF_COMMERCE.md's "Two-way display" note: "a second
-- screen facing the customer showing items as they are scanned, the
-- running total, and then the receipt... Design it as a projection of
-- the till state, not a separate app — same data, customer-appropriate
-- framing, no staff controls, no cost or margin data ever visible."
--
-- ── ONE ROW PER WORKSPACE, UPSERTED IN PLACE, NOT AN EVENT LOG ───────────
--
-- This is live, ephemeral "what is on the till screen right now" state,
-- not history — nothing here is ever queried for "what did we sell last
-- Tuesday" (that is Sale/SaleLine, already built). One row per workspace
-- is deliberately as small a model as the feature needs: this codebase
-- has no multi-till/multi-register concept anywhere yet (till_page.dart
-- assumes one active till per workspace), so there is nothing to key a
-- second row on. Revisit if/when a business ever runs two tills at once.
--
-- ── WHY A REAL TABLE, NOT AN IN-MEMORY REGISTRY LIKE THE CHANNEL
--    BOT REGISTRIES ─────────────────────────────────────────────────────
--
-- TelegramBotRegistry/WhatsAppBotRegistry/etc. hold live state in memory
-- because they own a live external connection (a bot polling loop, a
-- webhook) that cannot be reconstructed from a database row alone. This
-- has no such connection — it is a value two independent HTTP callers
-- (the till's own tab, the customer display's tab, on the SAME or a
-- DIFFERENT device) need to agree on. A table Supabase already durably
-- stores and that survives a server restart is the simpler, more
-- correct choice here; an in-memory map would also break the moment two
-- server instances run behind a load balancer, since the till's push and
-- the display's poll could land on different processes.
--
-- ── customer_display_enabled ON workspaces, SEPARATE FROM
--    public_catalog_enabled (migration 057) ───────────────────────────────
--
-- Two different customer-facing surfaces, two different explicit
-- opt-ins — DESIGN_BRIEF_COMMERCE.md calls the display "owner-
-- configurable" on its own terms, independent of whether that same
-- business also publishes a catalog. Same "a business decides to turn
-- this on, it never happens by itself" reasoning as 057.

create table if not exists till_display_state (
    workspace_id  bigint primary key references workspaces(id) on delete cascade,
    items_json    jsonb not null default '[]'::jsonb,
    subtotal_minor bigint not null default 0,
    currency      text not null default 'NGN',
    -- 'idle' | 'shopping' | 'payment' | 'receipt' — mirrors till_page.dart's
    -- own _Screen enum (sell/payment/receipt) plus an 'idle' state for
    -- before the first item of a fresh sale is scanned, so the display
    -- has something honest to show between sales rather than showing a
    -- stale finished cart forever.
    status        text not null default 'idle',
    updated_at    timestamptz not null default now()
);

alter table workspaces
    add column if not exists customer_display_enabled boolean not null default false;

-- ─────────────────────────────────────────────────────────────────────────────
