// admin_platform_endpoint.dart — kola_admin, ADMIN_APP_SPEC.md §3.5,
// build-order step 6, deferred until this pass ("build up everything
// admin related").
//
// WHAT'S REAL HERE VS. WHAT WOULD BE FABRICATED:
//   Real: sweep-job last-run status (see PlatformHealthRegistry — an
//   honest, in-memory, single-instance mirror of the six Timer.periodic
//   jobs in server.dart), AI provider configured/not-configured status
//   (AiOrchestrator.providerConfigStatus — a key-presence check, not a
//   reachability ping, see that getter's header), and the embedding
//   provider's availability/active model/daily free-tier cap (the cap is
//   a documented constant, NOT a live usage counter — see
//   [embeddingQuotaInfo]'s header for why no such counter exists today).
//
//   NOT built, stated honestly rather than invented: error rates and
//   queue depth. No error-log table or job-queue system exists anywhere
//   in this codebase to aggregate from — inventing a number here would
//   be fabricating a metric, which this project's own standing
//   discipline (see AdminWorkspaceEndpoint's header, WorkspaceRepository
//   .search's header) explicitly refuses to do. kola_admin's platform
//   health page shows this as a visible "not tracked" note, not a fake
//   0 or empty chart.
//
// AUTHORISATION: read-only across the board — Support level, same bar as
// every other read-only admin surface (listWorkspaces, getWorkspace).

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/platform_health_registry.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';
import 'package:kola_server/src/services/ai/ai_orchestrator.dart';
import 'package:kola_server/src/services/memory/embedding_orchestrator.dart';

class AdminPlatformEndpoint extends Endpoint {
  AiOrchestrator get _ai => getIt<AiOrchestrator>();
  EmbeddingOrchestrator get _embeddings => getIt<EmbeddingOrchestrator>();

  /// One formatted "jobName|lastRunAtIso|ok|summary" line per sweep job
  /// that has run at least once since this process started. A job
  /// missing from the list means it hasn't ticked yet since boot (or the
  /// process just restarted) — not that it's broken; kola_admin's page
  /// shows that distinction in its own copy.
  Future<List<String>> listSweepJobStatuses(Session session, String adminToken) async {
    await requireAdminLevel(adminToken: adminToken);
    return PlatformHealthRegistry.snapshot();
  }

  /// One "providerName|configured" line per AI provider in cascade
  /// order. See [AiOrchestrator.providerConfigStatus]'s header on why
  /// this is a key-presence check, not a live ping.
  Future<List<String>> listAiProviderStatus(Session session, String adminToken) async {
    await requireAdminLevel(adminToken: adminToken);
    return _ai.providerConfigStatus.entries.map((e) => '${e.key}|${e.value}').toList();
  }

  /// Embedding subsystem status. The daily-cap figure (1500) is Gemini's
  /// own published free-tier limit for the embedding model this project
  /// uses — a real, documented number — NOT a live "requests used today"
  /// counter, because no such counter is tracked anywhere in
  /// EmbeddingOrchestrator or its providers today. Stated as a static
  /// cap alongside "usage not tracked" rather than showing a progress
  /// bar against a number that doesn't exist.
  Future<String> embeddingQuotaInfo(Session session, String adminToken) async {
    await requireAdminLevel(adminToken: adminToken);
    if (!_embeddings.isAvailable) {
      return 'unavailable|no embedding provider configured (set GEMINI_API_KEY)';
    }
    return 'available|${_embeddings.activeModel}|${_embeddings.dimensions}|dailyCap=1500|usageTracked=false';
  }
}
