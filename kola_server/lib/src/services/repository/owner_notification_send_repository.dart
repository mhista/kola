// owner_notification_send_repository.dart
//
// All database read/write operations for OwnerNotificationSend — see
// owner_notification_send.spy.yaml. Exists purely to support
// notification_rate_limiter.dart's per-plan daily caps.

import 'package:logging/logging.dart';
import 'package:kola_server/src/services/repository/supabase_client.dart';

final _log = Logger('OwnerNotificationSendRepository');

/// Narrow interface notification_rate_limiter.dart depends on, rather
/// than the concrete repository class directly — keeps that file's
/// dependency to exactly the two methods it calls.
abstract class OwnerNotificationSendRepositoryLike {
  Future<void> record({required int workspaceId, required String channel});
  Future<int> countSince({
    required int workspaceId,
    required String channel,
    required DateTime since,
  });
}

class OwnerNotificationSendRepository implements OwnerNotificationSendRepositoryLike {
  const OwnerNotificationSendRepository();

  /// Records one successful (or successfully-attempted) notification
  /// send, for rate-limit counting.
  Future<void> record({required int workspaceId, required String channel}) async {
    _log.fine('record workspaceId=$workspaceId channel=$channel');
    await supabase.from('owner_notification_sends').insert({
      'workspace_id': workspaceId,
      'channel': channel,
      'sent_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// How many [channel] notifications [workspaceId] has sent since
  /// [since] (typically the start of today, UTC) — what
  /// NotificationRateLimiter compares against a plan's daily cap.
  Future<int> countSince({
    required int workspaceId,
    required String channel,
    required DateTime since,
  }) async {
    _log.fine('countSince workspaceId=$workspaceId channel=$channel since=$since');
    final response = await supabase
        .from('owner_notification_sends')
        .select('id')
        .eq('workspace_id', workspaceId)
        .eq('channel', channel)
        .gte('sent_at', since.toIso8601String());

    return (response as List).length;
  }
}
