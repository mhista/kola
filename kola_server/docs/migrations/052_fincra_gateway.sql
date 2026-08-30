-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 052 — Gate 11 breadth: Fincra gateway)
--
-- Apply AFTER 051.
--
-- Same "widen, don't drop, the CHECK constraint" reasoning migration 020
-- (Stripe) and 051 (Monnify) already established — a fifth value, same
-- pattern. Unlike Monnify, Fincra needs no new column: its auth is a
-- single static secret key (the `api-key` header — see
-- fincra_service.dart's header), so the existing encrypted_secret_key
-- column every gateway already has is enough.
-- ─────────────────────────────────────────────────────────────────────────────

alter table payment_gateway_credentials
  drop constraint if exists payment_gateway_credentials_gateway_check;

alter table payment_gateway_credentials
  add constraint payment_gateway_credentials_gateway_check
  check (gateway in ('paystack', 'flutterwave', 'stripe', 'monnify', 'fincra'));

alter table payment_transactions
  drop constraint if exists payment_transactions_gateway_check;

alter table payment_transactions
  add constraint payment_transactions_gateway_check
  check (gateway in ('paystack', 'flutterwave', 'stripe', 'monnify', 'fincra'));
