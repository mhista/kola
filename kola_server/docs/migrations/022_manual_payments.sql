-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 022 — manual bank-transfer payments)
--
-- Apply AFTER 021.
--
-- WHY THIS EXISTS: bank transfer is how a very large share of SME commerce
-- actually settles — in Nigeria, and equally in Kenya, India and Indonesia.
-- Gateways take a cut, need onboarding and KYC, and plenty of traders
-- simply do not have one. A product that only supports gateway checkout
-- does not work for a large part of its own market.
--
-- ── THE DISTINCTION THIS MIGRATION EXISTS TO ENFORCE ─────────────────────────
--
-- A gateway payment is VERIFIED: the provider is re-queried and confirms
-- the money moved. A bank transfer marked paid is a HUMAN CLAIM: one
-- person tapped a button.
--
-- Those must never look the same. Not primarily because of fraud —
-- because a rep marking the wrong order paid is an ordinary mistake, and
-- without this distinction it is invisible in the timeline, in reports,
-- and in revenue totals. `confirmation_method` is what makes it visible,
-- and every surface that displays money must read it.
--
-- ── TWO SEPARATE AXES, DELIBERATELY ──────────────────────────────────────────
--   gateway              — how the money was MEANT to move
--   confirmation_method  — how we know it ARRIVED
-- A card payment is (paystack, gateway_verified). A transfer is
-- (bank_transfer, human_marked). Collapsing them into one column would
-- make "verified" unrepresentable for anything but a gateway.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── BANK ACCOUNTS ────────────────────────────────────────────────────────────
-- WHY A TABLE AND NOT FREE TEXT ON THE ERRAND: a bot broadcasting bank
-- details is exactly the pattern payment scammers impersonate. Account
-- details a customer is asked to send money to must come from ONE
-- deliberate, workspace-level record — not from a text box someone typed
-- into while building an errand, where a typo or a swapped digit reaches
-- customers with the business's name attached to it.
--
-- Also means changing account details is one edit, not a hunt through
-- every errand that happens to embed them.
create table if not exists payment_bank_accounts (
  id              bigserial primary key,
  workspace_id    bigint not null references workspaces(id) on delete cascade,
  bank_name       text not null,
  account_number  text not null,
  account_name    text not null,
  currency        text not null default 'NGN',
  -- Marked true only after someone has confirmed these details are
  -- correct. An unverified account can be stored but must NOT be sent to
  -- a customer — see ManualPaymentService.
  is_verified     boolean not null default false,
  -- Only one account per workspace is offered to customers at a time.
  -- Others are kept for history rather than deleted, so a transaction
  -- from six months ago still resolves to the account it named.
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists payment_bank_account_workspace_idx
  on payment_bank_accounts (workspace_id);

-- At most one active account per workspace+currency. A partial unique
-- index rather than a constraint, so historical (inactive) rows are
-- unaffected.
create unique index if not exists payment_bank_account_active_idx
  on payment_bank_accounts (workspace_id, currency)
  where is_active;

alter table payment_bank_accounts enable row level security;

-- ── TRANSACTIONS: manual path ────────────────────────────────────────────────

-- 'bank_transfer' joins the real gateways. Widened rather than dropped,
-- for the same reason as migration 020: the constraint is what stops a
-- typo persisting and failing later at charge time.
alter table payment_transactions
  drop constraint if exists payment_transactions_gateway_check;

alter table payment_transactions
  add constraint payment_transactions_gateway_check
  check (gateway in ('paystack', 'flutterwave', 'stripe', 'bank_transfer'));

-- THE INTEGRITY COLUMN. Defaults to 'gateway_verified' so every existing
-- row keeps its current, correct meaning — everything recorded so far
-- came through a gateway and was verified against it.
alter table payment_transactions
  add column if not exists confirmation_method text not null
    default 'gateway_verified'
    check (confirmation_method in ('gateway_verified', 'human_marked'));

comment on column payment_transactions.confirmation_method is
  'How we know the money arrived. gateway_verified = re-queried against '
  'the provider. human_marked = a person tapped a button. These must be '
  'visually distinct everywhere money is displayed.';

-- Who marked it, for a human-marked payment. Null for gateway payments.
alter table payment_transactions
  add column if not exists confirmed_by text;

alter table payment_transactions
  add column if not exists confirmed_at timestamptz;

-- ── PROOF ────────────────────────────────────────────────────────────────────
-- What makes a dispute resolvable three weeks later. Captured at the
-- moment of confirmation, when the person still has the transfer receipt
-- in front of them — asking for it later almost never works.
alter table payment_transactions
  add column if not exists proof_reference text;

alter table payment_transactions
  add column if not exists proof_url text;

-- ── REMINDER SCHEDULE ────────────────────────────────────────────────────────
-- The original design reminded every 2 minutes indefinitely until someone
-- confirmed. A customer saying "I will send it this evening" would
-- generate roughly thirty notifications an hour to two people, who would
-- then mute the channel — killing the mechanism for the case where it
-- actually mattered.
--
-- Instead: a stated expectation, intervals that BACK OFF, a hard cap, and
-- an automatic expiry. See ManualPaymentService.reminderSchedule.
alter table payment_transactions
  add column if not exists expected_by timestamptz;

alter table payment_transactions
  add column if not exists reminder_count int not null default 0;

alter table payment_transactions
  add column if not exists last_reminder_at timestamptz;

-- Who is responsible for watching for this transfer. Free text (a name
-- or email) rather than a foreign key: the person may be a shop
-- assistant who has no Kola login at all.
alter table payment_transactions
  add column if not exists assigned_to text;

-- 'unconfirmed' is a real, distinct end state — NOT a failure. The money
-- may well have arrived; nobody confirmed it in the window. Collapsing it
-- into 'failed' would understate revenue and hide reconciliation work.
alter table payment_transactions
  drop constraint if exists payment_transactions_status_check;

alter table payment_transactions
  add constraint payment_transactions_status_check
  check (status in ('pending', 'completed', 'failed', 'refunded', 'unconfirmed'));

-- Finds transfers still awaiting confirmation, for the reminder sweep and
-- for end-of-day reconciliation.
create index if not exists payment_transaction_awaiting_idx
  on payment_transactions (workspace_id, status, expected_by)
  where gateway = 'bank_transfer';
