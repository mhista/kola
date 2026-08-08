-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 024 — document supersession + recency)
--
-- Apply AFTER 023. APPLIED AND VERIFIED against Supabase.
--
-- ── THE PROBLEM ──────────────────────────────────────────────────────────────
--
-- An owner uploads "Price list — July", then in August uploads "Price list —
-- August". Both are indexed. Both match "how much is the ankara". Retrieval
-- has no notion of which is current, so kola quotes July's prices with full
-- confidence — the worst kind of wrong answer, because it is well-sourced.
--
-- ── TWO MECHANISMS, DELIBERATELY SEPARATE ────────────────────────────────────
--
--   superseded_by   An EXPLICIT statement that one document replaces another.
--                   Superseded documents are excluded from retrieval entirely.
--                   Kept in the table rather than deleted: "what did we charge
--                   in July" is a real question, and an audit trail that
--                   deletes itself is not an audit trail.
--
--   effective_from  When the content started being true. Defaults to
--                   created_at, but an owner uploading August prices on the
--                   3rd can say they applied from the 1st.
--
-- ── WHY RECENCY IS A TIEBREAK, NOT A WEIGHT ──────────────────────────────────
--
-- A recency weight needs a half-life constant nobody can justify, and it
-- pushes genuinely relevant old documents below vaguely relevant new ones. A
-- returns policy written in 2024 is not less true for being old.
--
-- So recency only decides between results retrieval ALREADY rates equally:
-- `order by rrf_score desc, effective_from desc`. Relevance first, always.
--
-- ── WHAT THIS DOES NOT SOLVE ─────────────────────────────────────────────────
--
-- DETECTING supersession. Setting the column is easy; knowing that "Price
-- list — August" replaces "Price list — July" is the hard half, and it is
-- deliberately NOT automated here.
--
-- Auto-superseding on a title heuristic would silently hide a document the
-- owner still wanted, and they would have no way to know why kola stopped
-- citing it. The intended flow is: ingestion notices a likely replacement
-- (same source type, high title similarity, overlapping content) and ASKS.
-- A wrong guess the owner confirms is recoverable; a wrong guess applied
-- silently is not.
-- ─────────────────────────────────────────────────────────────────────────────

alter table knowledge_documents
  add column if not exists effective_from timestamptz;

alter table knowledge_documents
  add column if not exists superseded_by bigint
  references knowledge_documents(id) on delete set null;

update knowledge_documents set effective_from = created_at where effective_from is null;
alter table knowledge_documents alter column effective_from set default now();

comment on column knowledge_documents.superseded_by is
  'The document that replaces this one. Non-null means EXCLUDED from retrieval. Retained rather than deleted so historical questions still resolve.';
comment on column knowledge_documents.effective_from is
  'When this content started being true. Retrieval tiebreak only, never a weight.';

alter table knowledge_documents drop constraint if exists knowledge_documents_no_self_supersede;
alter table knowledge_documents add constraint knowledge_documents_no_self_supersede
  check (superseded_by is null or superseded_by <> id);

create index if not exists knowledge_document_current_idx
  on knowledge_documents (workspace_id, effective_from desc)
  where superseded_by is null;

-- The RPC is redefined in full by this migration so that BOTH arms read from
-- one `live` CTE. Filtering only the vector arm would leave keyword search as
-- the single path that still returns superseded prices — and that path is
-- exactly the one an "order 4471" query takes.
--
-- See the applied definition in Supabase, or migration 023 for the fusion
-- logic itself. The only change here is the `live` CTE and the ORDER BY
-- tiebreak.
