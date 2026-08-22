// telegram_service.dart
//
// Full-featured Telegram Bot service. This is the low-level wrapper around
// Televerse — every other piece of bot code talks to Telegram THROUGH this,
// never directly through Bot/RawAPI.
//
// MULTI-TENANCY NOTE (the one real difference from the degenbot_server
// version this was ported from):
//   Degenbot ran exactly one global Telegram bot with one token from env.
//   Kola is Bot-as-a-Service — every business connects their OWN bot,
//   created via @BotFather, so this class is instantiated ONCE PER
//   CONNECTED TELEGRAM CHANNEL, each with a different botToken. Nothing
//   in this file is actually global/static (it never was, even in
//   Degenbot — every field lives on the instance), so no rework was
//   needed to make multiple simultaneous instances safe; the only new
//   piece is TelegramBotRegistry (telegram_bot_registry.dart), which owns
//   the map of channelId → TelegramService instances.
//
// KEY DESIGN DECISION — NO BUILT-IN WEBHOOK SERVER:
//   Televerse can run its own webhook HTTP server via `_bot.startWebhook()`,
//   but we deliberately DON'T use that here. Serverpod's Relic web server
//   already owns the port this server listens on, and every connected
//   channel gets its own route (`/webhooks/telegram/<channelId>`, see
//   telegram_webhook_route.dart). Telegram POSTs updates to that route,
//   which decodes them and calls `telegramService.handleUpdate(update)` —
//   feeding the update into Televerse's internal handler pipeline without
//   Televerse ever opening its own socket.
//
// LOCAL DEV NOTE:
//   Telegram needs a public HTTPS URL to deliver webhooks to. Your
//   laptop doesn't have one. For local development, check your OWN
//   `.env`'s SERVER_PORT (NOT necessarily 8080 — this is a per-install
//   override), then run `ngrok http <that value + 1>` — webServer always
//   listens one port above whatever apiServer's SERVER_PORT actually is
//   (see server.dart's header on why there are two separate ports; every
//   webhook route, this one included, is registered on webServer, never
//   apiServer) — to get a temporary public URL, then set
//   WEBHOOK_BASE_URL to that ngrok URL in .env. Pointing ngrok at
//   SERVER_PORT itself instead of SERVER_PORT + 1 is a real, easy-to-hit
//   mistake — it 404s on every /webhooks/... path since that route isn't
//   registered on apiServer at all. In production, the server's real
//   public domain IS the webhook base — no ngrok needed there. Leaving
//   WEBHOOK_BASE_URL empty falls back to long-polling mode for every
//   bot, no ngrok required at all for day-to-day local development.

import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:televerse/telegram.dart'
    show
        Message,
        ParseMode,
        ChatAction,
        ReplyParameters,
        BotCommand,
        BotCommandScope,
        ReplyMarkup,
        MessageEntity,
        InputPollOption,
        PollType,
        InlineKeyboardMarkup,
        LinkPreviewOptions,
        User,
        Update,
        InlineKeyboardButton;
import 'package:televerse/televerse.dart';

final _log = Logger('TelegramService');

/// Enhanced Telegram Bot service with full feature support. One instance
/// per connected Telegram Channel — see the multi-tenancy note above.
class TelegramService {
  TelegramService._({
    required String botToken,
    this.webhookUrl,
    this.webhookPort,
  }) : _bot = Bot(botToken);

  factory TelegramService({
    required String botToken,
    String? webhookUrl,
    int? webhookPort,
  }) {
    return TelegramService._(
      botToken: botToken,
      webhookUrl: webhookUrl,
      webhookPort: webhookPort,
    );
  }
  
  final Bot _bot;
  final String? webhookUrl;
  final int? webhookPort;
  bool _isStarted = false;

  Bot get bot => _bot;
  RawAPI get api => _bot.api;

  // ==================== LIFECYCLE ====================

