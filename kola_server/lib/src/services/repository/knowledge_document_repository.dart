// knowledge_document_repository.dart
//
// All database read/write operations for KnowledgeDocument records
// (Phase 9 / Layer 2 — Business Memory).
//
// MULTI-TENANCY: every method here takes and filters by workspaceId, per
// SRS.md §5's repository-layer isolation rule. There is deliberately NO
// global/cross-workspace method on this repository — unlike
// SupportTicketRepository.listOpenPastDeadline or
// ChannelRepository.listConnected, nothing about business memory is swept
// server-wide, so no such escape hatch should exist to be misused later.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/knowledge_document_dto.dart';
import 'supabase_client.dart';

final _log = Logger('KnowledgeDocumentRepository');

const _dto = KnowledgeDocumentDto();

class KnowledgeDocumentRepository {
  const KnowledgeDocumentRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<KnowledgeDocument?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, workspaceId=$workspaceId)');
    final response = await supabase
        .from('knowledge_documents')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every document in a workspace, newest first — the Knowledge page's
  /// list view.
  ///
  /// NOTE this selects every column INCLUDING raw_text, which can be
  /// large. That is a real cost and a deliberate one for now: the
  /// dashboard's edit flow needs the original text, and a workspace has
  /// tens of documents, not thousands. If document counts grow, the fix
  /// is a narrowed select for the list view specifically — flagged here
  /// rather than pre-optimized into an awkward two-method API today.
  Future<List<KnowledgeDocument>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('knowledge_documents')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Finds an existing document in this workspace with the same content
  /// hash, if any — the dedupe check DocumentIngestionService runs BEFORE
  /// embedding anything (see knowledge_document.spy.yaml's contentHash
  /// comment on why the order matters: embedding is the expensive step).
  Future<KnowledgeDocument?> findByContentHash(
    int workspaceId,
    String contentHash,
  ) async {
    _log.fine('findByContentHash($workspaceId, $contentHash)');
    final response = await supabase
        .from('knowledge_documents')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('content_hash', contentHash)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Finds this workspace's existing document for a given connector
  /// source, if any — e.g. `'google_sheets:<spreadsheetId>'`. Lets a
  /// connector sync REINDEX its own prior ingestion in place (same
  /// document id, chunks replaced) instead of creating a second,
  /// independent document every time it re-syncs — see
  /// DocumentIngestionService.ingestFromConnector's header for why that
  /// distinction matters. Newest-first + limit 1 as a defensive measure
  /// only: sourceRef is meant to be unique per (workspace, source), this
  /// does not enforce that at the database level.
  Future<KnowledgeDocument?> findBySourceRef(
    int workspaceId,
    String sourceRef,
  ) async {
    _log.fine('findBySourceRef($workspaceId, $sourceRef)');
    final response = await supabase
        .from('knowledge_documents')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('source_ref', sourceRef)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// True if this workspace has at least one fully-indexed document.
  /// bot_knowledge_service.dart calls this to decide whether to use real
  /// retrieval or fall back to the legacy Bot.knowledgeSeed — a cheap
  /// count, not a full fetch, because it runs on every inbound message.
  Future<bool> hasIndexedDocuments(int workspaceId) async {
    final response = await supabase
        .from('knowledge_documents')
        .select('id')
        .eq('workspace_id', workspaceId)
        .eq('status', 'indexed')
        .limit(1)
        .maybeSingle();

    return response != null;
  }

  /// How many documents this workspace holds — the number
  /// PlanLimits.cappedFreeKnowledgeDocumentCap is checked against.
  ///
  /// Counts EVERY document regardless of status, including 'failed'
  /// ones, on purpose: a failed document still occupies a slot the owner
  /// can see and delete, and excluding them would let a workspace
  /// accumulate unlimited failed rows and then appear under the cap.
  ///
  /// Selects only the `id` column and counts the rows client-side rather
  /// than using PostgREST's `.count()`. That is deliberate: it is the
  /// exact pattern every other cap check in this codebase already uses
  /// (WaitlistSignupRepository, OwnerNotificationSendRepository,
  /// BotEndpoint._enforceBotCap), and the caps this feeds are single
  /// digits, so fetching a handful of integers costs nothing. Worth
  /// revisiting only if document counts ever reach a scale where an
  /// exact server-side count actually matters.
  Future<int> countByWorkspace(int workspaceId) async {
    final response = await supabase
        .from('knowledge_documents')
        .select('id')
        .eq('workspace_id', workspaceId);

    return (response as List).length;
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Inserts a document in 'pending' status. Chunks and embeddings do not
  /// exist yet at this point — [markIndexed] is what makes it retrievable.
  Future<KnowledgeDocument> create(KnowledgeDocument document) async {
    _log.info('create(workspaceId=${document.workspaceId}, "${document.title}")');
    final response = await supabase
        .from('knowledge_documents')
        .insert(_dto.toRow(document))
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Flips a document to 'indexed' and records how many chunks it
  /// produced. Until this runs, match_knowledge_chunks ignores the
  /// document entirely (see migration 017's `kd.status = 'indexed'`
  /// clause) — so a crash mid-ingestion leaves a document invisible
  /// rather than half-answerable.
  Future<void> markIndexed(int id, int chunkCount) async {
    _log.info('markIndexed($id, chunkCount=$chunkCount)');
    await supabase.from('knowledge_documents').update({
      'status': 'indexed',
      'chunk_count': chunkCount,
      'error_message': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Records an ingestion failure with a reason the OWNER will actually
  /// see. A silently-failed document is the worst outcome in this whole
  /// subsystem — the owner believes the bot was told something it was
  /// never told — so the reason is persisted, not just logged.
  Future<void> markFailed(int id, String errorMessage) async {
    _log.warning('markFailed($id): $errorMessage');
    await supabase.from('knowledge_documents').update({
      'status': 'failed',
      'error_message': errorMessage,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Updates only the title, leaving content, hash and status untouched.
  ///
  /// Used by DocumentIngestionService.reindex when it detects the
  /// incoming text hashes IDENTICAL to what's already indexed — a pure
  /// rename (or a no-op re-save) must not pay for a delete-and-re-embed
  /// it doesn't need, but a genuine title edit still has to land.
  Future<void> updateTitle(int id, String title) async {
    _log.info('updateTitle($id)');
    await supabase.from('knowledge_documents').update({
      'title': title,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Flips the owner's manual on/off switch for whether this document
  /// feeds the bot's answers (migration 061). Independent of `status` and
  /// `superseded_by` — a fully-indexed, un-superseded document can still
  /// be excluded here on nothing but the owner's say-so. Both retrieval
  /// RPCs filter on this column directly (see migration 061), so this
  /// write is what actually stops — or resumes — a document grounding an
  /// answer, not just a label in the dashboard.
  Future<KnowledgeDocument> setFeedingEnabled({
    required int id,
    required int workspaceId,
    required bool enabled,
  }) async {
    _log.info('setFeedingEnabled($id, workspaceId=$workspaceId, enabled=$enabled)');
    final response = await supabase
        .from('knowledge_documents')
        .update({
          'feeding_enabled': enabled,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Deletes a document. Its chunks go with it via ON DELETE CASCADE
  /// (migration 017) — deliberately enforced by the database rather than
  /// a second Dart call, so there is no code path that can orphan chunks
  /// where retrieval would still surface them.
  Future<void> deleteScoped(int id, int workspaceId) async {
    _log.info('deleteScoped($id, workspaceId=$workspaceId)');
    await supabase
        .from('knowledge_documents')
        .delete()
        .eq('id', id)
        .eq('workspace_id', workspaceId);
  }
}
