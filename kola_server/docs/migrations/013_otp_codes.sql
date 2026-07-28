-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 013 — Phase 8b: OTP delivery via email)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers otp_code.spy.yaml — see its header for the full rationale (in
-- particular: why this is conversation-scoped rather than user-scoped
-- like asami_server's equivalent, and why a new row is inserted per
-- code rather than updating one in place). This file is the schema
-- itself, not the reasoning trail.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists otp_codes (
  id                bigserial primary key,
  workspace_id      bigint not null references workspaces(id) on delete cascade,
  conversation_id   bigint not null references conversations(id) on delete cascade,
  recipient_email   text not null,
  code              text not null,
  expires_at        timestamptz not null,
  attempts          int not null default 0,
  verified_at       timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists otp_code_workspace_idx on otp_codes (workspace_id);
create index if not exists otp_code_conversation_idx on otp_codes (conversation_id);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger otp_codes_updated_at
  before update on otp_codes for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as every prior migration: kola_server always talks to
-- Supabase with the service_role key (bypasses RLS); our repository
-- layer enforces workspace isolation instead (SRS.md §5). RLS enabled
-- with zero policies blocks the anon key from touching any of this
-- outright.
alter table otp_codes enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
