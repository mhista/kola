-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 053 — Gate 13: payment-to-order reconciliation)
--
-- Apply AFTER 052.
--
-- Adds payment_transactions.sale_id — the link PaymentReconciliationService
-- writes once it deterministically matches a completed payment (any
-- gateway: Paystack, Flutterwave, Stripe, Monnify, Fincra, or a manually
-- confirmed bank transfer) to a till Sale. See that service's own header
-- for the matching rules and payment_transaction.spy.yaml's saleId field
-- doc for why this is a plain nullable link rather than a review-queue
-- table like customer merge proposals — a wrong link here is cheap to
-- notice and cheap to reverse, unlike a wrong customer merge.
--
-- ON DELETE SET NULL, not CASCADE: a Sale being voided/refunded must not
-- delete or corrupt the payment record it was matched to — the payment
-- still happened; it just needs to go back to being unmatched money
-- (which the next sweep will correctly report again).
-- ─────────────────────────────────────────────────────────────────────────────

alter table payment_transactions
  add column if not exists sale_id integer references sales(id) on delete set null;

create index if not exists payment_transactions_sale_id_idx
  on payment_transactions (sale_id);

comment on column payment_transactions.sale_id is
  'Gate 13 — set by PaymentReconciliationService once a completed payment '
  'is deterministically matched to a till Sale (same workspace, exact '
  'amount+currency, within the matching window, never contradicting a '
  'resolved customer on either side). Null means either "not a till sale" '
  '(most bot-checkout payments) or "not matched yet" — see that service '
  'for how the unmatched-money finding tells the two apart.';
