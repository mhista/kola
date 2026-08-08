// memory_retrieval_service.dart
//
// PHASE 9 (Layer 2 — Business Memory). The read side: turns a customer's
// question into the specific passages of a business's own knowledge that
// should ground the answer, plus the citations that say where each came
// from.
//
// THIS FILE IS WHERE "every AI answer must cite where its information
// came from internally" STOPS BEING ASPIRATIONAL. The prompt block it
// builds numbers each retrieved passage and names its source document,
// and [RetrievedContext.citations] carries those sources back to the
// caller — so an answer can be traced to the exact document and section
// it came from, rather than the bot being trusted on faith. Without this,
// grounded retrieval is just a fancier way to stuff text into a prompt.
//
// TOKEN BUDGET, AND WHY IT ISN'T JUST "TOP 6":
//   Retrieved chunks compete for the same context window as the system
//   prompt, the conversation, and the tool definitions. Taking a fixed
//   count means a query that happens to match six long chunks silently
//   overflows, and the provider truncates from wherever it likes —
//   usually the end, which is where the most-recent conversation lives.
//   So chunks are taken in similarity order until the budget is spent,
//   and the count is a ceiling rather than a target.

import 'package:logging/logging.dart';

import 'package:kola_server/src/services/repository/knowledge_chunk_repository.dart';
import 'package:kola_server/src/services/repository/knowledge_document_repository.dart';

import 'embedding_orchestrator.dart';

final _log = Logger('MemoryRetrievalService');

/// One source behind an answer.
class MemoryCitation {
  const MemoryCitation({
    required this.documentId,
    required this.documentTitle,
    required this.chunkIndex,
    required this.similarity,
  });

  final int documentId;
  final String documentTitle;
  final int chunkIndex;
  final double similarity;

  /// Short owner-facing label, e.g. `Return policy (section 3)`.
  /// chunkIndex is 0-based internally and 1-based here — a business owner
  /// reading "section 0" would reasonably think something is broken.
  String get label => '$documentTitle (section ${chunkIndex + 1})';
}

/// Everything retrieval produced for one question.
class RetrievedContext {
  const RetrievedContext({
    required this.promptBlock,
    required this.citations,
    required this.matches,
  });

  /// Ready to drop into a system prompt. Empty string when nothing was
  /// retrieved — callers check [isEmpty] rather than inspecting this.
  final String promptBlock;

  final List<MemoryCitation> citations;
  final List<KnowledgeChunkMatch> matches;

  bool get isEmpty => matches.isEmpty;

  /// Highest similarity among the retrieved chunks, or 0 if none. Useful
  /// as a confidence signal — a top match at 0.35 means "technically
  /// above threshold but probably not really an answer".
  double get topSimilarity =>
      matches.isEmpty ? 0 : matches.first.similarity;
}

class MemoryRetrievalService {
  MemoryRetrievalService({
    required EmbeddingOrchestrator embeddings,
    required KnowledgeChunkRepository chunks,
    required KnowledgeDocumentRepository documents,
  })  : _embeddings = embeddings,
        _chunks = chunks,
        _documents = documents;

  final EmbeddingOrchestrator _embeddings;
  final KnowledgeChunkRepository _chunks;
  final KnowledgeDocumentRepository _documents;

  /// Roughly 1,500 tokens of retrieved material — comfortably inside
  /// every model in the provider cascade while leaving room for the
  /// conversation and tool definitions. Deliberately conservative: the
  /// smallest context window in the cascade is what matters, not the
  /// largest.
  static const defaultTokenBudget = 1500;

  /// Hard ceiling on chunks regardless of budget. Past roughly this many
  /// passages, additional ones are usually noise that dilutes the strong
  /// matches rather than adding anything.
  static const defaultMaxChunks = 6;

  /// Below this cosine similarity a chunk is treated as unrelated. Set
  /// deliberately rather than at 0: without a floor, EVERY query returns
  /// its six nearest chunks no matter how irrelevant, and the model
  /// dutifully tries to answer from them — which is how a grounded bot
  /// starts confidently misciting a price list to answer a question
  /// about delivery.
  static const defaultMinSimilarity = 0.35;

  /// True if this workspace has any indexed memory at all. Cheap check
  /// used by callers to decide whether to attempt retrieval or fall
  /// straight through to the legacy knowledgeSeed path.
  Future<bool> hasMemory(int workspaceId) =>
      _documents.hasIndexedDocuments(workspaceId);

  /// Retrieves the passages most relevant to [query] within
  /// [workspaceId], newest-and-most-similar first.
  ///
  /// Returns an empty [RetrievedContext] — never throws — when
  /// embeddings are unconfigured or nothing clears the similarity floor.
  /// Retrieval failing should degrade the answer, not break the
  /// conversation: a customer waiting on WhatsApp gets a worse reply, not
  /// an error.
  Future<RetrievedContext> retrieve({
    required int workspaceId,
    required String query,
    int maxChunks = defaultMaxChunks,
    int tokenBudget = defaultTokenBudget,
    double minSimilarity = defaultMinSimilarity,
  }) async {
    if (!_embeddings.isAvailable) return _empty;
    if (query.trim().isEmpty) return _empty;

    try {
      final queryVector = await _embeddings.embedQuery(query);

      final matches = await _chunks.searchSimilar(
        queryText: query,
        workspaceId: workspaceId,
        queryEmbedding: queryVector.vector,
        embeddingModel: queryVector.model,
        matchCount: maxChunks,
        minSimilarity: minSimilarity,
      );

      if (matches.isEmpty) {
        _log.fine('No chunks above $minSimilarity for workspace $workspaceId');
        return _empty;
      }

      // Spend the token budget in similarity order. `kept` may be shorter
      // than `matches` — that is the budget working, not a bug.
      final kept = <KnowledgeChunkMatch>[];
      var spent = 0;
      for (final match in matches) {
        if (kept.isNotEmpty && spent + match.tokenEstimate > tokenBudget) break;
        kept.add(match);
        spent += match.tokenEstimate;
      }

      final citations = [
        for (final match in kept)
          MemoryCitation(
            documentId: match.documentId,
            documentTitle: match.documentTitle,
            chunkIndex: match.chunkIndex,
            similarity: match.similarity,
          ),
      ];

      _log.fine('Retrieved ${kept.length} chunks (~$spent tokens) for '
          'workspace $workspaceId, top similarity '
          '${kept.first.similarity.toStringAsFixed(3)}');

      return RetrievedContext(
        promptBlock: _buildPromptBlock(kept),
        citations: citations,
        matches: kept,
      );
    } catch (e) {
      // Degrade, don't break — see this method's doc comment.
      _log.warning('Retrieval failed for workspace $workspaceId: $e');
      return _empty;
    }
  }

  /// Formats retrieved passages as a numbered, source-labelled block.
  ///
  /// The numbering is not decoration: it gives the model a stable handle
  /// to cite ("[2]"), which is what makes an answer's provenance
  /// checkable after the fact. Each passage is labelled with its source
  /// document so a citation names something the owner recognizes.
  static String _buildPromptBlock(List<KnowledgeChunkMatch> matches) {
    final buffer = StringBuffer();
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      buffer.writeln('[${i + 1}] Source: ${match.documentTitle} '
          '(section ${match.chunkIndex + 1})');
      buffer.writeln(match.content.trim());
      if (i != matches.length - 1) buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  static const _empty = RetrievedContext(
    promptBlock: '',
    citations: [],
    matches: [],
  );
}
