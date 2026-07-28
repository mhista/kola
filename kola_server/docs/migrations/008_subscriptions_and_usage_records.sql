-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 008 — Phase 5a: Subscription +
-- UsageRecord)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers subscription.spy.yaml, usage_record.spy.yaml — see each for the
-- full rationale behind its fields; this file is the schema itself, not
-- the reasoning trail.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── SUBSCRIPTIONS ────────────────────────────────────────────────────────────
create table if not exists subscriptions (
  id                        bigserial primary key,
  workspace_id              bigint not null references workspaces(id) on delete cascade,
  plan                      text not null,
  gateway_provider          text check (gateway_provider in ('paystack', 'flutterwave')),
  gateway_customer_id       text,
  gateway_subscription_id   text,
  current_period_start      timestamptz,
  current_period_end        timestamptz,
  status                    text not null default 'none'
                               check (status in ('none', 'active', 'pastDue', 'canceled')),
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

create unique index if not exists subscription_workspace_idx on subscriptions (workspace_id);

-- ── USAGE RECORDS ────────────────────────────────────────────────────────────
-- One row per (workspace, usage_class, day) — a daily rollup, not a raw
-- event log. See usage_record.spy.yaml's header for why.
create table if not exists usage_records (
  id             bigserial primary key,
  workspace_id   bigint not null references workspaces(id) on delete cascade,
  usage_class    text not null,
  period_date    date not null,
  quantity       double precision not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create unique index if not exists usage_record_workspace_class_date_idx
  on usage_records (workspace_id, usage_class, period_date);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger subscriptions_updated_at
  before update on subscriptions for each row execute function update_updated_at();
create or replace trigger usage_records_updated_at
  before update on usage_records for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5). RLS enabled
-- with zero policies blocks the anon key from touching any of this
-- outright.
alter table subscriptions   enable row level security;
alter table usage_records   enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
