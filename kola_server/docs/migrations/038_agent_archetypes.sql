-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 038 — agent archetypes)
--
-- Apply AFTER 037.
--
-- Phase A of the architecture correction: connecting WhatsApp or Telegram
-- does not make something an agent — a channel is a communication surface
-- an agent uses, not the agent itself. What defines an agent is its ROLE.
-- `bots.archetype` already exists (migration 001) but only ever allowed
-- three values (customerCare, catalog, custom), none of which name a real
-- role like payment collection or ticket routing. This migration widens
-- the CHECK constraint to match the new registry in
-- kola_server/lib/src/services/agents/agent_archetypes.dart — see that
-- file's header for the full reasoning and why the two lists (this SQL
-- constraint and that Dart file) must be kept in lockstep by hand.
--
-- ── WHY THE CONSTRAINT NAME IS GUESSED, THEN VERIFIED, NOT ASSUMED BLIND ──────
--
-- The original inline `check (archetype in (...))` in migration 001 was
-- declared with no explicit name, so Postgres auto-generated one following
-- its own convention for a single-column check: `<table>_<column>_check`.
-- For `bots.archetype` that is `bots_archetype_check`. This is Postgres's
-- documented, stable naming rule for exactly this shape of constraint (one
-- column, one CHECK, no name given) — not a guess about undocumented
-- behaviour. `DROP CONSTRAINT IF EXISTS` below means a wrong guess fails
-- silently into a no-op rather than an error, and the `DO` block after it
-- re-verifies the new constraint actually landed, so a naming mismatch is
-- caught at migration time instead of surfacing later as "why did this bad
-- archetype value get accepted."
--
-- ── THIS IS ADDITIVE, NOT DESTRUCTIVE ──────────────────────────────────────────
--
-- Every existing archetype value (customerCare, catalog, custom) is still
-- valid. No existing `bots` row changes. This only ADDS six new accepted
-- values; nothing is removed from the allowed set.

begin;

alter table bots drop constraint if exists bots_archetype_check;

alter table bots add constraint bots_archetype_check
  check (archetype in (
    'customerCare', 'catalog', 'custom',
    'payment', 'support', 'finance', 'inventory', 'marketing', 'sales'
  ));

-- Verify the constraint actually exists under the name this migration
-- (and any future one touching this column) assumes, rather than trusting
-- the ADD above silently succeeded under a different name.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'bots_archetype_check'
      and conrelid = 'bots'::regclass
  ) then
    raise exception 'bots_archetype_check was not created as expected — check constraint naming before applying this migration further.';
  end if;
end $$;

commit;
