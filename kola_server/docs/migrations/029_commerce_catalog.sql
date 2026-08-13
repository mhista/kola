-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 029 — the catalog)
--
-- Apply AFTER 028.
--
-- The first commerce tables. Migration 028 locked the commerce flags because
-- there was nothing behind them; this is the start of putting something there.
-- The flags stay locked until the endpoints and the Catalog page exist.
--
-- ── THE FIELD LIST COMES FROM THE DESIGN, NOT FROM GUESSWORK ─────────────────
--
-- Kola Catalog.dc.html's product editor is the specification. Its state:
--
--   editName, editDesc, editArchetype, editSku, editTag,
--   editPrice, editCost, editStock, editLowStock, variantRows
--
-- Every one of those has a column below. editCost in particular is not
-- decoration — it is the only thing that makes margin analysis possible, and
-- the design collected it before anything asked for it.
--
-- PRODUCTS[] adds two more facts the editor does not: `priceUnit` ('/yd', on
-- fabric sold by the yard) and the observation that a SERVICE has price null
-- and stock null. Both are modelled rather than flattened — see below.
--
-- ── MONEY IS STORED IN MINOR UNITS, WITH ITS CURRENCY ────────────────────────
--
-- price_minor is an integer count of the currency's smallest unit (kobo for
-- NGN), never a float. Floating point cannot represent 0.1 exactly, and a
-- catalog is the last place to discover that.
--
-- This follows the precedent already set by WorkspaceEndpoint.getBillingSummary,
-- which returns {priceMinor, priceCurrency, priceDecimals} for exactly this
-- reason. price_currency is stored PER ROW rather than derived from
-- workspaces.region at read time: region is where the business is, which is not
-- always what it prices in, and a price whose currency is inferred is a price
-- that can silently change meaning if the business relocates.
--
-- ── NULL PRICE AND NULL STOCK ARE MEANINGFUL ─────────────────────────────────
--
-- The design's 'Custom tailoring' row has both null. They are NOT zero:
--
--   price_minor NULL → "ask us", not free. A bot quoting ₦0 for tailoring
--                      would be a false fact with a real cost attached.
--   stock       NULL → not stock-tracked, not out of stock. Tailoring cannot
--                      run out, and showing it as sold out would turn away
--                      business the shop can absolutely take.
--
-- Nothing downstream may collapse either to 0. The check constraints below
-- allow NULL deliberately and forbid negatives.
--
-- ── VARIANTS ARE ROWS, NOT A COUNT ───────────────────────────────────────────
--
-- PRODUCTS[] carries `variants: 4` and the editor carries variantRows of
-- {label, stock}. The count is a rendering convenience; the rows are the fact.
-- Stored as a child table so a variant can carry its own stock and its own
-- price override — 'Ready-made gown' in size XL legitimately costs more.
--
-- variant.price_minor NULL means "same as the parent", which is the common
-- case and keeps a four-size product from repeating one price four times.
--
-- ── MEDIA HAS A TABLE AND NO PIPELINE YET ────────────────────────────────────
--
-- The editor has a "Photos & video" tab. Uploading is not built. The table
-- exists now anyway, for the same reason owner_notification_settings carries
-- its unused SMS columns: adding it later means another migration against a
-- table that is by then carrying live customer data, for no gain.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists products (
    id                    bigserial primary key,
    workspace_id          bigint not null references workspaces (id) on delete cascade,

    name                  text not null,
    description           text,

    -- 'packaged' | 'variants' | 'services' — ARCHETYPES in the export.
    -- Deliberately the design's own words. These are shop-owner categories
    -- ("Sizes & variants"), not a taxonomy, and the wizard already asks the
    -- same question in the same language.
    archetype             text not null default 'packaged',

    sku                   text,
    tag                   text,

    -- See the money note. NULL = "ask", never zero.
    price_minor           bigint,
    price_currency        text not null default 'NGN',

    -- '/yd', '/kg', '/hour'. Display only — it does not change the maths,
    -- it tells a customer what they are getting for the number.
    price_unit            text,

    -- What the business paid. Never shown to a customer; the input to margin.
    cost_minor            bigint,

    -- NULL = not stock-tracked. See the note above.
    stock                 integer,
    low_stock_threshold   integer not null default 5,

    -- 'active' | 'archived'. Archive rather than delete: a product that has
    -- been sold is referenced by past orders, and deleting it would rewrite
    -- history the business may need for tax.
    status                text not null default 'active',

    created_at            timestamptz not null default now(),
    updated_at            timestamptz not null default now(),

    constraint products_archetype_check
        check (archetype in ('packaged', 'variants', 'services')),
    constraint products_status_check
        check (status in ('active', 'archived')),
    -- Negative money and negative stock are always a bug upstream. Caught
    -- here so the bad value never lands, rather than being noticed later in
    -- a report nobody reconciles.
    constraint products_price_nonneg     check (price_minor is null or price_minor >= 0),
    constraint products_cost_nonneg      check (cost_minor is null or cost_minor >= 0),
    constraint products_stock_nonneg     check (stock is null or stock >= 0),
    constraint products_low_stock_nonneg check (low_stock_threshold >= 0)
);

