// channel_health_check_service.dart
//
// Task #82 / SRS.md §13's "nightly channel-credential health check":
// "proactively validate every stored WhatsApp/Telegram access token and
// push a notification to the workspace owner if one is invalid or
// expiring, rather than letting a bot silently go dark and having the
// owner discover it days later from a customer complaint."
//
// WHY THIS DOESN'T RE-DECRYPT ANYTHING ITSELF: every currently-connected
// channel already has a live, decrypted TelegramService/WhatsAppService
// sitting in TelegramBotRegistry/WhatsAppBotRegistry's memory — that's
// what actually sends replies right now. This service calls INTO those
// registries' own checkHealth(channelId) methods rather than loading
// ChannelRepository rows and decrypting credentials a second time, the
// same "don't duplicate what the registry already owns" instinct as
// every other health/diagnostic hook on those two classes
// (isRunning/messagingFor).
//
// WHY A CHANNEL WITH NO REGISTERED SERVICE COUNTS AS UNHEALTHY: if
// ChannelRepository says 'connected' but the registry has nothing for
// that channelId, that's either a channel that failed to bootstrap at
// startup (see bootstrapFromDb()'s own try/catch, which logs and moves
// on rather than crashing the server) or one connected before the
// current server process was even alive. Either way "the bot is
// currently unable to actually send/receive" is exactly the same
// customer-facing symptom SRS §13 wants surfaced, so it's treated
// identically to a real failed API call — see checkHealth's own doc
// comment on each registry.
//
// EXPIRY WARNING: SRS §13 also asks to warn about tokens that are still
// valid today but "expiring." WhatsAppService.debugToken() can tell a
// temporary (~24h) token apart from a permanent System User one, but
// that call needs appId/appSecret AND is a separate Graph API call this
// service doesn't make on every channel every run (probe() alone is the
// "is it dead right now" check; a temporary-vs-permanent classification
// belongs to the connect-time flow, which already warns about it — see
// ChannelEndpoint.connectWhatsAppChannelManual). Telegram bot tokens
// don't expire at all by design, so there's no equivalent for that
// platform. Scoped out here rather than guessed at.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/connector_sync_log_repository.dart';
import 'package:kola_server/src/services/notifications/owner_notification_dispatcher.dart';
import 'telegram/telegram_bot_registry.dart';
import 'whatsapp/whatsapp_bot_registry.dart';
import 'instagram/instagram_bot_registry.dart';

class ChannelHealthCheckService {
  ChannelHealthCheckService({
    required ChannelRepository channels,
    required BotRepository bots,
    required OwnerNotificationDispatcher notifications,
    required ConnectorSyncLogRepository syncLog,
  }) : _channels = channels,
       _bots = bots,
       _notifications = notifications,
       _syncLog = syncLog;

  final ChannelRepository _channels;
  final BotRepository _bots;
  final OwnerNotificationDispatcher _notifications;

  /// Gate 1 — this is now the first writer of connector_sync_log (see
  /// migration 036), turning each run of this sweep into a
  /// per-channel dead-letter/observability row, not just a
  /// connected/disconnected flip on the Channel row itself.
  final ConnectorSyncLogRepository _syncLog;

  /// Checks every currently-'connected' channel and marks+notifies any
  /// that fail. Returns the count flagged, for the caller's own log line
  /// (see server.dart). Per-channel try/catch: one channel's check
  /// blowing up (a transient network error, an unexpected API shape)
  /// must never stop the rest of the sweep.
  Future<int> runOnce() async {
    final connected = await _channels.listConnected();
    Log.info('ChannelHealthCheckService: checking ${connected.length} connected channel(s)...');

    var flaggedCount = 0;
    for (final channel in connected) {
      final channelId = channel.id;
      if (channelId == null) continue;

      // Gate 1 — resolve workspaceId for the sync-log row before the
      // check itself, so a failure inside _checkOne still gets logged
      // under the right workspace rather than silently under none.
      final bot = await _bots.findById(channel.botId);
      final workspaceId = bot?.workspaceId ?? 0;

      try {
        final healthy = await _checkOne(channel.platformType, channelId);
        await _channels.touchHealthCheck(channelId);
        await _syncLog.record(
          workspaceId: workspaceId,
          connectorKey: channel.platformType,
          store: 'channel',
          kind: 'health',
          success: healthy,
          errorMessage: healthy ? null : 'Routine credential check failed.',
        );

        if (!healthy) {
          await _flagUnhealthy(channel);
          flaggedCount++;
        }
      } catch (e) {
        Log.error('ChannelHealthCheckService: check failed for channel $channelId', error: e);
        await _syncLog.record(
          workspaceId: workspaceId,
          connectorKey: channel.platformType,
          store: 'channel',
          kind: 'health',
          success: false,
          errorMessage: e.toString(),
        );
      }
    }

    Log.info('ChannelHealthCheckService: done — $flaggedCount channel(s) flagged unhealthy');
    return flaggedCount;
  }

  Future<bool> _checkOne(String platformType, int channelId) async {
    switch (platformType) {
      case 'telegram':
        return TelegramBotRegistry.instance.checkHealth(channelId);
      case 'whatsapp':
        return WhatsAppBotRegistry.instance.checkHealth(channelId);
      case 'instagram':
        return InstagramBotRegistry.instance.checkHealth(channelId);
      default:
        // An unrecognized platform isn't this service's problem to
        // diagnose — leave it alone rather than guess at a check for it.
        return true;
    }
  }

  Future<void> _flagUnhealthy(Channel channel) async {
    final channelId = channel.id!;
    await _channels.markDisconnected(channelId);

    final bot = await _bots.findById(channel.botId);
    if (bot == null) {
      Log.warning('ChannelHealthCheckService: channel $channelId has no owning Bot — cannot notify');
      return;
    }

    final label = channel.displayName != null && channel.displayName!.isNotEmpty
        ? '${channel.platformType} (${channel.displayName})'
        : channel.platformType;

    await _notifications.notify(
      workspaceId: bot.workspaceId,
      subject: 'A channel needs reconnecting — Kola credential check',
      body:
          'Your $label channel for "${bot.name}" stopped responding to a routine '
          'credential check and has been marked disconnected — the bot will not '
          'send or receive messages on it until you reconnect it from your Kola '
          'dashboard.',
    );
  }
}
