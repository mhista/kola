-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 054 — kola_admin, steps 1-2 of
-- ADMIN_APP_SPEC.md's build order)
--
-- Apply AFTER 001–053.
--
-- Two tables, and ONLY these two — see ADMIN_APP_SPEC.md §5: "Steps 1 and
-- 2 are not negotiable as a starting point." Admin identity first, then
-- the audit log wired BEFORE any mutating admin endpoint exists — a log
-- retrofitted after the fact has an unrecorded early history exactly
-- when the most consequential platform-wide changes were being made.
--
-- DELIBERATELY SEPARATE FROM WORKSPACE-SCOPED AUTH: admin identity is
-- Kola staff, not a workspace member with a flag — see ADMIN_APP_SPEC.md
-- §1/§2. There must be no path by which registering as a customer can
-- result in admin access. admin_users has no foreign key to workspaces
-- or workspace_members, on purpose.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── ADMIN USERS ──────────────────────────────────────────────────────────────
-- No self-registration, ever — a row here is created by an existing
-- admin (or, for the very first account, by hand against this table
-- directly). password_hash is PBKDF2-HMAC-SHA256, salted, stored as
-- "iterations:base64(salt):base64(hash)" — see admin_password_hasher.dart
-- for why this scheme rather than bcrypt (no bcrypt package is a
-- reachable dependency in this environment; PBKDF2 via pointycastle,
-- already a direct dependency for AES-256-GCM elsewhere in this
-- codebase, is a real, correct choice, not a placeholder).
--
-- HONEST GAP, STATED HERE RATHER THAN HIDDEN: ADMIN_APP_SPEC.md §2 says
-- MFA is "required. Not optional, not encouraged." mfa_enabled exists as
-- a real column so the schema doesn't need a second migration once real
-- TOTP is wired up, but no TOTP verification exists yet in this pass —
-- see admin_auth_service.dart's header for the same caveat stated where
-- a reader will actually hit it.
create table if not exists admin_users (
  id            bigserial primary key,
  email         text not null unique,
  password_hash text not null,
  -- 'support' | 'operator' | 'owner' — see ADMIN_APP_SPEC.md §2's table.
  level         text not null check (level in ('support', 'operator', 'owner')),
  mfa_enabled   boolean not null default false,
  active        boolean not null default true,
  last_seen_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists admin_user_email_idx on admin_users (email);

-- ── ADMIN AUDIT LOG ──────────────────────────────────────────────────────────
-- Append-only. No update/delete path exists anywhere in this codebase
-- for this table, and none should ever be added — an editable audit log
-- is not an audit log. before_value/after_value are free-form JSON text
-- rather than typed columns because every admin action shapes its own
-- before/after differently (a flag state string, a plan name, a
-- suspended boolean) and forcing one shape onto all of them would either
-- lose information or bloat this table with mostly-null columns.
create table if not exists admin_audit_log (
  id                bigserial primary key,
  actor_email       text not null,
  actor_level       text not null,
  -- e.g. 'feature.state_change', 'feature.override_grant',
  -- 'feature.override_revoke', 'feature.wave_release'. A stable
  -- dot-namespaced action key, same convention as FeatureKeys, so a
  -- later admin UI can group/filter the log the same way it groups
  -- feature flags.
  action            text not null,
  -- Which workspace this action touched, if any. Null for platform-wide
  -- actions (a feature flag's state is not a workspace's data).
  target_workspace_id bigint references workspaces(id) on delete set null,
  target_feature_key  text,
  before_value      text,
  after_value       text,
  note              text,
  ip_address        text,
  created_at        timestamptz not null default now()
);

create index if not exists admin_audit_log_actor_idx on admin_audit_log (actor_email);
create index if not exists admin_audit_log_workspace_idx on admin_audit_log (target_workspace_id);
create index if not exists admin_audit_log_created_idx on admin_audit_log (created_at);

-- ── RLS ──────────────────────────────────────────────────────────────────────
-- Same deny-all posture as every other table in this project — reached
-- only through the server's service_role client (specifically, only
-- from kola_admin-authenticated endpoint methods, never from the
-- customer-facing server's normal request path).
alter table admin_users     enable row level security;
alter table admin_audit_log enable row level security;
