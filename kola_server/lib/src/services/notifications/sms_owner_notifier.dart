// sms_owner_notifier.dart
//
// ARCHITECTURAL PLACEHOLDER — per the user's explicit instruction ("sms
// will come in later, but you can bake in the architecture"). This
// exists so OwnerNotificationDispatcher's channel list, the 'sms' entry
// in OwnerNotificationSettings/OwnerNotificationSend, and
// NotificationRateLimiter's design already have a real slot for SMS —
// no future rework of any of those needed, just implement send() below
// once a provider (Termii, Africa's Talking, Twilio, etc.) is chosen.
//
// isReady() always returns false, so the dispatcher always skips this
// channel with skipReason 'not implemented' rather than ever calling
// send() — send() throwing is a backstop, not the intended path.

import 'package:kola_server/src/generated/protocol.dart';
import 'owner_notifier.dart';

class SmsOwnerNotifier implements OwnerNotifier {
  @override
  String get channel => 'sms';

  @override
  bool isReady(OwnerNotificationSettings settings) => false;

  @override
  Future<OwnerNotifierResult> send({
    required OwnerNotificationSettings settings,
    required String subject,
    required String body,
  }) async {
    return const OwnerNotifierResult(sent: false, skipReason: 'not implemented');
  }
}
