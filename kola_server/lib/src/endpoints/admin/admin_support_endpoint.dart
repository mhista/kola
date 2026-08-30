// admin_support_endpoint.dart — kola_admin, "Support queue" as its own
// page (deferred nav item, built this pass). Thin wrapper over
// SupportTicketRepository.listOpenGlobal (added this pass) — every
// open/in-progress ticket across every workspace, the cross-tenant view
// an admin needs that no workspace-scoped dashboard page can show.
// Support level: read-only, matches this being the literal "Support"
// queue.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';
import 'package:kola_server/src/services/repository/support_ticket_repository.dart';

class AdminSupportEndpoint extends Endpoint {
  SupportTicketRepository get _tickets => getIt<SupportTicketRepository>();

  Future<List<SupportTicket>> listOpenTickets(Session session, String adminToken, {int limit = 200}) async {
    await requireAdminLevel(adminToken: adminToken);
    return _tickets.listOpenGlobal(limit: limit);
  }
}
