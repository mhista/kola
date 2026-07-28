-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 009 — Phase 8a / task #127: Live
-- payment collection Errand)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers payment_gateway_credential.spy.yaml, payment_transaction.spy.yaml —
-- see each for the full rationale (in particular: why this is a BYO-
-- per-workspace credential model, not a shared Kola-wide account, and why
-- hold_status is bookkeeping only, not real fund custody). This file is
-- the schema itself, not the reasoning trail.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── PAYMENT GATEWAY CREDENTIALS ──────────────────────────────────────────────
create table if not exists payment_gateway_credentials (
  id                          bigserial primary key,
  workspace_id                bigint not null references workspaces(id) on delete cascade,
  gateway                     text not null check (gateway in ('paystack', 'flutterwave')),
  encrypted_secret_key        text not null,
  encrypted_webhook_secret    text,
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

create unique index if not exists payment_gateway_credential_workspace_gateway_idx
  on payment_gateway_credentials (workspace_id, gateway);

-- ── PAYMENT TRANSACTIONS ─────────────────────────────────────────────────────
create table if not exists payment_transactions (
  id                        bigserial primary key,
  workspace_id              bigint not null references workspaces(id) on delete cascade,
  gateway                   text not null check (gateway in ('paystack', 'flutterwave')),
  reference                 text not null,
  amount_kobo               bigint not null check (amount_kobo > 0),
  currency                  text not null default 'NGN',
  customer_email            text not null,
  customer_phone            text,
  status                    text not null default 'pending'
                               check (status in ('pending', 'completed', 'failed')),
  hold_status               text not null default 'notHeld'
                               check (hold_status in ('notHeld', 'held', 'released')),
  conversation_id           bigint references conversations(id) on delete set null,
  channel_id                bigint references channels(id) on delete set null,
  checkout_url              text,
  gateway_transaction_id    text,
  metadata_json             text,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  paid_at                   timestamptz
);

create unique index if not exists payment_transaction_reference_idx
  on payment_transactions (reference);
create index if not exists payment_transaction_workspace_idx
  on payment_transactions (workspace_id);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger payment_gateway_credentials_updated_at
  before update on payment_gateway_credentials for each row execute function update_updated_at();
create or replace trigger payment_transactions_updated_at
  before update on payment_transactions for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5). RLS enabled
-- with zero policies blocks the anon key from touching any of this
-- outright — doubly important here since these tables hold encrypted
-- payment-gateway secret keys.
alter table payment_gateway_credentials enable row level security;
alter table payment_transactions        enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
