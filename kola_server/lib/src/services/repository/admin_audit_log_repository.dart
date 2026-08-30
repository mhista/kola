// admin_audit_log_repository.dart — kola_admin, step 2. Append-only:
// this repository intentionally has no update or delete method, and
// none should ever be added — see admin_audit_log.dart's header.

import 'package:logging/logging.dart';
import '../admin/admin_audit_log.dart';
import 'supabase_client.dart';

final _log = Logger('AdminAuditLogRepository');

class AdminAuditLogRepository {
  const AdminAuditLogRepository();

  /// Read path added for step "Audit log as its own page"
  /// (ADMIN_APP_SPEC.md build-order, deferred until this pass). Safe to
  /// add: the table itself stays append-only (no update/delete method
  /// exists or should ever exist here), this only reads it. Returns
  /// pre-formatted lines rather than a list of AdminAuditLogEntry
  /// because that class has no Serverpod wire representation (it's a
  /// plain internal Dart class, not a generated model) — see this
  /// project's "avoid inventing a new generated model when a formatted
  /// String list is enough for an admin to read" precedent
  /// (AdminFeatureEndpoint's reconcile() output is the same shape).
  Future<List<String>> listRecent({int limit = 200}) async {
    final response = await supabase
        .from('admin_audit_log')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((row) {
      final r = row as Map<String, dynamic>;
      final when = r['created_at'] ?? '';
      final actor = r['actor_email'] ?? '?';
      final level = r['actor_level'] ?? '?';
      final action = r['action'] ?? '?';
      final ws = r['target_workspace_id'];
      final feature = r['target_feature_key'];
      final before = r['before_value'];
      final after = r['after_value'];
      final note = r['note'] ?? '';
      final target = ws != null
          ? 'workspace=$ws'
          : (feature != null ? 'feature=$feature' : '-');
      return '$when|$actor ($level)|$action|$target|${before ?? '-'} -> ${after ?? '-'}|$note';
    }).toList();
  }

  Future<void> record(AdminAuditLogEntry entry) async {
    _log.info(
      'AUDIT: ${entry.actorEmail} (${entry.actorLevel}) → ${entry.action}'
      '${entry.targetFeatureKey != null ? ' [${entry.targetFeatureKey}]' : ''}'
      '${entry.targetWorkspaceId != null ? ' workspace=${entry.targetWorkspaceId}' : ''}',
    );

    await supabase.from('admin_audit_log').insert({
      'actor_email': entry.actorEmail,
      'actor_level': entry.actorLevel,
      'action': entry.action,
      'target_workspace_id': entry.targetWorkspaceId,
      'target_feature_key': entry.targetFeatureKey,
      'before_value': entry.beforeValue,
      'after_value': entry.afterValue,
      'note': entry.note,
      'ip_address': entry.ipAddress,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
