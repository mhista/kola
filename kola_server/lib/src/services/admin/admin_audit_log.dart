// admin_audit_log.dart — kola_admin, step 2 of ADMIN_APP_SPEC.md's build
// order, and the non-negotiable one: wired BEFORE any mutating admin
// endpoint exists (see this file's sibling admin_feature_endpoint.dart,
// which calls AdminAuditLogRepository.record on every state-changing
// method — there is no code path in this pass that mutates platform
// state without writing a row here first).
//
// Plain Dart class, same reasoning as AdminUser: nothing sends an
// AdminAuditLogEntry across the wire yet (no audit-log-reading UI in
// this pass — that's ADMIN_APP_SPEC.md §3.3/§5 step 5, explicitly
// deferred), so it stays internal-only until something needs to read it
// back through kola_admin.

class AdminAuditLogEntry {
  const AdminAuditLogEntry({
    required this.actorEmail,
    required this.actorLevel,
    required this.action,
    this.targetWorkspaceId,
    this.targetFeatureKey,
    this.beforeValue,
    this.afterValue,
    this.note,
    this.ipAddress,
  });

  final String actorEmail;
  final String actorLevel;

  /// Dot-namespaced, e.g. 'feature.state_change' — same convention as
  /// FeatureKeys, so a later admin UI can group/filter this log the
  /// same way it groups feature flags.
  final String action;

  final int? targetWorkspaceId;
  final String? targetFeatureKey;
  final String? beforeValue;
  final String? afterValue;
  final String? note;
  final String? ipAddress;
}
