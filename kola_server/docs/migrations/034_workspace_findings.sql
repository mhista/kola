-- 034_workspace_findings.sql
--
-- ── WHAT A FINDING IS ────────────────────────────────────────────────
--
-- One thing kola noticed about a workspace that the owner might want to
-- act on: a product out of stock, a conversation waiting, a document
-- that failed to index.
--
-- The design shows these as "Needs your attention" and "Top
-- recommendation". Neither has existed — the Overview has been rendering
-- an attention list computed inline from whatever the page happened to
-- have loaded, which is why it could only ever mention conversations.
--
-- ── WHY A TABLE AND NOT A COMPUTATION ────────────────────────────────
--
-- Recomputing on every page load would be less code, and it cannot
-- express the three things that make this useful:
--
--   SINCE WHEN.   "Out of stock" is a fact. "Out of stock for six days"
--                 is the one an owner acts on. That needs first_seen_at,
--                 which needs a row that survives the page.
--   DISMISSED.    Telling kola "I know, leave it" has to stick. A
--                 computed list forgets, so the same item returns on the
--                 next load and the owner learns to ignore the section.
--   ELSEWHERE.    A finding that only exists while someone is looking at
--                 the Overview can never become a WhatsApp nudge, a
--                 Monday digest, or a Timeline entry. Those are separate
--                 features, but they are separate READERS of this table
--                 rather than three more scans.
--
-- ── STABLE IDENTITY IS THE WHOLE DESIGN ──────────────────────────────
--
-- `fingerprint` is what makes a finding the SAME finding across sweeps.
-- It is derived from the kind and the subject — 'product_out_of_stock:41'
-- — never from the wording, which changes as the template improves, and
-- never from the count, which changes daily.
--
-- Get this wrong and the table becomes an append-only log of
-- near-duplicates: the same out-of-stock product appearing once per
-- sweep, each with its own dismissed flag, none of them ever settling.
--
-- The unique index is on (workspace_id, fingerprint) and the sweep
-- UPSERTS. So re-running it is idempotent, first_seen_at survives, and
-- dismissal survives with it.
--
-- ── RESOLVED, NOT DELETED ────────────────────────────────────────────
--
-- When an owner restocks, the finding is marked resolved rather than
-- removed. Deleting would lose the answer to "how long was that out of
-- stock, and how quickly did I fix it?" — which is the question the
-- Timeline exists to answer, and it costs one column to keep.

create table if not exists workspace_findings (
  id              bigserial primary key,
  workspace_id    bigint not null references workspaces(id) on delete cascade,

  -- What kind of thing this is. Deliberately a text code rather than an
  -- enum type: adding a new detector should be a deploy, not a migration
  -- plus a deploy. The set lives in finding_kinds.dart.
  kind            text   not null,

  -- Stable identity within a workspace. See the header.
  fingerprint     text   not null,

  -- 1 = highest. An integer rather than 'high'/'medium'/'low' so ordering
  -- is total and a detector can slot between two existing levels without
  -- renaming anything.
  severity        int    not null default 3,

  -- Owner-facing wording, rendered from a template at sweep time.
  --
  -- STORED rather than re-rendered on read, because it must match the
  -- moment it describes. "3 products low on stock" re-rendered a week
  -- later against today's data would silently rewrite history, and the
  -- Timeline would show an entry that never happened.
  title           text   not null,
  detail          text,

  -- What the finding is ABOUT, so the dashboard can link to it and the
  -- sweep can re-check it. Nullable: some findings are about the
  -- workspace itself rather than one row.
  subject_type    text,
  subject_id      bigint,

  -- Deterministic detectors are certain by construction, so this is 1.0
  -- for everything today. Present because the design shows a confidence
  -- on recommendations, and because a later AI-authored recommendation
  -- must be visibly less certain than "this product has 0 stock" rather
  -- than sitting beside it looking equally solid.
  confidence      double precision not null default 1.0,

  first_seen_at   timestamptz not null default now(),
  last_seen_at    timestamptz not null default now(),

  -- Set when the underlying condition goes away. See the header.
  resolved_at     timestamptz,

  -- Set when the owner says "I know". Survives every later sweep.
  dismissed_at    timestamptz,

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- The upsert target. Also the guarantee that a sweep cannot duplicate a
-- finding no matter how many times it runs or how many workers run it.
create unique index if not exists workspace_findings_identity_idx
  on workspace_findings (workspace_id, fingerprint);

-- The Overview's read: open findings for one workspace, worst first,
-- oldest first within a severity — so the thing that has been wrong
-- longest wins a tie, which is the one most likely to be forgotten.
create index if not exists workspace_findings_open_idx
  on workspace_findings (workspace_id, severity, first_seen_at)
  where resolved_at is null and dismissed_at is null;

-- RLS ON WITH NO POLICIES, matching every other table here: the server
-- connects as the table owner and the repository layer is the isolation
-- boundary. A policy-less RLS table is unreachable by anon/authenticated
-- keys, which is the intent — nothing should read this except kola.
alter table workspace_findings enable row level security;
