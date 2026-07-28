// telegram_owner_notifier.dart
//
// Wraps KolaNotifierBot.instance — the one Kola-owned Telegram bot every
// workspace's owner notifications share, regardless of whether that
// workspace has its own Telegram *channel* connected. See
// kola_notifier_bot.dart's header for the /start → chat_id flow that
// gets a value into settings.telegramChatId in the first place.

import 'package:kola_server/src/generated/protocol.dart';
import 'kola_notifier_bot.dart';
import 'owner_notifier.dart';

class TelegramOwnerNotifier implements OwnerNotifier {
  @override
  String get channel => 'telegram';

  @override
  bool isReady(OwnerNotificationSettings settings) {
    final chatId = settings.telegramChatId;
    return settings.telegramEnabled &&
        chatId != null &&
        chatId.trim().isNotEmpty &&
        KolaNotifierBot.instance.isConfigured;
  }

  @override
  Future<OwnerNotifierResult> send({
    required OwnerNotificationSettings settings,
    required String subject,
    required String body,
  }) async {
    if (!isReady(settings)) return OwnerNotifierResult.disabled;

    try {
      await KolaNotifierBot.instance.sendText(
        chatId: settings.telegramChatId!,
        text: body,
      );
      return const OwnerNotifierResult(sent: true);
    } catch (e) {
      return OwnerNotifierResult(sent: false, skipReason: e.toString());
    }
  }
}
