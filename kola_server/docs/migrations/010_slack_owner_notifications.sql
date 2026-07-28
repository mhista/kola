-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 010 — Phase 8h / task #129: Slack
-- owner-notification channel)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Adds Slack as a fifth owner-notification channel, alongside WhatsApp/
-- Telegram/email/SMS already on owner_notification_settings (see
-- 006_conversations_and_notifications.sql). See
-- owner_notification_settings.spy.yaml's header for why the webhook URL
-- itself is encrypted (it's a bearer secret, not a plain recipient
-- address like ownerWhatsappNumber/telegramChatId) and why Slack is
-- deliberately uncapped in notification_rate_limiter.dart.
--
-- Convention: never edit old migrations, add a new numbered one.
-- ─────────────────────────────────────────────────────────────────────────────

alter table owner_notification_settings
  add column if not exists encrypted_slack_webhook_url text,
  add column if not exists slack_enabled boolean not null default false;
