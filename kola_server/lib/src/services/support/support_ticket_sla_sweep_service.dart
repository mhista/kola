// support_ticket_sla_sweep_service.dart
//
// Task #130 / Phase 8b's other half: actually detecting an SLA breach
// and telling the workspace owner about it, the same "sweep + notify"
// shape as trial_sweep_service.dart (trialing → paused) and
// channel_health_check_service.dart (dead credential → flagged). Wired
// to run on an interval from server.dart via a plain Dart Timer, same
// reasoning as those two: Serverpod Mini has no Postgres of its own, so
// there's no FutureCall infrastructure to lean on, and a Timer inside
// the same long-running process costs nothing extra.
//
// A BREACHED TICKET IS NOT AUTO-CLOSED OR AUTO-ESCALATED — this service
// only notifies. Deciding what happens next (reassign, escalate the
// underlying Conversation, etc.) is a human call; silently mutating a
// ticket's own state on breach would hide the fact that something needs
// attention behind a status change nobody asked for.
//
// NOTIFIED-ONCE, NOT EVERY SWEEP: without some memory of "already told
// the owner about this one," a ticket sitting breached across many sweep
// intervals would re-notify every single time — the kind of notification
// fatigue notification_rate_limiter.dart's daily-cap mechanism exists to
// prevent for OTHER channels, but this service sits upstream of that (one
// notify() call, fanned out across whichever channels are enabled), so it
// needs its own dedupe. No dedicated `notifiedAt` column exists for this
// v1 — instead [_alreadyNotified] uses a bounded grace window right
// after slaDeadline passes (sized to this sweep's own interval, see
// server.dart): a ticket is notified exactly once, on the first sweep
// that observes it within that window of its deadline. A ticket first
// observed breached well outside the window (e.g. the server was down
// for a while) is treated as already-handled rather than re-surfaced
// late — an acceptable v1 trade-off flagged honestly, not hidden.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/support_ticket_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/notifications/owner_notification_dispatcher.dart';

class SupportTicketSlaSweepService {
  SupportTicketSlaSweepService({
    required SupportTicketRepository tickets,
    required ConversationRepository conversations,
    required OwnerNotificationDispatcher notifications,
  }) : _tickets = tickets,
       _conversations = conversations,
       _notifications = notifications;

  final SupportTicketRepository _tickets;
  final ConversationRepository _conversations;
  final OwnerNotificationDispatcher _notifications;

  /// Finds every open/inProgress ticket whose slaDeadline has passed and
  /// notifies that ticket's workspace owner, one ticket at a time so a
  /// single bad row can't stop the rest of the sweep. Returns how many
  /// notifications were actually sent this run.
  Future<int> sweepOnce({DateTime? now}) async {
    final n = (now ?? DateTime.now()).toUtc();
    final breached = await _tickets.listOpenPastDeadline(now: n);

    var notified = 0;
    for (final ticket in breached) {
      if (_alreadyNotified(ticket, now: n)) continue;

      try {
        await _notifyBreach(ticket);
        notified++;
      } catch (e) {
        Log.error('SupportTicketSlaSweepService: failed to notify for ticket ${ticket.id}', error: e);
      }
    }
    return notified;
  }

  /// True once a ticket's breach is outside the notify window — i.e. a
  /// prior sweep already had its chance to notify on this one, so this
  /// sweep skips it. The window (2h) is sized to comfortably straddle
  /// the sweep interval (1h, see server.dart) plus startup jitter, so a
  /// freshly-breached ticket is guaranteed to be caught by at least one
  /// sweep while it's still inside the window. KNOWN v1 LIMITATION,
  /// flagged honestly: if the server is down long enough that a ticket's
  /// breach is only first observed AFTER the window has already closed,
  /// it's treated as already-handled and silently never notified — a
  /// dedicated `notifiedAt` column would remove this edge case entirely
  /// and is the natural v2 fix if it turns out to matter in practice.
  bool _alreadyNotified(SupportTicket ticket, {required DateTime now}) {
    const notifyWindow = Duration(hours: 2);
    return now.difference(ticket.slaDeadline) > notifyWindow;
  }

  Future<void> _notifyBreach(SupportTicket ticket) async {
    final conversation = await _conversations.findByIdScoped(
      ticket.conversationId,
      ticket.workspaceId,
    );
    final customerLabel = conversation?.displayName?.trim().isNotEmpty == true
        ? conversation!.displayName!
        : (conversation?.externalUserId ?? 'a customer');

    await _notifications.notify(
      workspaceId: ticket.workspaceId,
      subject: 'A support ticket missed its SLA — Kola',
      body:
          'Ticket "${ticket.subject}" (priority: ${ticket.priority}) from $customerLabel '
          'was due by ${ticket.slaDeadline.toIso8601String()} and is still ${ticket.status}.\n\n'
          'Open your Kola inbox to follow up.',
    );

    Log.warning(
      'SupportTicketSlaSweepService: ticket ${ticket.id} breached SLA (workspaceId=${ticket.workspaceId})',
    );
  }
}
