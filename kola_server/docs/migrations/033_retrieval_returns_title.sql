-- 033_retrieval_returns_title.sql
--
-- ── RETRIEVAL HAS BEEN FAILING 100% OF THE TIME SINCE 023 ────────────────────
--
-- Every call logged:
--
--   MemoryRetrievalService: Retrieval failed for workspace 12:
--   type 'Null' is not a subtype of type 'String' in type cast
--
-- The cause is a contract mismatch, not a data problem.
-- KnowledgeChunkRepository.searchSimilar reads six fields off each row:
--
--   id  document_id  document_title  chunk_index  content  token_estimate
--
-- hybrid_match_knowledge_chunks returns six columns too, but not the same
-- six:
--
--   id  document_id  chunk_index  content  similarity  matched_by
--
-- So `map['document_title'] as String` casts null on the FIRST row of
-- every single search, and `token_estimate` would have failed straight
-- after it. Migration 017's RPC returned the title; 023 replaced that
-- function with the hybrid one and dropped the column, and the Dart was
-- never updated to match.
--
-- ── WHY THIS WAS INVISIBLE FOR SO LONG ───────────────────────────────────────
--
-- MemoryRetrievalService.retrieve catches everything and returns empty
-- context, deliberately: "a customer waiting on WhatsApp gets a worse
-- reply, not an error". That is the right behaviour and it is also what
-- hid this. The bot kept answering — from the legacy knowledgeSeed
-- fallback — so the SYMPTOM was not an error page, it was kola answering
-- every question from the same stale seed text no matter what the owner
-- uploaded. Which is exactly what was reported.
--
-- Newly uploaded documents were being chunked and embedded correctly the
-- whole time. Nothing could ever read them back.
--
-- ── THE FIX IS IN THE FUNCTION, NOT THE DART ─────────────────────────────────
--
-- Both fields are genuinely wanted at the call site, so widening the
-- function is the honest direction:
--
--   document_title  every answer must cite a source the owner recognises.
--                   Citing "document 41" is not a citation.
--   token_estimate  retrieve() spends a token budget in similarity order.
--                   Without it there is no budget, and a long passage
--                   could crowd out everything else in the prompt.
--
-- ── AND A SECOND NULL WAITING BEHIND THE FIRST ───────────────────────────────
--
-- similarity was `1 - (kc.embedding <=> p_query_embedding)`, which is
-- NULL when the embedding is null. A keyword-arm-only match on a chunk
-- that never embedded would have reached `map['similarity'] as num` and
-- thrown the same class of error the moment the first one was fixed.
-- Coalesced to 0 here: found by literal match, no meaning score. That is
-- a true statement about the row, not a filled-in blank.
--
-- Return type changes require a drop; `create or replace` cannot widen a
-- RETURNS TABLE.

drop function if exists hybrid_match_knowledge_chunks(
  bigint, vector, text, text, int, double precision
);

create function hybrid_match_knowledge_chunks (
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
    -- Identical normalisation to the generated column (023). If these two
    -- ever disagree, identifier search silently stops working and nothing
    -- errors — which is why it lives inside the function.
    select websearch_to_tsquery(
      'simple', regexp_replace(coalesce(p_query_text, ''), '[-_/]+', ' ', 'g')
    ) as tsq
  ),
  -- Chunks of documents that have not been superseded (024). Applied to
  -- BOTH arms: a replaced price list must not be reachable by keyword
  -- search either, or exact-identifier queries become the one path that
  -- still returns stale prices.
  live as (
    select kc.id, kc.embedding, kc.content_tsv, kd.effective_from
    from knowledge_chunks kc
    join knowledge_documents kd on kd.id = kc.document_id
    where kc.workspace_id = p_workspace_id
      and kc.embedding_model = p_embedding_model
      and kd.superseded_by is null
  ),
  vector_arm as (
    select l.id,
           row_number() over (order by l.embedding <=> p_query_embedding) as rank
    from live l
    where l.embedding is not null
      -- The floor applies to THIS arm only. A literal identifier match is
      -- valuable at any cosine similarity.
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
           -- Reciprocal Rank Fusion. Absence from an arm contributes
           -- nothing rather than a penalty.
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
         -- 0, not null, when the chunk has no embedding: found by literal
         -- match with no meaning score. See the header.
         coalesce((1 - (kc.embedding <=> p_query_embedding)), 0)::double precision
           as similarity,
         f.matched_by
  from fused f
  join knowledge_chunks kc on kc.id = f.id
  join knowledge_documents kd on kd.id = kc.document_id
  -- Recency as a TIEBREAK only, after relevance.
  order by f.rrf_score desc, kd.effective_from desc nulls last
  limit p_match_count;
$$;
