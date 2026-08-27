# Gate 10 — Reply capacity: reply-absorption slice

Status: **PARTIAL, by explicit scope choice.** Rev 5 Part VIII defines
Gate 10 as "Graph-segmented audiences, approval, dry run — AND the agent
absorbs the resulting reply wave without flooding a human." This pass
built only the second half — the part most likely to actually bite an
owner once broadcasts are running (Gate 9, shipped earlier this session).
The audience-builder/approval/dry-run half is a deliberate, separate cut,
not an oversight.

## What "reply-absorption" means here

Before this change: `InboundMessageHandler` (the single choke point for
every inbound WhatsApp/Telegram message, organic or broadcast-triggered)
already ran every reply through the customer-facing AI
(`BotKnowledgeService.decide()`), and escalated to a human exactly the
same way regardless of origin — one `OwnerNotificationDispatcher
.notifyEscalation` call per escalated conversation. A broadcast that
prompts a burst of ambiguous replies in a short window meant a burst of
individual notifications, capped only by `NotificationRateLimiter`'s
*daily* limit (3 WhatsApp/day on the free plan) — after which further
escalations went completely silent, with no visibility that they were
even happening, let alone that they traced back to one broadcast.

## What was built

1. **Migration 050** — `conversations.broadcast_id` (FK → broadcasts,
   nullable) and `broadcasts.escalated_reply_count` /
   `broadcasts.last_digest_sent_at`.
2. **Tagging at send time, not reply time** — `OutboundMessageService
   .send()` gained an optional `broadcastId` param. `broadcast_sweep_
   service.dart` (Gate 9's per-recipient sender) now passes its own
   broadcast's id on every send, which tags the recipient's conversation
   the moment the broadcast message goes out — no lookup needed later
   when the reply arrives.
3. **`BroadcastReplyDigestService`** (new) — when an escalation happens
   on a broadcast-tagged conversation, `InboundMessageHandler` routes
   through this instead of the plain notifier:
   - 1st escalated reply for a broadcast → notifies immediately, same as
     an organic escalation always has.
   - Further escalated replies within a 15-minute cooldown → counted
     (`broadcasts.escalated_reply_count`), no notification fires.
   - The next one after the cooldown elapses → notifies again, this time
     reporting the running total, and resets the cooldown.
4. Repository support: `ConversationRepository.setBroadcast`,
   `BroadcastRepository.incrementEscalatedReplyCount` /
   `.markDigestSent`.

Net effect: a quiet broadcast (0–1 escalations) behaves exactly as
before. A loud one gets an immediate heads-up followed by at most one
notification per 15 minutes with an accurate running total, instead of
either one-per-reply flooding or (once the daily cap hit) total silence.

## What was deliberately NOT built (still open against Gate 10)

- **Graph-segmented audiences.** `BroadcastEndpoint.createBroadcast`
  still takes a raw recipient list from the caller — no "customers who
  bought X in the last 30 days" style selection against the business
  graph.
- **Approval workflow / dry run.** A broadcast still goes straight from
  `draft` to `running` on `startBroadcast` — no preview-and-approve step.
- **No dashboard visibility into reply volume per broadcast.** The
  running count lives on `broadcasts.escalated_reply_count` and shows up
  in the digest notification's text, but there's no UI surfacing "this
  broadcast has 14 open replies" — an owner has to open the inbox and
  triage manually once notified.
- **Cooldown is a fixed 15 minutes, not tunable per plan/workspace.**

## Verification note

Everything here depends on `Conversation.broadcastId` and
`Broadcast.escalatedReplyCount`/`lastDigestSentAt` existing on the
generated Dart models — which requires `serverpod generate` to run
against the updated `.spy.yaml` files (same limitation noted for every
gate this session: no Dart toolchain in this environment). Migration 050
also needs to be applied to the live database before any of this can
work — it has NOT been applied yet, only written.
