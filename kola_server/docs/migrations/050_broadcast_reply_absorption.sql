-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 050 — Gate 10: reply-absorption slice)
--
-- Apply AFTER 049.
--
-- Rev 5 Part VIII, Gate 10: "the agent absorbs the resulting reply wave
-- without flooding a human." This migration carries the two pieces of
-- state that make that possible:
--
--   conversations.broadcast_id — which Broadcast (if any) this thread's
--   customer was sent, set at broadcast SEND time by
--   outbound_message_service.dart (reused by broadcast_sweep_service.dart
--   — see that file's header on why the same send() path serves both
--   Gate 8 single sends and Gate 9 broadcast sends). This is what lets
--   inbound_message_handler.dart recognise "this escalation is a reply to
--   a broadcast" instead of treating every reply as an unrelated,
--   individually-notified event.
--
--   broadcasts.escalated_reply_count / last_digest_sent_at — running
--   state for broadcast_reply_digest_service.dart's coalescing: the first
--   escalated reply to a broadcast notifies immediately, later ones
--   within a cooldown window are folded into a running count instead of
--   each firing their own notification, and a fresh notification with the
--   up-to-date total goes out once the cooldown elapses. See that
--   service's header for the exact rule.
-- ─────────────────────────────────────────────────────────────────────────────

alter table conversations
  add column if not exists broadcast_id bigint references broadcasts(id);

create index if not exists conversations_broadcast_idx on conversations (broadcast_id);

alter table broadcasts
  add column if not exists escalated_reply_count int not null default 0;

alter table broadcasts
  add column if not exists last_digest_sent_at timestamptz;

-- No RLS changes needed — both tables already have RLS enabled with no
-- policies (conversations since migration 001-era work, broadcasts since
-- 049/049b) and a new column on an already-locked-down table inherits
-- that posture automatically; there's nothing to add here.