  /// Start the bot — DOES NOT start Televerse's own webhook server.
  /// Serverpod's Relic route handles the actual HTTP endpoint; this just
  /// authenticates the bot and, if a webhookUrl is configured, registers
  /// it with Telegram's servers via setWebhook (a one-time API call, not
  /// a running server).
  Future<void> start() async {
    if (_isStarted) return;

    try {
      _log.info('Initializing Telegram bot...');

      final me = await api.getMe();
      _log.info('Bot authenticated: @${me.username}');

      if (webhookUrl != null && webhookUrl!.isNotEmpty) {
        try {
          await _configureWebhook();

          // Televerse's Bot.handleUpdate() silently no-ops until the bot is
          // "running" (internal _isRunning flag set by _bot.start()). In webhook
          // mode we don't want long-polling — so we pass a _NoOpFetcher that
          // never actually contacts Telegram. This lets start() run its
          // initialization (getMe → botInfo) and set _isRunning = true without
          // triggering any polling loop or 409 Conflict errors.
          _log.info('Webhook mode: initializing bot with no-op fetcher (no polling)...');
          unawaited(_bot.start(_NoOpFetcher()));

          // Give initialize()/getMe() ~300ms to complete before the first
          // webhook update could arrive (Telegram needs to receive our
          // setWebhook ACK before it begins delivering — typically >500ms).
          await Future.delayed(const Duration(milliseconds: 300));
          _log.info('Webhook mode: bot initialized — ready for updates');
        } catch (e) {
          _log.warning(
            'Webhook registration failed ($e). '
            'Falling back to long-polling mode. '
            'Check that WEBHOOK_BASE_URL is publicly reachable by Telegram.',
          );
          // NOT awaited — see the header comment below _NoOpFetcher (bug
          // found 2026-08-22): Bot.start() with a real LongPollingFetcher
          // does not return once it starts, the polling loop IS the
          // awaited Future, by design, for as long as the bot runs. This
          // used to be `await _bot.start();` here, which meant this
          // method's own caller (and everything sequenced after it —
          // server.dart's trial sweep, ticket SLA sweep, customer
          // campaign sweep, and critically the connector sync sweep that
          // Google Sheets/Paystack/Flutterwave/etc. depend on) never ran
          // on any deploy that reached this bot: server.dart's startup
          // sequence was permanently stuck inside this one `await`,
          // confirmed by a production boot log showing zero log lines
          // for anything past this point, ever, across many deploys.
          unawaited(_bot.start());
          _log.info('Telegram bot started in polling mode (webhook fallback)');
        }
      } else {
        _log.info('No webhook URL configured — using long-polling mode');
        // Same fix, same reason — see the catch block above.
        unawaited(_bot.start());
        _log.info('Telegram bot started in polling mode');
      }

      _isStarted = true;
      _log.info('Telegram service fully initialized');
    } catch (e, stackTrace) {
      _log.severe('Failed to start Telegram bot: $e', e, stackTrace);

      if (e.toString().contains('Network') || e.toString().contains('Dio')) {
        _log.warning(
          'NETWORK ERROR — check internet connection, VPN if Telegram '
          'is blocked in your region, and that the bot token is correct.',
        );
      }

      rethrow;
    }
  }

  /// Registers our webhook URL with Telegram's servers. This tells
  /// Telegram "POST updates to THIS url" — it does not start any local
  /// server. The actual receiving route lives in telegram_webhook_route.dart.
  Future<void> _configureWebhook() async {
    try {
      _log.info('Setting webhook URL: $webhookUrl');

      await api.deleteWebhook(dropPendingUpdates: true);

      // FIXED (found via a real `dart analyze` run — this file was
      // authored without a Dart SDK available to verify it):
      // setWebhook takes the URL as its first POSITIONAL argument, not a
      // named `url:` — and the value here was a literal string
      // "webhookUrl!" (11 characters, a copy-paste-shaped typo) instead
      // of the actual webhookUrl variable. allowedUpdates also takes raw
      // UpdateType enum values, not .name strings — confirmed against
      // degenbot_server's identical, real-Dart-SDK-verified call.
      final success = await api.setWebhook(
        webhookUrl!,
        allowedUpdates: [
          UpdateType.message,
          UpdateType.editedMessage,
          UpdateType.callbackQuery,
          UpdateType.inlineQuery,
          UpdateType.chosenInlineResult,
          UpdateType.myChatMember,
          UpdateType.chatMember,
        ],
      );

      if (success) {
        _log.info('Webhook configured successfully');
        final info = await api.getWebhookInfo();
        _log.info('Webhook info: url=${info.url} pending=${info.pendingUpdateCount}');
        if (info.lastErrorMessage != null) {
          _log.warning('Last webhook error: ${info.lastErrorMessage}');
        }
      } else {
        _log.warning('Failed to set webhook');
      }
    } catch (e) {
      _log.severe('Error configuring webhook: $e');
      rethrow; // caller (start()) catches this and falls back to polling
    }
  }

