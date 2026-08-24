-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 044 — Gate 5's second half: mapping a
-- dbCredential Errand's query results into the business graph)
--
-- Apply AFTER 043.
--
-- Backs docs/Kolaa_Connections_Backbone_Direction_v5.pdf PART VIII, Gate 5:
-- "Guided REST builder + read-only Postgres with schema discovery.
-- Someone else's system, mapped to entities, queried." Migrations 036
-- (connector contract) and 007 (webhook/dbCredential Errands) built the
-- "queried" half; this is the "mapped to entities" half — deliberately
-- narrow, see below.
--
-- ── WHY ONLY CUSTOMER, NOT A GENERIC "ORDER" ─────────────────────────────────
--
-- PART V lists a full entity roster (Customer, Contact, Company, Product,
-- Order, Invoice, Payment, ...). This codebase's actual graph (migration
-- 039, Gate 3) only ever built Customer + identity signals, plus the
-- already-domain-specific Sale (migration 035, till-only) and
-- PaymentTransaction (migration 009, gateway-checkout-only — see its own
-- header on why holdStatus/confirmationMethod/gatewayTransactionId make
-- it a poor fit for an arbitrary business's own query result). Forcing
-- an arbitrary Level-3 row into either of those would misuse a model
-- built for a narrower, different purpose — the exact "duplicate/misuse
-- an existing model" mistake this project's own rules warn against.
-- Customer is the one entity generic enough to actually fit a row from
-- someone else's schema, and it already has a real, deterministic,
-- owner-reviewed resolver (CustomerIdentityResolver) built and proven in
-- production against Paystack/Flutterwave/Bumpa. This migration wires
-- Level 3 into THAT, and nothing else, for now.
--
-- ── WHY A NEW TABLE, NOT A COLUMN ON `errands` ────────────────────────────────
--
-- `errands`/`errand_credentials` already exist as generated Serverpod
-- models (errand.spy.yaml / errand_credential.spy.yaml); adding a field
-- to either means regenerating kola_client's protocol classes via
-- `serverpod generate`, which the environment that wrote this migration
-- could not run (no Dart toolchain available — see docs/GATE_5_STATUS.md).
-- A new table + a repository that talks to Supabase directly (like every
-- repository in this project already does) needs no new generated model
-- at all: ErrandEndpoint.getEntityMapping/setEntityMapping move the
-- mapping across the wire as a JSON string, the same "flexible shape
-- lives in a text column, parsed one layer up" pattern
-- errand.spy.yaml's own inputSchemaJson already uses. Safe to fold into
-- a real column on `errands` later, once `serverpod generate` can
-- actually be run again.
--
-- ── mapping_json SHAPE ────────────────────────────────────────────────────────
-- {"enabled": true, "phoneColumn": "phone", "emailColumn": "email",
--  "nameColumn": "customer_name"}
-- At least one of phoneColumn/emailColumn is required when enabled —
-- validated in ErrandEndpoint.setEntityMapping, not here (same division
-- of labour as every other *Json column in this project).

create table if not exists errand_entity_mappings (
    id           bigserial   primary key,
    errand_id    bigint      not null references errands (id) on delete cascade,
    mapping_json text        not null default '{}',
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

-- One mapping per Errand — a second save replaces it (see
-- ErrandEntityMappingRepository.upsert), never accumulates a second row.
create unique index if not exists errand_entity_mapping_errand_idx
    on errand_entity_mappings (errand_id);

create or replace trigger errand_entity_mappings_updated_at
    before update on errand_entity_mappings for each row execute function update_updated_at();

-- ── RLS ──────────────────────────────────────────────────────────────────────
-- Enabled, no policies — deny-all to PostgREST, matching every table in
-- this project since migration 001. The repository layer (Supabase
-- service-role client) IS the isolation boundary, same as everywhere
-- else — see PART IX's non-negotiable rule.
alter table errand_entity_mappings enable row level security;
-- ─────────────────────────────────────────────────────────────────────────────
