// telegram_bot_registry.dart
//
// Owns every running Telegram bot — one per connected Channel row. This
// is the piece that doesn't exist in degenbot_server at all, because
// Degenbot only ever ran a single global bot from one env-var token.
// Kola is Bot-as-a-Service: every business connects THEIR OWN bot
// (created via @BotFather, per PRD.md's Telegram-as-zero-cost-alternative
// story), so "the Telegram bot" is really "a map of channelId →
// TelegramService" that grows as businesses connect channels, both at
// startup (already-connected channels, loaded from the DB) and at
// runtime (a business connecting a brand-new channel through
// ChannelEndpoint.connectTelegramChannel, with no server restart).
//
// TWO-PHASE STARTUP (mirrors Degenbot's TelegramBot.init()/connect()
// split, for the same reason): bootstrapFromDb() builds every
// already-connected bot's TelegramService + registers its webhook route
// BEFORE pod.start(), so the routes exist; connectAll() actually talks
// to Telegram's servers (getMe + setWebhook per bot) AFTER pod.start(),
// so the routes are live and reachable before Telegram is told about
// them. See server.dart for exactly where each phase is called.
//
// PHASE 2a SCOPE — THE BOT LOGIC ITSELF IS DELIBERATELY MINIMAL:
// DEVELOPMENT_PLAN.md's "done when" bar for this phase is "a message
// sent to a real Telegram bot gets a real reply from a hardcoded/simple
// response, end to end through the new server" — not real AI (that's
// Phase 3's Errand/AI orchestrator). Every bot registered here gets the
// exact same canned reply until Phase 3 wires a real handler in.

import 'dart:async';
import 'package:serverpod/serverpod.dart' hide Message, Logger;
import 'package:televerse/telegram.dart' show Update;
// REQUIRED for ctx.reply()/etc. below — found via a real `dart analyze` run
// plus checking Televerse's actual source: reply() isn't a member of the
// Context class itself (that only has direct getters like .text) — it's
// an EXTENSION method (`extension ContextAwareMethods on Context`) living
// in this same library. Extension methods are only visible in a file that
// imports the library declaring them; inferring Context's *type* from
// telegram_service.dart's `bot` getter (as this file already did) is not
// enough on its own — this direct import is what actually brings
// ContextAwareMethods into scope here.
import 'package:televerse/televerse.dart';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/conversations/inbound_message_handler.dart';
import '../messaging_service_interface.dart';
import 'telegram_service.dart';
import 'telegram_service_adapter.dart';
import 'telegram_webhook_route.dart';

class TelegramBotRegistry {
  TelegramBotRegistry._();

  static final TelegramBotRegistry instance = TelegramBotRegistry._();

  final Map<int, TelegramService> _services = {};
  final Map<int, TelegramServiceAdapter> _adapters = {};

  // channelId -> the Bot that owns it — needed by _handleInboundMessage
  // to look up workspaceId/knowledgeSeed via InboundMessageHandler.
  // Populated in _register(), same lifetime as _services/_adapters.
  final Map<int, int> _botIdForChannel = {};

  /// The Channel row per channelId.
  ///
  /// Needed because resolving an inbound PHOTO requires the channel's own
  /// bot token — Telegram's file download URL embeds it, and
  /// InboundMediaService decrypts the credential off the Channel. The
  /// botId alone is not enough.
  final Map<int, Channel> _channelById = {};

  void Function(Route route, String path)? _addRoute;
  String _webhookBaseUrl = '';

  /// Call once from server.dart, right after the Serverpod instance is
  /// created but before pod.start() — wires up how this registry adds
  /// new HTTP routes so both bootstrapFromDb() (startup) and
  /// connectChannel() (runtime, a business connecting a brand-new bot)
  /// share exactly one mechanism for doing it.
  void configure({
    required void Function(Route route, String path) addRoute,
    required String webhookBaseUrl,
  }) {
    _addRoute = addRoute;
    _webhookBaseUrl = webhookBaseUrl;
  }

  /// Phase 1 of startup — load every already-connected Telegram channel
  /// from the DB, decrypt its token, build its TelegramService/adapter,
  /// register the Phase 2a hardcoded-reply handler, and add its webhook
  /// route. Does NOT talk to Telegram's servers yet (no getMe/setWebhook
  /// calls) — call connectAll() after pod.start() for that.
  Future<void> bootstrapFromDb() async {
    final channels =
        await getIt<ChannelRepository>().listConnectedByPlatform('telegram');

    Log.startupInfo(
      'TelegramBotRegistry: bootstrapping ${channels.length} connected Telegram channel(s)...',
    );

    for (final channel in channels) {
      if (channel.encryptedCredential == null) {
        Log.warning(
          'Channel ${channel.id} is marked connected but has no credential — skipping',
        );
        continue;
      }
      try {
        final botToken = ChannelCredentialEncryptionService.decrypt(
          channel.encryptedCredential!,
        );
        _register(channel: channel, botToken: botToken);
      } catch (e) {
        Log.error(
          'Failed to bootstrap Telegram channel ${channel.id}',
          error: e,
        );
      }
    }
  }

