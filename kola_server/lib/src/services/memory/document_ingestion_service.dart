// document_ingestion_service.dart
//
// PHASE 9 (Layer 2 — Business Memory). Turns a piece of business text
// into retrievable memory: dedupe → persist → chunk → embed → index.
//
// THE ORDER OF OPERATIONS IS THE DESIGN, and each step is where it is
// for a reason:
//
//   1. HASH AND DEDUPE FIRST. Embedding is the only step that costs
//      money and burns a rate-limited quota (Gemini's free tier is 1,500
//      requests/day). Checking whether we already have this exact text
//      BEFORE embedding it is the whole reason knowledge_documents
//      stores a content hash.
//   2. PERSIST THE DOCUMENT AS 'pending' BEFORE EMBEDDING. If embedding
//      fails halfway — quota, network, a bad key — there is a real row
//      to attach the failure reason to, and the owner sees "failed:
//      quota exceeded" rather than the upload silently vanishing.
//      match_knowledge_chunks ignores non-'indexed' documents, so a
//      pending row is invisible to retrieval, never half-answerable.
//   3. MARK 'indexed' LAST, only after every chunk is written. This is
//      the commit point.
//
// WHAT THIS DELIBERATELY DOES NOT DO — file parsing.
//   knowledge_document.spy.yaml's sourceType allows 'upload', and the
//   design calls for PDF/DOCX/XLSX ingestion. That is NOT built here,
//   and is not stubbed as if it were: this service takes TEXT. Parsing
//   binary formats in Dart means picking and vetting real packages per
//   format, handling scanned-image PDFs (which need OCR and produce
//   nothing useful without it), and testing against real business
//   documents. Pretending to support it by extracting whatever bytes
//   look like text would produce garbage chunks that embed to noise and
//   surface as confidently wrong answers — strictly worse than not
//   accepting the file. Extraction belongs in a separate service that
//   feeds [ingestText]; this file's contract does not change when it
//   arrives.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/knowledge_chunk_repository.dart';
import 'package:kola_server/src/services/repository/knowledge_document_repository.dart';

import 'embedding_orchestrator.dart';
import 'text_chunker.dart';

final _log = Logger('DocumentIngestionService');

/// Outcome of an ingestion attempt. A result object rather than a thrown
/// exception for the expected failure paths, because "you already have
/// this document" and "the daily embedding quota is used up" are things
/// the OWNER needs told in plain language, not stack traces.
class IngestionResult {
  const IngestionResult({
    required this.status,
    this.document,
    this.chunkCount = 0,
    this.message,
  });

  final IngestionStatus status;
  final KnowledgeDocument? document;
  final int chunkCount;

  /// Owner-facing explanation. Always set for anything other than
  /// [IngestionStatus.indexed].
  final String? message;

  bool get isSuccess => status == IngestionStatus.indexed;
}

enum IngestionStatus {
  /// Chunked, embedded, and retrievable.
  indexed,

  /// Byte-identical content already exists in this workspace. The
  /// existing document is returned rather than a second copy created.
  duplicate,

  /// Nothing usable in the input (empty, or whitespace only).
  empty,

  /// Embeddings are not configured at all, so nothing can be indexed.
  unavailable,

  /// A real failure — quota, network, provider error. The document row
  /// exists and is marked 'failed' with the reason.
  failed,
}

class DocumentIngestionService {
  DocumentIngestionService({
    required EmbeddingOrchestrator embeddings,
    required KnowledgeDocumentRepository documents,
    required KnowledgeChunkRepository chunks,
    TextChunker chunker = const TextChunker(),
  })  : _embeddings = embeddings,
        _documents = documents,
        _chunks = chunks,
        _chunker = chunker;

  final EmbeddingOrchestrator _embeddings;
  final KnowledgeDocumentRepository _documents;
  final KnowledgeChunkRepository _chunks;
  final TextChunker _chunker;

