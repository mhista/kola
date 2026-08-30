# Gate 11 — Breadth: Fincra connector

Status: **BUILT, sync-only** — third of the five connectors named in
the Rev 6 addendum as still unbuilt (after Google Drive and Monnify).
Fincra pay-ins now sync into the customer/sales graph, same as
Paystack, Flutterwave, and Monnify's already do; generating a Fincra
checkout from kolaa is a separate, unbuilt capability (see scope cut
below).

## What was verified before writing anything

Same discipline as every other connector this session: real docs
fetched and cited, not assumed.

- **Auth** — confirmed against https://docs.fincra.com/docs/authentication
  on 2026-08-27: a single static secret key sent as the `api-key`
  header on every call. No login/token-exchange step, genuinely simpler
  than Monnify's Basic-auth-then-Bearer-token flow. (Fincra also has a
  Public key for the client-side checkout widget and a separate
  Webhook Encryption Key — neither is used by this sync-only build.)
- **Base URL** — confirmed against
  https://docs.fincra.com/docs/live-environment on 2026-08-27:
  `https://api.fincra.com`.
- **Business ID** — confirmed against
  https://docs.fincra.com/reference/get-business-information.md on
  2026-08-27: `GET /profile/business/me` returns `data._id`, a value
  Fincra's own transaction-listing endpoint requires as a query
  parameter (unlike Paystack/Flutterwave/Monnify, which infer the
  caller's account from the key alone).
- **Transaction list** — confirmed as a real, paginated endpoint
  (`page`/`perPage` query params) against
  https://docs.fincra.com/reference/get-wallet-top-ups.md on
  2026-08-27: `GET /wallets/topups`, described as "view both a single
  or multiple collections made to a business wallet."

## The real uncertainty this pass surfaced

**No dedicated "list charges/checkout transactions" endpoint exists in
Fincra's documented API.** This was checked thoroughly, not assumed:
Fincra's Checkout Standard and Direct Charge APIs only expose
per-reference `verify`/`get-by-reference` calls plus webhook delivery
(`charge.successful` etc.) — no list. The full API reference index
(https://docs.fincra.com/llms.txt) was fetched and read end-to-end
looking for one; `GET /wallets/topups` ("Get Topup History") is the
closest real analog to Paystack's `/transaction` list or Monnify's
`/merchant/transactions/search/`, and is what this build uses. Two
honest caveats about that choice, both left visible in
`fincra_service.dart`'s header rather than glossed over:

1. **"Wallet top-ups" may be broader than "customer checkout
   payments."** It's Fincra's own general term for money landing in
   the business's wallet, which could include manual funding or other
   products' settlements alongside actual customer checkouts. This
   build treats every row as a candidate customer payment — the same
   blunt inclusion every other gateway adapter here applies to its own
   "success only" filter — and is worth revisiting against a real
   account's data.
2. **The response schema is completely undocumented.** Fincra's own
   reference page shows an empty `{}` example body for both the 200
   and 400 cases of this endpoint. `FincraAdapter` parses defensively
   (tries a small set of plausible envelope/field shapes borrowed from
   the one sibling endpoint whose response IS documented — Get Balance
   History — and skips+logs anything it can't make sense of) rather
   than asserting a schema never actually seen. This is a bigger
   unknown than Monnify's (Monnify's fields, at least, were named in
   prose elsewhere in its docs); tightening this needs a real Fincra
   sandbox account.

This was a genuine architectural fork worth naming rather than paving
over: Fincra's API is built for webhook-driven confirmation, not
polling. A webhook-only connector was the other real option (documented
in the prior status handoff as something to surface, not assume). This
build stayed with the pull-based `ConnectorAdapter.sync()` shape every
other gateway here uses, on the theory that a syncing-but-imprecise
connector a business can turn on today is more useful than no connector
while a webhook-receiving architecture (a materially different shape
from every adapter in this codebase) gets designed — but this is a
real trade-off, not a foregone conclusion, and worth a second look once
`/wallets/topups`'s actual shape is known.

## What was built

1. **`FincraService`** (new, `lib/src/services/billing/`) — resolves
   the business ID, lists top-ups. No checkout initiation, no webhook
   verification — see its own header.
2. **`FincraAdapter`** (new, implements `ConnectorAdapter`) — same
   shape as the other three gateway adapters. Unlike them,
   `supportsIncrementalSync: false` — no confirmed date-range filter on
   this endpoint, so every sync run walks every page rather than asking
   for only what's new; relies on `upsertFromSync`'s own idempotency to
   keep repeated full walks cheap on the write side.
3. **Migration 052** — widens the `gateway` CHECK constraint on both
   `payment_gateway_credentials` and `payment_transactions` (same
   pattern as 020/051). **No new column** — Fincra's single secret key
   fits the existing `encrypted_secret_key` column every gateway
   already has, unlike Monnify.
4. **`connector_catalog.dart`** — new `'fincra'` entry, one field
   (`secretKey`), `category: 'pay'`, reuses `FeatureKeys.payments`.
5. **`payment_endpoint.dart`** — new `case 'fincra':` in the connect-
   time probe switch (added when Monnify's fix replaced the old
   if/else chain — this gateway inherits that safety for free).
6. **`payment_checkout_service.dart`** — `'fincra'` added to
   `validPaymentGateways`, deliberately NOT added to
   `checkoutSupportedGateways` (same scope cut as Monnify).
7. **`connector_sync_sweep_service.dart`** — Fincra needs only ONE
   secret, so unlike Monnify it fits `_sweepGateway`'s existing generic
   loop directly — no bespoke `_sweepFincra()` method needed.
8. **Dashboard/client** — no changes needed. Fincra's catalog entry has
   only the `secretKey` field every gateway's form already renders and
   forwards; the `apiKey` plumbing added for Monnify stays null and
   ignored for Fincra, exactly as it already is for Paystack/
   Flutterwave/Stripe.

## Real, named scope cut

**No checkout-initiation path**, same as Monnify — `fincra` is excluded
from `checkoutSupportedGateways`, and `initializeCheckout(gateway:
'fincra')` throws a clear "not supported for checkout yet" error.

## Verification note

Same limitation as every gate this session: no Dart toolchain here, so
none of this compiled locally. `dart pub get && serverpod generate` is
needed before this builds — though unlike Monnify, no server model
field changed here, so the blast radius of skipping regeneration is
smaller (no DTO/repository code references a field that doesn't exist
yet). Migration 052 **has** been applied to the live database already
(confirmed via `get_advisors` — same pre-existing INFO/WARN posture as
every other table, no new issues). The bigger open risk is the
undocumented `/wallets/topups` response shape described above — that
needs a real sandbox account to close, not a code change.
