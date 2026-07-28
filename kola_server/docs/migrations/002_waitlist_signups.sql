-- ============================================================================
-- Migration 002 — waitlist_signups table + anon-insert RLS (Phase 1e)
-- ============================================================================
-- The kola_landing page calls Supabase's REST API (PostgREST) directly with
-- the **anon** key to record a signup — no server round-trip (see
-- kola_landing/lib/services/waitlist_api_service.dart's header comment for
-- why). Without RLS this table would be fully open to any request bearing
-- that key, in both directions. This migration grants exactly one
-- permission — INSERT — and nothing else:
--
--   • anon can INSERT a new signup (the landing page's three forms)
--   • anon CANNOT SELECT — nobody can read who else is on the list
--   • anon CANNOT UPDATE/DELETE existing rows
--
-- The **service_role** key used by kola_server's WaitlistEndpoint (for any
-- future internal/admin caller) bypasses RLS automatically — no changes
-- needed there.
--
-- Apply in Supabase dashboard → SQL Editor, or via the CLI:
--   supabase db push --include-all
-- ============================================================================

-- ── waitlist_signups ─────────────────────────────────────────────────────────
-- unique(email) is what makes upsert-by-email behave correctly — a repeat
-- signup from the same address updates the row instead of erroring, both in
-- WaitlistSignupRepository.upsertByEmail and in the landing page's direct
-- PostgREST call (on_conflict=email).
create table if not exists waitlist_signups (
  id            bigserial primary key,
  name          text,
  email         text not null,
  phone         text,
  business_type text,
  source        text not null
                  check (source in ('hero', 'waitlist_section', 'footer')),
  created_at    timestamptz not null default now(),
  unique (email)
);

create unique index if not exists waitlist_signup_email_idx on waitlist_signups (email);

-- ── RLS for waitlist_signups ─────────────────────────────────────────────────
alter table waitlist_signups enable row level security;

-- Landing page inserts new signups (anon key)
-- Postgres has no `create policy if not exists`, so drop-then-create makes
-- this script safe to re-run (e.g. if a later statement in this same batch
-- ever fails and you re-paste the whole file).
drop policy if exists "anon can insert waitlist signups" on waitlist_signups;
create policy "anon can insert waitlist signups"
  on waitlist_signups for insert
  to anon
  with check (true);

-- Deliberately no SELECT/UPDATE/DELETE policy for anon — see header comment.
