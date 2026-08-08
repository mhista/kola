// embedding_orchestrator.dart
//
// PHASE 9 (Layer 2 — Business Memory). The single entry point every
// other file uses to turn text into vectors — nothing else in this
// codebase should construct an EmbeddingProvider directly, exactly the
// rule ai_orchestrator.dart already sets for chat providers.
//
// HOW THIS DELIBERATELY DIFFERS FROM AiOrchestrator, AND WHY:
//   AiOrchestrator cascades: try Groq, and on ANY failure fall through to
//   Gemini, then OpenRouter. That is correct for chat, because any of the
//   three can answer the same question acceptably.
//
//   It would be WRONG here. Vectors from two different embedding models
//   are not comparable — they are points in unrelated spaces. Falling
//   back to a second provider mid-ingestion would silently write chunks
//   that can never be retrieved by a query embedded with the first
//   provider. The failure would not surface as an error; it would surface
//   months later as "the bot suddenly can't find things", which is far
//   worse than a loud failure at ingestion time.
//
//   So: this class holds an ORDERED PREFERENCE LIST, and picks the first
//   configured provider ONCE — [active]. It does not fall through on
//   error. A quota error is surfaced to the caller to retry later, not
//   papered over by switching model families.
//
// WHEN A SECOND PROVIDER IS ADDED LATER:
//   Adding one is a single new class plus one line in _providers below,
//   same as AiProvider. But CHANGING which one is active for an existing
//   deployment is a data migration, not a config flip — every stored
//   chunk must be re-embedded. knowledge_chunks.embedding_model exists
//   precisely so that migration can find the stale rows. See
//   memory_retrieval_service.dart, which refuses to mix models at query
//   time rather than returning quietly-wrong results.

import 'package:kola_server/src/config/env.dart';

import 'embedding_provider.dart';
import 'providers/gemini_embedding_provider.dart';

class EmbeddingOrchestrator {
  EmbeddingOrchestrator({List<EmbeddingProvider>? providers})
      : _providers = providers ??
            [
              // Gemini is the only real option today: Groq serves no
              // embeddings endpoint, and OpenRouter does not proxy
              // embeddings. This is a one-entry list on purpose, not an
              // oversight — see embedding_provider.dart's header.
              GeminiEmbeddingProvider(apiKey: Env.geminiApiKey),
            ];

  final List<EmbeddingProvider> _providers;

  /// The provider actually in use, or null if none is configured.
  /// Resolved fresh each access (cheap — an isNotEmpty check per entry)
  /// so a key added at runtime doesn't require a restart to take effect.
  EmbeddingProvider? get active {
    for (final provider in _providers) {
      if (provider.isConfigured) return provider;
    }
    return null;
  }

  /// True when embeddings are available at all. Callers that can degrade
  /// gracefully (see bot_knowledge_service.dart, which falls back to the
  /// legacy Bot.knowledgeSeed) should check this rather than catching a
  /// StateError from [embedDocuments]/[embedQuery].
  bool get isAvailable => active != null;

  /// The model identifier of the active provider, for persisting
  /// alongside stored chunks. Throws if nothing is configured — callers
  /// should have checked [isAvailable] first.
  String get activeModel => _require().model;

  /// Vector width of the active provider. MUST equal the `vector(N)`
  /// width in migration 017 — see [assertDimensionsMatchSchema].
  int get dimensions => _require().dimensions;

  /// The dimension migration 017's `knowledge_chunks.embedding` column
  /// was created with. Hardcoded deliberately: this is a fact about the
  /// DATABASE, not about the provider, and the point of the check below
  /// is to catch the case where the two have drifted apart.
  static const schemaDimensions = 768;

  /// Fails fast at startup if a provider is emitting a vector width the
  /// database column cannot store. Without this, the mismatch surfaces
  /// as a per-row insert error deep inside an ingestion job, long after
  /// the actual mistake (swapping a provider or changing its dimension
  /// constant without a migration). Called from server.dart.
  void assertDimensionsMatchSchema() {
    final provider = active;
    if (provider == null) return; // nothing configured; nothing to check
    if (provider.dimensions != schemaDimensions) {
      throw StateError(
        'Embedding provider "${provider.name}" emits '
        '${provider.dimensions}-dimensional vectors, but the '
        'knowledge_chunks.embedding column is vector($schemaDimensions). '
        'Changing embedding dimensions requires a schema migration AND '
        're-embedding every existing chunk — see '
        'embedding_orchestrator.dart\'s header.',
      );
    }
  }

  /// Embeds passages for STORAGE. Use [embedQuery] for search input —
  /// the two are not interchangeable (see EmbeddingProvider.embed).
  Future<List<EmbeddingResult>> embedDocuments(List<String> texts) {
    return _require().embed(texts: texts, taskType: EmbeddingTaskType.document);
  }

  /// Embeds a single search query. Returns one vector.
  Future<EmbeddingResult> embedQuery(String query) async {
    final results = await _require()
        .embed(texts: [query], taskType: EmbeddingTaskType.query);
    return results.single;
  }

  EmbeddingProvider _require() {
    final provider = active;
    if (provider == null) {
      throw StateError(
        'No embedding provider is configured, so long-term memory is '
        'unavailable. Set GEMINI_API_KEY in .env (free tier: '
        'https://aistudio.google.com) and re-run '
        '`dart run build_runner build`. Note this is the SAME key the '
        'chat-side GeminiProvider already uses — no separate credential.',
      );
    }
    return provider;
  }
}
