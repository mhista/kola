-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 005 — Phase 3b: Errand system +
-- minimal knowledge seed)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers the three Errand models from SRS.md §6/§7 (Errand,
-- ErrandCredential, ErrandExecutionLog) plus a minimal `knowledge_seed`
-- column on `bots` — see errand.spy.yaml / errand_credential.spy.yaml /
-- errand_execution_log.spy.yaml / bot.spy.yaml for the full rationale
-- behind each field; this file is the schema itself, not the reasoning
-- trail.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── MINIMAL KNOWLEDGE SEED (Phase 3, bot.spy.yaml) ───────────────────────────
alter table bots add column if not exists knowledge_seed text;

-- ── ERRANDS ──────────────────────────────────────────────────────────────────
create table if not exists errands (
  id                        bigserial primary key,
  workspace_id              bigint not null references workspaces(id) on delete cascade,
  name                      text not null,
  description_for_ai        text not null,
  source                    text not null default 'builtin'
                              check (source in ('builtin', 'webhook', 'dbCredential', 'mcp')),
  builtin_handler_key       text,
  created_via               text not null default 'naturalLanguage'
                              check (created_via in ('naturalLanguage', 'api')),
  permission_scope          text not null default 'readOnly'
                              check (permission_scope in ('readOnly', 'readWrite')),
  input_schema_json         text not null default '{}',
  sensitive_input_keys_json text not null default '[]',
  status                    text not null default 'active'
                              check (status in ('active', 'disabled')),
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

create index if not exists errand_workspace_idx on errands (workspace_id);

-- ── ERRAND CREDENTIALS ───────────────────────────────────────────────────────
-- encrypted_credential holds ciphertext only — see
-- errand_credential.spy.yaml's header comment. A 'builtin' Errand never
-- gets a row here.
create table if not exists errand_credentials (
  id                    bigserial primary key,
  errand_id             bigint not null references errands(id) on delete cascade,
  encrypted_credential  text not null,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create unique index if not exists errand_credential_errand_idx on errand_credentials (errand_id);

-- ── ERRAND EXECUTION LOGS ────────────────────────────────────────────────────
create table if not exists errand_execution_logs (
  id             bigserial primary key,
  errand_id      bigint not null references errands(id) on delete cascade,
  workspace_id   bigint not null references workspaces(id) on delete cascade,
  input_json     text not null default '{}',
  result_json    text,
  success        boolean not null,
  error_message  text,
  latency_ms     integer not null,
  executed_at    timestamptz not null default now()
);

create index if not exists errand_execution_log_errand_idx on errand_execution_logs (errand_id);
create index if not exists errand_execution_log_workspace_idx on errand_execution_logs (workspace_id);

-- ── AUTO-UPDATE updated_at ───────────────────────────────────────────────────
-- update_updated_at() already exists from migration 001 — reused, not
-- redefined.
create or replace trigger errands_updated_at
  before update on errands for each row execute function update_updated_at();
create or replace trigger errand_credentials_updated_at
  before update on errand_credentials for each row execute function update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Same reasoning as migration 001: kola_server always talks to Supabase
-- with the service_role key (bypasses RLS); our repository layer enforces
-- workspace isolation instead (SRS.md §5). RLS enabled with zero policies
-- blocks the anon key from touching any of this outright.
alter table errands                enable row level security;
alter table errand_credentials     enable row level security;
alter table errand_execution_logs  enable row level security;
-- (no policies = anon is blocked entirely; service_role bypasses RLS)
