// support_ticket_endpoint.dart
//
// Task #130 / Phase 8b — the bare-bones surface for a human to see and
// resolve support tickets a bot opened, WITHOUT building a full
// dashboard ticket queue yet. Same "full loop but not the full Phase 4
// dashboard" scope line as ConversationEndpoint/OwnerNotificationEndpoint
// — mirrors ConversationEndpoint's shape exactly: requireWorkspaceAccess
// on every method, findByIdScoped before any mutation, Log.success on
// writes.
//
// Tickets themselves are only ever CREATED by a bot via the
// 'createSupportTicket' built-in Errand (builtin_errand_executor.dart) —
// there's no manual-create method here, since a ticket without a
// conversationId behind it doesn't fit this feature's shape (see
// support_ticket.spy.yaml's header on why a ticket is tied to a thread).

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/support_ticket_repository.dart';
import 'package:kola_server/kola_logger.dart';

class SupportTicketEndpoint extends Endpoint {
  SupportTicketRepository get _tickets => getIt<SupportTicketRepository>();

  /// Every ticket for a workspace, newest first. [status] optionally
  /// narrows to one status (e.g. just the open queue).
  Future<List<SupportTicket>> list(
    Session session,
    String accessToken,
    int workspaceId, {
    String? status,
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _tickets.listByWorkspace(workspaceId, status: status);
  }

  /// Transitions a ticket's status — 'open' | 'inProgress' | 'resolved' |
  /// 'closed'. Setting to 'resolved'/'closed' stamps resolvedAt
  /// automatically (see SupportTicketRepository.setStatus); reopening
  /// back to 'open'/'inProgress' clears it.
  Future<SupportTicket> setStatus(
    Session session,
    String accessToken,
    int workspaceId,
    int ticketId,
    String status,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    await _requireTicketInWorkspace(ticketId, workspaceId);

    const validStatuses = {'open', 'inProgress', 'resolved', 'closed'};
    if (!validStatuses.contains(status)) {
      throw Exception('Unknown status "$status" — must be one of: ${validStatuses.join(", ")}');
    }

    final updated = await _tickets.setStatus(ticketId, status);

    Log.success(
      'Support ticket status updated',
      data: {'workspaceId': workspaceId, 'ticketId': ticketId, 'status': status},
      session: session,
    );

    return updated;
  }

  Future<SupportTicket> _requireTicketInWorkspace(int ticketId, int workspaceId) async {
    final ticket = await _tickets.findByIdScoped(ticketId, workspaceId);
    if (ticket == null) {
      throw Exception('SupportTicket $ticketId not found in workspace $workspaceId');
    }
    return ticket;
  }
}
