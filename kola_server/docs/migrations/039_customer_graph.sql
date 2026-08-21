-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 039 — the customer graph: Gate 3)
--
-- Apply AFTER 038.
--
-- Backs docs/Kolaa_Connections_Backbone_Direction_v5.pdf PART VIII, Gate 3:
-- "Entities exist with provenance. Deterministic identity resolution.
-- Merges are owner-confirmed proposals." And PART V, "The business
-- graph" / "Identity resolution is the hard part" — deterministic
-- matching only (normalized phone, then email, then exact name plus a
-- corroborating field — no fuzzy matching in v1), merges are proposals
-- an owner confirms, never merge on name alone, merges must be
-- reversible.
--
-- ── WHY THIS IS A NEW `customers` TABLE, NOT customer_profiles ───────────────
--
-- customer_profiles (migration 012) looked like the obvious place to
-- extend, and was rejected after actually reading it: its own header
-- says it is "1:1 with a Conversation... holds the one extra fact
-- Conversation itself has no reason to model" (birthday/anniversary),
-- and conversation_id is NOT NULL + unique. A customer identified
-- through a Paystack payment or an in-person till sale has no
-- conversation at all — that table cannot represent them without
-- rewriting its meaning out from under the birthday/anniversary feature
-- that already ships on it. `customers` is the actual identity anchor;
-- customer_profiles is untouched by this migration and keeps its narrow
-- job. A future join (conversations.customer_id, once set below) is how
-- the two connect — no new column needed on customer_profiles itself.
--
-- ── SCOPE: WHAT GATE 3 ACTUALLY BUILDS ────────────────────────────────────────
--
-- customers                  the entity itself, with provenance
-- customer_identity_signals  every phone/email/platform-id ever seen
--                             for a customer — what the deterministic
--                             matcher checks against
-- customer_merge_proposals   the owner-confirmation queue — NEVER an
--                             auto-merge
-- conversations.customer_id  NEW — with a same-migration backfill
-- payment_transactions.customer_id  NEW — matched against existing
--                             signals only, not fabricated (see below)
-- sales.customer_id          NEW — no backfill; the till (Gate 3b) is
--                             what starts populating it
--
-- ── WHY NAME IS STORED BUT NEVER MATCHED ON, YET ─────────────────────────────
--
-- The PDF allows "exact name plus one corroborating field" as a third
-- matching tier. This codebase has no corroborating field to pair a
-- name with today (no address, no city, nothing) — inventing one to
-- satisfy the letter of that rule would be exactly the kind of
-- overclaiming Gate 3's own "deterministic, not fuzzy" bar exists to
-- prevent. `name` is stored as a signal (useful for display, and ready
-- for the day a real corroborating field exists) but
-- CustomerIdentityResolver (Dart side) only ever matches on phone or
-- email. Never on name alone — which the PDF forbids outright anyway.
--
-- ── WHY TELEGRAM CANNOT USE A 'phone' SIGNAL ──────────────────────────────────
--
-- WhatsApp Business conversations' external_user_id IS the customer's
-- phone number (see channels/conversations, migration 006) — a real,
-- portable identity fact. Telegram's external_user_id is an opaque
-- numeric Telegram account id; the Bot API does not hand a bot the
-- user's phone number unless the user explicitly shares a contact card,
-- which this codebase does not currently capture. Treating a Telegram
-- id as a phone would silently and wrongly claim portability it doesn't
-- have. It gets its own signal_type, 'platform_user' — normalized as
-- 'telegram:<id>' — which still makes repeat messages from the same
-- Telegram user resolve to the same customer (idempotent within that
-- platform) without pretending it identifies them anywhere else.
--
-- ── WHY MERGES REPOINT NOTHING (merged_into_id, not a rewrite) ────────────────
--
-- PART V: "Merges must be reversible. Keep source records intact and
-- make identity a layer above them, never a destructive rewrite." The
-- tempting implementation — reassign every conversations/payment_
-- transactions/sales row's customer_id from the loser to the survivor —
-- is exactly the destructive rewrite that line forbids, and it cannot
-- be cleanly undone once done. Instead: confirming a merge sets
-- customers.merged_into_id on the loser and touches nothing else. Every
-- read that resolves "the customer for this record" follows
-- merged_into_id to its root (CustomerIdentityResolver.canonicalId,
-- Dart side). Un-merging is one UPDATE clearing merged_into_id back to
-- null. No foreign key anywhere is ever rewritten.
--
-- ── BACKFILL POLICY ────────────────────────────────────────────────────────
--
-- conversations: backfilled below, in this migration. One source
-- (existing conversations), no conflict risk — a customer plus one
-- signal per conversation, keyed by the platform's own already-unique
-- (channel_id, external_user_id).
--
-- payment_transactions: NOT fabricated here. A payment is matched
-- against a signal that already exists (from the conversations
-- backfill above, or a real one going forward) and linked if found;
-- left null otherwise. Writing a conflict-aware identity resolver
-- correctly needs the merge-proposal machinery this migration only
-- just created — doing that logic by hand in SQL, with no way to raise
-- a proposal for a genuine conflict, risks silently mis-linking two
-- different people. That belongs in CustomerIdentityResolver (Dart),
-- run once as a reconciliation pass after this migration, not in DDL.
--
-- sales: no backfill. The till (Gate 3b) is what starts writing these.

