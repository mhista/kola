// knowledge_endpoint.dart
//
// PHASE 9 (Layer 2 — Business Memory). The authenticated, workspace-
// scoped surface for a business's long-term memory: add a document,
// list what's stored, delete one, and search memory directly.
//
// WHY A NEW ENDPOINT RATHER THAN MORE METHODS ON BotEndpoint:
//   BotEndpoint.setKnowledgeSeed exists because knowledge USED to be a
//   property of one bot. It isn't any more — knowledge_document.spy.yaml
//   is workspace-scoped, shared by every bot and (later) every
//   specialized agent in the workspace. Hanging workspace-scoped memory
//   off a bot-scoped endpoint would encode exactly the wrong ownership
//   model in the API, and every caller would then have to pass a botId
//   that is genuinely irrelevant to the operation.
//
//   BotEndpoint.setKnowledgeSeed is deliberately LEFT ALONE and still
//   works — see bot_knowledge_service.dart's header on why the seed
//   remains a live fallback rather than something to rip out today.
//
// EVERY METHOD CALLS requireWorkspaceAccess FIRST, same as every other
// endpoint in this project (SRS.md §5). The workspaceId a caller passes
// is validated against their token before it reaches any repository —
// it is never trusted as an identifier on its own.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/billing/plan_limits.dart';
import 'package:kola_server/src/services/billing/trial_state_machine.dart';
import 'package:kola_server/src/services/memory/document_ingestion_service.dart';
import 'package:kola_server/src/services/memory/memory_retrieval_service.dart';
import 'package:kola_server/src/services/repository/knowledge_document_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/kola_logger.dart';

class KnowledgeEndpoint extends Endpoint {
  DocumentIngestionService get _ingestion => getIt<DocumentIngestionService>();
  MemoryRetrievalService get _retrieval => getIt<MemoryRetrievalService>();
  KnowledgeDocumentRepository get _documents => getIt<KnowledgeDocumentRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  TrialStateMachine get _trialStateMachine => getIt<TrialStateMachine>();

  /// Every document in the workspace, newest first.
  Future<List<KnowledgeDocument>> listDocuments(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );
    return _documents.listByWorkspace(workspaceId);
  }

  /// Ingests [text] as a new document: dedupe, chunk, embed, index.
  ///
  /// THROWS with an owner-readable message on every non-success path
  /// (duplicate, empty, quota exhausted, embeddings unconfigured) rather
  /// than returning a status object. That's the convention every other
  /// endpoint in this codebase already follows, and it keeps the
  /// generated client's return type honest — a KnowledgeDocument here
  /// always means a document that is actually searchable.
  ///
  /// The one place that's a slightly awkward fit is 'duplicate', which
  /// isn't really an error. The message says so plainly and names the
  /// existing document, so the dashboard can offer "save it anyway"
  /// (which calls this again with [allowDuplicate] true) rather than
  /// presenting a dead end.
  Future<KnowledgeDocument> addDocument(
    Session session,
    String accessToken,
    int workspaceId,
    String title,
    String text, {
    bool allowDuplicate = false,
  }) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    if (text.trim().isEmpty) {
      throw Exception('There\'s no text to save.');
    }

    // Sanity bound before anything expensive happens — see
    // PlanLimits.maxDocumentCharacters on why this isn't a plan limit.
    if (text.length > PlanLimits.maxDocumentCharacters) {
      throw Exception(
        'That document is too large (${text.length} characters). The limit '
        'is ${PlanLimits.maxDocumentCharacters}. Split it into a few '
        'smaller documents — that also makes the bot\'s answers more '
        'accurate, since it can point at the right one.',
      );
    }

    // Plan cap, checked BEFORE ingestion so a rejected document never
    // burns embedding quota.
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace != null) {
      final tier = _trialStateMachine.effectiveTier(workspace);
      if (tier == EffectiveTier.cappedFree || tier == EffectiveTier.paused) {
        final existing = await _documents.countByWorkspace(workspaceId);
        if (existing >= PlanLimits.cappedFreeKnowledgeDocumentCap) {
          throw Exception(
            'This workspace is on the free plan, which stores up to '
            '${PlanLimits.cappedFreeKnowledgeDocumentCap} knowledge documents. '
            'Delete one, or upgrade to add more.',
          );
        }
      }
    }

    final result = await _ingestion.ingestText(
      workspaceId: workspaceId,
      title: title,
      text: text,
      sourceType: 'paste',
      allowDuplicate: allowDuplicate,
    );

    if (result.isSuccess) {
      Log.success(
        'Indexed knowledge document "${result.document?.title}" '
        '(${result.chunkCount} chunks) for workspace $workspaceId',
        session: session,
      );
      return result.document!;
    }

    throw Exception(result.message ?? 'Could not save that document.');
  }

  /// Removes a document from memory. Its chunks go with it via ON DELETE
  /// CASCADE (migration 017), so the bot genuinely stops knowing this —
  /// there is no path that leaves retrievable chunks behind.
  Future<void> deleteDocument(
    Session session,
    String accessToken,
    int workspaceId,
    int documentId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final existing = await _documents.findByIdScoped(documentId, workspaceId);
    if (existing == null) {
      throw Exception('That document doesn\'t exist in this workspace.');
    }

    await _documents.deleteScoped(documentId, workspaceId);
    Log.success(
      'Deleted knowledge document $documentId '
      '("${existing.title}") from workspace $workspaceId',
      session: session,
    );
  }

  /// Replaces an existing document's content in place, keeping its id.
  Future<KnowledgeDocument> updateDocument(
    Session session,
    String accessToken,
    int workspaceId,
    int documentId,
    String title,
    String text,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    if (text.length > PlanLimits.maxDocumentCharacters) {
      throw Exception(
        'That document is too large. The limit is '
        '${PlanLimits.maxDocumentCharacters} characters.',
      );
    }

    final result = await _ingestion.reindex(
      workspaceId: workspaceId,
      documentId: documentId,
      title: title,
      text: text,
    );

    if (result.isSuccess) return result.document!;
    throw Exception(result.message ?? 'Could not update that document.');
  }

  /// Runs a real memory search and returns what the bot WOULD retrieve
  /// for [query], scores included.
  ///
  /// This is an inspection tool, and it is the reason
  /// knowledge_search_hit.spy.yaml exists — see that file's header. An
  /// owner can type a question a customer actually asked and see exactly
  /// which passages ground the answer, rather than having to trust the
  /// bot or argue with it.
  Future<List<KnowledgeSearchHit>> searchMemory(
    Session session,
    String accessToken,
    int workspaceId,
    String query,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final context = await _retrieval.retrieve(
      workspaceId: workspaceId,
      query: query,
    );

    return [
      for (final match in context.matches)
        KnowledgeSearchHit(
          chunkId: match.chunkId,
          documentId: match.documentId,
          documentTitle: match.documentTitle,
          chunkIndex: match.chunkIndex,
          content: match.content,
          similarity: match.similarity,
        ),
    ];
  }
}
