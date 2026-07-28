// owner_notifier.dart
//
// The one interface every owner-notification channel implements — same
// "pluggable behind one interface" rule messaging (IMessagingService)
// and AI (AiProvider) already follow in this project.
// OwnerNotificationDispatcher never touches WhatsApp/Telegram/email/SMS
// specifics directly, only this.

import 'package:kola_server/src/generated/protocol.dart';

class OwnerNotifierResult {
  const OwnerNotifierResult({required this.sent, this.skipReason});

  /// True if the notification was actually sent.
  final bool sent;

  /// Set when [sent] is false — e.g. "not configured", "not implemented
  /// yet" — so the dispatcher can log/report exactly why a channel was
  /// skipped instead of a bare false. Rate-limit skips are decided (and
  /// their reason logged) by the dispatcher itself, before a notifier's
  /// send() is even called — see owner_notification_dispatcher.dart.
  final String? skipReason;

  static const notConfigured = OwnerNotifierResult(sent: false, skipReason: 'not configured');
  static const disabled = OwnerNotifierResult(sent: false, skipReason: 'disabled');
}

abstract class OwnerNotifier {
  /// 'whatsapp' | 'telegram' | 'email' | 'sms' — matches
  /// OwnerNotificationSend.channel and NotificationRateLimiter's keys.
  String get channel;

  /// Whether [settings] has this channel both enabled AND has the
  /// contact info this notifier needs (e.g. a non-empty
  /// ownerWhatsappNumber) — checked by the dispatcher BEFORE consulting
  /// the rate limiter, so a disabled/unconfigured channel never counts
  /// against a workspace's daily cap.
  bool isReady(OwnerNotificationSettings settings);

  /// Sends a short escalation ping. [subject] is used only by channels
  /// that have a concept of one (email); channels without one (chat
  /// messages) fold it into [body] or ignore it. Callers must have
  /// already confirmed [isReady] and cleared the rate limiter — this
  /// method itself does neither check.
  Future<OwnerNotifierResult> send({
    required OwnerNotificationSettings settings,
    required String subject,
    required String body,
  });
}
