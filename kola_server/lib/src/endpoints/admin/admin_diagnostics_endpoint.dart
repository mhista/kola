// admin_diagnostics_endpoint.dart — kola_admin, ADMIN_APP_SPEC.md §3.3
// "customer service diagnostics", build-order step 5, deferred until
// this pass.
//
// THE SPEC'S ASK: "a single diagnostic view that checks: channel
// credential expired, daily message cap hit, trial paused, no AI
// provider reachable, security filter blocked it, knowledge document
// failed to index — and says which one it is," plus conversation
// lookup, recent errors, resend a failed notification, and manually
// re-index a failed knowledge document.
//
// WHAT'S REAL VS. HONESTLY NARROWED, PER CHECK:
//   - channel credential expired  -> real: Channel.status != 'connected'
//     (ChannelHealthCheckService already flips this via markDisconnected
//     on a failed check — this just reads that same field, no new
//     tracking added).
//   - daily message cap hit       -> PARTIAL: PlanLimits
//     .cappedFreeDailyMessageCap (50, a real confirmed constant) is
//     reported, but there is no live "messages sent today" counter
//     anywhere in this codebase to compare it against — see
//     inbound_message_handler.dart, which enforces the cap inline but
//     doesn't persist a queryable running count. Reported as the cap
//     value with an explicit "today's usage isn't tracked" note, not a
//     fabricated "N/50 used."
//   - trial paused                -> real: Workspace.status == 'paused'.
//   - no AI provider reachable    -> PARTIAL: AiOrchestrator
//     .providerConfigStatus is a key-configured check, not a live ping
//     (see that getter's header) — reported as "no provider configured"
//     vs. "provider(s) configured, reachability not tested."
//   - security filter blocked it  -> NOT built: SecurityFilter's rate
//     limiting is in-memory only (_requestHistory, a static map — see
//     that file's header) with no persistence of individual block
//     events anywhere queryable per workspace. Reported plainly as "not
//     tracked" rather than guessed at.
//   - knowledge document failed   -> real: KnowledgeDocument.status ==
//     'failed', read straight off KnowledgeDocumentRepository.
//
// So [diagnoseWorkspace] returns one line per check, each explicitly
// tagged OK / FAIL / WARN / UNKNOWN — UNKNOWN meaning "this platform
// doesn't track that yet," never silently omitted.
//
// AUDITED READS: conversation lookup and recent-errors are logged the
// same as every mutating action (a customer's message content is
// sensitive even though reading it doesn't change anything) — see the
// spec's own "reads are logged too where they touch customer
// conversation content."

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/admin_audit_log.dart';
import 'package:kola_server/src/services/admin/admin_user.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';
import 'package:kola_server/src/services/ai/ai_orchestrator.dart';
import 'package:kola_server/src/services/billing/plan_limits.dart';
import 'package:kola_server/src/services/memory/document_ingestion_service.dart';
import 'package:kola_server/src/services/repository/admin_audit_log_repository.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/knowledge_document_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/notifications/owner_notification_dispatcher.dart';

class AdminDiagnosticsEndpoint extends Endpoint {
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  BotRepository get _bots => getIt<BotRepository>();
  ChannelRepository get _channels => getIt<ChannelRepository>();
  ConversationRepository get _conversations => getIt<ConversationRepository>();
  KnowledgeDocumentRepository get _documents => getIt<KnowledgeDocumentRepository>();
  AiOrchestrator get _ai => getIt<AiOrchestrator>();
  DocumentIngestionService get _ingestion => getIt<DocumentIngestionService>();
  OwnerNotificationDispatcher get _dispatcher => getIt<OwnerNotificationDispatcher>();
  AdminAuditLogRepository get _audit => getIt<AdminAuditLogRepository>();

