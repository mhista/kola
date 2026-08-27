-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 048 — Gate 8 feature flag)
--
-- Apply AFTER 047.
--
-- Adds the 'messaging.send' capability key declared in feature_keys.dart
-- (FeatureKeys.messagingSend) for POST /v1/messages — the public,
-- API-key-authenticated single-send outbound messaging endpoint. Same
-- structure and same guarantees as 018/019 — see 018's SEED CONTENT NOTE
-- for why `name`/`description` are neutral placeholders and why the `on
-- conflict` clause never touches state, name or description.
--
-- Ships 'locked' — built and deployed, invisible until unlocked from
-- kola_admin per workspace/beta, same as every other capability in this
-- table. No new tables: Gate 8 reuses conversations/messages/channels/
-- api_keys as-is.
-- ─────────────────────────────────────────────────────────────────────────────

insert into feature_flags (key, name, description, state, minimum_plan, release_phase, externally_gated) values
    ('messaging.send', 'Messaging send', 'Capability flag.', 'locked', 'pro', 'R6', false)
on conflict (key) do update set
  minimum_plan     = excluded.minimum_plan,
  release_phase    = excluded.release_phase,
  externally_gated = excluded.externally_gated,
  updated_at       = now();
-- state / name / description deliberately absent from the update — see
-- 018's note.
