-- ============================================================================
-- Migration 004 — Hard reset of waitlist_signups RLS (002/003 didn't fix it)
-- ============================================================================
-- If you're still seeing 42501 "new row violates row-level security policy"
-- after running 003, the cause is one of a few things 003 didn't cover:
--
--   1. A DIFFERENT, conflicting policy already exists on the table (e.g.
--      one accidentally created "restrictive" instead of the Postgres
--      default "permissive", or one scoped to the wrong command) — 003
--      only touched the one policy by name, not every policy on the table.
--   2. The table was created by hand (Table Editor UI, or a one-off SQL
--      Editor statement outside these migration files) and never actually
--      picked up Supabase's usual default grants — the RLS *policy* only
--      decides which rows a role can touch; the role also needs the
--      underlying SQL-level GRANT to attempt the operation at all.
--   3. You're pointed at a different Supabase project/branch than you
--      think — this file's fix is a no-op if run against the wrong
--      database, so this is worth double-checking directly (see step 0).
--
-- STEP 0 — CONFIRM YOU'RE ON THE RIGHT PROJECT FIRST:
--   Run this and make sure the URL matches the SUPABASE_URL you're
--   building kola_landing with:
--     select current_database(), inet_server_addr();
--   (Or simpler: just check the project ref in your browser's URL bar
--   while the SQL Editor is open.)
--
-- WHAT THIS MIGRATION DOES: drops every existing policy on the table
-- (not just one by name), recreates exactly the one policy we want, and
-- explicitly grants INSERT to anon at the SQL level too — belt-and-
-- suspenders against cause #2 above. Safe to run any number of times.
-- ============================================================================

-- ── Diagnostic — run this block FIRST and read the output before applying
--    the fix below, so you know which cause you actually hit. ───────────────
select relrowsecurity, relforcerowsecurity
  from pg_class
  where relname = 'waitlist_signups';

select schemaname, policyname, cmd, permissive, roles, with_check
  from pg_policies
  where tablename = 'waitlist_signups';

-- ── The fix ──────────────────────────────────────────────────────────────────

-- Drop EVERY policy currently on the table, whatever it's named — this is
-- the part 003 didn't do (it only dropped-and-recreated one specific name).
do $$
declare
  pol record;
begin
  for pol in
    select policyname from pg_policies where tablename = 'waitlist_signups'
  loop
    execute format('drop policy %I on waitlist_signups', pol.policyname);
  end loop;
end $$;

create policy "anon can insert waitlist signups"
  on waitlist_signups for insert
  to anon
  with check (true);

alter table waitlist_signups enable row level security;

-- Explicit SQL-level grants — harmless if these were already in place
-- (Supabase's Table Editor UI adds them automatically; a table created
-- via the SQL Editor directly does NOT get them automatically, which is
-- exactly how this table was created here).
grant usage on schema public to anon;
grant insert on waitlist_signups to anon;

-- ── Confirm — should show exactly one row, cmd = 'INSERT', roles = {anon} ──
select schemaname, policyname, cmd, permissive, roles, with_check
  from pg_policies
  where tablename = 'waitlist_signups';
