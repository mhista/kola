-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 051 — Gate 11 breadth: Monnify gateway)
--
-- Apply AFTER 050.
--
-- Same "widen, don't drop, the CHECK constraint" reasoning migration 020
-- already established when Stripe was added — see that file's own
-- comment, unchanged here, just a fourth value.
--
-- Monnify also needs a genuinely SECOND required credential (an apiKey,
-- alongside the existing secretKey column every gateway already has) —
-- see payment_gateway_credential.spy.yaml's encryptedApiKey field for
-- why this is a new nullable column rather than reusing
-- encrypted_webhook_secret, which means something specific and different
-- for Flutterwave.
-- ─────────────────────────────────────────────────────────────────────────────

alter table payment_gateway_credentials
  drop constraint if exists payment_gateway_credentials_gateway_check;

alter table payment_gateway_credentials
  add constraint payment_gateway_credentials_gateway_check
  check (gateway in ('paystack', 'flutterwave', 'stripe', 'monnify'));

alter table payment_transactions
  drop constraint if exists payment_transactions_gateway_check;

alter table payment_transactions
  add constraint payment_transactions_gateway_check
  check (gateway in ('paystack', 'flutterwave', 'stripe', 'monnify'));

alter table payment_gateway_credentials
  add column if not exists encrypted_api_key text;

comment on column payment_gateway_credentials.encrypted_api_key is
  'Gate 11 — Monnify-only today: a second required credential alongside '
  'encrypted_secret_key (Basic base64(apiKey:secretKey) auth). Null for '
  'every gateway that authenticates with a single key.';