-- ── CUSTOMERS ──────────────────────────────────────────────────────────────────
create table if not exists customers (
    id               bigserial   primary key,
    workspace_id     bigint      not null references workspaces (id) on delete cascade,

    -- Best-known display name — the latest 'name' signal seen, kept
    -- denormalized here so a list view never has to join
    -- customer_identity_signals just to show a label. Not authoritative;
    -- customer_identity_signals is.
    display_name     text,

    -- Provenance of the entity itself — PART V: "every record carries
    -- original source, source ID... and provenance."
    -- 'whatsapp' | 'telegram' | 'paystack' | 'flutterwave' | 'till' | 'manual'
    first_seen_source text       not null,
    first_seen_at     timestamptz not null default now(),

    -- See header. Null on every customer that has never been proposed
    -- as a duplicate of another. Self-referencing rather than a
    -- separate "canonical customer" table — one column answers "is this
    -- row still the one to use."
    merged_into_id   bigint      references customers (id) on delete set null,

    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now()
);

create index if not exists customers_workspace_idx on customers (workspace_id);
create index if not exists customers_merged_into_idx on customers (merged_into_id)
    where merged_into_id is not null;

create or replace trigger customers_updated_at
    before update on customers for each row execute function update_updated_at();

-- ── CUSTOMER IDENTITY SIGNALS ────────────────────────────────────────────────
--
-- Every phone/email/name/platform-id ever seen for a customer. The
-- unique index is the matcher itself: given an incoming normalized
-- value, a lookup either finds the one customer who already owns it, or
-- finds nothing and a new customer gets created. Two DIFFERENT existing
-- customers can never claim the same (workspace, signal_type,
-- normalized_value) — that state is exactly what a merge proposal
-- exists to resolve, not something this index should ever allow to
-- occur silently.
create table if not exists customer_identity_signals (
    id               bigserial   primary key,
    workspace_id     bigint      not null references workspaces (id) on delete cascade,
    customer_id      bigint      not null references customers (id) on delete cascade,

    -- 'phone' | 'email' | 'name' | 'platform_user' — see header on why
    -- 'name' is stored but never matched on yet, and why Telegram gets
    -- 'platform_user' instead of 'phone'.
    signal_type      text        not null
                     check (signal_type in ('phone', 'email', 'name', 'platform_user')),

    -- Normalized so the same real-world value always compares equal:
    -- phone -> digits only, E.164-ish (no '+', no spaces); email ->
    -- lowercased, trimmed; platform_user -> '<platform>:<external_id>';
    -- name -> lowercased, trimmed (stored for display/future
    -- corroboration, per header — not matched on today).
    normalized_value text        not null,

    -- Same provenance vocabulary as customers.first_seen_source.
    source           text        not null,
    -- Loose pointer to where this signal came from (a conversation id,
    -- a payment_transactions.reference, a sales.reference) — text, not
    -- a foreign key, because it can point into any of three different
    -- tables depending on signal_type/source, matching connector_sync_
    -- log's own "identified by its own row, not a catalog FK" precedent
    -- from migration 036.
    source_ref       text,

    first_seen_at    timestamptz not null default now()
);

create unique index if not exists customer_identity_signal_lookup_idx
    on customer_identity_signals (workspace_id, signal_type, normalized_value);
create index if not exists customer_identity_signal_customer_idx
    on customer_identity_signals (customer_id);

-- ── CUSTOMER MERGE PROPOSALS ──────────────────────────────────────────────────
--
-- "these two look like the same customer" — raised only when a single
-- incoming event's signals resolve to two DIFFERENT existing customers
-- (e.g. a payment's phone matches Customer A but its email matches
-- Customer B) — never from comparing customers against each other for
-- similarity, which would be fuzzy matching and is explicitly out of
-- scope. See CustomerIdentityResolver's header for the exact trigger.
create table if not exists customer_merge_proposals (
    id               bigserial   primary key,
    workspace_id     bigint      not null references workspaces (id) on delete cascade,

    -- Canonical ordering (a < b) enforced below so the same pair is
    -- never proposed twice regardless of which one the resolver noticed
    -- first.
    customer_a_id    bigint      not null references customers (id) on delete cascade,
    customer_b_id    bigint      not null references customers (id) on delete cascade,
    check (customer_a_id < customer_b_id),

    -- Owner-facing explanation of what triggered this, e.g. 'phone
    -- +2348012345678 matches customer A; email chidinma@gmail.com on
    -- the same incoming payment matches customer B'.
    matched_on       text        not null,

    -- jsonEncode'd — the actual signal values compared, for the
    -- evidence-disclosure UI (design brief §9's "Evidence disclosure"
    -- component, reused here rather than invented fresh).
    evidence_json    text        not null default '{}',

    status           text        not null default 'pending'
                     check (status in ('pending', 'confirmed', 'rejected')),

    resolved_by_email text,
    resolved_at       timestamptz,

    created_at       timestamptz not null default now()
);

