// kola_notifier_bot.dart
//
// ONE Telegram bot, owned by Kola itself (not any business's connected
// channel), used only to ping a workspace owner when a conversation
// escalates — see telegram_owner_notifier.dart. Deliberately separate
// from TelegramBotRegistry: a business may run a WhatsApp-only bot and
// still want Telegram-based owner notifications, so this can't be tied
// to whether the workspace happens to have its own Telegram channel
// connected.
//
// GETTING A CHAT ID: an owner messages this bot's /start once. It
// replies with their chat_id, which they paste into
// OwnerNotificationSettings.telegramChatId (via whatever endpoint sets
// that — no dashboard UI for it yet, same "no UI wires to this" gap
// already flagged for other Phase 3 settings). No linking-code/
// verification flow beyond that — the chat_id itself is what receiving
// notifications requires, so there's nothing more to prove.
//
// LONG-POLLING, NOT A WEBHOOK ROUTE: this bot's message volume is tiny
// (one /start per owner, ever) and doesn't warrant its own webhook
// route/route registration ceremony — TelegramService already supports
// polling mode automatically whenever no webhookUrl is given (see its
// header).

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/env.dart';
// REQUIRED for ctx.reply() below — see telegram_bot_registry.dart's
// import comment for the full explanation of why this direct import is
// necessary (an extension method, not visible via type inference alone).
import 'package:televerse/televerse.dart';
import '../messaging/telegram/telegram_service.dart';

class KolaNotifierBot {
  KolaNotifierBot._();

  static final KolaNotifierBot instance = KolaNotifierBot._();

  TelegramService? _service;

  bool get isConfigured => Env.kolaNotifierTelegramBotToken.isNotEmpty;

  /// Call once from server.dart's run(), after pod.start() — same
  /// "polling bots can start any time, nothing depends on a route
  /// existing first" reasoning as any long-polling Telegram bot.
  Future<void> start() async {
    if (!isConfigured) {
      Log.startupWarning(
        'KOLA_NOTIFIER_TELEGRAM_BOT_TOKEN not set — Telegram owner '
        'escalation notifications will not work until it is. See .env.example.',
      );
      return;
    }

    final service = TelegramService(botToken: Env.kolaNotifierTelegramBotToken);
    service.bot.command('start', (ctx) {
      final chatId = ctx.chat?.id;
      // Fire-and-forget: televerse's command handler is void-returning, so
      // this future was never awaited even when it was `return`ed.
      ctx.reply(
        chatId == null
            ? "Sorry, I couldn't read your chat ID — please try again."
            : "👋 This is Kola's notification bot.\n\n"
                "Your Telegram Chat ID is: $chatId\n\n"
                "Paste this into your Kola workspace's notification settings "
                "to receive an alert here whenever a conversation escalates "
                "to a human.",
      );
    });

    await service.start();
    _service = service;
    Log.startupSuccess('Kola notifier Telegram bot started (long-polling)');
  }

  /// Sends a plain text notification to [chatId] — the escalation ping
  /// itself. Throws if [start] was never called or the bot token isn't
  /// configured; callers (telegram_owner_notifier.dart) check
  /// [isConfigured] first specifically to avoid this.
  Future<void> sendText({required String chatId, required String text}) async {
    final service = _service;
    if (service == null) {
      throw StateError('KolaNotifierBot is not started or not configured');
    }
    await service.sendTextMessage(chatId: chatId, text: text);
  }
}
