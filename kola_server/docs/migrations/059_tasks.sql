-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 059 — Phase 13b: Tasks page/backend)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers task.spy.yaml — see its header for the full rationale (in
-- particular: why `assignee` is free text and not a real member link,
-- and why `source_finding_id` only ever points at recommendation/
-- observation findings, never operations). This file is the schema
-- itself, not the reasoning trail.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists tasks (
  id                 bigserial primary key,
  workspace_id       bigint not null references workspaces(id) on delete cascade,
  title              text not null,
  status             text not null default 'todo'
                       check (status in ('todo', 'in_progress', 'done')),
  priority           text not null default 'medium'
                       check (priority in ('high', 'medium', 'low')),

  -- Which subsystem this task originated from, if any — a free-text
  -- label, not a strict enum, since 'operation' tasks today have no
  -- single backing table to point at (a task can come from a
  -- conversation, a support ticket, or just be typed in by hand). See
  -- task.spy.yaml's header.
  source_type        text
                       check (source_type is null or source_type in ('recommendation', 'observation', 'operation')),

  -- Only ever populated when source_type is 'recommendation' or
  -- 'observation' — both are backed by the same workspace_findings
  -- table (WorkspaceFinding), so one column covers both. Null for
  -- 'operation' or manually-created tasks.
  source_finding_id  bigint references workspace_findings(id) on delete set null,

  -- Free text (an initial or a name), not a foreign key to a member
  -- table — this codebase has no per-task assignment/member-picker
  -- infrastructure yet. See task.spy.yaml's header on why this is an
  -- honest simplification rather than a silently invented feature.
  assignee           text,

  due_at             timestamptz,
  completed_at       timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index if not exists tasks_workspace_idx on tasks (workspace_id);
create index if not exists tasks_status_idx on tasks (status);
create index if not exists tasks_source_finding_idx on tasks (source_finding_id);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger tasks_updated_at
  before update on tasks for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5). RLS enabled
-- with zero policies blocks the anon key from touching any of this
-- outright.
alter table tasks enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
