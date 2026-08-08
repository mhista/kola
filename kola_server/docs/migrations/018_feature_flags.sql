-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 018 — Phase 10: Release Control)
--
-- Apply AFTER 001–017.
--
-- THE MODEL: Kola builds everything, then releases in phases. A feature
-- is deployed to production in 'locked' state — fully built, fully
-- running, entirely invisible — and later flipped to 'beta' for chosen
-- workspaces, then 'released' for everyone. Unlocking is a state change
-- made from kola_admin. Nothing is deployed at unlock time.
--
-- WHICH features exist is defined in Dart (feature_keys.dart). This
-- schema owns WHAT STATE each one is in. The seed at the bottom creates
-- one row per declared key.
--
-- See docs/RELEASE_PHASES.md for what each of R1–R7 contains and why the
-- order is what it is.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── INTERNAL WORKSPACE FLAG ──────────────────────────────────────────────────
-- Read by FeatureFlagService when a feature is in 'internal' state — the
-- dogfooding stage between "built" and "shown to a single customer".
--
-- Settable ONLY from kola_admin. A customer-reachable path that could
-- mint an internal workspace would unlock every unreleased feature on
-- the platform and make this whole system decorative.
alter table workspaces
  add column if not exists is_internal boolean not null default false;

-- ── FEATURE FLAGS ────────────────────────────────────────────────────────────
create table if not exists feature_flags (
  id               bigserial primary key,
  key              text not null unique,
  name             text not null,
  description      text not null,
  state            text not null default 'locked'
                     check (state in   ('locked', 'Locked', 'Capability flag.', 'released')),
  -- null = every plan; 'pro' = paid plans only. Deliberately separate
  -- from `state`: state answers "has this shipped", minimum_plan answers
  -- "do we charge for it". Collapsing them would make it impossible to
  -- run a paid feature in beta, which is what a design-partner
  -- programme has to do.
  minimum_plan     text check (minimum_plan is null or minimum_plan in ('pro','business')),
  release_phase    text not null check (release_phase in ('R1','R2','R3','R4','R5','R6','R7')),
  -- True when the feature is blocked on something outside the product —
  -- an auditor's report, a signed BAA, a Meta App Review approval. No
  -- workspace override can switch these on early.
  externally_gated boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists feature_flag_phase_idx on feature_flags (release_phase);

-- ── WORKSPACE OVERRIDES ──────────────────────────────────────────────────────
-- Two directions, both load-bearing:
--   enabled = true  → this workspace sees something others don't (beta)
--   enabled = false → this workspace does NOT see something everyone
--                     else does (per-workspace kill switch after a bug,
--                     without punishing the whole platform)
--
-- `note` is NOT NULL on purpose. An unexplained override found six
-- months later cannot be safely removed, so the schema refuses to
-- create one.
create table if not exists workspace_feature_overrides (
  id           bigserial primary key,
  workspace_id bigint not null references workspaces(id) on delete cascade,
  feature_key  text not null references feature_flags(key) on delete cascade,
  enabled      boolean not null,
  note         text not null,
  created_by   text not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (workspace_id, feature_key)
);

create index if not exists workspace_feature_override_workspace_idx
  on workspace_feature_overrides (workspace_id);
create index if not exists workspace_feature_override_feature_idx
  on workspace_feature_overrides (feature_key);

-- ── SEED ─────────────────────────────────────────────────────────────────────
-- One row per key declared in FeatureKeys.
--
-- CRITICAL: `on conflict (key) do update` deliberately does NOT touch
-- `state`. Re-running this seed after a later deploy must never silently
-- re-lock a feature that has already been released to customers. Only
-- the descriptive columns are refreshed; state is owned by kola_admin
-- from the moment the row exists.
-- ─────────────────────────────────────────────────────────────────────────────
-- SEED CONTENT NOTE
--
-- `name` and `description` below are short, neutral placeholders. They are
-- NOT the copy shown in the admin dashboard.
--
-- Two reasons:
--   1. This repository is public. Marketing-quality descriptions of
--      capabilities that have not shipped would publish a forward view
--      of capabilities to anyone reading the repo.
--   2. `name` and `description` are admin-editable content once a row
--      exists. A migration should create the row, not own its copy
--      forever.
--
-- Accordingly the `on conflict` clause below deliberately updates ONLY the
-- structural columns (minimum_plan, release_phase, externally_gated). It
-- never touches `state`, `name` or `description` — so re-running this seed
-- after a deploy can neither re-lock a live capability nor overwrite copy
-- an admin has since written.
-- ─────────────────────────────────────────────────────────────────────────────

insert into feature_flags (key, name, description, state, minimum_plan, release_phase, externally_gated) values
  -- ── R1 — FOUNDATION (released at first public launch) ──────────────────────
    ('bots.core', 'Bots', 'Capability flag.', 'released', null, 'R1', false),
    ('channels.whatsapp', 'Whatsapp', 'Capability flag.', 'released', null, 'R1', false),
    ('channels.telegram', 'Telegram', 'Capability flag.', 'released', null, 'R1', false),
    ('conversations.inbox', 'Inbox', 'Capability flag.', 'released', null, 'R1', false),
    ('conversations.escalation', 'Escalation', 'Capability flag.', 'released', null, 'R1', false),
    ('memory.documents', 'Documents', 'Capability flag.', 'released', null, 'R1', false),
    ('memory.retrieval', 'Retrieval', 'Capability flag.', 'released', null, 'R1', false),
    ('memory.inspector', 'Inspector', 'Capability flag.', 'released', null, 'R1', false),
    ('errands.builtin', 'Builtin', 'Capability flag.', 'released', null, 'R1', false),
    ('billing.core', 'Billing', 'Capability flag.', 'released', null, 'R1', false),
    ('notifications.owner', 'Owner', 'Capability flag.', 'released', null, 'R1', false),

  -- ── R2 — VISIBILITY ────────────────────────────────────────────────────────
    ('platform.event_bus', 'Event bus', 'Capability flag.', 'locked', null, 'R2', false),
    ('timeline.core', 'Timeline', 'Capability flag.', 'locked', null, 'R2', false),
    ('customers.core', 'Customers', 'Capability flag.', 'locked', null, 'R2', false),
    ('operations.core', 'Operations', 'Capability flag.', 'locked', null, 'R2', false),
    ('operations.support_tickets', 'Support tickets', 'Capability flag.', 'locked', null, 'R2', false),
    ('payments.collect', 'Collect', 'Capability flag.', 'locked', 'pro', 'R2', false),

  -- ── R3 — INTELLIGENCE ──────────────────────────────────────────────────────
    ('intelligence.observations', 'Observations', 'Capability flag.', 'locked', 'pro', 'R3', false),
    ('intelligence.recommendations', 'Recommendations', 'Capability flag.', 'locked', 'pro', 'R3', false),
    ('intelligence.dashboards', 'Dashboards', 'Capability flag.', 'locked', 'pro', 'R3', false),
    ('intelligence.analytics', 'Analytics', 'Capability flag.', 'locked', 'pro', 'R3', false),
    ('intelligence.forecasting', 'Forecasting', 'Capability flag.', 'locked', 'pro', 'R3', false),

  -- ── R4 — DELEGATION ────────────────────────────────────────────────────────
    ('agents.core', 'Agents', 'Capability flag.', 'locked', 'pro', 'R4', false),
    ('agents.sales', 'Sales', 'Capability flag.', 'locked', 'pro', 'R4', false),
    ('agents.support', 'Support', 'Capability flag.', 'locked', 'pro', 'R4', false),
    ('agents.finance', 'Finance', 'Capability flag.', 'locked', 'pro', 'R4', false),
    ('agents.inventory', 'Inventory', 'Capability flag.', 'locked', 'pro', 'R4', false),
    ('automations.workflows', 'Workflows', 'Capability flag.', 'locked', 'pro', 'R4', false),
    ('automations.approvals', 'Approvals', 'Capability flag.', 'locked', 'pro', 'R4', false),
    ('tasks.core', 'Tasks', 'Capability flag.', 'locked', null, 'R4', false),

  -- ── R5 — REACH (several externally gated on Meta approval) ─────────────────
    ('channels.messenger', 'Messenger', 'Capability flag.', 'locked', null, 'R5', true),
    ('channels.instagram', 'Instagram', 'Capability flag.', 'locked', null, 'R5', true),
    ('channels.email', 'Email', 'Capability flag.', 'locked', null, 'R5', false),
    ('messaging.broadcast', 'Broadcast', 'Capability flag.', 'locked', 'pro', 'R5', true),
    ('connectors.commerce', 'Commerce', 'Capability flag.', 'locked', 'pro', 'R5', false),
    ('connectors.storage', 'Storage', 'Capability flag.', 'locked', 'pro', 'R5', false),
    ('connectors.accounting', 'Accounting', 'Capability flag.', 'locked', 'pro', 'R5', false),
    ('connectors.calendar', 'Calendar', 'Capability flag.', 'locked', 'pro', 'R5', false),
    ('connectors.crm', 'Crm', 'Capability flag.', 'locked', 'pro', 'R5', false),

  -- ── R6 — PLATFORM ──────────────────────────────────────────────────────────
    ('platform.public_api', 'Public api', 'Capability flag.', 'locked', 'pro', 'R6', false),
    ('platform.webhooks_outbound', 'Webhooks outbound', 'Capability flag.', 'locked', 'pro', 'R6', false),
    ('platform.developer_portal', 'Developer portal', 'Capability flag.', 'locked', 'pro', 'R6', false),
    ('errands.webhook', 'Webhook', 'Capability flag.', 'locked', 'pro', 'R6', false),
    ('errands.db_credential', 'Db credential', 'Capability flag.', 'locked', 'pro', 'R6', false),

  -- ── R7 — ENTERPRISE (mostly gated on real-world artefacts, not code) ───────
    ('enterprise.sso', 'Sso', 'Capability flag.', 'locked', 'business', 'R7', true),
    ('enterprise.audit_log', 'Audit log', 'Capability flag.', 'locked', 'business', 'R7', false),
    ('enterprise.data_residency', 'Data residency', 'Capability flag.', 'locked', 'business', 'R7', true),
    ('enterprise.advanced_roles', 'Advanced roles', 'Capability flag.', 'locked', 'business', 'R7', false),
    ('enterprise.agency_workspaces', 'Agency workspaces', 'Capability flag.', 'locked', 'pro', 'R7', false)
on conflict (key) do update set
  minimum_plan     = excluded.minimum_plan,
  release_phase    = excluded.release_phase,
  externally_gated = excluded.externally_gated,
  updated_at       = now();
-- state / name / description deliberately absent — see the note above.

-- ── RLS ──────────────────────────────────────────────────────────────────────
-- Same deny-all posture as every other table: reached only through the
-- server's service_role client, isolation enforced in the repository
-- layer. feature_flags is platform state, not tenant data, and is never
-- read by an anon or authenticated key.
alter table feature_flags               enable row level security;
alter table workspace_feature_overrides enable row level security;
