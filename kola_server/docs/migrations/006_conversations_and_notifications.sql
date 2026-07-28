-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 006 — escalation feature:
-- Conversation/Message + owner notification system)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers conversation.spy.yaml, message.spy.yaml,
-- owner_notification_settings.spy.yaml, owner_notification_send.spy.yaml —
-- see each for the full rationale behind its fields; this file is the
-- schema itself, not the reasoning trail.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── CONVERSATIONS ────────────────────────────────────────────────────────────
create table if not exists conversations (
  id                bigserial primary key,
  workspace_id      bigint not null references workspaces(id) on delete cascade,
  bot_id            bigint not null references bots(id) on delete cascade,
  channel_id        bigint not null references channels(id) on delete cascade,
  platform_type     text not null check (platform_type in ('telegram', 'whatsapp')),
  external_user_id  text not null,
  display_name      text,
  status            text not null default 'bot'
                       check (status in ('bot', 'escalated', 'closed')),
  last_message_at   timestamptz not null default now(),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists conversation_workspace_idx on conversations (workspace_id);
create unique index if not exists conversation_channel_external_user_idx
  on conversations (channel_id, external_user_id);
create index if not exists conversation_status_idx on conversations (status);

-- ── MESSAGES ─────────────────────────────────────────────────────────────────
create table if not exists messages (
  id               bigserial primary key,
  conversation_id  bigint not null references conversations(id) on delete cascade,
  direction        text not null check (direction in ('inbound', 'outbound')),
  sender_type      text not null check (sender_type in ('customer', 'bot', 'human')),
  body             text not null,
  created_at       timestamptz not null default now()
);

create index if not exists message_conversation_idx on messages (conversation_id);

-- ── OWNER NOTIFICATION SETTINGS ──────────────────────────────────────────────
-- One row per workspace (1:1, unique index below) — see
-- owner_notification_settings.spy.yaml's header for the four-channels/
-- three-implemented-today rationale.
create table if not exists owner_notification_settings (
  id                       bigserial primary key,
  workspace_id             bigint not null references workspaces(id) on delete cascade,
  owner_email              text,
  email_enabled            boolean not null default false,
  owner_whatsapp_number    text,
  whatsapp_enabled         boolean not null default false,
  telegram_chat_id         text,
  telegram_enabled         boolean not null default false,
  owner_sms_number         text,
  sms_enabled              boolean not null default false,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);

create unique index if not exists owner_notification_settings_workspace_idx
  on owner_notification_settings (workspace_id);

-- ── OWNER NOTIFICATION SENDS ─────────────────────────────────────────────────
-- Append-only log purely for NotificationRateLimiter's per-plan daily
-- caps — see notification_rate_limiter.dart.
create table if not exists owner_notification_sends (
  id            bigserial primary key,
  workspace_id  bigint not null references workspaces(id) on delete cascade,
  channel       text not null check (channel in ('email', 'whatsapp', 'telegram', 'sms')),
  sent_at       timestamptz not null default now()
);

create index if not exists owner_notification_send_workspace_channel_idx
  on owner_notification_sends (workspace_id, channel);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger conversations_updated_at
  before update on conversations for each row execute function update_updated_at();
create or replace trigger owner_notification_settings_updated_at
  before update on owner_notification_settings for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5). RLS enabled
-- with zero policies blocks the anon key from touching any of this
-- outright.
alter table conversations                 enable row level security;
alter table messages                      enable row level security;
alter table owner_notification_settings   enable row level security;
alter table owner_notification_sends      enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
