-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 062 — customer notes)
--
-- Apply AFTER 061.
--
-- Phase 14h named this gap directly: `Kola Customers.dc.html`'s detail panel
-- has a free-text Notes section ("Prefers deliveries after 5pm...") and
-- `customers_page.dart` deliberately left it unrendered because Customer had
-- no notes column anywhere and nothing let an owner write one. This is the
-- small, separate follow-up that closes it.
--
-- NULLABLE, NO DEFAULT NEEDED — most customers will never get a note; an
-- empty string default would make "no note" and "a note that says nothing"
-- indistinguishable in storage. null means "never written", '' is not a
-- state the dashboard will ever intentionally save (an empty save clears the
-- column back to null instead — see CustomerRepository.setNotes).
-- ─────────────────────────────────────────────────────────────────────────────

alter table customers
  add column if not exists notes text;

comment on column customers.notes is
  'Free-text owner annotation ("Prefers deliveries after 5pm..."). Manually '
  'written and edited by the workspace owner only — nothing in the codebase '
  'writes this automatically. Null means no note has ever been saved.';
