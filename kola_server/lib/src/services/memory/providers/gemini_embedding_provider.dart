// gemini_embedding_provider.dart
//
// PHASE 9 (Layer 2 — Business Memory). The one real EmbeddingProvider
// today, against Google's gemini-embedding-001 via the same
// generativelanguage.googleapis.com host and the same plain-`package:http`
// style gemini_provider.dart already uses for chat — same API key
// (Env.geminiApiKey), no new credential to configure.
//
// WHY 768 DIMENSIONS AND NOT THE DEFAULT 3072:
//   gemini-embedding-001 emits 3072 floats by default, and is trained
//   with Matryoshka Representation Learning (MRL) so a truncated prefix
//   remains a valid, high-quality embedding — 768 is one of Google's own
//   recommended truncation points. Three concrete reasons to take it:
//
//     1. pgvector's HNSW index (the one migration 017 builds) supports at
//        most 2000 dimensions. A 3072-dim column CAN be stored but CANNOT
//        be HNSW-indexed, which would leave every similarity search doing
//        a sequential scan of the whole table — the exact thing the index
//        exists to prevent.
//     2. Storage: 768 floats is 3KB/chunk vs 12.3KB at 3072. Across a
//        few thousand documents per workspace, times thousands of
//        workspaces, that is the difference between a cheap table and an
//        expensive one.
//     3. Retrieval quality loss at 768 is small and well documented,
//        and is not the bottleneck for this use case — chunking quality
//        and the amount of real business content ingested matter far more.
//
//   This IS a one-way door in the sense that changing it later means
//   re-embedding everything. That is why [model] and the dimension are
//   recorded on every stored chunk (see knowledge_chunk.spy.yaml), so
//   such a change is detectable and migratable rather than silent.
//
// WHY WE NORMALIZE OURSELVES:
//   Google documents gemini-embedding-001's output as normalized at the
//   full 3072 length. A truncated MRL prefix of a unit vector is NOT
//   itself unit-length — its norm is whatever fraction of the magnitude
//   lived in those first 768 components. Since migration 017's index and
//   the match_knowledge_chunks RPC both use the cosine operator, and
//   since we want inner-product and cosine to stay interchangeable, we
//   re-normalize every truncated vector here rather than trusting the
//   API's guarantee at a length it wasn't making the guarantee about.
//   Doing this twice is harmless (normalizing a unit vector is identity);
//   NOT doing it when required is a silent, hard-to-trace quality bug.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../embedding_provider.dart';

class GeminiEmbeddingProvider implements EmbeddingProvider {
  GeminiEmbeddingProvider({required this.apiKey, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _http;

  /// IN-REQUEST BACKOFF ON 429 (2026-09 diagnosis — see this file's header
  /// and embedding_orchestrator.dart's header on why the "Today's limit
  /// for processing new knowledge has been reached" failure is really a
  /// live Gemini rate limit, not a per-workspace daily counter). Gemini's
  /// per-MINUTE rate limits often clear within seconds, so a short retry
  /// right here — no new infrastructure, no job queue, nothing persisted —
  /// resolves a meaningful fraction of 429s inside the SAME ingestion
  /// attempt, before the caller (DocumentIngestionService) ever sees a
  /// failure. This is deliberately NOT ConnectorRetry.run: that helper
  /// requires a ConnectorSyncLogRepository dead-letter sink built for
  /// connector syncs, which doesn't fit (or belong to) a single HTTP call
  /// here, so a small local loop is used instead — same
  /// least-new-infrastructure instinct, applied to a different shape of
  /// problem.
  static const _rateLimitRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
  ];

  /// Process-static, in-memory only (same "one instance, no persistence"
  /// honesty as PlatformHealthRegistry — see that file's header). Set the
  /// moment a 429 survives every retry above, so
  /// AdminPlatformEndpoint.embeddingQuotaInfo can tell kola_admin
  /// "currently rate-limited" without inventing a real usage counter that
  /// doesn't exist. Cleared implicitly by time — callers should treat a
  /// timestamp older than a few minutes as stale, not read this as a
  /// still-active state flag.
  static DateTime? lastRateLimitedAt;

  /// Google's generally-available text embedding model.
  static const _modelId = 'gemini-embedding-001';

  /// See this file's header for why 768 rather than the 3072 default.
  static const _dimensions = 768;

  /// Gemini's batch endpoint caps how many texts one request may carry.
  /// Ingestion of a long document is split into batches of this size by
  /// [embed] itself, so callers never have to think about it.
  static const _maxBatchSize = 100;

  @override
  String get name => 'gemini';

  @override
  String get model => _modelId;

  @override
  int get dimensions => _dimensions;

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  @override
  Future<List<EmbeddingResult>> embed({
    required List<String> texts,
    required EmbeddingTaskType taskType,
  }) async {
    if (texts.isEmpty) return const [];

    final results = <EmbeddingResult>[];
    // Chunk the batch rather than assuming the caller respected the API's
    // per-request limit — a 400-chunk document is a completely normal
    // ingestion and must not fail on an avoidable request-shape error.
    for (var start = 0; start < texts.length; start += _maxBatchSize) {
      final end = math.min(start + _maxBatchSize, texts.length);
      results.addAll(await _embedBatch(texts.sublist(start, end), taskType));
    }
    return results;
  }

  Future<List<EmbeddingResult>> _embedBatch(
    List<String> batch,
    EmbeddingTaskType taskType,
  ) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_modelId:batchEmbedContents?key=$apiKey',
    );