  /// Phase 2 of startup — actually authenticate every bot registered by
  /// bootstrapFromDb() with Telegram and register its webhook (or fall
  /// back to long-polling). Must run AFTER pod.start().
  Future<void> connectAll() async {
    for (final entry in _services.entries) {
      try {
        await entry.value.start();
      } catch (e) {
        Log.error('Failed to connect Telegram channel ${entry.key}', error: e);
      }
    }
  }

  /// Runtime path — called by ChannelEndpoint.connectTelegramChannel once
  /// a business has pasted in a token that's already been validated (a
  /// real getMe() call, before this is ever reached) and persisted.
  /// Registers AND connects in one step, since the server (and its
  /// webhook routes) is already live at this point — there's no
  /// bootstrap/connect split needed for a single new channel.
  Future<void> connectChannel({
    required Channel channel,
    required String botToken,
  }) async {
    _register(channel: channel, botToken: botToken);
    await _services[channel.id]!.start();
  }

void _register({required Channel channel, required String botToken}) {
  final channelId = channel.id;
  if (channelId == null) {
    throw ArgumentError('Cannot register a Channel with no id');
  }

  final webhookUrl = _webhookBaseUrl.isEmpty
      ? null
      : '$_webhookBaseUrl/webhooks/telegram/$channelId';

  final service = TelegramService(botToken: botToken, webhookUrl: webhookUrl);
  final adapter = TelegramServiceAdapter(service);
  _registerMessageHandler(service, channelId);

  // A reconnect/retry for a channel we've already registered before must
  // NOT call _addRoute again — the path is purely a function of channelId,
  // so there's nothing new to add, and Relic's router throws "Conflicting
  // values" if the same path is injected twice. Only the underlying
  // TelegramService in the map needs to change; TelegramWebhookRoute
  // always looks up the CURRENT entry by channelId at request time, so
  // swapping the map value is all that's needed for the route to pick up
  // the new service. Dispose the old one first so it isn't left polling
  // or holding a stale webhook registration in the background.
  final alreadyRegistered = _services.containsKey(channelId);
  _services[channelId]?.dispose();

  _services[channelId] = service;
  _adapters[channelId] = adapter;
  _botIdForChannel[channelId] = channel.botId;
  _channelById[channelId] = channel;

  if (!alreadyRegistered) {
    _addRoute?.call(
      TelegramWebhookRoute(channelId: channelId),
      '/webhooks/telegram/$channelId',
    );
  }

  Log.startupSuccess('Telegram channel $channelId registered (webhook: ${webhookUrl ?? "polling"})');
}

