-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 031 — ImageKit media, and categories)
--
-- Apply AFTER 030.
--
-- ── WHY product_media CHANGES SHAPE ──────────────────────────────────────────
--
-- 029 gave it `storage_path`, with a comment about Supabase Storage object
-- paths and signed URLs. The decision since is ImageKit, which is a different
-- kind of thing: it returns a permanent CDN url and its own fileId, and
-- transformations are expressed in the URL rather than negotiated per request.
--
-- So the column is replaced rather than reinterpreted. `storage_path` holding
-- an ImageKit URL would be a lie in the schema, and the next person would
-- write code against the name.
--
-- Safe to do destructively: products, product_variants and product_media are
-- all empty (verified before writing this). Once a business has uploaded a
-- photo this becomes a data migration instead.
--
--   imagekit_file_id  ImageKit's own id. REQUIRED to delete the file later —
--                     without it, removing a photo from kola leaves it live on
--                     the CDN forever, which for a business's product shots is
--                     both a cost and a privacy problem.
--   url               The permanent CDN URL. What a bot sends a customer.
--   thumbnail_url     ImageKit's thumbnail for the grid. Stored rather than
--                     derived so the transformation string lives in one place.
--   width / height    Known at upload. Lets the grid reserve the right space
--                     instead of reflowing when each image lands.
--
-- ── WHY VIDEO IS THE SAME TABLE ──────────────────────────────────────────────
--
-- `kind` already distinguishes them and ImageKit treats both as files with the
-- same upload endpoint and the same id. A separate product_videos table would
-- duplicate every column and every query for one differing field.
--
-- ── tag BECOMES category ─────────────────────────────────────────────────────
--
-- 029 called it `tag`: "free-text label the owner groups by". That is what a
-- category IS for a small shop, and the product editor already labels the
-- field for grouping. Two columns for one idea is how owner_phone would have
-- drifted from owner_notification_settings — so this renames rather than adds.
--
-- Renamed, not duplicated, and the table is empty so nothing is lost. An index
-- comes with it: filtering a catalog by category is the second thing an owner
-- does after searching it.
-- ─────────────────────────────────────────────────────────────────────────────

alter table products rename column tag to category;

create index if not exists products_workspace_category_idx
    on products (workspace_id, category)
    where category is not null;

comment on column products.category is
    'How the owner groups this product — "Dresses", "Fabric", "Accessories". '
    'Free text on purpose: a managed category table would force a small shop '
    'to file things the way we think rather than the way they say it.';

-- product_media, reshaped for ImageKit.
drop table if exists product_media;

create table product_media (
    id                bigserial primary key,
    product_id        bigint not null references products (id) on delete cascade,

    -- 'image' | 'video'.
    kind              text not null default 'image',

    -- ImageKit's file id. Needed to delete the asset — see the note above.
    imagekit_file_id  text not null,

    url               text not null,
    thumbnail_url     text,

    width             integer,
    height            integer,

    -- Position 0 is the product's main image: what the catalog row shows and
    -- what a bot sends first. Explicit rather than "oldest wins", because the
    -- best photo is rarely the first one taken.
    position          integer not null default 0,

    created_at        timestamptz not null default now(),

    constraint product_media_kind_check check (kind in ('image', 'video'))
);

create index product_media_product_idx
    on product_media (product_id, position);

-- One row per ImageKit file. A retried upload that succeeded twice would
-- otherwise show the same photo twice in the grid.
create unique index product_media_file_idx
    on product_media (imagekit_file_id);

alter table product_media enable row level security;

comment on column product_media.imagekit_file_id is
    'ImageKit fileId. Without it a deleted photo stays live on the CDN.';
comment on column product_media.position is
    'Position 0 is the main image — what the catalog row and the bot use.';