  /// Ingests [text] as a document in [workspaceId].
  ///
  /// [allowDuplicate] exists because identical text under two titles is
  /// occasionally legitimate (the same policy genuinely applying to two
  /// product lines) — see migration 017's note on why the content-hash
  /// index is not a unique constraint. Default is false: the caller is
  /// told about the duplicate and decides, rather than the service
  /// quietly creating a second copy that will then return two identical
  /// chunks for every future query.
  Future<IngestionResult> ingestText({
    required int workspaceId,
    required String title,
    required String text,
    String sourceType = 'paste',
    String? sourceRef,
    bool allowDuplicate = false,
  }) async {
    if (!_embeddings.isAvailable) {
      return const IngestionResult(
        status: IngestionStatus.unavailable,
        message: 'Long-term memory is not available because no embedding '
            'provider is configured. Set GEMINI_API_KEY on the server.',
      );
    }

    // Chunk FIRST — it normalizes whitespace, and normalized text is what
    // gets hashed. Otherwise the same document pasted from Word and from
    // a text file would hash differently and dedupe would never fire.
    final pieces = _chunker.chunk(text);
    if (pieces.isEmpty) {
      return const IngestionResult(
        status: IngestionStatus.empty,
        message: 'There was no readable text to save.',
      );
    }

    final normalizedForHash = pieces.map((p) => p.content).join('\n');
    final hash = sha256.convert(utf8.encode(normalizedForHash)).toString();

    if (!allowDuplicate) {
      final existing = await _documents.findByContentHash(workspaceId, hash);
      if (existing != null) {
        return IngestionResult(
          status: IngestionStatus.duplicate,
          document: existing,
          chunkCount: existing.chunkCount,
          message: 'This is identical to "${existing.title}", which is '
              'already saved. Save it again anyway if you meant to.',
        );
      }
    }

    final now = DateTime.now().toUtc();
    final document = await _documents.create(
      KnowledgeDocument(
        workspaceId: workspaceId,
        title: title.trim().isEmpty ? 'Untitled' : title.trim(),
        sourceType: sourceType,
        sourceRef: sourceRef,
        contentHash: hash,
        rawText: text,
        status: 'pending',
        chunkCount: 0,
        createdAt: now,
        updatedAt: now,
        // A brand new document always feeds — see migration 061's header
        // on why the toggle defaults true. There is no owner action yet
        // for turning it off at creation time; that only happens later,
        // explicitly, through KnowledgeEndpoint.setFeedingEnabled.
        feedingEnabled: true,
      ),
    );

    final documentId = document.id!;

    try {
      final vectors = await _embeddings.embedDocuments(
        [for (final piece in pieces) piece.content],
      );

      // GeminiEmbeddingProvider already refuses to return a mismatched
      // count, but this is the boundary where a positional zip actually
      // happens, so it is checked here too rather than trusted across a
      // layer.
      if (vectors.length != pieces.length) {
        throw StateError(
          'Embedded ${vectors.length} vectors for ${pieces.length} chunks.',
        );
      }

      await _chunks.insertChunks(
        chunks: [
          for (var i = 0; i < pieces.length; i++)
            KnowledgeChunk(
              documentId: documentId,
              workspaceId: workspaceId,
              chunkIndex: pieces[i].index,
              content: pieces[i].content,
              tokenEstimate: pieces[i].tokenEstimate,
              embeddingModel: vectors[i].model,
              createdAt: now,
            ),
        ],
        embeddings: [for (final v in vectors) v.vector],
      );

      await _documents.markIndexed(documentId, pieces.length);
      _log.info('Indexed "${document.title}" (${pieces.length} chunks) '
          'for workspace $workspaceId');

      return IngestionResult(
        status: IngestionStatus.indexed,
        document: document,
        chunkCount: pieces.length,
      );
    } catch (e) {
      // The document row survives, marked failed with a reason the owner
      // can act on — see this file's header on why silent failure is the
      // worst outcome in this subsystem.
      final reason = _ownerFacingReason(e);
      await _documents.markFailed(documentId, reason);
      _log.severe('Ingestion failed for document $documentId: $e');
      return IngestionResult(
        status: IngestionStatus.failed,
        document: document,
        message: reason,
      );
    }
  }

  /// Re-indexes an existing document against new text, in place. Used
  /// when an owner edits something already saved — keeps the same
  /// document id (so anything referencing it stays valid) while
  /// replacing its chunks entirely.
  ///
  /// Old chunks are deleted BEFORE the new ones are written. The window
  /// between the two is real: a query landing in it retrieves nothing
  /// from this document rather than a mix of old and new. That is the
  /// right trade — briefly knowing less is safe, briefly answering from
  /// two contradictory versions of a policy is not.
  Future<IngestionResult> reindex({
    required int workspaceId,
    required int documentId,
    required String title,
    required String text,
  }) async {
    final existing = await _documents.findByIdScoped(documentId, workspaceId);
    if (existing == null) {
      return const IngestionResult(
        status: IngestionStatus.failed,
        message: 'That document no longer exists.',
      );
    }

    // ── SKIP THE RE-EMBED WHEN THE CONTENT HASN'T ACTUALLY CHANGED ──────
    //
    // This is the gap ingestText's dedupe never covered: ingestText only
    // runs BEFORE a document exists, so it only ever protects the
    // "create a new document" path. reindex is the "same document, new
    // text" path — knowledge_page.dart's _generateFrom hits it every
    // single time the owner presses "Generate knowledge" (even when the
    // catalog hasn't changed since the last press), and
    // ingestFromConnector hits it on every periodic re-sync of an
    // unchanged source. Both used to unconditionally delete every chunk
    // and pay for a fresh embedding call — exactly the waste this file's
    // header describes hashing BEFORE embedding to avoid, just missed on
    // this one path.
    //
    // Hashed with the SAME normalization ingestText uses (chunk first,
    // join chunk contents) so a whitespace-only difference from
    // re-chunking doesn't read as a real change, and compared against
    // the row's OWN previous hash — not any other document's — so this
    // is a true "did THIS document's content change" check, not a
    // workspace-wide dedupe.
    final pieces = _chunker.chunk(text);
    if (pieces.isNotEmpty) {
      final normalizedForHash = pieces.map((p) => p.content).join('\n');
      final hash = sha256.convert(utf8.encode(normalizedForHash)).toString();

      if (hash == existing.contentHash) {
        final trimmedTitle = title.trim().isEmpty ? existing.title : title.trim();
        if (trimmedTitle != existing.title) {
          // Content is identical but the owner did rename it — that
          // still has to land, it just doesn't need chunks touched.
          await _documents.updateTitle(documentId, trimmedTitle);
        }

        _log.info(
          'Skipping re-embed for document $documentId ("${existing.title}") '
          'in workspace $workspaceId — content unchanged (hash '
          '${hash.substring(0, 12)}…). No embedding call made.',
        );

        return IngestionResult(
          status: IngestionStatus.indexed,
          document: existing.copyWith(title: trimmedTitle),
          chunkCount: existing.chunkCount,
          message: 'Content unchanged — nothing to re-embed.',
        );
      }
    }

    await _chunks.deleteByDocument(documentId);
    await _documents.deleteScoped(documentId, workspaceId);

    return ingestText(
      workspaceId: workspaceId,
      title: title,
      text: text,
      sourceType: existing.sourceType,
      sourceRef: existing.sourceRef,
      allowDuplicate: true,
    );
  }

