// embedding_provider.dart
//
// PHASE 9 (Layer 2 — Business Memory). The embedding-side twin of
// ai_provider.dart, and deliberately a SEPARATE interface rather than
// another method bolted onto AiProvider.
//
// WHY SEPARATE, AND NOT `AiProvider.embed()`:
//   Of the three providers already in AiOrchestrator's cascade, only ONE
//   can do this at all. Groq serves chat/inference models only and has
//   no embeddings endpoint; OpenRouter deliberately does not proxy
//   embeddings either. Adding `embed()` to AiProvider would therefore
//   have forced two of three implementations to be permanent
//   `throw UnsupportedError(...)` stubs, and would have made
//   AiOrchestrator's "fall through to the next provider on ANY failure"
//   cascade silently meaningless for embeddings — it would try Groq,
//   fail, try Gemini, and only ever succeed on the one provider that
//   was always going to be the answer.
//
//   A separate interface states that honestly: embeddings have their own
//   (currently one-entry) provider list, and adding a second real one
//   later (Voyage, Cohere, a self-hosted model) is one new class here,
//   exactly like adding an AiProvider is.
//
// THE HARD CONSTRAINT NOBODY CAN REFACTOR AWAY:
//   An embedding is only comparable to another embedding produced by the
//   SAME model at the SAME dimensionality. Two providers' vectors are not
//   interchangeable, so this is NOT a failover cascade the way
//   AiOrchestrator is — switching embedding providers means RE-EMBEDDING
//   every stored chunk, not just routing the next call elsewhere. See
//   embedding_orchestrator.dart's header for how that's handled, and why
//   knowledge_chunks rows record which model produced them.

/// One embedding model behind a stable interface.
abstract class EmbeddingProvider {
  /// Short identifier for logging (e.g. "gemini") — never user-facing.
  String get name;

  /// The specific model identifier whose vectors this provider produces
  /// (e.g. "gemini-embedding-001"). PERSISTED alongside every chunk, so
  /// a later model change is detectable rather than silently corrupting
  /// similarity scores — see [EmbeddingResult.model].
  String get model;

  /// Vector length this provider is configured to emit. Must match the
  /// `vector(N)` column width in migration 017 exactly.
  int get dimensions;

  /// True if an API key is configured — checked before any HTTP call.
  bool get isConfigured;

  /// Embeds [texts] in one call and returns one vector per input, IN THE
  /// SAME ORDER. Batch-shaped rather than single-text because ingestion
  /// embeds a whole document's chunks at once and the per-request
  /// overhead dominates otherwise.
  ///
  /// [taskType] matters for retrieval quality and is not cosmetic: an
  /// asymmetric embedding model encodes a stored passage differently
  /// from a search query, and using the wrong one measurably degrades
  /// recall. Callers should never pass this by hand — use
  /// [EmbeddingTaskType.document] when ingesting and
  /// [EmbeddingTaskType.query] when searching.
  ///
  /// Throws on any failure (bad key, quota, network, unexpected shape).
  Future<List<EmbeddingResult>> embed({
    required List<String> texts,
    required EmbeddingTaskType taskType,
  });
}

/// Whether a text is being stored for later retrieval, or is the search
/// query being matched against stored texts. See [EmbeddingProvider.embed].
enum EmbeddingTaskType {
  /// A passage being indexed into long-term memory.
  document,

  /// A question being matched against indexed passages.
  query,
}

/// One embedded text: the vector plus the provenance needed to know
/// whether it's still comparable to anything else in the table.
class EmbeddingResult {
  const EmbeddingResult({
    required this.vector,
    required this.model,
    required this.dimensions,
  });

  /// The embedding itself. Always L2-normalized (unit length), so cosine
  /// similarity and inner product are equivalent — see
  /// gemini_embedding_provider.dart on why normalization is done in our
  /// own code rather than assumed from the API.
  final List<double> vector;

  /// Which model produced [vector]. Stored per-chunk.
  final String model;

  final int dimensions;
}

/// Thrown when a provider is out of quota specifically — distinguished
/// from a generic failure so callers can back off and retry later rather
/// than treating a temporary cap as a permanent error. Mirrors
/// ai_provider.dart's AiQuotaExceededException for the same reason.
class EmbeddingQuotaExceededException implements Exception {
  const EmbeddingQuotaExceededException(this.message);
  final String message;
  @override
  String toString() => 'EmbeddingQuotaExceededException: $message';
}