-- One live proposal per pair at a time — a second conflicting event
-- while one is still pending should not spam a duplicate card.
create unique index if not exists customer_merge_proposal_pending_pair_idx
    on customer_merge_proposals (workspace_id, customer_a_id, customer_b_id)
    where status = 'pending';

create index if not exists customer_merge_proposal_workspace_status_idx
    on customer_merge_proposals (workspace_id, status, created_at desc);

-- ── LINK EXISTING ENTITIES TO THE GRAPH ───────────────────────────────────────

alter table conversations
    add column if not exists customer_id bigint references customers (id) on delete set null;

alter table payment_transactions
    add column if not exists customer_id bigint references customers (id) on delete set null;

alter table sales
    add column if not exists customer_id bigint references customers (id) on delete set null;

create index if not exists conversations_customer_idx on conversations (customer_id);
create index if not exists payment_transactions_customer_idx on payment_transactions (customer_id);
create index if not exists sales_customer_idx on sales (customer_id);

-- ── BACKFILL: EVERY EXISTING CONVERSATION GETS A CUSTOMER ────────────────────
--
-- One customer + one identity signal per conversation not already
-- linked. Safe as a single pass: (channel_id, external_user_id) is
-- already unique per migration 006, so this cannot create two
-- customers for what conversations itself already treats as one
-- correspondent. WhatsApp's external_user_id is a real phone number
-- (signal_type 'phone'); Telegram's is not (signal_type
-- 'platform_user') — see this file's header.
do $$
declare
    conv record;
    new_customer_id bigint;
    v_signal_type text;
    v_normalized text;
begin
    for conv in
        select id, workspace_id, channel_id, platform_type, external_user_id,
               display_name, created_at
        from conversations
        where customer_id is null
    loop
        if conv.platform_type = 'whatsapp' then
            v_signal_type := 'phone';
            v_normalized := regexp_replace(conv.external_user_id, '[^0-9]', '', 'g');
        else
            v_signal_type := 'platform_user';
            v_normalized := 'telegram:' || conv.external_user_id;
        end if;

        -- Reuse an existing customer if this exact signal already
        -- resolved to one (possible if two conversations somehow share
        -- a normalized value across channels); otherwise create.
        select customer_id into new_customer_id
        from customer_identity_signals
        where workspace_id = conv.workspace_id
          and signal_type = v_signal_type
          and normalized_value = v_normalized
        limit 1;

        if new_customer_id is null then
            insert into customers (workspace_id, display_name, first_seen_source, first_seen_at)
            values (conv.workspace_id, conv.display_name, conv.platform_type, conv.created_at)
            returning id into new_customer_id;

            insert into customer_identity_signals
                (workspace_id, customer_id, signal_type, normalized_value, source, source_ref, first_seen_at)
            values
                (conv.workspace_id, new_customer_id, v_signal_type, v_normalized,
                 conv.platform_type, conv.id::text, conv.created_at);
        end if;

        update conversations set customer_id = new_customer_id where id = conv.id;
    end loop;
end $$;

-- ── LIGHT BACKFILL: PAYMENTS MATCHED AGAINST SIGNALS THAT ALREADY EXIST ──────
--
-- Deliberately not creating new customers or signals here — see header.
-- A payment whose phone or email already matches a known customer gets
-- linked; everything else stays null for CustomerIdentityResolver to
-- pick up properly (with real conflict/merge-proposal handling) once
-- Gate 3's Dart side is live.
update payment_transactions pt
set customer_id = sig.customer_id
from customer_identity_signals sig
where pt.customer_id is null
  and sig.workspace_id = pt.workspace_id
  and (
    (pt.customer_phone is not null
     and sig.signal_type = 'phone'
     and sig.normalized_value = regexp_replace(pt.customer_phone, '[^0-9]', '', 'g'))
    or
    (sig.signal_type = 'email'
     and sig.normalized_value = lower(trim(pt.customer_email)))
  );

-- ── RLS ──────────────────────────────────────────────────────────────────────
-- Enabled, no policies — deny-all to PostgREST, matching every table in
-- this project since migration 001.
alter table customers enable row level security;
alter table customer_identity_signals enable row level security;
alter table customer_merge_proposals enable row level security;
-- ─────────────────────────────────────────────────────────────────────────────
