// platform_health_registry.dart — ADMIN_APP_SPEC.md §3.5 "platform
// health", build-order step 6, deferred until this pass.
//
// WHAT THIS IS: a plain in-memory, process-static record of "when did
// each background sweep job last run, and what happened" — nothing
// persisted, nothing queryable across a restart or across more than one
// server instance. That is a real, stated limitation (see
// docs/ADMIN_CONTROL_PLANE_STATUS.md), not an oversight: today there is
// exactly one running instance of kola_server (same single-instance
// assumption SecurityFilter's in-memory rate limiter already documents),
// so a static map is a faithful mirror of "is this job actually alive"
// for as long as that remains true. If Kola ever runs more than one
// instance, this needs to move to a real table the same way
// SecurityFilter's rate limiter would.
//
// WHY A SEPARATE FILE RATHER THAN EACH SWEEP SERVICE OWNING ITS OWN
// STATUS: every sweep service already returns a plain `int` from its
// `sweepOnce()`/`runOnce()` — changing that return shape to also report
// pass/fail status would touch six unrelated files and their own
// existing tests. Recording happens at the ONE place all six are already
// invoked from — server.dart's startup sequence — by wrapping each call.
// No sweep service needs to import or know about this registry at all.

class PlatformHealthEntry {
  const PlatformHealthEntry({
    required this.jobName,
    required this.lastRunAt,
    required this.ok,
    required this.summary,
  });

  final String jobName;
  final DateTime lastRunAt;
  final bool ok;
  final String summary;
}

class PlatformHealthRegistry {
  PlatformHealthRegistry._();

  static final Map<String, PlatformHealthEntry> _entries = {};

  static void record(String jobName, {required bool ok, required String summary}) {
    _entries[jobName] = PlatformHealthEntry(
      jobName: jobName,
      lastRunAt: DateTime.now().toUtc(),
      ok: ok,
      summary: summary,
    );
  }

  /// Formatted "job|lastRunAt|ok|summary" lines — see AdminAuditLogRepository
  /// .listRecent's header for why a formatted String list, not a new
  /// generated model, is this project's default for admin-only read
  /// surfaces that don't need to be queried by anything but a table on a
  /// page.
  static List<String> snapshot() {
    return _entries.values
        .map((e) =>
            '${e.jobName}|${e.lastRunAt.toIso8601String()}|${e.ok}|${e.summary}')
        .toList();
  }
}
