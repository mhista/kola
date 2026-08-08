// knowledge_chunk_repository.dart
//
// All database operations for KnowledgeChunk records, including the one
// vector-similarity search in this codebase (Phase 9 / Layer 2).
//
// THIS REPOSITORY IS THE ONLY FILE THAT TOUCHES THE `embedding` COLUMN.
// knowledge_chunk.spy.yaml deliberately does not model the vector (see
// its header), so the embedding travels as a separate argument through
// [insertChunks] and never appears on the Serverpod model at all.
//
// MULTI-TENANCY: [searchSimilar] passes workspaceId into the RPC, which
// applies it as a WHERE clause inside the same query as the vector scan
// (migration 017). There is no code path that runs a similarity search
// without a workspace filter.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/knowledge_chunk_dto.dart';
import 'supabase_client.dart';

final _log = Logger('KnowledgeChunkRepository');

const _dto = KnowledgeChunkDto();

/// One hit from a similarity search: the chunk's text plus everything
/// needed to CITE it. Not a KnowledgeChunk, on purpose — it carries a
/// similarity score and the parent document's title, neither of which is
/// a property of the stored row, and it deliberately omits fields the
/// answer path has no use for.
class KnowledgeChunkMatch {
  const KnowledgeChunkMatch({
    required this.chunkId,
    required this.documentId,
    required this.documentTitle,
    required this.chunkIndex,
    required this.content,
    required this.tokenEstimate,
    required this.similarity,
  });

  final int chunkId;
  final int documentId;

  /// Shown to the owner in the answer's source list — this is what makes
  /// "every AI answer must cite where its information came from
  /// internally" real rather than aspirational.
  final String documentTitle;

  final int chunkIndex;
  final String content;
  final int tokenEstimate;

  /// Cosine similarity in [0, 1]; higher is closer. Converted from
  /// pgvector's distance operator inside the RPC so every caller reasons
  /// in the same direction.
  final double similarity;
}

class KnowledgeChunkRepository {
  const KnowledgeChunkRepository();

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Inserts every chunk of one document in a SINGLE batch insert, with
  /// its embedding attached.
  ///
  /// [chunks] and [embeddings] are zipped POSITIONALLY and must be the
  /// same length — the caller (DocumentIngestionService) guarantees this,
  /// and GeminiEmbeddingProvider refuses to return a mismatched count
  /// rather than padding, so a mismatch here means a real bug upstream
  /// and throws rather than silently truncating.
  ///
  /// Batched rather than per-chunk because a 200-chunk document would
  /// otherwise be 200 round trips, and because a partial insert is much
  /// easier to reason about as one failed statement than as "somewhere
  /// between 0 and 200 rows landed".
  Future<void> insertChunks({
    required List<KnowledgeChunk> chunks,
    required List<List<double>> embeddings,
  }) async {
    if (chunks.isEmpty) return;
    if (chunks.length != embeddings.length) {
      throw ArgumentError(
        'insertChunks got ${chunks.length} chunks but '
        '${embeddings.length} embeddings — refusing to guess the pairing.',
      );
    }

    _log.info('insertChunks(${chunks.length} chunks, '
        'documentId=${chunks.first.documentId})');

    final rows = <Map<String, dynamic>>[
      for (var i = 0; i < chunks.length; i++)
        {
          ..._dto.toRow(chunks[i]),
          // pgvector accepts its text input form — '[0.1,0.2,...]'.
          // Passing the raw List<double> would be serialized as a JSON
          // array, which PostgREST will NOT coerce into a vector column
          // on insert; the explicit string form is what works. (The RPC
          // path in searchSimilar is different — see its own note.)
          'embedding': _toVectorLiteral(embeddings[i]),
        },
    ];

    await supabase.from('knowledge_chunks').insert(rows);
  }

  /// Deletes every chunk of a document. Normally unnecessary — ON DELETE
  /// CASCADE handles document deletion — but RE-INDEXING an existing
  /// document (same row, new content) has to clear the old chunks first,
  /// and that is not a delete of the parent.
  Future<void> deleteByDocument(int documentId) async {
    _log.info('deleteByDocument($documentId)');
    await supabase.from('knowledge_chunks').delete().eq('document_id', documentId);
  }

  // ── SEARCH ────────────────────────────────────────────────────────────────

  /// Semantic search over one workspace's memory.
  ///
  /// Goes through the `match_knowledge_chunks` RPC rather than a
  /// PostgREST query because vector distance ordering cannot be expressed
  /// in PostgREST's filter syntax at all — this is Supabase's own
  /// documented pgvector pattern, not a workaround. See migration 017.
  ///
  /// [embeddingModel] excludes chunks embedded by a different model,
  /// which would otherwise be compared against an incompatible query
  /// vector and return confident nonsense (see
  /// embedding_orchestrator.dart's header).
  Future<List<KnowledgeChunkMatch>> searchSimilar({
    required int workspaceId,
    required List<double> queryEmbedding,
    required String embeddingModel,
    int matchCount = 6,
    double minSimilarity = 0.3,
  }) async {
    _log.fine('searchSimilar(workspaceId=$workspaceId, '
        'matchCount=$matchCount, minSimilarity=$minSimilarity)');

    final response = await supabase.rpc(
      'match_knowledge_chunks',
      params: {
        'p_workspace_id': workspaceId,
        // As an RPC ARGUMENT (unlike the insert path above) the vector's
        // text literal form is also what's expected — PostgREST hands the
        // value to Postgres as text and the declared vector(768)
        // parameter type casts it. Using the same literal helper in both
        // places keeps one representation rather than two.
        'p_query_embedding': _toVectorLiteral(queryEmbedding),
        'p_embedding_model': embeddingModel,
        'p_match_count': matchCount,
        'p_min_similarity': minSimilarity,
      },
    );

    if (response == null) return const [];

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return KnowledgeChunkMatch(
        chunkId: map['id'] as int,
        documentId: map['document_id'] as int,
        documentTitle: map['document_title'] as String,
        chunkIndex: map['chunk_index'] as int,
        content: map['content'] as String,
        tokenEstimate: map['token_estimate'] as int,
        similarity: (map['similarity'] as num).toDouble(),
      );
    }).toList();
  }

  /// pgvector's text input format: `[1,2,3]`. Kept in one place so the
  /// insert path and the search path can never drift into two different
  /// representations of the same thing.
  static String _toVectorLiteral(List<double> vector) =>
      '[${vector.join(',')}]';
}
