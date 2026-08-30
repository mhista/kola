# Gate 13 — Reconciliation

Status: **BUILT**. Payment-to-order matching, demonstrable across every
gateway this codebase syncs (Paystack, Flutterwave, Stripe, Monnify,
Fincra) plus manually confirmed bank transfers, against till Sales. This
is the capability Rev 5's own Part V used to justify the whole business-
graph build: *"₦180,000 from six customers has not been matched to any
order... money the business has and does not know what to do with.
Paystack cannot see this; it sees payments, not conversations [or
orders]."*

## Not the same "reconciliation" already in this codebase

Worth stating plainly, because the word was already in use nearby.
`PaymentTransactionRepository.listForReconciliation` and
`ManualPaymentService`'s reminder sweep reconcile a CLAIMED bank
transfer against a gateway's own confirmation — payment-transaction-
to-payment-transaction, one table, `gateway == 'bank_transfer'` only.
Gate 13 is a different, wider thing: matching a CONFIRMED payment (any
gateway) against a till Sale — two different tables, the graph
correlation Rev 5 actually asked for. Both now coexist under the name
"reconciliation"; each file's own header cross-references the other so
this isn't rediscovered as confusion later.

## What was built

1. **Migration 053** — `payment_transactions.sale_id`, nullable,
   `references sales(id) on delete set null`, indexed. Applied to the
   live database and verified clean via `get_advisors` (same pre-
   existing INFO/WARN posture as every other table, no new issues).
2. **`payment_transaction.spy.yaml`** gained the `saleId` field — and
   because `serverpod generate` cannot run in this environment, the
   generated model (`lib/src/generated/payment_transaction.dart`) was
   hand-edited to match: constructor, factory, `fromJson`, field
   declaration, `toJson`/`toJsonForProtocol`, and both `copyWith`
   overrides. Same drill as Monnify's `encryptedApiKey` field earlier
   in Gate 11 — a real build risk until `serverpod generate` actually
   runs, flagged below, not silently assumed fine.
3. **`PaymentTransactionRepository`** gained
   `listCompletedByWorkspaceAndRange` (any gateway, a bounded window,
   both matched and unmatched rows in one query) and `setSaleId`.
4. **`PaymentReconciliationService`** (new,
   `lib/src/services/billing/`) — the matching logic itself. Given a
   workspace: fetch completed payments and sales in a 14-day window,
   attempt deterministic links, return what's still unmatched.
5. **`WorkspaceSweepService`** gained a new detector,
   `_detectPaymentReconciliation` — the one detector in that file that
   WRITES (runs the actual matching pass) before reporting, flagged
   explicitly in its own comment since every sibling detector there is
   a pure read. Unmatched money above zero becomes a `payment_unmatched`
   finding, which the existing "Needs your attention" surface renders
   with no dashboard code changes — `overview_page.dart`'s finding
   renderer is generic by kind/subjectType and already has honest
   fallbacks ("Take a look", no link) for a kind it has no specific
   mapping for.
6. **`finding_kinds.dart`** gained `paymentUnmatched`, severity 2
   (alongside `ticketDueSoon`/`productOutOfStock` — real money the
   owner can't currently place, but not a promise already broken to a
   named person).

## The matching rule — deterministic, and why auto-link is safe here

A payment is a candidate match for a sale only when: same currency,
**exact** amount (no tolerance — a partial or over-payment is a real
discrepancy worth surfacing, not something to paper over), sold within
48 hours of when the payment actually landed, and neither side's
resolved `customerId` contradicts the other's (either side being null
does not block a match — a walk-in till entry can still match the one
payment that landed at the right amount and moment). A payment links
**only** when its candidate sale is unambiguous both ways: exactly one
sale fits the payment, and no other still-unmatched payment fits that
same sale equally well.

This is a lighter safety bar than customer-identity merging gets
elsewhere in this codebase (Rev 5: *"merges are proposals, not
facts"*), and deliberately so: a wrong customer merge silently combines
two people's order histories with no error message for it; a wrong
payment-to-sale link is cheap to notice (a mismatched amount or
customer is visible on the sale) and cheap to reverse (clear one
column). Auto-linking on certainty was the right call for this risk
level, not a shortcut past the review-queue pattern.

## Real, named scope cuts

- **14-day matching window, not all history.** `FindingEndpoint
  .listFindings` runs the full sweep — now including this matching pass
  — on every dashboard Overview load (see `finding_endpoint.dart`'s own
  header on why: no scheduler exists yet). An unbounded query and
  in-memory match would break that "handful of indexed reads" cost
  model every other detector already honors. Money that goes unmatched
  longer than the window stops being actively re-attempted, though the
  finding keeps reporting whatever falls inside the rolling window from
  "now." Worth widening (or moving to a real scheduled job) if a real
  workspace shows this window being too short — not designed away
  speculatively.
- **No dashboard route for the new finding kind.** `overview_page.dart`
  routes findings to a page per `kind` for a handful of cases
  (`no_channel_connected` → `/integrations`, etc.); `payment_unmatched`
  has no such mapping because no dedicated Sales/Reports route exists
  in `nav_model.dart` to point it at — inventing one would be exactly
  the "model chooses a URL" mistake Rev 5's own rules forbid. The
  finding still renders correctly with the generic fallback action
  ("Take a look", no broken link). A real Sales/reconciliation page is
  follow-up work, not part of this gate.
- **Amount must match exactly.** A customer who pays ₦500 short, or a
  till entry rung up for the wrong amount, will not auto-link — by
  design, since blurring that with a tolerance would hide a real
  discrepancy rather than surface it. It still counts toward the
  unmatched total, which is the honest outcome.
- **Not wired into `WorkspaceAnswerService`'s digests.** The Gate 12
  public/dashboard Q&A surface does not yet have a dedicated
  reconciliation digest to answer "what payments haven't I accounted
  for" directly in conversation — the finding on the Overview is the
  only surface today. A natural follow-up given Gate 12 already ships,
  not built this pass to keep this gate's diff to the graph-correlation
  claim itself.

## Verification note

Same limitation as every gate this session: no Dart toolchain here, so
none of this compiled locally. This gate's hand-edited generated model
makes `dart pub get && serverpod generate` more than routine — a build
before regenerating references `PaymentTransaction.saleId` from several
files (DTO, repository, service) that assume it exists, so it will fail
loudly rather than silently miss the field, same posture Gate 11's
Monnify work left this codebase in. Migration 053 has been applied to
the live database and confirmed clean.
