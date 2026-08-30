// admin_audit_log_repository.dart — kola_admin, step 2. Append-only:
// this repository intentionally has no update or delete method, and
// none should ever be added — see admin_audit_log.dart's header.

import 'package:logging/logging.dart';
import '../admin/admin_audit_log.dart';
import 'supabase_client.dart';

final _log = Logger('AdminAuditLogRepository');

class AdminAuditLogRepository {
  const AdminAuditLogRepository();

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
