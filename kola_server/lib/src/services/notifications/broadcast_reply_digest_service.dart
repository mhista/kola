// broadcast_reply_digest_service.dart — Gate 10 (reply-absorption slice).
//
// Rev 5 Part VIII, Gate 10: "the agent absorbs the resulting reply wave
// without flooding a human." inbound_message_handler.dart already sends
// ONE owner notification per escalated conversation (see
// owner_notification_dispatcher.dart) — fine for organic traffic, but a
// broadcast can put the same question in front of hundreds of customers
// at once. If even a modest fraction reply ambiguously enough to
// escalate, that's a burst of individually-fired notifications landing
// on the owner within minutes of each other — the literal "flooding a
// human" this gate exists to prevent.
//
// THE RULE — coalesce, don't drop:
//   1st escalated reply for a broadcast (ever, or since the cooldown
//     last elapsed) -> notify immediately. An owner should hear about a
//     broadcast reply wave starting, not find out later.
//   Every escalated reply after that, while still within [_cooldown] of
//     the last notification -> counted (broadcasts.escalated_reply_count,
//     via BroadcastRepository.incrementEscalatedReplyCount), but no
//     notification fires. The count is never lost — see below.
//   The next escalated reply to arrive AFTER the cooldown has elapsed ->
//     notifies again, this time reporting the running total, and resets
//     the cooldown clock.
//
// This means a quiet broadcast (one escalation, ever) behaves exactly
// like today — one immediate notification, same as any organic
// escalation. A loud one gets an immediate heads-up followed by at most
// one notification per [_cooldown] window, each with an accurate total,
// instead of one notification per reply. Nothing is ever silently
// dropped the way NotificationRateLimiter's daily cap drops it — this
// coalesces INTO fewer sends, it doesn't discard.
//
// WHY THIS WRAPS notify() RATHER THAN notifyEscalation(): notifyEscalation
// describes a single customer's escalation; a coalesced broadcast digest
// is about a broadcast's TOTAL so far, not any one customer, so it needs
// its own subject/body rather than that canned shape.
//
// WHAT THIS DELIBERATELY DOES NOT DO (v1 scope — see the "reply-
// absorption only" cut this session's roadmap check landed on): no
// separate digest UI, no per-broadcast reply dashboard, no distinguishing
// "these 40 replies are about the same underlying question" beyond the
// running count. Those are the audience-builder/dry-run half of Gate 10,
// deliberately deferred.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/services/repository/broadcast_repository.dart';
import 'owner_notification_dispatcher.dart';

class BroadcastReplyDigestService {
  BroadcastReplyDigestService({
    required BroadcastRepository broadcasts,
    required OwnerNotificationDispatcher notifications,
  }) : _broadcasts = broadcasts,
       _notifications = notifications;

  final BroadcastRepository _broadcasts;
  final OwnerNotificationDispatcher _notifications;

  /// Below this, a lone escalated reply just isn't a "wave" — notifying
  /// immediately every time is exactly right and matches how an organic
  /// escalation already behaves. The coalescing only needs to kick in
  /// once replies start arriving faster than a human could reasonably
  /// read them one at a time.
  static const _cooldown = Duration(minutes: 15);

  /// Called by inbound_message_handler.dart INSTEAD OF
  /// OwnerNotificationDispatcher.notifyEscalation whenever the escalating
  /// conversation carries a broadcastId (see conversation.spy.yaml). Never
  /// throws outward — same "a notification failure must never block the
  /// customer's reply" discipline the caller already applies to the
  /// organic-escalation path.
  Future<void> handleEscalation({
    required int workspaceId,
    required int broadcastId,
    required String customerDisplayName,
  }) async {
    try {
      final updated = await _broadcasts.incrementEscalatedReplyCount(broadcastId);
      final total = updated.escalatedReplyCount;
      final lastSent = updated.lastDigestSentAt;
      final now = DateTime.now().toUtc();

      final shouldNotify = lastSent == null || now.difference(lastSent) >= _cooldown;
      if (!shouldNotify) {
        Log.info(
          'BroadcastReplyDigestService: broadcast $broadcastId — reply #$total from '
          '$customerDisplayName folded into the running count, still within cooldown',
        );
        return;
      }

      final subject = total == 1
          ? 'A reply to your broadcast needs you'
          : 'Replies to your broadcast need you';
      final body = total == 1
          ? '$customerDisplayName replied to your broadcast and needs a human.\n\n'
              'Open your Kola inbox to reply.'
          : '$total replies to your broadcast have needed a human so far '
              '(most recently $customerDisplayName).\n\n'
              "You'll get at most one more update like this every "
              '${_cooldown.inMinutes} minutes while replies keep coming in — '
              'open your Kola inbox to see and answer them.';

      await _notifications.notify(workspaceId: workspaceId, subject: subject, body: body);
      await _broadcasts.markDigestSent(broadcastId, now);

      Log.info(
        'BroadcastReplyDigestService: notified workspace $workspaceId about broadcast '
        '$broadcastId (total escalated replies: $total)',
      );
    } catch (e, stackTrace) {
      Log.error(
        'BroadcastReplyDigestService: failed to process escalation for broadcast $broadcastId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
