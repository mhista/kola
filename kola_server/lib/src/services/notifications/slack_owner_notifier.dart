// slack_owner_notifier.dart
//
// Posts an escalation ping to a Slack "Incoming Webhook" URL the business
// created themselves in their own Slack workspace — see the header of
// owner_notification_settings.spy.yaml for why this is BYO like every
// other integration in this codebase, rather than a Kola-owned Slack App.
//
// Incoming webhooks take a flat {"text": "..."} POST body and return
// plain "ok" (200) on success — no JSON response to parse, unlike
// WebhookErrandExecutor's caller-defined-contract webhooks.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'owner_notifier.dart';

class SlackOwnerNotifier implements OwnerNotifier {
  @override
  String get channel => 'slack';

  @override
  bool isReady(OwnerNotificationSettings settings) {
    final url = settings.encryptedSlackWebhookUrl;
    return settings.slackEnabled && url != null && url.trim().isNotEmpty;
  }

  @override
  Future<OwnerNotifierResult> send({
    required OwnerNotificationSettings settings,
    required String subject,
    required String body,
  }) async {
    if (!isReady(settings)) return OwnerNotifierResult.disabled;

    final webhookUrl = ChannelCredentialEncryptionService.decrypt(
      settings.encryptedSlackWebhookUrl!,
    );

    // Slack has no separate subject concept for incoming webhooks — fold
    // it into the message text the same way a chat-based channel would.
    final text = '*$subject*\n$body';

    try {
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        Log.error(
          'SlackOwnerNotifier: webhook returned HTTP ${response.statusCode}: ${response.body}',
        );
        return OwnerNotifierResult(
          sent: false,
          skipReason: 'Slack webhook returned HTTP ${response.statusCode}',
        );
      }

      return const OwnerNotifierResult(sent: true);
    } catch (e) {
      Log.error('SlackOwnerNotifier failed to send: $e');
      return OwnerNotifierResult(sent: false, skipReason: e.toString());
    }
  }
}
