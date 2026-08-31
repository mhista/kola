// messenger_bot_registry.dart
//
// Owns every connected Facebook Page — one MessengerService per
// connected Channel row, same role InstagramBotRegistry/
// WhatsAppBotRegistry/TelegramBotRegistry play for their platforms. This
// is the fourth channel connector, built 31 Aug 2026 straight from the
// Instagram template (the third time this exact pattern has been
// proven) — see instagram_bot_registry.dart's header for the shared
// "why per-channel routes, why no two-phase startup split" reasoning,
// which applies identically here.
//
// disconnectChannel IS PRESENT FROM THE START, UNLIKE THE OTHER THREE:
// Telegram/WhatsApp/Instagram each needed disconnect retrofitted in a
// later pass (31 Aug 2026) after connect-only shipped first. Messenger
// is the first channel built after that retrofit, so its registry
// includes disconnectChannel from day one instead of needing a second
// pass.

import 'package:serverpod/serverpod.dart' show Route;
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/conversations/inbound_message_handler.dart';
import 'package:kola_server/src/services/connectors/contract/connector_retry.dart';
import 'package:kola_server/src/services/repository/connector_sync_log_repository.dart';
import '../messaging_service_interface.dart';
import '../whatsapp/whatsapp_signature_verifier.dart';
import 'messenger_credential.dart';
import 'messenger_service.dart';
import 'messenger_service_adapter.dart';
import 'messenger_webhook_route.dart';

class MessengerBotRegistry {
  MessengerBotRegistry._();

  static final MessengerBotRegistry instance = MessengerBotRegistry._();

  final Map<int, MessengerService> _services = {};
  final Map<int, MessengerServiceAdapter> _adapters = {};

  // Keyed by channelId — every connected channel's App Secret, used ONLY
  // for verifying that channel's own X-Hub-Signature-256 header. Never
  // used for outbound sends — pageAccessToken's job.
  final Map<int, String> _appSecrets = {};

  // channelId -> the Bot that owns it — needed to reach
  // InboundMessageHandler with the right botId.
  final Map<int, int> _botIdForChannel = {};

  void Function(Route route, String path)? _addRoute;
  String _webhookBaseUrl = '';

  /// Call once from server.dart, right after the Serverpod instance is
  /// created but before pod.start() — same contract as
  /// InstagramBotRegistry.configure().
  void configure({
    required void Function(Route route, String path) addRoute,
    required String webhookBaseUrl,
  }) {
    _addRoute = addRoute;
    _webhookBaseUrl = webhookBaseUrl;
  }

  /// Load every already-connected Messenger channel from the DB, decrypt
  /// its credential, and register it (and its own webhook route) in
  /// memory. Call before pod.start().
  Future<void> bootstrapFromDb() async {
    final channels =
        await getIt<ChannelRepository>().listConnectedByPlatform('messenger');

    Log.startupInfo(
      'MessengerBotRegistry: bootstrapping ${channels.length} connected Messenger channel(s)...',
    );

    for (final channel in channels) {
      if (channel.encryptedCredential == null) {
        Log.warning(
          'Channel ${channel.id} is marked connected but has no credential — skipping',
        );
        continue;
      }
      try {
        final decrypted = ChannelCredentialEncryptionService.decrypt(
          channel.encryptedCredential!,
        );
        final credential = MessengerCredential.decode(decrypted);
        _register(channel: channel, credential: credential);
      } catch (e) {
        Log.error(
          'Failed to bootstrap Messenger channel ${channel.id}',
          error: e,
        );
      }
    }
  }

  /// Runtime path — called by ChannelEndpoint.connectMessengerChannelManual
  /// once a business has pasted in a token + pageId + appSecret that
  /// have already been validated (a real MessengerService.probe() call)
  /// and persisted. Registers the channel's own webhook route
  /// immediately — the business needs webhookUrlFor(channelId) to paste
  /// into their Meta App Dashboard right after this call returns.
  void connectChannel({
    required Channel channel,
    required MessengerCredential credential,
  }) {
    _register(channel: channel, credential: credential);
  }

