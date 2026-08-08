-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 021 — workspace region)
--
-- Apply AFTER 020.
--
-- WHY: Kola's own Pro plan is now priced per region at rough
-- purchasing-power parity (see plan_pricing.dart) rather than one naira
-- figure. To charge the right amount, in the right currency, through the
-- right gateway, a workspace has to record which market it is in.
--
-- ── WHY IT DEFAULTS TO 'NG' AND NOT 'XX' ─────────────────────────────────────
-- Every workspace that exists today is Nigerian, and Nigeria is the only
-- price that is commercially settled. Defaulting to 'NG' means every
-- existing row keeps billing exactly as it does now — the migration
-- changes no one's price. Defaulting to the international tier would
-- silently re-price every current customer in USD, which is the kind of
-- thing that ends a customer relationship.
--
-- New workspaces set it explicitly at creation.
--
-- ── WHY IT IS NOT A CHECK CONSTRAINT ─────────────────────────────────────────
-- Unlike `gateway`, the set of valid regions is open-ended and grows
-- whenever a market is added — a constraint would mean a migration for
-- every new country. plan_pricing.dart resolves an unknown code to the
-- international tier rather than failing, so an unrecognised value is
-- safe here in a way an unrecognised gateway is not: worst case a
-- customer is billed the default price, not a charge that errors.
-- ─────────────────────────────────────────────────────────────────────────────

alter table workspaces
  add column if not exists region text not null default 'NG';

comment on column workspaces.region is
  'ISO-3166 alpha-2, or ''XX'' for the international default. Selects the '
  'Pro-plan price, currency and collecting gateway — see plan_pricing.dart. '
  'Unknown values resolve to the international tier rather than failing.';

create index if not exists workspace_region_idx on workspaces (region);
