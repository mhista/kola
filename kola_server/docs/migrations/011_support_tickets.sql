-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 011 — Phase 8b / task #130: complaint
-- ticketing with SLA tracking)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers support_ticket.spy.yaml — see its header for the full rationale
-- (in particular: how a ticket differs from an escalated Conversation,
-- and how slaDeadline is computed). This file is the schema itself, not
-- the reasoning trail.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists support_tickets (
  id               bigserial primary key,
  workspace_id     bigint not null references workspaces(id) on delete cascade,
  conversation_id  bigint not null references conversations(id) on delete cascade,
  subject          text not null,
  description      text not null,
  priority         text not null check (priority in ('low', 'medium', 'high', 'urgent')),
  status           text not null default 'open'
                     check (status in ('open', 'inProgress', 'resolved', 'closed')),
  sla_deadline     timestamptz not null,
  resolved_at      timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists support_ticket_workspace_idx on support_tickets (workspace_id);
create index if not exists support_ticket_conversation_idx on support_tickets (conversation_id);
create index if not exists support_ticket_status_idx on support_tickets (status);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger support_tickets_updated_at
  before update on support_tickets for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5). RLS enabled
-- with zero policies blocks the anon key from touching any of this
-- outright.
alter table support_tickets enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
