// instagram_bot_registry.dart
//
// Owns every connected Instagram professional account — one
// InstagramService per connected Channel row, same role
// WhatsAppBotRegistry/TelegramBotRegistry play for their platforms. This
// is the final channel connector of the Connections Backbone build —
// Rev 5/6's Gate 11 explicitly deferred it, scoped separately because
// Instagram DMs are push-driven (webhook + conversation threading) like
// WhatsApp/Telegram, not sync()-shaped like every other Gate 11
// connector (Google Drive, Monnify, Fincra, Notion).
//
// PER-CHANNEL ROUTES ONLY, FROM DAY ONE — unlike WhatsAppBotRegistry,
// there is no legacy shared-route mode here to carry forward: every
// Instagram channel this codebase will ever connect starts on its own
// /webhooks/instagram/<channelId> URL, exactly the WhatsApp per-channel
// design WITHOUT the transitional baggage (see whatsapp_bot_registry.dart's
// header for why that baggage exists there and not here).
//
// NO TWO-PHASE STARTUP SPLIT, SAME REASONING AS WhatsApp: Meta learns a
// channel's callback URL only when the business pastes it into their own
// App Dashboard, entirely outside anything this server does. This
// registry only needs its routes registered before pod.start() —
// bootstrapFromDb() running before pod.start() in server.dart guarantees
// that, same as WhatsApp's.

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
import 'instagram_credential.dart';
import 'instagram_service.dart';
import 'instagram_service_adapter.dart';
import 'instagram_webhook_route.dart';

class InstagramBotRegistry {
  InstagramBotRegistry._();

  static final InstagramBotRegistry instance = InstagramBotRegistry._();

  final Map<int, InstagramService> _services = {};
  final Map<int, InstagramServiceAdapter> _adapters = {};

  // Keyed by channelId — every connected channel's App Secret, used ONLY
  // for verifying that channel's own X-Hub-Signature-256 header. Never
  // used for outbound sends — accessToken's job.
  final Map<int, String> _appSecrets = {};

  // channelId -> the Bot that owns it — needed to reach
  // InboundMessageHandler with the right botId.
  final Map<int, int> _botIdForChannel = {};

  void Function(Route route, String path)? _addRoute;
  String _webhookBaseUrl = '';

  /// Call once from server.dart, right after the Serverpod instance is
  /// created but before pod.start() — same contract as
  /// WhatsAppBotRegistry.configure().
  void configure({
    required void Function(Route route, String path) addRoute,
    required String webhookBaseUrl,
  }) {
    _addRoute = addRoute;
    _webhookBaseUrl = webhookBaseUrl;
  }

