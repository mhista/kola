// admin_overview_endpoint.dart — kola_admin, "Overview" landing page.
// Added in a robustness pass after the initial "build everything admin
// related" push: Overview was the one nav item still pointing nowhere
// even though every other surface it would summarize (workspaces,
// platform health, audit log, support queue) was already real by then.
//
// DELIBERATELY THIN: this endpoint does not introduce any new tracked
// metric — it only aggregates numbers that other admin endpoints already
// expose individually (AdminPlatformEndpoint's sweep/AI/embedding
// status, WorkspaceRepository's rows, SupportTicketRepository's open
// queue) into one call, so the landing page loads in one round trip
// instead of five. Anything genuinely NOT tracked elsewhere (error
// rates, queue depth) is not tracked here either — see
// AdminPlatformEndpoint's header for why those stay honest gaps rather
// than fabricated numbers.
//
// AUTHORISATION: Support level, read-only, same bar as every other
// summary/listing endpoint in this file's siblings.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/platform_health_registry.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';
import 'package:kola_server/src/services/ai/ai_orchestrator.dart';
import 'package:kola_server/src/services/memory/embedding_orchestrator.dart';
import 'package:kola_server/src/services/repository/admin_audit_log_repository.dart';
import 'package:kola_server/src/services/repository/support_ticket_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';

class AdminOverviewEndpoint extends Endpoint {
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  SupportTicketRepository get _tickets => getIt<SupportTicketRepository>();
  AdminAuditLogRepository get _audit => getIt<AdminAuditLogRepository>();
  AiOrchestrator get _ai => getIt<AiOrchestrator>();
  EmbeddingOrchestrator get _embeddings => getIt<EmbeddingOrchestrator>();

  /// "key|value" lines: workspace counts by status, open ticket count,
  /// sweep job pass/fail counts since last restart, AI providers
  /// configured, embedding availability. One call, everything the
  /// landing page needs.
  Future<List<String>> getSummary(Session session, String adminToken) async {
    await requireAdminLevel(adminToken: adminToken);

    final workspaces = await _workspaces.listAllUncapped();
    final byStatus = <String, int>{};
    for (final w in workspaces) {
      byStatus[w.status] = (byStatus[w.status] ?? 0) + 1;
    }

    final openTickets = await _tickets.listOpenGlobal(limit: 5000);

    final sweeps = PlatformHealthRegistry.snapshot();
    final sweepsOk = sweeps.where((s) => s.split('|').length > 2 && s.split('|')[2] == 'true').length;
    final sweepsFailed = sweeps.length - sweepsOk;

    final aiConfigured = _ai.providerConfigStatus.values.where((v) => v).length;

    return [
      'workspaces_total|${workspaces.length}',
      for (final entry in byStatus.entries) 'workspaces_${entry.key}|${entry.value}',
      'open_tickets|${openTickets.length}',
      'sweep_jobs_reported|${sweeps.length}',
      'sweep_jobs_ok|$sweepsOk',
      'sweep_jobs_failed|$sweepsFailed',
      'ai_providers_configured|$aiConfigured',
      'embedding_available|${_embeddings.isAvailable}',
    ];
  }

  /// The 5 most recent audit log entries, same formatted-line shape as
  /// AdminAuditLogEndpoint.listRecent, just pre-limited for a compact
  /// landing-page widget rather than the full log page.
  Future<List<String>> getRecentActivity(Session session, String adminToken) async {
    await requireAdminLevel(adminToken: adminToken);
    return _audit.listRecent(limit: 5);
  }
}
