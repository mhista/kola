-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 023 — hybrid keyword + vector retrieval)
--
-- Apply AFTER 022.
--
-- ── THE PROBLEM THIS FIXES ───────────────────────────────────────────────────
--
-- Vector search is SEMANTIC. It is excellent at "can I send it back if it
-- doesn't fit" matching a returns policy that never uses those words. It is
-- close to useless at "where is order 1041".
--
-- An identifier like `1041`, `SKU-4471` or `INV-2026-0033` carries almost no
-- semantic content. Its embedding sits near every other short alphanumeric
-- string, so the passage that literally contains it often ranks BELOW prose
-- that merely sounds related — and with a similarity floor in place, it is
-- frequently not returned at all.
--
-- This is not a tuning problem. Lowering the floor returns more noise without
-- reliably surfacing the exact match. The two retrieval modes fail on
-- different inputs, which is precisely why the fix is to run both.
--
-- ── TWO CORRECTIONS FOUND BY TESTING, NOT BY REASONING ───────────────────────
--
-- 1. SEPARATOR NORMALISATION. The first version of this migration assumed
--    'simple' tokenises SKU-4471 into `sku` and `4471`. It does not — Postgres
--    reads the hyphenated tail as a SIGNED INTEGER and produces `sku` and
--    `-4471`, so a query for the bare number "4471" matched nothing. That is
--    precisely the failure this migration exists to fix, and it would have
--    shipped looking correct.
--
--    Both the generated column and the query are now passed through
--    regexp_replace(..., '[-_/]+', ' ', 'g') first. Verified: bare `4471`,
--    bare `0033`, full `SKU-4471` and full `INV-2026-0033` all match; the
--    unrelated word `bicycle` does not.
--
--    THE TWO NORMALISATIONS MUST STAY IDENTICAL. If they diverge, keyword
--    search stops finding identifiers and nothing errors.
--
-- 2. p_embedding_model WAS MISSING. match_knowledge_chunks (017) filters on
--    it so that a chunk embedded by a different model is never compared
--    against this query's vector — different models produce unrelated vector
--    spaces, and the resulting cosine similarity is meaningless but
--    confident. The first hybrid version dropped the parameter. It is now on
--    BOTH arms, because a keyword hit still reports a similarity.
--
-- ── WHY `simple` AND NOT `english` ───────────────────────────────────────────
--
-- The 'english' text search config stems words and strips stop words: it turns
-- "returns" into "return", which is good for prose. It also mangles exactly
-- what we need preserved here — and prose is already covered by the vector
-- arm. Splitting the job cleanly:
--
--     vector arm   → meaning, paraphrase, synonyms
--     keyword arm  → literal tokens: codes, SKUs, order numbers, names
--
-- 'simple' lower-cases and splits without stemming. It does NOT split on
-- every punctuation mark — see correction 1 above, which is why separators
-- are normalised to spaces before tokenising. With that in place `SKU-4471`
-- indexes as `sku` and `4471`, and either finds it. Under 'english' the same
-- query is far less predictable, and stop-word removal can drop short tokens
-- outright.
--
-- ── WHY RECIPROCAL RANK FUSION, NOT A WEIGHTED SCORE ─────────────────────────
--
-- Cosine similarity is roughly 0..1. ts_rank is unbounded and scaled entirely
-- differently. Any `0.7 * vector + 0.3 * keyword` formula requires tuning two
-- numbers that drift the moment the corpus changes, and it is impossible to
-- reason about why a given result won.
--
-- RRF ignores scores and uses only RANK: score = Σ 1/(k + rank). A chunk that
-- places 2nd in both lists beats one that places 1st in a single list. It
-- needs no tuning, is stable as the corpus grows, and is the standard approach
-- for exactly this problem.
--
-- k = 60 is the value from the original RRF paper (Cormack et al., 2009) and
-- the de-facto default. It damps the difference between the top few ranks so
-- one arm cannot dominate on a single strong hit.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── THE KEYWORD INDEX ────────────────────────────────────────────────────────
--
-- A GENERATED column, not a trigger-maintained one. Generated columns cannot
-- drift: there is no path where content is updated and the search vector is
-- left stale, which is the classic failure of the trigger approach and one
-- that stays invisible until someone searches for recently-edited text.
alter table knowledge_chunks
  add column if not exists content_tsv tsvector
  generated always as (
    to_tsvector('simple', regexp_replace(coalesce(content, ''), '[-_/]+', ' ', 'g'))
  ) stored;

