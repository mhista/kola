-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 043 — workspace answer turns)
--
-- Apply AFTER 042.
--
-- Connect Gate, subphase 4g — CONFIRMED WITH THE USER: the owner
-- dashboard's "Ask kola" box (WorkspaceAnswerService) was fully
-- stateless. Every call to askWorkspace() saw ONLY the current
-- question — no memory of what was just asked a moment ago — so a
-- follow-up like "and the second one?" had nothing to resolve "the
-- second one" against, and read as kola "resetting" after every turn.
--
-- This table is the fix: a short, persisted transcript per workspace.
-- ONE rolling thread per workspace, not per logged-in user — same
-- "single owner" assumption OwnerNotificationSettingsRepository and
-- friends already make elsewhere in this codebase. If a workspace ever
-- gets real multi-user seats, this needs a user_id column added; not
-- pretended today.
--
-- WHY A NEW TABLE AND NOT conversations/messages: those are scoped to a
-- (workspace, bot, channel, external customer) — a CUSTOMER's
-- conversation with the business. The owner asking their own dashboard
-- a question is a different kind of thing entirely, and forcing it
-- through that shape would make Operations' "customer conversations"
-- list start showing the owner talking to themselves. A small,
-- dedicated table is the honest fit.
--
-- BOUNDED, NOT UNBOUNDED: WorkspaceAnswerTurnRepository trims each
-- workspace down to its most recent N rows right after every insert —
-- this is short-term conversational memory (what was just asked), not
-- a permanent transcript archive. Nothing here is meant to answer "what
-- did I ask kola three months ago."

create table if not exists workspace_answer_turns (
    id            bigserial   primary key,
    workspace_id  bigint      not null references workspaces (id) on delete cascade,

    -- 'user' | 'assistant' — plain OpenAI-style role naming, matching
    -- how [_recentTurnsBlock] below renders these back into a prompt.
    role          text        not null check (role in ('user', 'assistant')),

    content       text        not null,

    created_at    timestamptz not null default now()
);

create index if not exists workspace_answer_turns_workspace_created_idx
    on workspace_answer_turns (workspace_id, created_at desc);

-- RLS enabled, no policies — deny-all to PostgREST, matching every table
-- in this project since migration 001.
alter table workspace_answer_turns enable row level security;
-- ─────────────────────────────────────────────────────────────────────────────
