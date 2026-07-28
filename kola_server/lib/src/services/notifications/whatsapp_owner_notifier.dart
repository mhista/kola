// whatsapp_owner_notifier.dart
//
// Sends an escalation ping to the owner's WhatsApp number — FROM one of
// the WORKSPACE'S OWN connected WhatsApp channels (found at send time
// below), never from a separate Kola-owned number. This is the one
// owner-notification channel that reuses existing live infra
// (WhatsAppBotRegistry) rather than standing up anything new, which is
// also exactly why it only works if the workspace actually has a
// connected WhatsApp channel — see isReady().

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_bot_registry.dart';
import 'owner_notifier.dart';

class WhatsAppOwnerNotifier implements OwnerNotifier {
  BotRepository get _bots => getIt<BotRepository>();
  ChannelRepository get _channels => getIt<ChannelRepository>();

  @override
  String get channel => 'whatsapp';

  @override
  bool isReady(OwnerNotificationSettings settings) {
    final number = settings.ownerWhatsappNumber;
    return settings.whatsappEnabled && number != null && number.trim().isNotEmpty;
  }

  @override
  Future<OwnerNotifierResult> send({
    required OwnerNotificationSettings settings,
    required String subject,
    required String body,
  }) async {
    if (!isReady(settings)) return OwnerNotifierResult.disabled;

    final senderChannelId = await _findConnectedWhatsAppChannelId(settings.workspaceId);
    if (senderChannelId == null) return OwnerNotifierResult.notConfigured;

    final adapter = WhatsAppBotRegistry.instance.messagingFor(senderChannelId);
    if (adapter == null) return OwnerNotifierResult.notConfigured;

    final result = await adapter.sendText(
      recipient: settings.ownerWhatsappNumber!,
      text: body,
    );

    return OwnerNotifierResult(
      sent: result.success,
      skipReason: result.success ? null : result.errorMessage,
    );
  }

  /// The first connected WhatsApp channel belonging to any bot in
  /// [workspaceId] — two-step lookup (bots, then that bot's WhatsApp
  /// channel) rather than a single joined Supabase query, since a
  /// verified, safe join syntax for this specific shape wasn't worth
  /// guessing at (same caution that already caught real Relic API bugs
  /// elsewhere in this project) when a plain two-step lookup is just as
  /// correct and easier to verify by reading.
  Future<int?> _findConnectedWhatsAppChannelId(int workspaceId) async {
    final bots = await _bots.listByWorkspace(workspaceId);
    for (final bot in bots) {
      if (bot.id == null) continue;
      final channel = await _channels.findByBotAndPlatform(bot.id!, 'whatsapp');
      if (channel != null && channel.status == 'connected' && channel.id != null) {
        return channel.id;
      }
    }
    return null;
  }
}