  /// The exact URL a business must paste into their Meta App Dashboard's
  /// Messenger Webhooks Callback URL field for this channel.
  String? webhookUrlFor(int channelId) => _webhookBaseUrl.isEmpty
      ? null
      : '$_webhookBaseUrl/webhooks/messenger/$channelId';

  void _register({required Channel channel, required MessengerCredential credential}) {
    final channelId = channel.id;
    if (channelId == null) {
      throw ArgumentError('Cannot register a Channel with no id');
    }

    final service = MessengerService(
      pageAccessToken: credential.pageAccessToken,
      pageId: credential.pageId,
    );
    final adapter = MessengerServiceAdapter(service);

    _services[channelId] = service;
    _adapters[channelId] = adapter;
    _botIdForChannel[channelId] = channel.botId;
    if (credential.appSecret.isNotEmpty) {
      _appSecrets[channelId] = credential.appSecret;
    } else {
      Log.startupWarning(
        'Messenger channel $channelId has no App Secret stored — inbound '
        'webhooks for this channel will fail signature verification until '
        'it is reconnected with an App Secret. Sending still works normally.',
      );
    }

    _addRoute?.call(
      MessengerWebhookRoute(channelId: channelId),
      '/webhooks/messenger/$channelId',
    );

    final urlForLog = webhookUrlFor(channelId) ?? '(WEBHOOK_BASE_URL not set)';
    Log.startupSuccess(
      'Messenger channel $channelId registered (pageId: '
      '${credential.pageId}, webhook: $urlForLog)',
    );
  }

  /// Called by MessengerWebhookRoute BEFORE any JSON parsing of the
  /// inbound POST body. Reuses WhatsAppSignatureVerifier — same reuse-
  /// not-duplicate reasoning as instagram_webhook_route.dart.
  bool verifyWebhookSignatureForChannel({
    required int channelId,
    required String rawBody,
    required String? signatureHeader,
  }) {
    final secret = _appSecrets[channelId];
    if (secret == null) return false;
    return WhatsAppSignatureVerifier.verify(
      rawBody: rawBody,
      signatureHeader: signatureHeader,
      candidateAppSecrets: [secret],
    );
  }

  /// Entry point for MessengerWebhookRoute — one call per item in the
  /// webhook's `messaging` array. Always returns a result map rather
  /// than throwing; the route returns 200 OK to Meta regardless, same
  /// "never trigger a retry storm" reasoning as every other Meta webhook
  /// route in this codebase.
  Future<Map<String, dynamic>> processWebhookEvent(
    int channelId,
    Map<String, dynamic> event,
  ) async {
    if (!_adapters.containsKey(channelId)) {
      Log.warning('processWebhookEvent: no Messenger channel registered for channel $channelId');
      return {'success': false, 'error': 'no channel registered for channel $channelId'};
    }

    // Echo of this Page's own outbound send — see
    // messenger_webhook_route.dart's header on why this must never reach
    // InboundMessageHandler (infinite reply loop).
    final message = event['message'] as Map<String, dynamic>?;
    if (message?['is_echo'] == true) {
      return {'success': true, 'channelId': channelId, 'skipped': 'echo'};
    }

    await _replyToInboundMessage(channelId: channelId, event: event);
    return {'success': true, 'channelId': channelId};
  }

