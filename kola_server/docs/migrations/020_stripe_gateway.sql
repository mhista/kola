-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 020 — Stripe as a payment gateway)
--
-- Apply AFTER 019.
--
-- WHY: nothing about this product is country-specific. A shop in Nairobi,
-- São Paulo or Manila has the same problem as one in Lagos — the only
-- thing stopping them was that Kola spoke exclusively to two African
-- gateways. Stripe covers most of the rest of the world.
--
-- The BYO-credential model is unchanged: a business connects its OWN
-- Stripe account, money goes straight there, and Kola never holds funds.
--
-- ── WHY THE CONSTRAINT IS WIDENED RATHER THAN DROPPED ────────────────────────
-- It would be simpler to remove the CHECK entirely and let any string
-- through. That would be worse: the constraint is what stops a typo
-- ('stipe') persisting as a credential that then fails at charge time,
-- in front of a customer, with no obvious cause. Widening it keeps that
-- protection while admitting the new value. Adding a fourth gateway
-- later is one more migration of exactly this shape — which is the
-- intended cost, and cheap.
-- ─────────────────────────────────────────────────────────────────────────────

-- Postgres has no "alter check constraint", so each is dropped and
-- recreated. Names come from 009's inline CHECK definitions, which
-- Postgres auto-named; `if exists` makes this safe to re-run and safe on
-- a database where the auto-generated name differed.
alter table payment_gateway_credentials
  drop constraint if exists payment_gateway_credentials_gateway_check;

alter table payment_gateway_credentials
  add constraint payment_gateway_credentials_gateway_check
  check (gateway in ('paystack', 'flutterwave', 'stripe'));

alter table payment_transactions
  drop constraint if exists payment_transactions_gateway_check;

alter table payment_transactions
  add constraint payment_transactions_gateway_check
  check (gateway in ('paystack', 'flutterwave', 'stripe'));

-- ── CURRENCY ─────────────────────────────────────────────────────────────────
-- Kola was implicitly NGN-only: amounts were stored in kobo with no
-- record of which currency they were kobo OF. That is fine with one
-- market and silently wrong with several — a stored `50000` means ₦500,
-- $500, or ¥50000 depending on a currency nobody wrote down.
--
-- Defaults to NGN so every existing row keeps its current, correct
-- meaning. New rows must set it explicitly.
--
-- NOTE FOR ANYONE WRITING AMOUNT CODE: the amount stays in the
-- currency's SMALLEST unit, but "smallest unit" is not always 1/100 —
-- JPY, KRW, XOF and others have no minor unit at all. See
-- StripeService.zeroDecimalCurrencies. Assuming two decimals for those
-- charges the customer 100x.
alter table payment_transactions
  add column if not exists currency text not null default 'NGN';

comment on column payment_transactions.currency is
  'ISO-4217. Amount is in this currency''s smallest unit — but see '
  'StripeService.zeroDecimalCurrencies: some currencies have no minor unit.';
