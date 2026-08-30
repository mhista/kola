# Gate 11 — Breadth: Monnify connector

Status: **BUILT, sync-only** — second of the five connectors named in
the Rev 6 addendum as still unbuilt (after Google Drive). Monnify
transactions now sync into the customer/sales graph the same way
Paystack and Flutterwave's already do; generating a Monnify checkout
link from kolaa is a separate, unbuilt capability (see scope cut below).

## What was verified before writing anything

This codebase's own convention (every payment/OAuth service header cites
"confirmed against [docs URL] on [date]") was followed here too:
Monnify's real auth flow and transaction-search endpoint were fetched
from https://developers.monnify.com/docs/collections/quickstart and
.../manage-payments/reconciliation on 2026-08-27 — not assumed. What
that confirmed: Basic-auth login (`POST /api/v1/auth/login` with
`Authorization: Basic base64(apiKey:secretKey)`) issuing a 1-hour Bearer
token; the search endpoint (`GET
/api/v1/merchant/transactions/search`, `from`/`to` as **millisecond**
Unix timestamps — not ISO-8601 like Paystack/Flutterwave); and the field
names Monnify's own reconciliation guide names in prose
(`paymentReference`, `transactionReference`, `paymentStatus` with values
including `PAID`, `amountPaid`, `settlementAmount`).

What was **not** independently confirmed: the exact JSON envelope/
pagination shape of the search response (Monnify's interactive API
reference is a JS-rendered app this session's fetch tool couldn't read
past its shell). `MonnifyAdapter` parses defensively — tries a small set
of plausible envelope shapes, skips and logs a row it can't make sense
of rather than crashing the whole sync — instead of asserting a schema
never actually seen. Worth tightening against a real sandbox account.

## What was built

1. **`MonnifyService`** (new, `lib/src/services/billing/`) — auth +
   `searchTransactions`. Deliberately does NOT implement checkout
   initiation or webhook verification — see its own header.
2. **`MonnifyAdapter`** (new, implements `ConnectorAdapter`) — same shape
   as `PaystackAdapter`/`FlutterwaveAdapter`, filters to `PAID` only,
   resolves customer identity, emits `payment_confirmed` on the shared
   event bus.
3. **Migration 051** — widens the `gateway` CHECK constraint on both
   `payment_gateway_credentials` and `payment_transactions` (same
   pattern migration 020 used for Stripe), and adds a new
   `encrypted_api_key` column — Monnify is the first gateway needing a
   genuinely second required credential, so this doesn't overload the
   existing `encrypted_webhook_secret` column, which means something
   specific and different for Flutterwave.
4. **`connector_catalog.dart`** — new `'monnify'` entry, two fields
   (`apiKey`, `secretKey`), `category: 'pay'`, reuses the existing
   `FeatureKeys.payments` flag (no new flag needed).
5. **A real bug fixed, not just worked around**: `PaymentEndpoint
   .connectGateway`'s probe logic and `PaymentCheckoutService
   .initializeCheckout`'s gateway logic both ended in a bare `else`
   that silently treated any gateway that wasn't `'paystack'`/`'stripe'`
   as Flutterwave. Harmless with three gateways; a real silent-misroute
   risk with a fourth — a Monnify credential would have been probed
   against Flutterwave's API and rejected with a confusing error, or a
   Monnify checkout request would have silently tried to charge through
   Flutterwave. Fixed with an explicit `switch` (connect-side) and a new
   `checkoutSupportedGateways` set checked separately from
   `validPaymentGateways` (checkout-side), not just patched for Monnify
   — the next gateway added after this one inherits the safe pattern.
6. **`connector_sync_sweep_service.dart`** — new `_sweepMonnify()`,
   parallel to `_sweepBumpa()` rather than going through the generic
   `_sweepGateway` loop, because that loop's `buildAdapter` signature
   only carries one secret string and Monnify needs two.
7. **Dashboard** — `integrations_page.dart`'s `_submitGateway` now reads
   and forwards an `apiKey` form value (Monnify's card renders it
   automatically, since the form already iterates every
   `ConnectorField` the catalog entry declares — no new UI code needed
   beyond passing the value through). `kola_client`'s hand-maintained
   `connectGateway` stub gained the matching optional param.

## Real, named scope cut

**No checkout-initiation path.** Monnify is sync/graph-landing only —
`checkoutSupportedGateways` explicitly excludes it, and calling
`initializeCheckout` (or the `collectPayment` Errand) with `gateway:
'monnify'` throws a clear "not supported for checkout yet" error rather
than doing anything silently wrong. A business already collecting
payments through Monnify can connect it so those transactions land on
the graph; a business wanting kolaa to generate a Monnify payment link
cannot yet.

## Verification note

Same limitation as every gate this session: no Dart toolchain here, so
none of this compiled locally. `dart pub get && serverpod generate` is
required — this is the first gate this session where the SERVER model
change (`PaymentGatewayCredential.encryptedApiKey`) is referenced by
code that assumes it exists (DTO, repository, endpoint, sweep service),
so a build BEFORE regenerating will fail, not just silently miss the
field. Migration 051 also needs to be applied to the live database
before any of this can work — it has NOT been applied yet, only
written.
