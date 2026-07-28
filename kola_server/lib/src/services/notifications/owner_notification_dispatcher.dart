// owner_notification_dispatcher.dart
//
// The single entry point telegram_bot_registry.dart/
// whatsapp_bot_registry.dart (Phase 3's escalation wiring, task #95)
// call when a conversation escalates: "notify workspaceId's owner that
// escalationReason happened." Everything channel-specific — WhatsApp,
// Telegram, email, (future) SMS — and the per-plan daily caps live
// behind this one call so that wiring code never touches any of it
// directly.
//
// FAN-OUT, NOT FIRST-SUCCESS: every enabled+ready+rate-limit-cleared
// channel gets a send attempt — an owner who enabled both WhatsApp and
// email gets both, not just whichever tries first. This matches how the
// settings model is shaped (independent enabled flags per channel, not
// a single "preferred channel" field).

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/owner_notification_settings_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'notification_rate_limiter.dart';
import 'owner_notifier.dart';
import 'whatsapp_owner_notifier.dart';
import 'telegram_owner_notifier.dart';
import 'email_owner_notifier.dart';
import 'sms_owner_notifier.dart';
import 'slack_owner_notifier.dart';

class OwnerNotificationDispatchResult {
  const OwnerNotificationDispatchResult(this.perChannel);

  /// channel name -> outcome, e.g. {'whatsapp': OwnerNotifierResult(sent:
  /// true), 'email': OwnerNotifierResult(sent: false, skipReason:
  /// 'rate limited')}. Includes every channel this dispatcher knows
  /// about, whether or not the workspace even has it enabled — callers
  /// that just want "did anything go out" should check
  /// [anySent] instead of inspecting this directly.
  final Map<String, OwnerNotifierResult> perChannel;

  bool get anySent => perChannel.values.any((r) => r.sent);
}

class OwnerNotificationDispatcher {
  OwnerNotificationDispatcher({
    required OwnerNotificationSettingsRepository settingsRepo,
    required WorkspaceRepository workspaces,
    required NotificationRateLimiter rateLimiter,
    List<OwnerNotifier>? notifiers,
  }) : _settingsRepo = settingsRepo,
       _workspaces = workspaces,
       _rateLimiter = rateLimiter,
       _notifiers = notifiers ??
           [
             WhatsAppOwnerNotifier(),
             TelegramOwnerNotifier(),
             EmailOwnerNotifier(),
             SmsOwnerNotifier(),
             SlackOwnerNotifier(),
           ];

  final OwnerNotificationSettingsRepository _settingsRepo;
  final WorkspaceRepository _workspaces;
  final NotificationRateLimiter _rateLimiter;
  final List<OwnerNotifier> _notifiers;

  /// Notifies [workspaceId]'s owner on every channel they've enabled and
  /// configured, skipping (with a logged reason) any channel that's
  /// disabled, unconfigured, or over today's rate-limit cap for the
  /// workspace's plan.
  Future<OwnerNotificationDispatchResult> notifyEscalation({
    required int workspaceId,
    required String customerDisplayName,
    required String escalationReason,
  }) async {
    final subject = 'A customer needs you — Kola escalation';
    final body =
        '$customerDisplayName was escalated to a human.\n\n'
        'Reason: $escalationReason\n\n'
        'Open your Kola inbox to reply.';

    return notify(workspaceId: workspaceId, subject: subject, body: body);
  }

  /// Generic version of [notifyEscalation] — same fan-out/rate-limit
  /// logic, arbitrary subject/body. [notifyEscalation] is just the one
  /// canned message shape task #95 needs; other future callers (e.g. a
  /// "your trial is ending" notice) can reuse this directly instead of
  /// duplicating the settings-lookup/rate-limit dance.
  Future<OwnerNotificationDispatchResult> notify({
    required int workspaceId,
    required String subject,
    required String body,
  }) async {
    final settings = await _settingsRepo.findByWorkspaceId(workspaceId);
    if (settings == null) {
      Log.info('OwnerNotificationDispatcher: no settings for workspaceId=$workspaceId, skipping all channels');
      return OwnerNotificationDispatchResult({
        for (final n in _notifiers) n.channel: OwnerNotifierResult.notConfigured,
      });
    }

    final workspace = await _workspaces.findById(workspaceId);
    final plan = workspace?.plan ?? 'free';

    final results = <String, OwnerNotifierResult>{};

    for (final notifier in _notifiers) {
      if (!notifier.isReady(settings)) {
        results[notifier.channel] = OwnerNotifierResult.disabled;
        continue;
      }

      final canSend = await _rateLimiter.canSend(
        workspaceId: workspaceId,
        plan: plan,
        channel: notifier.channel,
      );
      if (!canSend) {
        Log.info(
          'OwnerNotificationDispatcher: workspaceId=$workspaceId hit daily cap for ${notifier.channel} (plan=$plan)',
        );
        results[notifier.channel] = const OwnerNotifierResult(sent: false, skipReason: 'rate limited');
        continue;
      }

      final result = await notifier.send(settings: settings, subject: subject, body: body);
      results[notifier.channel] = result;

      if (result.sent) {
        await _rateLimiter.recordSend(workspaceId: workspaceId, channel: notifier.channel);
      } else if (result.skipReason != null) {
        Log.warning(
          'OwnerNotificationDispatcher: ${notifier.channel} send failed for workspaceId=$workspaceId: ${result.skipReason}',
        );
      }
    }

    return OwnerNotificationDispatchResult(results);
  }
}
