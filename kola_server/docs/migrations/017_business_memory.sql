-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 017 — Phase 9: Business Memory / Layer 2)
--
-- Apply in Supabase dashboard → SQL Editor, AFTER 001–016.
--
-- This is the migration that finally replaces `bots.knowledge_seed` (a
-- single plain-text field injected wholesale into the system prompt) with
-- real long-term memory: documents, chunks, embeddings, and semantic
-- retrieval with source attribution.
--
-- NOTE: `bots.knowledge_seed` is deliberately NOT dropped here. Existing
-- workspaces have real content in it, and bot_knowledge_service.dart still
-- falls back to it when a workspace has no indexed documents yet. Dropping
-- it is a later, separate migration once every workspace has been migrated
-- across — see that file's header.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── PGVECTOR ─────────────────────────────────────────────────────────────────
-- Supabase ships pgvector; it just needs enabling once per project.
--
-- WHY `search_path` IS SET EXPLICITLY AND THE TYPE IS NOT SCHEMA-QUALIFIED:
--   Supabase's convention is to install extensions into the `extensions`
--   schema, but a project that enabled pgvector earlier (or via the
--   dashboard's older toggle) may already have it in `public`. In that
--   case `create extension if not exists ... with schema extensions` does
--   NOTHING — the extension already exists, so the schema clause is
--   ignored — and every `extensions.vector` reference below would then
--   fail with "type does not exist".
--
--   Setting search_path to cover BOTH and referencing the type
--   unqualified makes this migration correct either way. The same
--   applies to the `<=>` operator and the `vector_cosine_ops` operator
--   class, which are equally schema-bound.
create extension if not exists vector with schema extensions;

set search_path = public, extensions;

-- ── KNOWLEDGE DOCUMENTS ──────────────────────────────────────────────────────
-- One ingested source. See knowledge_document.spy.yaml for the reasoning
-- behind each column (this file is the schema, not the rationale trail).
create table if not exists knowledge_documents (
  id            bigserial primary key,
  workspace_id  bigint not null references workspaces(id) on delete cascade,
  title         text not null,
  source_type   text not null default 'paste'
                  check (source_type in ('paste','upload','url','conversation','connector')),
  source_ref    text,
  content_hash  text not null,
  raw_text      text not null,
  status        text not null default 'pending'
                  check (status in ('pending','indexed','failed')),
  chunk_count   int not null default 0,
  error_message text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists knowledge_document_workspace_idx
  on knowledge_documents (workspace_id);

-- Dedupe support. NOT a unique constraint on purpose: a business may
-- legitimately want the same text stored twice under different titles
-- (e.g. a policy that genuinely applies to two product lines). The
-- ingestion service checks this index and asks, rather than the database
-- refusing outright — a hard constraint here would turn a judgement call
-- into an error the owner can't resolve without deleting something.
create index if not exists knowledge_document_hash_idx
  on knowledge_documents (workspace_id, content_hash);

-- ── KNOWLEDGE CHUNKS ─────────────────────────────────────────────────────────
-- The retrievable unit. `embedding` is vector(768) — see
-- gemini_embedding_provider.dart's header for why 768 and not
-- gemini-embedding-001's 3072 default (short version: pgvector's HNSW
-- index caps at 2000 dimensions, and MRL truncation to 768 is one of
-- Google's own recommended sizes).
create table if not exists knowledge_chunks (
  id              bigserial primary key,
  document_id     bigint not null references knowledge_documents(id) on delete cascade,
  workspace_id    bigint not null references workspaces(id) on delete cascade,
  chunk_index     int not null,
  content         text not null,
  token_estimate  int not null default 0,
  embedding       vector(768),
  embedding_model text not null,
  created_at      timestamptz not null default now()
);

create index if not exists knowledge_chunk_document_idx
  on knowledge_chunks (document_id);

-- Tenant isolation index. Every retrieval filters on workspace_id BEFORE
-- (well, alongside) the vector scan — see the RPC below.
create index if not exists knowledge_chunk_workspace_idx
  on knowledge_chunks (workspace_id);

-- ── VECTOR INDEX ─────────────────────────────────────────────────────────────
-- HNSW rather than IVFFlat, deliberately:
--   • IVFFlat must be built AFTER a representative amount of data exists,
--     and needs rebuilding as the table grows — bad fit for a table that
--     starts empty for every new workspace and grows continuously.
--   • HNSW can be created on an empty table and stays correct as rows are
--     added, which is exactly this workload.
-- vector_cosine_ops matches the `<=>` operator used in the RPC below.
-- Vectors are L2-normalized in application code (see
-- gemini_embedding_provider.dart), so cosine distance and inner product
-- agree; cosine is used anyway because it stays correct even if a future
-- provider forgets to normalize.
create index if not exists knowledge_chunk_embedding_idx
  on knowledge_chunks
  using hnsw (embedding vector_cosine_ops);

-- ── SIMILARITY SEARCH RPC ────────────────────────────────────────────────────
-- WHY AN RPC AND NOT A POSTGREST QUERY: PostgREST cannot express a vector
-- distance ordering (`order by embedding <=> $1`) through its filter
-- syntax at all. Supabase's own documented pattern for pgvector search is
-- exactly this — a SQL function called via .rpc(). This is not a
-- workaround; it's the supported path.
--
-- SECURITY: `p_workspace_id` is a required argument and is applied as a
-- WHERE clause inside the same query as the vector scan, so a caller can
-- never receive another workspace's chunks regardless of how the
-- similarity ranks them. The repository layer supplies it from the
-- verified session (SRS.md §5), never from client input.
--
-- `p_embedding_model` guards the model-mismatch failure mode described in
-- embedding_orchestrator.dart: rows embedded by a different model are
-- excluded rather than compared against an incompatible query vector,
-- which would return confident nonsense.
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
-- A function's search_path is resolved at EXECUTION time from the
-- caller's session, not from the migration that created it — so the
-- `set search_path` above does not carry over here. Pinning it on the
-- function itself is what makes the `<=>` operator resolve reliably no
-- matter which client calls the RPC. (Pinning it also closes the
-- search-path-hijack class of issue Postgres warns about for functions.)
set search_path = public, extensions
as $$
  select
    kc.id,
    kc.document_id,
    kd.title as document_title,
    kc.chunk_index,
    kc.content,
    kc.token_estimate,
    -- `<=>` is cosine DISTANCE (0 = identical, 2 = opposite). Callers
    -- reason in similarity, so convert once here rather than in three
    -- different places in Dart.
    1 - (kc.embedding <=> p_query_embedding) as similarity
  from knowledge_chunks kc
  join knowledge_documents kd on kd.id = kc.document_id
  where kc.workspace_id = p_workspace_id
    and kc.embedding is not null
    and kc.embedding_model = p_embedding_model
    -- Only fully-indexed documents are retrievable. A 'pending' document
    -- has some chunks written but not all, and answering from a partial
    -- document is worse than answering from none — the bot would sound
    -- certain while missing half the policy.
    and kd.status = 'indexed'
    and 1 - (kc.embedding <=> p_query_embedding) >= p_min_similarity
  order by kc.embedding <=> p_query_embedding
  limit p_match_count;
$$;

-- ── RLS ──────────────────────────────────────────────────────────────────────
-- Both tables are reached ONLY through the server's service_role client
-- (see supabase_client.dart's header on why service_role, and why the
-- repository layer is what enforces workspace isolation). RLS is enabled
-- with no permissive policy so that if an anon/authenticated key ever
-- reaches these tables directly — the exact mistake migrations 003/004
-- had to correct for waitlist_signups — it reads nothing rather than
-- everything.
alter table knowledge_documents enable row level security;
alter table knowledge_chunks    enable row level security;

-- Same posture for the RPC: it runs as the invoker, so a non-service_role
-- caller hits the RLS above and gets nothing back.
revoke all on function match_knowledge_chunks from anon, authenticated;
