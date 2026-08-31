-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 060 — Phase 11g-e: stock conflict detection)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers stock_conflict.spy.yaml — see its header for the full
-- rationale (in particular: why this only becomes possible once
-- offline-queued sales can sync out of order, and why Product.stock
-- itself stays clamped at zero while this table carries the real
-- oversold signal). This file is the schema itself, not the reasoning
-- trail.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists stock_conflicts (
  id                 bigserial primary key,
  workspace_id       bigint not null references workspaces(id) on delete cascade,
  product_id         bigint not null references products(id) on delete cascade,
  sale_id            bigint references sales(id) on delete set null,

  oversold_by        integer not null check (oversold_by >= 1),

  detected_at        timestamptz not null default now(),

  status             text not null default 'open'
                       check (status in ('open', 'backordered', 'adjusted', 'dismissed')),
  resolved_at        timestamptz,
  resolved_by_email  text,

  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index if not exists stock_conflicts_workspace_idx on stock_conflicts (workspace_id);
create index if not exists stock_conflicts_status_idx on stock_conflicts (workspace_id, status);
create index if not exists stock_conflicts_product_idx on stock_conflicts (product_id);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger stock_conflicts_updated_at
  before update on stock_conflicts for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5). RLS enabled
-- with zero policies blocks the anon key from touching any of this
-- outright.
alter table stock_conflicts enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
