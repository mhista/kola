-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 049 — Gate 9: broadcast queue engine)
--
-- Apply AFTER 048.
--
-- Three tables backing the core broadcast queue engine — see
-- lib/src/models/broadcast.spy.yaml, broadcast_recipient.spy.yaml and
-- message_suppression.spy.yaml for the full reasoning behind each field.
-- No new feature flag needed: gated on the existing 'messaging.broadcast'
-- key (FeatureKeys.broadcast, seeded 'locked' in migration 018).
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists broadcasts (
  id                     bigserial primary key,
  workspace_id           bigint not null references workspaces(id),
  platform               text not null check (platform in ('whatsapp', 'telegram')),
  text                   text not null,
  status                 text not null default 'draft'
                           check (status in ('draft', 'running', 'paused', 'cancelled', 'completed')),
  throughput_per_minute  int not null default 20,
  total_recipients       int not null default 0,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  started_at             timestamptz,
  completed_at           timestamptz
);

create index if not exists broadcast_workspace_idx on broadcasts (workspace_id);
create index if not exists broadcast_status_idx on broadcasts (status);

create table if not exists broadcast_recipients (
  id                 bigserial primary key,
  broadcast_id       bigint not null references broadcasts(id) on delete cascade,
  workspace_id       bigint not null references workspaces(id),
  "to"               text not null,
  customer_id        bigint references customers(id),
  variables_json     text,
  state              text not null default 'queued'
                       check (state in ('queued', 'sending', 'sent', 'failed', 'skipped')),
  attempt_count      int not null default 0,
  last_error         text,
  message_id         bigint references messages(id),
  last_attempted_at  timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index if not exists broadcast_recipient_broadcast_idx on broadcast_recipients (broadcast_id);
create unique index if not exists broadcast_recipient_broadcast_to_idx on broadcast_recipients (broadcast_id, "to");
create index if not exists broadcast_recipient_state_idx on broadcast_recipients (state);

create table if not exists message_suppressions (
  id                    bigserial primary key,
  workspace_id          bigint not null references workspaces(id),
  platform              text not null check (platform in ('whatsapp', 'telegram')),
  address_normalized    text not null,
  reason                text not null default 'manual' check (reason in ('manual', 'stop_keyword')),
  created_at            timestamptz not null default now()
);

create unique index if not exists message_suppression_lookup_idx
  on message_suppressions (workspace_id, platform, address_normalized);

-- RLS enabled, no policies — deny-all to PostgREST, matching every table
-- in this project since migration 001. The repository layer (Supabase
-- service-role client) IS the isolation boundary. Missed in this
-- migration's original apply; added here and backfilled live via
-- Supabase's own security advisory — see PART IX's non-negotiable rule.
alter table broadcasts enable row level security;
alter table broadcast_recipients enable row level security;
alter table message_suppressions enable row level security;
