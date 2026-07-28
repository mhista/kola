-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 001 — initial, Phase 1c core domain models)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers the four core domain models from DEVELOPMENT_PLAN.md Phase 1c:
-- Workspace (tenant root), WorkspaceMember (user↔workspace + role),
-- Bot (a configured bot instance), Channel (a connected messaging channel).
-- Exact field-by-field rationale lives in each model's .spy.yaml
-- (kola_server/lib/src/models/) and DTO (kola_server/lib/src/services/dto/)
-- — this file is the schema itself, not the reasoning trail.
--
-- THIS IS THE FIRST MIGRATION — nothing to roll forward from. Later schema
-- changes get their own numbered file here (002, 003, ...), same convention
-- already proven in degenbot_server/docs/migrations/.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── WORKSPACES ───────────────────────────────────────────────────────────────
create table if not exists workspaces (
  id                        bigserial primary key,
  name                      text not null,
  industry_tag              text,
  plan                      text not null default 'free'
                              check (plan in ('free', 'pro', 'business')),
  status                    text not null default 'trialing'
                              check (status in ('trialing', 'active', 'paused')),
  trial_started_at          timestamptz not null default now(),
  trial_full_access_ends_at timestamptz not null,
  trial_ends_at             timestamptz not null,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

create index if not exists workspace_status_idx on workspaces (status);

-- ── WORKSPACE MEMBERS ────────────────────────────────────────────────────────
-- user_id is a Supabase Auth UUID, not our own bigserial scheme — see
-- workspace_member.spy.yaml's header comment for why identity and
-- membership are deliberately decoupled.
create table if not exists workspace_members (
  id           bigserial primary key,
  workspace_id bigint not null references workspaces(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  role         text not null default 'staff'
                 check (role in ('owner', 'staff', 'developer')),
  created_at   timestamptz not null default now(),
  unique (workspace_id, user_id)
);

create index if not exists workspace_member_workspace_idx on workspace_members (workspace_id);
create index if not exists workspace_member_user_idx      on workspace_members (user_id);

-- ── BOTS ─────────────────────────────────────────────────────────────────────
create table if not exists bots (
  id           bigserial primary key,
  workspace_id bigint not null references workspaces(id) on delete cascade,
  name         text not null,
  archetype    text not null default 'customerCare'
                 check (archetype in ('customerCare', 'catalog', 'custom')),
  status       text not null default 'draft'
                 check (status in ('draft', 'live', 'paused')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists bot_workspace_idx on bots (workspace_id);

-- ── CHANNELS ─────────────────────────────────────────────────────────────────
-- encrypted_credential holds ciphertext only — see channel.spy.yaml's header
-- comment. Nothing in this schema decrypts it; that's a Phase 2 service.
create table if not exists channels (
  id                    bigserial primary key,
  bot_id                bigint not null references bots(id) on delete cascade,
  platform_type         text not null
                          check (platform_type in ('telegram', 'whatsapp')),
  display_name          text,
  encrypted_credential  text,
  status                text not null default 'pending'
                          check (status in ('pending', 'connected', 'disconnected')),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create index if not exists channel_bot_idx on channels (bot_id);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- Same trigger pattern already proven in degenbot_server's migration 001 —
-- reused as-is rather than reinvented.
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace trigger workspaces_updated_at
  before update on workspaces for each row execute function update_updated_at();
create or replace trigger bots_updated_at
  before update on bots for each row execute function update_updated_at();
create or replace trigger channels_updated_at
  before update on channels for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- kola_server always talks to Supabase with the service_role key, which
-- bypasses RLS — our repository layer enforces workspace isolation instead
-- (SRS.md §5). No dashboard/browser code calls these four tables directly
-- (unlike waitlist_signups in migration 002), so for now we simply enable
-- RLS with zero policies — that fully blocks the anon key from touching
-- tenant data outright, and it costs nothing to have on from day one.
alter table workspaces        enable row level security;
alter table workspace_members enable row level security;
alter table bots              enable row level security;
alter table channels          enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