  /// Load every already-connected Instagram channel from the DB, decrypt
  /// its credential, and register it (and its own webhook route) in
  /// memory. Call before pod.start().
  Future<void> bootstrapFromDb() async {
    final channels =
        await getIt<ChannelRepository>().listConnectedByPlatform('instagram');

    Log.startupInfo(
      'InstagramBotRegistry: bootstrapping ${channels.length} connected Instagram channel(s)...',
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
        final credential = InstagramCredential.decode(decrypted);
        _register(channel: channel, credential: credential);
      } catch (e) {
        Log.error(
          'Failed to bootstrap Instagram channel ${channel.id}',
          error: e,
        );
      }
    }
  }

  /// Runtime path — called by ChannelEndpoint.connectInstagramChannelManual
  /// once a business has pasted in a token + igUserId + appSecret that
  /// have already been validated (a real InstagramService.probe() call)
  /// and persisted. Registers the channel's own webhook route
  /// immediately — the business needs webhookUrlFor(channelId) to paste
  /// into their Meta App Dashboard right after this call returns.
  void connectChannel({
    required Channel channel,
    required InstagramCredential credential,
  }) {
    _register(channel: channel, credential: credential);
  }

  /// The exact URL a business must paste into their Meta App Dashboard's
  /// Instagram Webhooks Callback URL field for this channel.
  String? webhookUrlFor(int channelId) => _webhookBaseUrl.isEmpty
      ? null
      : '$_webhookBaseUrl/webhooks/instagram/$channelId';

  void _register({required Channel channel, required InstagramCredential credential}) {
    final channelId = channel.id;
    if (channelId == null) {
      throw ArgumentError('Cannot register a Channel with no id');
    }

    final service = InstagramService(
      accessToken: credential.accessToken,
      igUserId: credential.igUserId,
    );
    final adapter = InstagramServiceAdapter(service);

    _services[channelId] = service;
    _adapters[channelId] = adapter;
    _botIdForChannel[channelId] = channel.botId;
    if (credential.appSecret.isNotEmpty) {
      _appSecrets[channelId] = credential.appSecret;
    } else {
      Log.startupWarning(
        'Instagram channel $channelId has no App Secret stored — inbound '
        'webhooks for this channel will fail signature verification until '
        'it is reconnected with an App Secret. Sending still works normally.',
      );
    }

    _addRoute?.call(
      InstagramWebhookRoute(channelId: channelId),
      '/webhooks/instagram/$channelId',
    );

    final urlForLog = webhookUrlFor(channelId) ?? '(WEBHOOK_BASE_URL not set)';
    Log.startupSuccess(
      'Instagram channel $channelId registered (igUserId: '
      '${credential.igUserId}, webhook: $urlForLog)',
    );
  }

  /// Called by InstagramWebhookRoute BEFORE any JSON parsing of the
  /// inbound POST body. Reuses WhatsAppSignatureVerifier — see
  /// instagram_webhook_route.dart's header on why that isn't a
  /// duplicate-and-rename.
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

  /// Entry point for InstagramWebhookRoute — one call per item in the
  /// webhook's `messaging` array. [event] is a single messaging event —
  /// see instagram_webhook_route.dart's header for its shape. Always
  /// returns a result map rather than throwing; the route returns 200 OK
  /// to Meta regardless, same "never trigger a retry storm" reasoning as
  /// every other Meta webhook route in this codebase.
  Future<Map<String, dynamic>> processWebhookEvent(
    int channelId,
    Map<String, dynamic> event,
  ) async {
    if (!_adapters.containsKey(channelId)) {
      Log.warning('processWebhookEvent: no Instagram channel registered for channel $channelId');
      return {'success': false, 'error': 'no channel registered for channel $channelId'};
    }

    // Echo of this account's own outbound send — see
    // instagram_webhook_route.dart's header on why this must never reach
    // InboundMessageHandler (infinite reply loop).
    final message = event['message'] as Map<String, dynamic>?;
    if (message?['is_echo'] == true) {
      return {'success': true, 'channelId': channelId, 'skipped': 'echo'};
    }

    await _replyToInboundMessage(channelId: channelId, event: event);
    return {'success': true, 'channelId': channelId};
  }

  /// Text-only for this pass — see instagram_service.dart's header and
  /// instagram_service_adapter.dart's for the same "real, named scope
  /// cut" discipline as everywhere else in this codebase: an inbound
  /// event with an `attachments` array instead of `message.text` (an
  /// image/audio/etc DM) gets the same honest, generic acknowledgement
  /// WhatsAppBotRegistry sends for its own non-text fallback branch —
  /// nothing is silently dropped, it's just not run through
  /// BotKnowledgeService the way text is. A real InboundMediaService.
  /// fromInstagram() (mirroring .fromWhatsApp()/.fromTelegram()) is
  /// follow-up work, not built speculatively here.
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
    final igsid = sender?['id'] as String?;
    if (igsid == null) return;

    final botId = _botIdForChannel[channelId];
    if (botId == null) {
      Log.warning('No botId registered for Instagram channel $channelId — cannot process message');
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
          platformType: 'instagram',
          externalUserId: igsid,
          // Instagram's webhook carries no display-name field alongside
          // messaging events (unlike WhatsApp's sibling `contacts`
          // array) — a real name would need a separate authenticated
          // /<IGSID>?fields=name call this pass doesn't add; the
          // conversation is created with no displayName, same as any
          // WhatsApp/Telegram customer who never sent one.
          inboundText: text,
          externalMessageId: mid,
        );
        if (reply != null) {
          await _sendText(adapter: adapter, botId: botId, recipient: igsid, text: reply);
        }
      } else {
        await _sendText(adapter: adapter, botId: botId, recipient: igsid, text: _nonTextReplyText);
      }
    } catch (e) {
      Log.error('Failed to process/send Instagram reply (channel $channelId)', error: e);
    }
  }

  /// Every outbound Instagram send goes through the shared retry/backoff
  /// wrapper — same "a transient API blip must not just lose the reply"
  /// reasoning as WhatsAppBotRegistry._sendText.
  Future<void> _sendText({
    required InstagramServiceAdapter adapter,
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
      connectorKey: 'instagram',
      store: 'channel',
      kind: 'sync',
    );
  }

  static const _nonTextReplyText =
      "✅ Got that! We'll get back to you shortly. — Powered by Kola";

  /// Platform-agnostic sender for a connected channel — same contract as
  /// WhatsAppBotRegistry.messagingFor.
  IMessagingService? messagingFor(int channelId) => _adapters[channelId];

  bool isRunning(int channelId) => _services.containsKey(channelId);

  /// Nightly credential health check's Instagram probe — same pattern as
  /// WhatsAppBotRegistry.checkHealth.
  Future<bool> checkHealth(int channelId) async {
    final service = _services[channelId];
    if (service == null) return false;
    try {
      await service.probe();
      return true;
    } catch (e) {
      Log.warning('Instagram health check failed for channel $channelId: $e');
      return false;
    }
  }
}

/// Thrown by ChannelEndpoint when a pasted-in Instagram credential fails
/// a real probe() call — mirrors InvalidWhatsAppCredentialException's role.
class InvalidInstagramCredentialException implements Exception {
  final String message;
  const InvalidInstagramCredentialException(this.message);

  @override
  String toString() => 'InvalidInstagramCredentialException: $message';
}
