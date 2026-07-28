-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 014 — task #150: programmatic WhatsApp
-- message templates)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers whatsapp_message_template.spy.yaml — see its header for the full
-- rationale (in particular: why this only matters for OUT-OF-WINDOW sends,
-- and why 'utility' is requested by default). This file is the schema
-- itself, not the reasoning trail.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists whatsapp_message_templates (
  id                  bigserial primary key,
  workspace_id        bigint not null references workspaces(id) on delete cascade,
  channel_id          bigint not null references channels(id) on delete cascade,
  meta_template_name  text not null,
  requested_category  text not null check (requested_category in ('utility', 'marketing', 'authentication')),
  meta_category       text check (meta_category in ('utility', 'marketing', 'authentication')),
  language            text not null,
  body_text           text not null,
  meta_template_id    text,
  status              text not null default 'pending'
                        check (status in ('pending', 'approved', 'rejected', 'disabled')),
  rejection_reason     text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index if not exists whatsapp_template_workspace_idx on whatsapp_message_templates (workspace_id);
create index if not exists whatsapp_template_channel_idx on whatsapp_message_templates (channel_id);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger whatsapp_message_templates_updated_at
  before update on whatsapp_message_templates for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5). RLS enabled
-- with zero policies blocks the anon key from touching any of this
-- outright.
alter table whatsapp_message_templates enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