    // RETRIEVAL_DOCUMENT vs RETRIEVAL_QUERY — the asymmetric pair this
    // model is trained for. See EmbeddingProvider.embed's doc comment on
    // why picking the wrong one silently costs recall.
    final taskTypeValue = switch (taskType) {
      EmbeddingTaskType.document => 'RETRIEVAL_DOCUMENT',
      EmbeddingTaskType.query => 'RETRIEVAL_QUERY',
    };

    final body = jsonEncode({
      'requests': [
        for (final text in batch)
          {
            'model': 'models/$_modelId',
            'content': {
              'parts': [
                {'text': text},
              ],
            },
            'taskType': taskTypeValue,
            'outputDimensionality': _dimensions,
          },
      ],
    });

    final response = await _postWithRateLimitBackoff(url, body);

    if (response.statusCode == 429) {
      // Every retry in [_postWithRateLimitBackoff] was exhausted and it's
      // still 429 — record it so kola_admin can see the platform is
      // currently rate-limited (see [lastRateLimitedAt]'s header), then
      // surface the real reason to the caller rather than a fabricated
      // "today's limit" story.
      lastRateLimitedAt = DateTime.now().toUtc();
      throw const EmbeddingQuotaExceededException(
        'Gemini embedding quota exceeded (free tier is 1,500 requests/day). '
        'Ingestion will need to resume later, or the key upgraded.',
      );
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Gemini embedding failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final embeddings = decoded['embeddings'] as List<dynamic>?;
    if (embeddings == null || embeddings.length != batch.length) {
      // Order and count are load-bearing: the caller zips these results
      // back against its own chunk list positionally. A short or
      // reordered response must fail loudly, never be padded or guessed.
      throw Exception(
        'Gemini embedding returned ${embeddings?.length ?? 0} vectors for '
        '${batch.length} inputs — refusing to guess the alignment.',
      );
    }

    return [
      for (final entry in embeddings)
        EmbeddingResult(
          vector: _normalize(
            ((entry as Map<String, dynamic>)['values'] as List<dynamic>)
                .map((v) => (v as num).toDouble())
                .toList(),
          ),
          model: _modelId,
          dimensions: _dimensions,
        ),
    ];
  }

  /// Posts [body] to [url], retrying ONLY on a 429 with the fixed delays
  /// in [_rateLimitRetryDelays] (2s, 4s, 8s — up to 3 retries, 4 attempts
  /// total). Any other status code (200, 4xx other than 429, 5xx) is
  /// returned immediately on the first attempt — those aren't the
  /// transient per-minute rate limit this backoff targets, and retrying
  /// them here would just delay a real failure without fixing it.
  Future<http.Response> _postWithRateLimitBackoff(
    Uri url,
    String body,
  ) async {
    http.Response response = await _http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: body,
    );

    for (final delay in _rateLimitRetryDelays) {
      if (response.statusCode != 429) return response;
      await Future.delayed(delay);
      response = await _http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: body,
      );
    }

    return response;
  }

  /// L2-normalizes [vector] in place-equivalent fashion. See this file's
  /// header for why this is done rather than assumed. A zero vector
  /// (which the API should never return, but which would produce NaNs
  /// throughout the index if it did) is returned untouched rather than
  /// divided by zero.
  static List<double> _normalize(List<double> vector) {
    var sumOfSquares = 0.0;
    for (final v in vector) {
      sumOfSquares += v * v;
    }
    if (sumOfSquares == 0) return vector;
    final norm = math.sqrt(sumOfSquares);
    return [for (final v in vector) v / norm];
  }
}
