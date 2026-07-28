// support_ticket_repository.dart
//
// All database read/write operations for SupportTicket records (task
// #130 / Phase 8b).
//
// MULTI-TENANCY: every per-workspace method filters by workspaceId, same
// convention as every other repository in this project — EXCEPT
// [listOpenPastDeadline], which is deliberately global (no workspaceId
// param), same precedent as ChannelRepository.listConnected() /
// WorkspaceRepository.listByStatus(): a background sweep that runs once
// for the whole server needs to find rows across every workspace in one
// query, not iterate workspace-by-workspace.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/support_ticket_dto.dart';
import 'supabase_client.dart';

final _log = Logger('SupportTicketRepository');

const _dto = SupportTicketDto();

/// priority → how long from creation until slaDeadline. Illustrative
/// defaults, same "not final, easy to retune without touching calling
/// code" spirit as NotificationRateLimiter's daily caps — retune here,
/// not in create()'s call sites.
const Map<String, Duration> _slaDurationByPriority = {
  'urgent': Duration(hours: 2),
  'high': Duration(hours: 8),
  'medium': Duration(hours: 24),
  'low': Duration(hours: 72),
};

class SupportTicketRepository {
  const SupportTicketRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<SupportTicket?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, workspaceId=$workspaceId)');
    final response = await supabase
        .from('support_tickets')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every ticket for a workspace, newest first — the ticket-list view.
  /// [status] optionally narrows to one status (e.g. just 'open' ones).
  Future<List<SupportTicket>> listByWorkspace(int workspaceId, {String? status}) async {
    _log.fine('listByWorkspace($workspaceId, status=$status)');
    final response = status == null
        ? await supabase
            .from('support_tickets')
            .select()
            .eq('workspace_id', workspaceId)
            .order('created_at', ascending: false)
        : await supabase
            .from('support_tickets')
            .select()
            .eq('workspace_id', workspaceId)
            .eq('status', status)
            .order('created_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every still-open ('open' or 'inProgress') ticket across EVERY
  /// workspace whose slaDeadline has already passed — see file header on
  /// why this is deliberately global. SupportTicketSlaSweepService is the
  /// one caller.
  Future<List<SupportTicket>> listOpenPastDeadline({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).toUtc();
    _log.fine('listOpenPastDeadline(cutoff=$cutoff)');
    final response = await supabase
        .from('support_tickets')
        .select()
        .inFilter('status', ['open', 'inProgress'])
        .lt('sla_deadline', cutoff.toIso8601String());

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Creates a ticket with slaDeadline computed from [priority] — see
  /// [_slaDurationByPriority]. Throws [ArgumentError] on an unrecognized
  /// priority rather than silently defaulting, since a wrong SLA window
  /// is worse than a loud failure at creation time.
  Future<SupportTicket> create({
    required int workspaceId,
    required int conversationId,
    required String subject,
    required String description,
    required String priority,
  }) async {
    final duration = _slaDurationByPriority[priority];
    if (duration == null) {
      throw ArgumentError(
        'Unknown priority "$priority" — must be one of: '
        '${_slaDurationByPriority.keys.join(", ")}',
      );
    }

    final now = DateTime.now().toUtc();
    _log.info(
      'Creating support ticket workspaceId=$workspaceId conversationId=$conversationId priority=$priority',
    );

    final ticket = SupportTicket(
      workspaceId: workspaceId,
      conversationId: conversationId,
      subject: subject,
      description: description,
      priority: priority,
      status: 'open',
      slaDeadline: now.add(duration),
      resolvedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final row = _dto.toRow(ticket, includeId: false);
    row['created_at'] = now.toIso8601String();
    final response = await supabase.from('support_tickets').insert(row).select().single();
    return _dto.fromRow(response);
  }

  /// Transitions status — sets resolvedAt automatically the moment status
  /// becomes 'resolved' or 'closed', clears it (back to null) if a ticket
  /// is ever reopened to 'open'/'inProgress' from one of those.
  Future<SupportTicket> setStatus(int ticketId, String status) async {
    _log.info('setStatus ticketId=$ticketId status=$status');
    final now = DateTime.now().toUtc();
    final isResolved = status == 'resolved' || status == 'closed';

    final response = await supabase
        .from('support_tickets')
        .update({
          'status': status,
          'resolved_at': isResolved ? now.toIso8601String() : null,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', ticketId)
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
