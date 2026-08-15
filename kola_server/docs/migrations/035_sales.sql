-- 035_sales.sql — the till.
--
-- Backs "Kola Till.dc.html", whose state is:
--
--   { screen, searchQuery, cat, lines, payMethod, cashReceived,
--     paidMethod, queued, online, showScanner }
--
-- ── A SALE IS A HISTORICAL RECORD, NOT A VIEW OF THE CATALOG ─────────
--
-- This is the single most important decision in this file, and getting
-- it wrong is the classic point-of-sale bug.
--
-- sale_lines SNAPSHOTS the product's name and unit price at the moment
-- of sale. It does NOT join to products for them.
--
-- If lines held only product_id and read the name and price live, then:
--
--   • raising a price would silently rewrite every past receipt
--   • renaming a product would rewrite what a customer was handed
--   • archiving one would empty the line entirely
--
-- A receipt is a statement about what happened on a Tuesday. It must
-- keep saying that. product_id is kept ALONGSIDE the snapshot — nullable,
-- ON DELETE SET NULL — so "how many did we sell" still works while
-- deleting a product cannot destroy the record of having sold it.
--
-- ── TAX IS OPT-IN, AND THE DESIGN'S 7.5% IS NOT A DEFAULT ────────────
--
-- The export computes `Math.round(subtotal * 0.075)` unconditionally.
-- That is Nigeria's VAT rate, and it is correct ONLY for a
-- VAT-registered business — which most small shops are not, being under
-- the turnover threshold.
--
-- Applied to everyone it would overcharge real customers and misstate
-- the owner's books, and it would do so invisibly, on every sale,
-- forever. So the rate lives on the workspace, defaults to ZERO, and a
-- sale stores the rate it actually used.
--
-- Storing tax_rate_bps per SALE rather than reading it from the
-- workspace at report time is the same rule as the line snapshot:
-- changing the rate next year must not rewrite last year's totals.
--
-- ── MONEY ────────────────────────────────────────────────────────────
--
-- Integer minor units, per-row currency, matching products.price_minor.
-- Never doubles: 0.1 + 0.2 is not 0.3, and a till that is off by a kobo
-- per line is a till nobody trusts.
--
-- ── OFFLINE ──────────────────────────────────────────────────────────
--
-- The design shows `queued: 6, online: false` — sales made with no
-- connection, held locally, synced later (commerce.offline, R1).
--
-- `client_reference` is what makes that safe: the till generates it, and
-- it is UNIQUE per workspace. A queued sale replayed twice — because the
-- response was lost, not because the request failed — collides and is
-- rejected rather than recording the same money twice. Nullable, because
-- a sale rung up online has no need of one.

create table if not exists sales (
  id                bigserial primary key,
  workspace_id      bigint not null references workspaces(id) on delete cascade,

  -- Human-facing, shown on the receipt. Assigned server-side.
  reference         text   not null,

  -- Idempotency key from an offline till. See the header.
  client_reference  text,

  subtotal_minor    bigint not null,

  -- The rate ACTUALLY APPLIED, in basis points (750 = 7.5%). Stored so a
  -- later rate change cannot rewrite this sale. 0 for the common case.
  tax_rate_bps      int    not null default 0,
  tax_minor         bigint not null default 0,

  total_minor       bigint not null,
  currency          text   not null default 'NGN',

  -- 'cash' | 'transfer' | 'card' | 'split'
  --
  -- Text rather than an enum: adding a method should be a deploy, not a
  -- migration. 'card' is only reachable once payments.collect unlocks —
  -- the till offers what the workspace can actually take.
  payment_method    text   not null,

  -- Cash tendered and change given. Both null for a transfer: recording
  -- 0 would claim the customer handed over nothing, which is different
  -- from the question not applying.
  cash_received_minor bigint,
  change_minor        bigint,

  -- 'completed' | 'refunded' | 'void'
  --
  -- A void or refund is a NEW STATE on the original row, never a delete.
  -- Money that was taken and given back is a fact about the day, and a
  -- till whose history can vanish is one an owner cannot reconcile
  -- against their cash box.
  status            text   not null default 'completed',

  -- When the SALE happened, which is not when the row arrived. An
  -- offline sale synced the next morning belongs to yesterday's takings.
  sold_at           timestamptz not null default now(),

  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create table if not exists sale_lines (
  id                bigserial primary key,
  sale_id           bigint not null references sales(id) on delete cascade,

  -- Nullable ON DELETE SET NULL — deleting a product must not delete the
  -- record of having sold it. See the header.
  product_id        bigint references products(id) on delete set null,

  -- THE SNAPSHOT. What the customer was charged for, as it read then.
  name              text   not null,
  unit_price_minor  bigint not null,

  quantity          int    not null check (quantity > 0),
  line_total_minor  bigint not null,

  created_at        timestamptz not null default now()
);

-- Idempotency for the offline queue. Partial, so the many online sales
-- with a null client_reference do not collide with each other.
create unique index if not exists sales_client_reference_idx
  on sales (workspace_id, client_reference)
  where client_reference is not null;

-- The reference an owner reads off a receipt must find exactly one sale.
create unique index if not exists sales_reference_idx
  on sales (workspace_id, reference);

-- "What did we take today", the till's own most common read.
create index if not exists sales_workspace_sold_at_idx
  on sales (workspace_id, sold_at desc);

create index if not exists sale_lines_sale_idx on sale_lines (sale_id);

-- "How many of this did we sell" — the join reports will want, and the
-- reason product_id is kept alongside the snapshot.
create index if not exists sale_lines_product_idx on sale_lines (product_id);

-- The tax rate the till should apply, per workspace.
--
-- DEFAULT 0, deliberately. A shop that is not VAT-registered must not
-- start charging it because a design mock did. Turning it on is a
-- decision the owner makes knowingly, in Settings.
alter table workspaces
  add column if not exists tax_rate_bps int not null default 0;

-- Same posture as every other table here: RLS on, no policies, the
-- repository layer is the isolation boundary.
alter table sales enable row level security;
alter table sale_lines enable row level security;
