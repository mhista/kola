-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 007 — Phase 3c: webhook + database-
-- credential Errand types)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Only one schema change: 'webhook' and 'dbCredential' Errands reuse the
-- existing `errands`/`errand_credentials` tables from migration 005 —
-- ErrandCredential.encryptedCredential already generically holds
-- whatever JSON blob a Errand's fulfillment type needs (see
-- webhook_errand_credential.dart / db_credential_errand_credential.dart).
-- The only new column is the pre-approved query template a dbCredential
-- Errand is allowed to run — see errand.spy.yaml's queryTemplateSql
-- field header for the full "never an open SQL console" rationale.
-- ─────────────────────────────────────────────────────────────────────────────

alter table errands add column if not exists query_template_sql text;
