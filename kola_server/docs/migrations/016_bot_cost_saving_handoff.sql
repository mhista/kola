-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 016 — cost-saving channel handoff,
-- addressing Meta's Oct 1, 2026 WhatsApp per-message pricing change)
--
-- Apply in Supabase dashboard → SQL Editor (or `supabase db push --include-all`
-- if you're using the Supabase CLI locally).
--
-- Covers two new optional columns on `bots` — see bot.spy.yaml for the
-- full rationale. This file is the schema itself, not the reasoning
-- trail.
-- ─────────────────────────────────────────────────────────────────────────────

alter table bots add column if not exists cost_saving_telegram_link text;
alter table bots add column if not exists cost_saving_alternate_whatsapp text;
