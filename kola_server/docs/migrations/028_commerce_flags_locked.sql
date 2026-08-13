-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 028 — commerce flags back to locked)
--
-- Apply AFTER 027.
--
-- ── WHAT THIS CORRECTS ───────────────────────────────────────────────────────
--
-- Migration 019 seeded eight commerce capability keys as `released`, phase R1.
-- Its own comment explains the intent, and the intent was sound:
--
--   "Commerce is available but OFF BY DEFAULT PER WORKSPACE. Note the two
--    layers... These flags control whether commerce is available on the
--    platform. Whether a given business has switched it on is a workspace
--    setting, not a flag."
--
-- Two things were true when that was written and are still true now:
--
--   1. There is no second layer. No `workspaces.commerce_enabled` column
--      exists, and nothing reads one. So "off by default per workspace" is
--      not implemented anywhere — the platform flag is the ONLY gate, and it
--      was open.
--
--   2. There is no commerce. As of this migration the database has no
--      products table, no catalog, no sales, no stock, no orders. The server
--      has no commerce model, endpoint, repository or service. `released`
--      described the PLAN, not the state.
--
-- ── WHY IT ONLY BECAME VISIBLE NOW ───────────────────────────────────────────
--
-- The dashboard's FeatureGate was never loaded for a newly created workspace
-- — it stayed empty, so EVERY gated nav item was hidden and the wrongly-open
-- commerce flags had no observable effect. Fixing that bug turned the flags
-- into what they always claimed to be, and the claim was false:
--
--   • Sidebar → "Sales counter"  → /counter   — route not registered
--   • Sidebar → "Catalog"        → /catalog   — route not registered
--   • Mobile tab bar → "Sell"    → /counter   — route not registered
--   • Overview next-step hint "Add what you sell" → /catalog — same
--
-- and, inverted, it SUPPRESSED two honest placeholders that only render when
-- commerce is off — "Sales this week —, starts counting when the sales
-- counter arrives" and "Products —, available once you can add a catalog".
--
-- So the open flag simultaneously advertised four things that do not exist
-- and hid the two lines that told the truth about them.
--
-- ── WHY SQL AND NOT CODE ─────────────────────────────────────────────────────
--
-- Four call sites could each have been patched to ignore the flag. One of
-- them already was: knowledge_page.dart hardcodes `false` where it used to
-- read commerce.catalog, with a comment recording exactly this reasoning.
--
-- That is the wrong layer. Patching readers to distrust a flag defeats the
-- flag. RELEASE_PHASES.md §0 is explicit that the release state lives in the
-- database and that "unlocking is a database change, not a deployment" — so
-- the honest state of an unbuilt capability is `locked`, and every reader
-- then behaves correctly with no code at all.
--
-- ── THIS IS NOT A SCOPE CUT ──────────────────────────────────────────────────
--
-- Commerce remains R1 and remains next. `release_phase` is deliberately left
-- at 'R1' so the roadmap is unchanged; only `state` moves. When the products
-- table, endpoints and Catalog page exist, the release is this file in
-- reverse — one UPDATE, no deployment.
--
-- commerce.invoices and commerce.reports are untouched: 019 already seeded
-- them `locked` at R2, which was correct.
-- ─────────────────────────────────────────────────────────────────────────────

update feature_flags
   set state      = 'locked',
       updated_at = now()
 where key in (
        'commerce.core',
        'commerce.catalog',
        'commerce.pos',
        'commerce.offline',
        'commerce.stock',
        'commerce.receipts',
        'commerce.catalog_import',
        'commerce.barcode_lookup'
       )
   and state <> 'locked';
