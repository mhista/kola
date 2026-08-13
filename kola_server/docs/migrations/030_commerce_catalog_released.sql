-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 030 — the catalog is real)
--
-- Apply AFTER 029.
--
-- ── THE OTHER HALF OF 028 ────────────────────────────────────────────────────
--
-- Migration 028 set eight commerce flags back to `locked`, because they had
-- been `released` since 019 with no tables, no endpoints and no pages behind
-- them — advertising a Catalog and a Sales counter that led nowhere.
--
-- 029 built products / product_variants / product_media. ProductEndpoint and
-- CatalogPage followed. So two of those eight are now true, and this is the
-- release: one UPDATE, no deployment, exactly as RELEASE_PHASES §0 describes.
--
-- ── ONLY TWO ─────────────────────────────────────────────────────────────────
--
--   commerce.core     ✅  the capability exists
--   commerce.catalog  ✅  products can be listed, created, edited, archived
--
-- The other six stay locked, and each for a reason that is still true:
--
--   commerce.pos            no sales counter, no orders table. Releasing this
--                           would put "Sales counter" back in the sidebar
--                           pointing at an unregistered /counter — the exact
--                           defect 028 removed.
--   commerce.stock          stock is a COLUMN on products and is edited in the
--                           catalog. There is no stock-movement history, which
--                           is what this flag actually names.
--   commerce.receipts       nothing generates one.
--   commerce.offline        no offline queue.
--   commerce.catalog_import no importer. The design has a whole screen for it
--                           (Kola Catalog Import.dc.html) and it is not built.
--   commerce.barcode_lookup no lookup service.
--
-- Releasing a flag because its neighbours shipped is how 019 ended up wrong.
-- Each one flips when the thing it names exists.
--
-- ── WHAT THIS TURNS ON, EXACTLY ──────────────────────────────────────────────
--
--   • Sidebar → Catalog (needs core + catalog)         appears, and resolves
--   • Mobile "More" sheet → Catalog                    same
--   • ProductEndpoint's flag check                     starts passing
--   • Overview's "Products —, available once you can add a catalog"
--     placeholder                                      stops rendering, and is
--                                                      replaced by a real count
--   • NextSteps' "Add what you sell → /catalog" hint   starts rendering, and
--                                                      now leads somewhere
--
--   • Sidebar → Sales counter                          STAYS HIDDEN (needs pos)
-- ─────────────────────────────────────────────────────────────────────────────

update feature_flags
   set state      = 'released',
       updated_at = now()
 where key in ('commerce.core', 'commerce.catalog')
   and state <> 'released';
