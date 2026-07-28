-- ============================================================================
-- Migration 003 — Re-apply the waitlist_signups anon-insert RLS policy
-- ============================================================================
-- WHY THIS FILE EXISTS:
--   Postgres error 42501 "new row violates row-level security policy for
--   table waitlist_signups" means: RLS is enabled on the table, but no
--   policy on it currently allows the request's role (anon) to insert.
--   That specific error message only ever comes from an RLS check failing
--   — a missing GRANT would instead say "permission denied for table
--   waitlist_signups", so the anon key itself is fine; it's specifically
--   the policy from migration 002 that isn't live on the table right now.
--
--   The most common real-world way this happens: the table already
--   existed (created once via the Supabase dashboard's Table Editor UI,
--   or 002 was run against a stale copy) before 002's `create policy`
--   ran, or 002 was only partially applied. `create table if not exists`
--   is idempotent and silently no-ops if the table's already there, but
--   `create policy` is NOT idempotent by itself — if it errored once
--   (e.g. "policy already exists" from an earlier partial run) the insert
--   policy can end up simply missing with no obvious trace.
--
-- WHAT THIS DOES:
--   Drops the policy by name first (safe no-op if it isn't there) and
--   recreates it identically to 002 — safe to run any number of times.
--
-- HOW TO CHECK WHAT'S CURRENTLY LIVE (run this first, in Supabase's SQL
-- Editor, before applying the fix below — it costs nothing and tells you
-- whether this is really the cause):
--
--   select relrowsecurity from pg_class where relname = 'waitlist_signups';
--   select policyname, cmd, roles, with_check
--     from pg_policies where tablename = 'waitlist_signups';
--
--   If the second query returns zero rows, this migration is the fix.
-- ============================================================================

drop policy if exists "anon can insert waitlist signups" on waitlist_signups;

create policy "anon can insert waitlist signups"
  on waitlist_signups for insert
  to anon
  with check (true);

-- Belt-and-suspenders: confirm RLS itself is actually on (it should already
-- be, from 002, but this is a no-op if it is).
alter table waitlist_signups enable row level security;
