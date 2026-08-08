-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 019 — commerce capability flags)
--
-- Apply AFTER 018.
--
-- Adds the commerce capability keys declared in feature_keys.dart. Same
-- structure and same guarantees as 018 — see that file's SEED CONTENT
-- NOTE for why `name` and `description` are neutral placeholders here and
-- why the `on conflict` clause never touches state, name or description.
--
-- Commerce is available but OFF BY DEFAULT PER WORKSPACE. Note the two
-- layers, because they are easy to confuse:
--   • These flags control whether commerce is available on the platform.
--   • Whether a given business has switched it on is a workspace setting,
--     not a flag. A released capability a business has not enabled is not
--     the same as a locked one, and the dashboard renders them
--     differently.
-- ─────────────────────────────────────────────────────────────────────────────

insert into feature_flags (key, name, description, state, minimum_plan, release_phase, externally_gated) values
    ('commerce.core',             'Commerce',         'Capability flag.', 'released', null,  'R1', false),
    ('commerce.catalog',          'Catalog',          'Capability flag.', 'released', null,  'R1', false),
    ('commerce.pos',              'Pos',              'Capability flag.', 'released', null,  'R1', false),
    ('commerce.offline',          'Offline',          'Capability flag.', 'released', null,  'R1', false),
    ('commerce.stock',            'Stock',            'Capability flag.', 'released', null,  'R1', false),
    ('commerce.receipts',         'Receipts',         'Capability flag.', 'released', null,  'R1', false),
    ('commerce.catalog_import',   'Catalog import',   'Capability flag.', 'released', null,  'R1', false),
    ('commerce.barcode_lookup',   'Barcode lookup',   'Capability flag.', 'released', null,  'R1', false),
    ('commerce.invoices',         'Invoices',         'Capability flag.', 'locked',   null,  'R2', false),
    ('commerce.reports',          'Reports',          'Capability flag.', 'locked',   null,  'R2', false),
    ('commerce.customer_display', 'Customer display', 'Capability flag.', 'locked',   null,  'R2', false),
    ('commerce.public_catalog',   'Public catalog',   'Capability flag.', 'locked',   'pro', 'R2', false),
    ('commerce.photo_capture',    'Photo capture',    'Capability flag.', 'locked',   null,  'R2', false),
    ('commerce.voice_capture',    'Voice capture',    'Capability flag.', 'locked',   null,  'R2', false)
on conflict (key) do update set
  minimum_plan     = excluded.minimum_plan,
  release_phase    = excluded.release_phase,
  externally_gated = excluded.externally_gated,
  updated_at       = now();
-- state / name / description deliberately absent — see 018's note.