create index if not exists products_workspace_idx
    on products (workspace_id, status);

-- SKUs are unique WITHIN a workspace and only when present. A partial index
-- rather than a plain unique constraint, because most small shops never set a
-- SKU at all and NULLs must not collide with each other.
create unique index if not exists products_workspace_sku_idx
    on products (workspace_id, sku)
    where sku is not null;

-- Name search. The catalog page's search box is the primary way an owner
-- finds anything once they have more than a screenful.
create index if not exists products_workspace_name_idx
    on products (workspace_id, lower(name));

create table if not exists product_variants (
    id            bigserial primary key,
    product_id    bigint not null references products (id) on delete cascade,

    -- 'Small' / 'XL' / 'Red'. The export's variantRows[].label.
    label         text not null,
    sku           text,

    -- NULL = inherit the parent's price. See the variants note.
    price_minor   bigint,

    stock         integer,

    -- Explicit ordering. A size list that sorts alphabetically reads
    -- L, M, S, XL, which is wrong in a way customers notice immediately.
    position      integer not null default 0,

    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now(),

    constraint product_variants_price_nonneg check (price_minor is null or price_minor >= 0),
    constraint product_variants_stock_nonneg check (stock is null or stock >= 0)
);

create index if not exists product_variants_product_idx
    on product_variants (product_id, position);

create table if not exists product_media (
    id          bigserial primary key,
    product_id  bigint not null references products (id) on delete cascade,

    -- 'image' | 'video'.
    kind        text not null default 'image',

    -- Supabase Storage object path, NOT a signed URL. Signed URLs expire;
    -- storing one would give a catalog that works for an hour.
    storage_path text not null,

    position    integer not null default 0,
    created_at  timestamptz not null default now(),

    constraint product_media_kind_check check (kind in ('image', 'video'))
);

create index if not exists product_media_product_idx
    on product_media (product_id, position);

-- Same posture as every other table here: RLS on with no policies, so
-- PostgREST reaches nothing and the server (connecting as table owner)
-- reaches everything. Workspace isolation is enforced in the repository
-- layer, which filters by workspace_id on every query.
alter table products         enable row level security;
alter table product_variants enable row level security;
alter table product_media    enable row level security;

comment on column products.price_minor is
    'Integer count of the smallest unit of price_currency (kobo for NGN). '
    'NULL means the price is on request — it does NOT mean zero.';
comment on column products.stock is
    'NULL means this product is not stock-tracked (e.g. a service). It does '
    'NOT mean out of stock.';
comment on column product_variants.price_minor is
    'NULL means inherit the parent product price.';