  /// Ingests text from a CONNECTOR sync (Google Sheets today; any future
  /// read-and-summarize connector reuses this same entry point) — the
  /// one deliberate departure from [ingestText]'s "the caller decides
  /// what to do with a duplicate" contract, and from
  /// knowledge_document.spy.yaml's "supersession is proposed, never
  /// automatic" rule for pasted/uploaded documents.
  ///
  /// WHY THE DEPARTURE IS SAFE HERE: [sourceRef] (e.g.
  /// 'google_sheets:<spreadsheetId>') is a STABLE identity for a
  /// connector-sourced document in a way two independently-pasted texts
  /// never are — this call and the next one an hour from now are the
  /// SAME external source re-fetched, not two documents whose
  /// relationship a human needs to judge. So: found existing → reindex
  /// in place (same document id, chunks replaced, matching
  /// [reindex]'s own "briefly knowing less beats briefly knowing two
  /// contradictory versions" trade-off). Not found → ingestText creates
  /// it fresh with sourceType 'connector'.
  Future<IngestionResult> ingestFromConnector({
    required int workspaceId,
    required String title,
    required String text,
    required String sourceRef,
  }) async {
    final existing = await _documents.findBySourceRef(workspaceId, sourceRef);
    if (existing != null && existing.id != null) {
      return reindex(
        workspaceId: workspaceId,
        documentId: existing.id!,
        title: title,
        text: text,
      );
    }
    return ingestText(
      workspaceId: workspaceId,
      title: title,
      text: text,
      sourceType: 'connector',
      sourceRef: sourceRef,
      // A connector's re-sync legitimately produces byte-identical text
      // to some OTHER already-ingested document in rare cases (an empty
      // sheet twice, say) — allowDuplicate: true here because the
      // sourceRef-based find-or-create above is already this method's
      // real dedupe mechanism; content-hash dedupe on top of that would
      // just block a legitimate first ingestion under an unlucky hash
      // collision with unrelated content.
      allowDuplicate: true,
    );
  }

  /// Turns an exception into something a business owner can read and act
  /// on. Anything unrecognized falls through to a generic message rather
  /// than leaking a stack trace or provider internals into the dashboard.
  String _ownerFacingReason(Object error) {
    final text = error.toString();
    if (text.contains('quota') || text.contains('429')) {
      // NOT a per-workspace daily limit — see gemini_embedding_provider
      // .dart's header and embedding_orchestrator.dart's header for the
      // 2026-09 diagnosis. This is a shared-key rate limit that clears on
      // its own, usually within minutes; GeminiEmbeddingProvider already
      // retries with backoff before this is ever thrown, so by the time
      // an owner sees this, the short retry already failed too. The old
      // wording ("Today's limit... has been reached") implied a real
      // per-workspace daily counter that does not exist, and told owners
      // to expect a whole day's wait, which is both wrong and needlessly
      // discouraging.
      return 'High demand right now — this document is saved and will be '
          'retried automatically. No action needed.';
    }
    if (text.contains('SocketException') || text.contains('Failed host lookup')) {
      return 'Could not reach the service that processes knowledge. '
          'Please try again shortly.';
    }
    return 'Something went wrong while processing this document. '
        'It has been saved but is not searchable yet.';
  }
}
