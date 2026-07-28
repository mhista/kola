// notification_rate_limiter.dart
//
// Per-plan daily caps on owner notifications — explicit product
// decision: WhatsApp is capped because Meta bills per conversation;
// email is capped too (much cheaper, but still worth an abuse/cost
// ceiling); Telegram is uncapped (Telegram's Bot API has no per-message
// cost — see kola_notifier_bot.dart). Slack is likewise absent from this
// table on purpose (task #129 / Phase 8h): a Slack incoming webhook is
// free and owned by the business's own Slack workspace, not a shared
// Kola resource anyone could exhaust on Kola's behalf, so it gets the
// same "not present == unlimited" treatment as Telegram without needing
// an explicit -1 entry. SMS isn't in this table at all — SmsOwnerNotifier
// never gets far enough to need a limit checked (see its file header).
//
// -1 means unlimited. Numbers below are illustrative defaults, same
// "not final, model against real usage" spirit as PRD.md §10's pricing
// note — easy to retune here without touching any calling code.

import 'package:kola_server/src/services/repository/owner_notification_send_repository.dart';

class NotificationRateLimiter {
  NotificationRateLimiter({required OwnerNotificationSendRepositoryLike sends})
      : _sends = sends;

  final OwnerNotificationSendRepositoryLike _sends;

  static const Map<String, Map<String, int>> _dailyLimits = {
    'free': {'whatsapp': 3, 'email': 5, 'telegram': -1},
    'pro': {'whatsapp': 20, 'email': 50, 'telegram': -1},
    'business': {'whatsapp': -1, 'email': -1, 'telegram': -1},
  };

  /// Whether [workspaceId] (on [plan]) may send one more [channel]
  /// notification right now. Always true for a channel/plan combination
  /// not present in [_dailyLimits] at all (fail open on an unknown plan
  /// value rather than silently blocking every notification if `plan`
  /// ever gets a new value this table hasn't caught up with yet).
  Future<bool> canSend({
    required int workspaceId,
    required String plan,
    required String channel,
  }) async {
    final limit = _dailyLimits[plan]?[channel];
    if (limit == null || limit < 0) return true;

    final startOfDayUtc = DateTime.now().toUtc();
    final since = DateTime.utc(startOfDayUtc.year, startOfDayUtc.month, startOfDayUtc.day);

    final sentToday = await _sends.countSince(
      workspaceId: workspaceId,
      channel: channel,
      since: since,
    );

    return sentToday < limit;
  }

  Future<void> recordSend({required int workspaceId, required String channel}) {
    return _sends.record(workspaceId: workspaceId, channel: channel);
  }
}