  /// Text-only for this pass — same "real, named scope cut" discipline
  /// as InstagramBotRegistry._replyToInboundMessage: an inbound event
  /// with an `attachments` array instead of `message.text` (an image/
  /// sticker/etc DM) gets the same honest, generic acknowledgement.
  Future<void> _replyToInboundMessage({
    required int channelId,
    required Map<String, dynamic> event,
  }) async {
    final adapter = _adapters[channelId];
    if (adapter == null) {
      Log.warning('_replyToInboundMessage: no adapter for channel $channelId');
      return;
    }

    final sender = event['sender'] as Map<String, dynamic>?;
    final psid = sender?['id'] as String?;
    if (psid == null) return;

    final botId = _botIdForChannel[channelId];
    if (botId == null) {
      Log.warning('No botId registered for Messenger channel $channelId — cannot process message');
      return;
    }

    final message = event['message'] as Map<String, dynamic>?;
    final text = message?['text'] as String?;
    final mid = message?['mid'] as String?;

    try {
      if (text != null && text.trim().isNotEmpty) {
        final reply = await getIt<InboundMessageHandler>().handle(
          botId: botId,
          channelId: channelId,
          platformType: 'messenger',
          externalUserId: psid,
          // Messenger's webhook carries no display-name field alongside
          // messaging events — a real name would need a separate
          // authenticated /<PSID>?fields=name call this pass doesn't
          // add; the conversation is created with no displayName, same
          // as any WhatsApp/Telegram/Instagram customer who never sent
          // one.
          inboundText: text,
          externalMessageId: mid,
        );
        if (reply != null) {
          await _sendText(adapter: adapter, botId: botId, recipient: psid, text: reply);
        }
      } else {
        await _sendText(adapter: adapter, botId: botId, recipient: psid, text: _nonTextReplyText);
      }
    } catch (e) {
      Log.error('Failed to process/send Messenger reply (channel $channelId)', error: e);
    }
  }

  /// Every outbound Messenger send goes through the shared retry/backoff
  /// wrapper — same "a transient API blip must not just lose the reply"
  /// reasoning as InstagramBotRegistry._sendText.
  Future<void> _sendText({
    required MessengerServiceAdapter adapter,
    required int? botId,
    required String recipient,
    required String text,
  }) async {
    final bot = botId == null ? null : await getIt<BotRepository>().findById(botId);
    final workspaceId = bot?.workspaceId ?? 0;

    await ConnectorRetry.run(
      () => adapter.sendText(recipient: recipient, text: text),
      deadLetter: getIt<ConnectorSyncLogRepository>(),
      workspaceId: workspaceId,
      connectorKey: 'messenger',
      store: 'channel',
      kind: 'sync',
    );
  }

  static const _nonTextReplyText =
      "✅ Got that! We'll get back to you shortly. — Powered by Kola";

  /// Platform-agnostic sender for a connected channel — same contract as
  /// InstagramBotRegistry.messagingFor.
  IMessagingService? messagingFor(int channelId) => _adapters[channelId];

  /// Owner-initiated disconnect — same role as
  /// InstagramBotRegistry.disconnectChannel. MessengerService holds no
  /// polling loop or persistent connection either, so this is map
  /// cleanup only. This channel's webhook route stays registered (Relic
  /// has no route-removal API); processWebhookEvent's existing
  /// `_adapters.containsKey` check already treats a missing entry as a
  /// normal, logged no-op.
  void disconnectChannel(int channelId) {
    _services.remove(channelId);
    _adapters.remove(channelId);
    _appSecrets.remove(channelId);
    _botIdForChannel.remove(channelId);
    Log.info('Messenger channel $channelId disconnected (owner-initiated)');
  }

  bool isRunning(int channelId) => _services.containsKey(channelId);

  /// Nightly credential health check's Messenger probe — same pattern
  /// as InstagramBotRegistry.checkHealth.
  Future<bool> checkHealth(int channelId) async {
    final service = _services[channelId];
    if (service == null) return false;
    try {
      await service.probe();
      return true;
    } catch (e) {
      Log.warning('Messenger health check failed for channel $channelId: $e');
      return false;
    }
  }
}

/// Thrown by ChannelEndpoint when a pasted-in Messenger credential fails
/// a real probe() call — mirrors InvalidInstagramCredentialException's role.
class InvalidMessengerCredentialException implements Exception {
  final String message;
  const InvalidMessengerCredentialException(this.message);

  @override
  String toString() => 'InvalidMessengerCredentialException: $message';
}
