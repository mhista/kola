-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 012 — Phase 8b / task #132: birthday/
-- anniversary campaigns)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers customer_profile.spy.yaml — see its header for the full
-- rationale (in particular: why this is a separate table from
-- Conversation, why only month+day ever matter for matching, and why
-- WhatsApp isn't sent to yet). This file is the schema itself, not the
-- reasoning trail.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists customer_profiles (
  id                            bigserial primary key,
  workspace_id                  bigint not null references workspaces(id) on delete cascade,
  conversation_id               bigint not null references conversations(id) on delete cascade,
  birthday                      date,
  anniversary                   date,
  last_birthday_greeting_year   int,
  last_anniversary_greeting_year int,
  created_at                    timestamptz not null default now(),
  updated_at                    timestamptz not null default now()
);

create index if not exists customer_profile_workspace_idx on customer_profiles (workspace_id);
create unique index if not exists customer_profile_conversation_idx
  on customer_profiles (conversation_id);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger customer_profiles_updated_at
  before update on customer_profiles for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5). RLS enabled
-- with zero policies blocks the anon key from touching any of this
-- outright.
alter table customer_profiles enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