  /// Feed a Telegram Update into Televerse's handler pipeline. Called by
  /// telegram_bot_registry.dart after decoding the raw webhook POST body.
  ///
  /// IMPORTANT — WHY runZonedGuarded:
  ///   Televerse's Bot.handleUpdate() is a VOID function (not `Future<void>`).
  ///   The official serverless example is: `bot.handleUpdate(update)` — no await.
  ///   It fires the handler chain asynchronously inside a new zone.
  ///   Errors thrown by our handlers do NOT bubble up through our try/catch —
  ///   they escape into an untracked zone and are silently swallowed.
  ///   runZonedGuarded catches them.
  Future<void> handleUpdate(Update update) async {
    if (!_isStarted) {
      _log.warning('Bot not started — ignoring update ${update.updateId}');
      return;
    }

    runZonedGuarded(
      () {
        // void return — the handler chain runs asynchronously in this zone.
        // Any uncaught error in the chain will surface in the error callback below.
        _bot.handleUpdate(update);
      },
      (e, st) {
        // Catches errors from the async handler chain that escape Televerse's
        // own error handler (bot.onError). Log everything so nothing is silent.
        _log.severe('Zone error from bot handler chain (update ${update.updateId}): $e', e, st);
      },
    );
  }

  Future<bool> isConnected() async {
    if (!_isStarted) return false;
    try {
      await api.getMe().timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      _log.warning('Connection check failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (!_isStarted) return;
    try {
      if (webhookUrl != null) {
        await api.deleteWebhook();
        _log.info('Webhook deleted');
      }
    } catch (e) {
      _log.warning('Error deleting webhook: $e');
    }
    _isStarted = false;
    _log.info('Telegram bot stopped');
  }

  void dispose() {
    stop();
    _log.info('TelegramService disposed');
  }

  void _ensureConnected() {
    if (!_isStarted) {
      throw Exception('Telegram bot is not started');
    }
  }

  // ==================== BASIC MESSAGING ====================

  Future<Message> sendTextMessage({
    required dynamic chatId,
    required String text,
    ParseMode? parseMode,
    bool? disableWebPagePreview,
    int? replyToMessageId,
    ReplyMarkup? replyMarkup,
    List<MessageEntity>? entities,
  }) async {
    _ensureConnected();
    return await api.sendMessage(
      ChatID(chatId),
      text,
      parseMode: parseMode,
      entities: entities,
      linkPreviewOptions: disableWebPagePreview == true
          ? LinkPreviewOptions(isDisabled: true)
          : null,
      replyParameters: replyToMessageId != null
          ? ReplyParameters(messageId: replyToMessageId)
          : null,
      replyMarkup: replyMarkup,
    );
  }

  Future<Message> sendPhoto({
    required dynamic chatId,
    required String photoUrl,
    String? caption,
    ParseMode? parseMode,
    bool? hasSpoiler,
    ReplyMarkup? replyMarkup,
    int? replyToMessageId,
  }) async {
    _ensureConnected();
    return await api.sendPhoto(
      ChatID(chatId),
      InputFile.fromUrl(photoUrl),
      caption: caption,
      parseMode: parseMode,
      hasSpoiler: hasSpoiler,
      replyMarkup: replyMarkup,
      replyParameters: replyToMessageId != null
          ? ReplyParameters(messageId: replyToMessageId)
          : null,
    );
  }

  Future<Message> sendVideo({
    required dynamic chatId,
    required String videoUrl,
    String? caption,
    ParseMode? parseMode,
    bool? supportsStreaming,
    bool? hasSpoiler,
    ReplyMarkup? replyMarkup,
  }) async {
    _ensureConnected();
    return await api.sendVideo(
      ChatID(chatId),
      InputFile.fromUrl(videoUrl),
      caption: caption,
      parseMode: parseMode,
      supportsStreaming: supportsStreaming,
      hasSpoiler: hasSpoiler,
      replyMarkup: replyMarkup,
    );
  }

  Future<Message> sendAudio({
    required dynamic chatId,
    required String audioUrl,
    String? caption,
    String? performer,
    String? title,
    int? duration,
  }) async {
    _ensureConnected();
    return await api.sendAudio(
      ChatID(chatId),
      InputFile.fromUrl(audioUrl),
      caption: caption,
      performer: performer,
      title: title,
      duration: duration,
    );
  }

  Future<Message> sendDocument({
    required dynamic chatId,
    required String documentUrl,
    String? caption,
    String? fileName,
    bool? disableContentTypeDetection,
  }) async {
    _ensureConnected();
    return await api.sendDocument(
      ChatID(chatId),
      InputFile.fromUrl(documentUrl),
      caption: caption,
      disableContentTypeDetection: disableContentTypeDetection,
    );
  }

  Future<Message> sendSticker({
    required dynamic chatId,
    required String stickerUrl,
    String? emoji,
  }) async {
    _ensureConnected();
    return await api.sendSticker(
      ChatID(chatId),
      InputFile.fromUrl(stickerUrl),
      emoji: emoji,
    );
  }

  // ==================== INTERACTIVE MESSAGES ====================

  Future<Message> sendInlineKeyboard({
    required dynamic chatId,
    required String text,
    required List<List<InlineKeyboardButton>> keyboard,
    ParseMode? parseMode,
  }) async {
    _ensureConnected();
    return await api.sendMessage(
      ChatID(chatId),
      text,
      parseMode: parseMode,
      replyMarkup: ReplyMarkup.inlineKeyboard(inlineKeyboard: keyboard),
    );
  }

  Future<Message> sendPoll({
    required dynamic chatId,
    required String question,
    required List<InputPollOption> options,
    bool? isAnonymous,
    PollType type = PollType.regular,
    bool? allowsMultipleAnswers,
  }) async {
    _ensureConnected();
    return await api.sendPoll(
      ChatID(chatId),
      question,
      options,
      isAnonymous: isAnonymous,
      type: type,
      allowsMultipleAnswers: allowsMultipleAnswers,
    );
  }

  // ==================== MESSAGE ACTIONS ====================

  Future<bool> sendChatAction({
    required dynamic chatId,
    required ChatAction action,
  }) async {
    _ensureConnected();
    return await api.sendChatAction(ChatID(chatId), action);
  }

  Future<Message> editMessageText({
    required dynamic chatId,
    required int messageId,
    required String text,
    ParseMode? parseMode,
    InlineKeyboardMarkup? replyMarkup,
  }) async {
    _ensureConnected();
    return await api.editMessageText(
      ChatID(chatId),
      messageId,
      text,
      parseMode: parseMode,
      replyMarkup: replyMarkup,
    );
  }

  Future<bool> deleteMessage({
    required dynamic chatId,
    required int messageId,
  }) async {
    _ensureConnected();
    return await api.deleteMessage(ChatID(chatId), messageId);
  }

  // ==================== LOCATION ====================

  Future<Message> sendLocation({
    required dynamic chatId,
    required double latitude,
    required double longitude,
  }) async {
    _ensureConnected();
    return await api.sendLocation(ChatID(chatId), latitude, longitude);
  }

  // ==================== CALLBACK QUERIES ====================

  Future<bool> answerCallbackQuery({
    required String callbackQueryId,
    String? text,
    bool? showAlert,
  }) async {
    return await api.answerCallbackQuery(
      callbackQueryId,
      text: text,
      showAlert: showAlert ?? false,
    );
  }

  // ==================== FILE OPERATIONS ====================

  Future<File?> downloadFile({
    required String fileId,
    required String savePath,
  }) async {
    final file = await api.getFile(fileId);
    return file.download(path: savePath);
  }

  // ==================== BOT COMMANDS ====================

  Future<bool> setMyCommands({
    required List<BotCommand> commands,
    BotCommandScope? scope,
  }) async {
    return await api.setMyCommands(commands, scope: scope);
  }

  // ==================== BOT INFO ====================

  Future<User> getMe() async => api.getMe();
}

// ── _NoOpFetcher ────────────────────────────────────────────────────────────
//
// A do-nothing UpdateFetcher for webhook mode.
//
// Televerse's Bot.handleUpdate() silently skips every update when the bot's
// internal _isRunning flag is false. _isRunning is only set by _bot.start().
// Calling _bot.start() without a fetcher defaults to LongPollingFetcher, which
// immediately gets 409 Conflict from Telegram ("webhook is active") and then
// retries in a loop — generating log noise and wasted API calls.
//
// By passing this fetcher instead, _bot.start() still:
//   1. Calls initialize() → getMe() → sets botInfo and _isInitialized = true
//   2. Sets _isRunning = true
//   3. Starts the fetcher → start() returns immediately, no polling ever happens
//   4. Awaits _startCompleter.future (suspended forever until stop() is called)
//
// Result: the bot accepts webhook updates through handleUpdate() with zero
// polling activity.
class _NoOpFetcher extends UpdateFetcher {
  final _controller = StreamController<Update>.broadcast();
  bool _running = false;

  @override
  Stream<Update> get updates => _controller.stream;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async { _running = true; }

  @override
  Future<void> stop() async { _running = false; }

  @override
  Future<void> close() async {
    _running = false;
    await _controller.close();
  }
}
