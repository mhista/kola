// admin_audit_log_endpoint.dart — kola_admin, "Audit log" as its own
// page (deferred nav item, built this pass). Thin: the append-only
// table already exists and is written to by every mutating admin
// endpoint; this just exposes AdminAuditLogRepository.listRecent (added
// this pass) over RPC. Support level: read-only, and the audit log
// itself is exactly the kind of thing a Support-level admin should be
// ABLE to read (visibility into what happened), even though they can't
// cause most of what's in it.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';
import 'package:kola_server/src/services/repository/admin_audit_log_repository.dart';

class AdminAuditLogEndpoint extends Endpoint {
  AdminAuditLogRepository get _audit => getIt<AdminAuditLogRepository>();

  Future<List<String>> listRecent(Session session, String adminToken, {int limit = 200}) async {
    await requireAdminLevel(adminToken: adminToken);
    return _audit.listRecent(limit: limit);
  }
}
