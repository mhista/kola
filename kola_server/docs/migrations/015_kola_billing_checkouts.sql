-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 015 — task #148: Kola's OWN SaaS
-- subscription checkout, distinct from payment_transactions)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers kola_billing_checkout.spy.yaml — see its header for why this is
-- a SEPARATE table from payment_transactions, not a reuse of it. This
-- file is the schema itself, not the reasoning trail.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists kola_billing_checkouts (
  id                     bigserial primary key,
  workspace_id           bigint not null references workspaces(id) on delete cascade,
  gateway                text not null check (gateway in ('paystack', 'flutterwave')),
  reference              text not null,
  amount_kobo            int not null,
  plan                   text not null,
  status                 text not null default 'pending'
                           check (status in ('pending', 'completed', 'failed')),
  checkout_url           text,
  gateway_transaction_id text,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  paid_at                timestamptz
);

create index if not exists kola_billing_checkout_workspace_idx on kola_billing_checkouts (workspace_id);
create unique index if not exists kola_billing_checkout_reference_idx on kola_billing_checkouts (reference);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
create or replace trigger kola_billing_checkouts_updated_at
  before update on kola_billing_checkouts for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5).
alter table kola_billing_checkouts enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
