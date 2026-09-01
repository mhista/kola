-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 061 — knowledge feed toggle)
--
-- Apply AFTER 060.
--
-- ── NAME SAYS "content_hash" TOO, BUT THAT PART DOESN'T NEED A SCHEMA CHANGE ──
--
-- The content-hash dedupe engine (this migration's other stated goal) turns
-- out to already exist: `content_hash` (017), `knowledge_document_hash_idx`
-- (017), and `KnowledgeDocumentRepository.findByContentHash` (used by
-- DocumentIngestionService.ingestText, BEFORE embedding) already skip
-- re-embedding byte-identical text on every path that creates a NEW
-- document row. What was actually missing is fixed in Dart, not SQL: see
-- document_ingestion_service.dart's `reindex` — it deleted and re-embedded
-- unconditionally on every call, even when the new text hashed identically
-- to what was already indexed. That path is hit on every "regenerate from
-- catalog" press (knowledge_page.dart's _generateFrom) and every connector
-- re-sync (ingestFromConnector), which is exactly the recurring waste this
-- migration was meant to close. Fixed by hashing the incoming text with the
-- same normalization ingestText uses and comparing against the existing
-- row's content_hash before touching a single chunk or calling the embedder.
-- Kept this file's name as originally planned so the migration number
-- matches what was tracked, even though its SQL body is feed-toggle only.
--
-- ── THE ACTUAL SCHEMA CHANGE: FEED TOGGLE ────────────────────────────────────
--
-- An owner has a document worth keeping (an old price list, a draft policy)
-- but does not want kola answering FROM it right now — without deleting it,
-- which would lose the content and any audit trail. superseded_by (024) is
-- the wrong tool: it means "replaced by a specific other document" and is
-- NEVER set by the owner directly (see 024's header — supersession is a
-- proposal ingestion makes, the owner confirms, never a manual switch). This
-- is the plain manual on/off that doesn't exist yet.
--
-- DEFAULT TRUE, NOT FALSE. Every document ingested before this migration is
-- already answering questions. Defaulting to false would silently turn
-- every workspace's bot dumb the instant this runs — the exact "vanishes
-- from answers with no explanation" failure knowledge_document.spy.yaml's
-- supersededBy comment already warns against, just triggered by a schema
-- change instead of a guess.
-- ─────────────────────────────────────────────────────────────────────────────

alter table knowledge_documents
  add column if not exists feeding_enabled boolean not null default true;

comment on column knowledge_documents.feeding_enabled is
  'Manual owner switch. False means this document is EXCLUDED from retrieval '
  'even though it is still indexed and still shown on the Knowledge page — '
  'kept, just not used to answer. Independent of status and superseded_by.';

-- ── BOTH RETRIEVAL RPCs REDEFINED TO RESPECT THE TOGGLE ──────────────────────
--
-- match_knowledge_chunks (017) is not on the live answer path today —
-- KnowledgeChunkRepository.searchSimilar calls hybrid_match_knowledge_chunks
-- only — but it is kept in the schema per its own "for callers that
-- genuinely want semantics alone" note, and a caller that starts using it
-- must not be the one path that ignores the toggle.
--
-- No return-type change on either function, so `create or replace` is
-- sufficient — no drop required (see 033's header for when a drop actually
-- is needed: a widened RETURNS TABLE, not the case here).

create or replace function match_knowledge_chunks (
  p_workspace_id    bigint,
  p_query_embedding vector(768),
  p_embedding_model text,
  p_match_count     int default 6,
  p_min_similarity  float default 0.3
)
returns table (
  id             bigint,
  document_id    bigint,
  document_title text,
  chunk_index    int,
  content        text,
  token_estimate int,
  similarity     float
)
language sql
stable
set search_path = public, extensions
as $$
  select
    kc.id,
    kc.document_id,
    kd.title as document_title,
    kc.chunk_index,
    kc.content,
    kc.token_estimate,
    1 - (kc.embedding <=> p_query_embedding) as similarity
  from knowledge_chunks kc
  join knowledge_documents kd on kd.id = kc.document_id
  where kc.workspace_id = p_workspace_id
    and kc.embedding is not null
    and kc.embedding_model = p_embedding_model
    and kd.status = 'indexed'
    and kd.feeding_enabled = true
    and 1 - (kc.embedding <=> p_query_embedding) >= p_min_similarity
  order by kc.embedding <=> p_query_embedding
  limit p_match_count;
$$;

-- Same body as the 033 definition of hybrid_match_knowledge_chunks; the
-- `live` CTE gains one more filter, and nothing else changes.
create or replace function hybrid_match_knowledge_chunks (
  p_workspace_id     bigint,
  p_query_embedding  vector,
  p_query_text       text,
  p_embedding_model  text,
  p_match_count      int,
  p_min_similarity   double precision
)
returns table (
  id              bigint,
  document_id     bigint,
  document_title  text,
  chunk_index     int,
  content         text,
  token_estimate  int,
  similarity      double precision,
  matched_by      text
)
language sql
stable
set search_path = public, extensions
as $$
  with q as (
    select websearch_to_tsquery(
      'simple', regexp_replace(coalesce(p_query_text, ''), '[-_/]+', ' ', 'g')
    ) as tsq
  ),
  -- Chunks of documents that have not been superseded (024) AND that the
  -- owner has not switched off (061). Applied to both arms, same reasoning
  -- as 033's own superseded_by filter: a toggled-off document must not stay
  -- reachable through the keyword arm while the vector arm respects it.
  live as (
    select kc.id, kc.embedding, kc.content_tsv, kd.effective_from
    from knowledge_chunks kc
    join knowledge_documents kd on kd.id = kc.document_id
    where kc.workspace_id = p_workspace_id
      and kc.embedding_model = p_embedding_model
      and kd.superseded_by is null
      and kd.feeding_enabled = true
  ),
  vector_arm as (
    select l.id,
           row_number() over (order by l.embedding <=> p_query_embedding) as rank
    from live l
    where l.embedding is not null
      and 1 - (l.embedding <=> p_query_embedding) >= p_min_similarity
    order by l.embedding <=> p_query_embedding
    limit p_match_count * 2
  ),
  keyword_arm as (
    select l.id,
           row_number() over (order by ts_rank(l.content_tsv, q.tsq) desc) as rank
    from live l, q
    where q.tsq is not null
      and l.content_tsv @@ q.tsq
    order by ts_rank(l.content_tsv, q.tsq) desc
    limit p_match_count * 2
  ),
  fused as (
    select coalesce(v.id, k.id) as id,
           coalesce(1.0 / (60 + v.rank), 0.0)
             + coalesce(1.0 / (60 + k.rank), 0.0) as rrf_score,
           case
             when v.id is not null and k.id is not null then 'both'
             when v.id is not null then 'meaning'
             else 'keyword'
           end as matched_by
    from vector_arm v
    full outer join keyword_arm k on v.id = k.id
  )
  select kc.id,
         kc.document_id,
         kd.title as document_title,
         kc.chunk_index,
         kc.content,
         kc.token_estimate,
         coalesce((1 - (kc.embedding <=> p_query_embedding)), 0)::double precision
           as similarity,
         f.matched_by
  from fused f
  join knowledge_chunks kc on kc.id = f.id
  join knowledge_documents kd on kd.id = kc.document_id
  order by f.rrf_score desc, kd.effective_from desc nulls last
  limit p_match_count;
$$;