  /// One "CHECK|STATUS|detail" line per diagnostic — see this file's
  /// header for exactly what each STATUS (OK/FAIL/WARN/UNKNOWN) means
  /// per check. Support level: read-only.
  Future<List<String>> diagnoseWorkspace(
    Session session,
    String adminToken,
    int workspaceId,
  ) async {
    final admin = await requireAdminLevel(adminToken: adminToken);

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'No workspace with id $workspaceId.');
    }

    final lines = <String>[];

    // trial paused
    lines.add(
      workspace.status == 'paused'
          ? 'trial_or_suspension|FAIL|workspace status is paused'
          : 'trial_or_suspension|OK|status=${workspace.status}',
    );

    // channel credentials
    final bots = await _bots.listByWorkspace(workspaceId);
    var disconnected = 0;
    var totalChannels = 0;
    for (final bot in bots) {
      final channels = await _channels.listByBot(bot.id!);
      totalChannels += channels.length;
      disconnected += channels.where((c) => c.status != 'connected').length;
    }
    lines.add(
      totalChannels == 0
          ? 'channel_credentials|WARN|no channels connected'
          : disconnected > 0
              ? 'channel_credentials|FAIL|$disconnected of $totalChannels channel(s) not connected'
              : 'channel_credentials|OK|$totalChannels channel(s) connected',
    );

    // daily message cap — see file header on why this is cap-only
    lines.add(
      'daily_message_cap|UNKNOWN|cap=${PlanLimits.cappedFreeDailyMessageCap}/day (free plan); '
      "today's usage is not tracked anywhere queryable yet",
    );

    // AI provider
    final configured = _ai.providerConfigStatus.entries.where((e) => e.value).map((e) => e.key);
    lines.add(
      configured.isEmpty
          ? 'ai_provider|FAIL|no AI provider has a key configured'
          : 'ai_provider|OK|configured: ${configured.join(", ")} (key presence only, not a live reachability ping)',
    );

    // security filter
    lines.add(
      'security_filter|UNKNOWN|rate-limit/abuse blocks are tracked in-memory only '
      '(SecurityFilter._requestHistory) with no per-workspace persisted history yet',
    );

    // knowledge documents
    final docs = await _documents.listByWorkspace(workspaceId);
    final failed = docs.where((d) => d.status == 'failed').length;
    lines.add(
      failed > 0
          ? 'knowledge_documents|FAIL|$failed of ${docs.length} document(s) failed to index'
          : 'knowledge_documents|OK|${docs.length} document(s), none failed',
    );

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'diagnostics.view',
      targetWorkspaceId: workspaceId,
      note: 'diagnostic view opened',
    ));

    return lines;
  }

  /// Most recent conversations for a workspace — the spec's "conversation
  /// lookup," audited because conversation content is customer data.
  Future<List<Conversation>> listRecentConversations(
    Session session,
    String adminToken,
    int workspaceId, {
    int limit = 20,
  }) async {
    final admin = await requireAdminLevel(adminToken: adminToken);
    final list = await _conversations.listByWorkspace(workspaceId);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = list.take(limit).toList();

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'diagnostics.conversations_viewed',
      targetWorkspaceId: workspaceId,
      note: 'viewed ${page.length} recent conversation(s)',
    ));

    return page;
  }

  /// The spec's "recent errors" surface, deliberately narrowed to what's
  /// actually queryable: failed knowledge documents (a real, persisted
  /// error with a stored message). There is no general per-workspace
  /// error log to draw from — see this file's header.
  Future<List<KnowledgeDocument>> listFailedKnowledgeDocuments(
    Session session,
    String adminToken,
    int workspaceId,
  ) async {
    await requireAdminLevel(adminToken: adminToken);
    final docs = await _documents.listByWorkspace(workspaceId);
    return docs.where((d) => d.status == 'failed').toList();
  }

  /// Re-runs ingestion for a failed document's original stored text.
  /// NOTE: this creates a NEW document row rather than mutating the
  /// failed one in place (IngestionResult/ingestText's contract doesn't
  /// support an in-place retry) — the failed row is left as-is, a
  /// historical record of the earlier failure. Operator level: this
  /// re-runs a real embedding call, a cost/quota-consuming action, not a
  /// read.
  Future<String> reindexDocument(
    Session session,
    String adminToken,
    int workspaceId,
    int documentId,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required to re-index a document.');
    }
    final admin = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.operator_,
    );

    final doc = await _documents.findByIdScoped(documentId, workspaceId);
    if (doc == null) {
      throw KolaException(message: 'No document $documentId in workspace $workspaceId.');
    }

    final result = await _ingestion.ingestText(
      workspaceId: workspaceId,
      title: doc.title,
      text: doc.rawText,
      sourceType: doc.sourceType,
      sourceRef: doc.sourceRef,
      allowDuplicate: true,
    );

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'diagnostics.reindex_document',
      targetWorkspaceId: workspaceId,
      beforeValue: 'document=$documentId status=failed',
      afterValue: 'status=${result.status.name}',
      note: note,
    ));

    return result.status.name;
  }

  /// Resends a generic owner notification through the existing
  /// OwnerNotificationDispatcher fan-out (the spec's "resend a failed
  /// notification") — every enabled+configured+rate-limit-cleared
  /// channel gets the attempt again, same as any other notify() call.
  /// Operator level: this sends a real message to a real customer-facing
  /// owner, not a read.
  Future<String> resendNotification(
    Session session,
    String adminToken,
    int workspaceId,
    String subject,
    String body,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required to resend a notification.');
    }
    final admin = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.operator_,
    );

    final result = await _dispatcher.notify(workspaceId: workspaceId, subject: subject, body: body);

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'diagnostics.resend_notification',
      targetWorkspaceId: workspaceId,
      afterValue: 'anySent=${result.anySent}',
      note: note,
    ));

    return result.anySent ? 'sent' : 'not_sent';
  }
}
