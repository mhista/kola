# Gate 9 — Broadcast messaging: status

Scope for this pass, per explicit user choice: **core queue engine only, no dashboard UI.**

## Built

- `broadcasts` / `broadcast_recipients` / `message_suppressions` tables (migration 049).
- `BroadcastRepository`, `BroadcastRecipientRepository`, `MessageSuppressionRepository`.
- `BroadcastSweepService` — the engine. Runs every 15s (`server.dart`), works through every
  `running` broadcast's `queued` recipients in throughput-paced batches, checks suppression
  at send time (not audience-build time), retries a failure up to 3 attempts before marking
  `failed`, and marks a broadcast `completed` once nothing is left `queued`/`sending`.
  Reuses `OutboundMessageService.send()` (Gate 8) per recipient — same conversation/customer
  linking, same `Message` persistence, same `message_sent` event emission, and the same
  idempotency mechanism, now keyed `broadcast:<id>:<recipientId>`.
- `BroadcastEndpoint` — `createBroadcast` / `startBroadcast` / `cancelBroadcast` /
  `listBroadcasts` / `getBroadcastProgress` / `listSuppressions` / `addSuppression` /
  `removeSuppression`. Dashboard-session-authenticated, gated on the existing
  `messaging.broadcast` flag. No dashboard screen calls these yet.

## Resumable, paced, cancellable, priority — how each spec requirement is actually met

- **Resumable**: all progress lives in `broadcast_recipients.state`, never in process memory.
  A crash loses nothing; the next tick just re-queries for `state = 'queued'`.
- **Paced**: `throughputPerMinute` on the broadcast → a per-15s batch size.
- **Cancellable**: `cancelBroadcast` sets `status = 'cancelled'`; the sweep only ever looks at
  `running` broadcasts, so a cancelled one is silently skipped from the next tick on. No recall
  of what already sent.
- **Priority lanes**: not runtime-arbitrated — Gate 8's `POST /v1/messages` sends are a
  completely separate code path that never touches `broadcast_recipients`, so a broadcast can
  structurally never block a transactional send.

## Deliberately not built in this pass (named gaps, not silent ones)

- **No dashboard UI.** Everything above is only reachable by calling `BroadcastEndpoint`
  directly.
- **No graph-based audience builder.** Recipients are supplied directly by the caller as a
  JSON array of addresses at `createBroadcast` time — not "customers who bought in June and
  haven't returned."
- **No WhatsApp template selection.** Same free-text-only scope cut Gate 8 made. A broadcast
  sent outside WhatsApp's 24h window will fail per-recipient with a real error, not silently.
- **No dry-run mode, no approval workflow.**
- **No delivered/read tracking.** This codebase's WhatsApp webhook route already discards
  status-update payloads (see `whatsapp_bot_registry.dart`) — "delivered"/"read" states would
  be fiction until that's wired, so recipient state stops at `sent`.
- **No automatic STOP-keyword listener.** `message_suppressions` exists and is checked, but
  every row today is added manually (`reason = 'manual'`) — nothing yet listens for a customer
  replying "STOP" and suppresses them automatically.
- **No WhatsApp quality-tier check before sending.** `throughputPerMinute` defaults to a fixed,
  conservative 20/min rather than anything read from the number's actual current limits.
- **Retry policy is a single fixed policy (3 attempts, then `failed`)**, not the spec's
  "rate-limited retries, invalid number doesn't" — the messaging adapters don't expose a
  machine-readable failure classification to build that on yet.

## Before this is usable

`dart pub get && serverpod generate` in `kola_server`, apply migration 049, then redeploy.
