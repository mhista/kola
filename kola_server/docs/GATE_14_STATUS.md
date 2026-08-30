# Gate 14 — Automated Evals

Status: **PARTIAL, and honestly so.** Rev 5 Part VIII's own wording:
"Automated evals: retrieval accuracy, attribution, permission
enforcement, SQL safety, cross-tenant isolation, send compliance."
Real, runnable `dart test` coverage now exists — three new files, 40
tests — for the highest-value pieces of that list that are actually
reachable without either a live database or a refactor this pass
didn't invent unasked. The rest of the list is named below as an open
gap, not silently declared done.

## The constraint this gate runs into that others didn't

Every prior gate this session hit "no Dart toolchain in this sandbox,
so none of this compiled locally" as a verification caveat — real, but
secondary to the gate's own work. Gate 14's entire *subject* is test
coverage, so the same constraint is load-bearing here in a different
way: this pass could not run `dart test` even once to confirm these
new files actually pass. They're written to the same conventions as
this codebase's one prior real test file
(`test/text_chunker_test.dart`, Phase 9 — "THE FIRST REAL AUTOMATED
TESTS IN THIS CODEBASE"), reviewed line by line against the real
implementations they test, but "reviewed" is not "run." A human with
`dart test test/` needs to be the one to actually turn this green.

## What was built

Three new files under `test/`, following `text_chunker_test.dart`'s
established shape (pure `package:test`, no mocks, no database, a header
explaining what isn't covered and why):

1. **`test/payment_reconciliation_service_test.dart`** (17 tests) —
   Gate 13's matching rule, the thing Rev 5's own Part V used to
   justify the whole business-graph build. `PaymentReconciliationService
   ._match` and `._distinctCustomerCount` were renamed to `isMatch` /
   `distinctCustomerCount` and made public *specifically* so this file
   could call them directly with plain `PaymentTransaction`/`Sale`
   instances — no behavior change, same private logic, just visible
   enough to test for real. Covers: exact amount/currency matching, the
   48-hour time-tolerance boundary (both edges, both directions),
   customer-identity non-contradiction (both-null, one-null-one-known,
   both-known-agreeing, both-known-conflicting), the `paidAt ?? createdAt`
   fallback, and `distinctCustomerCount`'s "+1 for unidentified, not
   one-per-anonymous-payment" rule.
2. **`test/customer_identity_resolver_test.dart`** (11 tests) — the
   near-miss fixture set Rev 5's testing-requirements section names
   explicitly: "same name different phone, same phone different name,
   shared family email." `CustomerIdentityResolver.resolve()` itself
   takes three concrete, non-interfaced repositories and can't be
   exercised without a database (see gap list below) — what's testable
   without one is the normalization layer every match actually depends
   on: `normalizePhone`, `normalizeEmail`, `normalizeName`,
   `normalizePlatformUser`. Includes a deliberately-negative test
   (`family@example.com` vs `family+dad@example.com` must NOT
   normalize equal) and a documented limitation (`08035551234` vs
   `+2348035551234` are NOT unified by this helper alone — asserted
   explicitly so a future change to the normalization rule shows up
   here as an intentional decision, not a silent behavior change).
3. **`test/security_filter_test.dart`** (23 tests) — the item Rev 5's
   checklist names by exact word: "SQL safety." `SecurityFilter` is
   pure (in-memory rate-limit state only, no DB, no network), covering
   all three checkpoints (`checkInboundMessage`, `checkErrandInput`,
   `checkOutboundText`): SQL injection, prompt injection, XSS,
   credential leakage, phishing, and spam/repetition detection — each
   with both a positive case (the pattern fires) and, where it matters
   most, a negative case (ordinary business language containing the
   bare word "insert" or "refund" must NOT false-positive — a filter
   that also blocks legitimate customers is its own class of bug this
   codebase has no other test guarding against). Also covers per-user
   rate limiting (under threshold, over threshold, and that one busy
   user does not block a different one) and confirms `warningMessage`
   never echoes the offending content back.

## Real, named gaps — Rev 5's checklist items NOT covered by this pass

- **Retrieval accuracy.** `text_chunker_test.dart` (pre-existing) covers
  chunking, not retrieval — that needs a live Gemini key or a fake
  `EmbeddingProvider`, which its own header already named as future
  work before this session started.
- **Attribution.** No automated test that a `WorkspaceAnswer`'s
  citations actually point at the chunks that produced the answer —
  same live-embedding dependency as retrieval accuracy.
- **Permission enforcement.** `Errand.permissionScope` gating and API
  key scope gating (Gate 12's `full`/`read_only`/`errands_only`) are
  both real, both load-bearing, and both untested here — they're
  authorization checks inside endpoint/route code that talk to a
  database and a session, not pure functions with an obvious seam to
  test in isolation the way `SecurityFilter` has.
- **Cross-tenant isolation "per connector, not once globally,"** per
  Rev 5's own wording. This needs either a live database with two real
  workspaces or fake repositories behind an interface. Every
  `*Repository` class in this codebase (`PaymentTransactionRepository`,
  `SaleRepository`, `CustomerRepository`, etc.) is concrete and talks to
  Supabase directly — there is no `abstract class` seam to implement a
  fake against today. Introducing one would be a real, cross-cutting
  refactor of the repository layer, not a Gate 14 side effect — named
  here as the single biggest thing standing between this codebase and
  Rev 5's cross-tenant-isolation testing bar, not attempted
  speculatively.
- **Replay and idempotency** ("ingest the same payload twice and assert
  one entity, not two"). `EventBus`'s fingerprint deduplication is
  already exercised — but by `tool/test_event_bus.dart`, a live-Supabase
  manual harness printing output for a human to read, not a `dart test`
  assertion. Converting it would need the same fake-repository seam as
  cross-tenant isolation.
- **Failure states** (expired token, revoked access, rate limit,
  malformed payload, provider outage) **per connector.** `SecurityFilter`
  now has real rate-limit tests; the other four failure modes are
  connector-specific and live inside adapters
  (`paystack_adapter.dart`, `monnify_adapter.dart`, etc.) that make real
  HTTP calls — same live-network dependency the existing
  `tool/test_connectors.dart` harness already carries.
- **Send compliance** (WhatsApp template constraints, Rev 5 Part VI).
  No automated test exists for template-shape validation before an
  outbound send; not investigated this pass.

## What this means, plainly

This gate moves the codebase from "zero automated coverage of the
things that most determine whether kola is trustworthy with money and
input" to "the pure, seam-having pieces of that list are covered for
real, and everything still blocked on the repository-interface gap is
named instead of assumed." The `tool/` manual harnesses remain exactly
as useful as they were — this doesn't replace them, since they're the
only thing today that exercises the live-database and live-network
paths at all. Full coverage of Rev 5's checklist is realistically a
follow-up gate of its own (repository interfaces + fakes), not
something this pass could honestly close in one diff.

## Verification note

Not run. No Dart toolchain in this sandbox, same limitation as every
gate this session — see this file's own second section. `dart test
test/` from `kola_server/` is the next real step, by a human, before
any of this can be called green rather than "reviewed and believed
correct."