comment on column knowledge_chunks.content_tsv is
  'Keyword search vector, simple config (no stemming) so identifiers such as '
  'SKU codes and order numbers survive tokenisation. Generated, so it cannot '
  'fall out of sync with content.';

-- GIN, not GiST: GIN is slower to build and larger on disk, but substantially
-- faster to query, and this table is written rarely and read on every single
-- customer message.
create index if not exists knowledge_chunk_tsv_idx
  on knowledge_chunks using gin (content_tsv);

-- ── THE HYBRID RPC ───────────────────────────────────────────────────────────
--
-- Same schema-qualification discipline as migration 017: an explicit
-- search_path pinned on the function, so `vector` resolves whether the
-- extension lives in public or extensions.
create or replace function hybrid_match_knowledge_chunks (
  p_workspace_id     bigint,
  p_query_embedding  vector,
  p_query_text       text,
  p_embedding_model  text,
  p_match_count      int,
  p_min_similarity   double precision
)
returns table (
  id            bigint,
  document_id   bigint,
  chunk_index   int,
  content       text,
  similarity    double precision,
  matched_by    text
)
language sql
stable
set search_path = public, extensions
as $$
  with q as (
    -- Identical normalisation to the generated column above.
    select websearch_to_tsquery(
      'simple', regexp_replace(coalesce(p_query_text, ''), '[-_/]+', ' ', 'g')
    ) as tsq
  ),
  vector_arm as (
    select
      kc.id,
      row_number() over (order by kc.embedding <=> p_query_embedding) as rank
    from knowledge_chunks kc
    where kc.workspace_id = p_workspace_id
      and kc.embedding is not null
      and kc.embedding_model = p_embedding_model
      -- The floor applies to THIS arm only. A literal identifier match is
      -- valuable at any cosine similarity, and excluding it here would
      -- reintroduce the exact bug this migration exists to fix.
      and 1 - (kc.embedding <=> p_query_embedding) >= p_min_similarity
    order by kc.embedding <=> p_query_embedding
    limit p_match_count * 2
  ),
  keyword_arm as (
    select
      kc.id,
      row_number() over (order by ts_rank(kc.content_tsv, q.tsq) desc) as rank
    from knowledge_chunks kc, q
    where kc.workspace_id = p_workspace_id
      and kc.embedding_model = p_embedding_model
      and q.tsq is not null
      and kc.content_tsv @@ q.tsq
    order by ts_rank(kc.content_tsv, q.tsq) desc
    limit p_match_count * 2
  ),
  fused as (
    select
      coalesce(v.id, k.id) as id,
      -- Reciprocal Rank Fusion. Absent from an arm contributes nothing
      -- rather than a penalty, so a chunk found by only one method still
      -- competes on the strength of its rank there.
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
  select
    kc.id,
    kc.document_id,
    kc.chunk_index,
    kc.content,
    -- The true cosine similarity is still returned, for every row including
    -- keyword-only ones. The UI shows this as a confidence score, and it must
    -- mean the same thing regardless of which arm surfaced the chunk —
    -- substituting the RRF score here would put an unrelated number behind a
    -- label that says "similarity".
    (1 - (kc.embedding <=> p_query_embedding))::double precision as similarity,
    f.matched_by
  from fused f
  join knowledge_chunks kc on kc.id = f.id
  order by f.rrf_score desc
  limit p_match_count;
$$;

comment on function hybrid_match_knowledge_chunks is
  'Retrieval over business memory, fusing semantic (vector) and literal '
  '(keyword) matches with Reciprocal Rank Fusion. The similarity floor is '
  'applied to the vector arm only, so exact identifiers are reachable at any '
  'cosine similarity. match_knowledge_chunks is retained for callers that '
  'genuinely want semantics alone.';

-- match_knowledge_chunks (migration 017) is deliberately LEFT IN PLACE.
-- Nothing is gained by dropping it, and keeping it means a caller can ask for
-- pure semantic search when that is what it actually wants — and gives an
-- immediate rollback if fusion ever behaves worse than expected on real data.