  /// Phase 3's escalation-wired bot logic — replaces Phase 2a's
  /// hardcoded canned reply. Every inbound text message goes through
  /// InboundMessageHandler (shared with WhatsApp — see that file's
  /// header), which persists the Conversation/Message trail, asks
  /// BotKnowledgeService for a grounded answer, and escalates +
  /// notifies the owner if the model itself decided a human is needed.
  /// A null return means the conversation is already escalated — the
  /// bot stays silent so it never talks over a human who's already
  /// replying (see task #96's sendHumanReply for that path).
  void _registerMessageHandler(TelegramService service, int channelId) {
    service.bot.command('start', (ctx) => ctx.reply(_welcomeText));
    service.bot.onText((ctx) async {
      final text = ctx.text;
      if (text == null || text.trim().isEmpty) return;

      // NOTE ON ctx.from/.chat: same direct-getter shape as ctx.text/
      // ctx.chat already proven elsewhere in this file — chat.id is
      // used as externalUserId (stable per Telegram chat, same id as
      // the user's own id in a private chat) rather than from.id, to
      // stay consistent regardless of whether Televerse ever surfaces
      // group-chat updates to this handler. from.firstName is used only
      // for display, never as an identifier.
      final chatId = ctx.chat?.id;
      if (chatId == null) return;
      final botId = _botIdForChannel[channelId];
      if (botId == null) {
        Log.warning('No botId registered for Telegram channel $channelId — cannot process message');
        return;
      }

      try {
        final reply = await getIt<InboundMessageHandler>().handle(
          botId: botId,
          channelId: channelId,
          platformType: 'telegram',
          externalUserId: chatId.toString(),
          displayName: ctx.from?.firstName,
          inboundText: text,
        );
        if (reply != null) {
          await ctx.reply(reply);
        }
      } catch (e, stackTrace) {
        Log.error('InboundMessageHandler failed (Telegram channel $channelId)', error: e, stackTrace: stackTrace);
        await ctx.reply(_fallbackErrorText);
      }
    });

    // ── PHOTOS ────────────────────────────────────────────────────────
    //
    // onText does NOT fire for a photo message, so before this handler
    // existed a customer sending a picture produced nothing at all: no
    // message row, no reply, no trace. For a shop where "do you have
    // this?" IS a photo, that is the most important message type there
    // is, and it was silently dropped.
    //
    // The LARGEST PhotoSize is chosen. Telegram sends an ascending ladder
    // of the same image; taking .first would store a thumbnail as the
    // original and there is no way back from that.
    service.bot.onPhoto((ctx) async {
      final chatId = ctx.chat?.id;
      final botId = _botIdForChannel[channelId];
      final channel = _channelById[channelId];
      if (chatId == null || botId == null || channel == null) return;

      final sizes = ctx.message?.photo;
      if (sizes == null || sizes.isEmpty) return;
      final largest = sizes.last;

      // A caption is the customer's actual question ("do you have this in
      // blue?"). Empty when they just sent the picture, and the bot still
      // has to see that a photo arrived — hence a placeholder rather than
      // an early return.
      final caption = ctx.caption?.trim() ?? '';

      try {
        final reply = await getIt<InboundMessageHandler>().handle(
          botId: botId,
          channelId: channelId,
          platformType: 'telegram',
          externalUserId: chatId.toString(),
          displayName: ctx.from?.firstName,
          inboundText: caption.isEmpty ? '[sent a photo]' : caption,
          mediaReference: largest.fileId,
          mediaKind: 'image',
          channel: channel,
        );
        if (reply != null) {
          await ctx.reply(reply);
        }
      } catch (e, stackTrace) {
        Log.error('InboundMessageHandler failed on photo (Telegram channel $channelId)',
            error: e, stackTrace: stackTrace);
        await ctx.reply(_fallbackErrorText);
      }
    });
    service.bot.onError((err) {
      Log.error(
        'Unhandled Telegram bot error (channel $channelId)',
        error: err.error,
        stackTrace: err.stackTrace,
      );
    });
  }

  static const _welcomeText =
      "👋 Hey! Thanks for messaging — this bot is powered by Kola. "
      "We've received your message and a real reply is on the way.";

  static const _fallbackErrorText =
      "Sorry, something went wrong on our end. We're looking into it.";

  /// Entry point called by TelegramWebhookRoute for every incoming POST.
  /// Always returns a result map — the route returns 200 OK to Telegram
  /// regardless, since Telegram aggressively retries non-200 responses
  /// and we never want a retry storm on a transient internal error.
  Future<Map<String, dynamic>> processWebhook(
    int channelId,
    Session session,
    Map<String, dynamic> payload,
  ) async {
    final service = _services[channelId];
    if (service == null) {
      Log.warning('processWebhook: no Telegram bot registered for channel $channelId');
      return {'success': false, 'error': 'no bot registered for channel $channelId'};
    }

    try {
      final update = Update.fromJson(payload);
      await service.handleUpdate(update);
      return {'success': true};
    } catch (e, stackTrace) {
      session.log(
        'Telegram webhook error (channel $channelId): $e',
        stackTrace: stackTrace,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Platform-agnostic sender for a connected channel — Phase 3's Errand
  /// engine and any future proactive-notification code use this instead
  /// of touching Televerse directly. Returns null if the channel isn't
  /// currently registered (never connected, or the server just started
  /// and hasn't reached it yet).
  IMessagingService? messagingFor(int channelId) => _adapters[channelId];

  /// Used by health checks / diagnostics — not part of any endpoint yet.
  bool isRunning(int channelId) => _services.containsKey(channelId);

  /// Task #82 — the nightly credential health check's Telegram probe.
  /// Reuses this channel's already-decrypted, already-registered
  /// TelegramService (no re-decryption needed) and makes one real getMe()
  /// call — Telegram's own cheapest "is this token still valid" check,
  /// the same call [start] makes when a channel first connects. Returns
  /// false for "definitely unhealthy" (a real API error) AND for "not
  /// even registered" (already disconnected, or the server hasn't
  /// bootstrapped it) — ChannelHealthCheckService only cares about
  /// "should this be marked disconnected," not which of those it is.
  Future<bool> checkHealth(int channelId) async {
    final service = _services[channelId];
    if (service == null) return false;
    try {
      await service.getMe();
      return true;
    } catch (e) {
      Log.warning('Telegram health check failed for channel $channelId: $e');
      return false;
    }
  }
}

/// Thrown by ChannelEndpoint when a pasted-in Telegram bot token fails a
/// real getMe() probe — lets the dashboard show "that token doesn't work"
/// instead of a generic 500.
class InvalidTelegramTokenException implements Exception {
  final String message;
  const InvalidTelegramTokenException(this.message);

  @override
  String toString() => 'InvalidTelegramTokenException: $message';
}
