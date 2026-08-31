// whatsapp_bot_registry.dart
//
// Owns every connected WhatsApp number — one WhatsAppService per
// connected Channel row, same role TelegramBotRegistry plays for
// Telegram.
//
// EACH CHANNEL NOW ALSO GETS ITS OWN WEBHOOK ROUTE
// (/webhooks/whatsapp/<channelId>) — CHANGED FROM THE ORIGINAL
// ONE-SHARED-URL DESIGN:
//   The original version of this file gave every business the same
//   single callback URL, reasoning that "Meta gives one App exactly one
//   webhook URL." That's true, but it's a per-App limit, not a
//   platform-wide one — Kola's manual-connect flow already has each
//   business register their OWN separate Meta App
//   (docs/WHATSAPP_MANUAL_SETUP.md Step 1), and each of those Apps has
//   its own independently-configurable Callback URL field. There's
//   nothing stopping Kola from handing out a distinct path per channel,
//   the exact same way TelegramBotRegistry already does
//   (/webhooks/telegram/<channelId>) — so every NEWLY connected channel
//   gets one from now on.
//
// LEGACY SHARED ROUTE KEPT ALIVE ON PURPOSE, NOT AN OVERSIGHT: the first
// channel connected under the old design is still verified against the
// original shared /webhooks/whatsapp route in Meta's dashboard, and
// re-doing that verification handshake for zero functional gain isn't
// worth the churn right now. So server.dart still registers that one
// shared route too (see its "legacy" WhatsAppWebhookRoute()), and this
// registry keeps a phone_number_id → channelId map alive to dispatch
// whatever arrives on it, same as the original design. New channels
// don't need this at all — they dispatch purely by which per-channel URL
// got hit. Once every channel has migrated to its own URL (tracked as a
// follow-up, not urgent), the shared route, this map, and
// processWebhookLegacy/verifyWebhookSignatureLegacy below can all be
// deleted together.
//
// STILL NO TWO-PHASE STARTUP SPLIT (unlike Telegram): Telegram's
// bootstrap/connect split exists because each bot needs a real
// setWebhook() API call made to Telegram's servers after pod.start().
// WhatsApp has no equivalent call — Meta learns a channel's callback URL
// only when the business themselves pastes it into their own App
// Dashboard, entirely outside of anything this server does. So this
// registry only needs its routes registered before pod.start(), which
// bootstrapFromDb() running before pod.start() in server.dart already
// guarantees, same as Telegram's.

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
import 'whatsapp_credential.dart';
import 'whatsapp_service.dart';
import 'whatsapp_service_adapter.dart';
import 'whatsapp_signature_verifier.dart';
import 'whatsapp_webhook_route.dart';

class WhatsAppBotRegistry {
  WhatsAppBotRegistry._();

  static final WhatsAppBotRegistry instance = WhatsAppBotRegistry._();

  final Map<int, WhatsAppService> _services = {};
  final Map<int, WhatsAppServiceAdapter> _adapters = {};

  // Legacy-only — dispatch for the one shared /webhooks/whatsapp route.
  // New per-channel routes carry their channelId in the URL and never
  // need this. See file header.
  final Map<String, int> _phoneNumberIdToChannelId = {};

  // Keyed by channelId — every connected channel's App Secret, used ONLY
  // for verifying that channel's own X-Hub-Signature-256 header (see
  // whatsapp_signature_verifier.dart). Deliberately never used for
  // outbound sends — that's accessToken's job.
  final Map<int, String> _appSecrets = {};

  // channelId -> the Bot that owns it — same role as
  // TelegramBotRegistry's _botIdForChannel; needed by
  // _replyToInboundMessages to reach InboundMessageHandler.
  final Map<int, int> _botIdForChannel = {};

  /// The Channel row per channelId.
  ///
  /// Resolving an inbound image needs the channel's own access token —
  /// Meta's media URL requires an Authorization header and expires in
  /// minutes, so ImageKit cannot fetch it and we must. See
  /// inbound_media_service.dart.
  final Map<int, Channel> _channelById = {};

  void Function(Route route, String path)? _addRoute;
  String _webhookBaseUrl = '';

  /// Call once from server.dart, right after the Serverpod instance is
  /// created but before pod.start() — same contract as
  /// TelegramBotRegistry.configure().
  void configure({
    required void Function(Route route, String path) addRoute,
    required String webhookBaseUrl,
  }) {
    _addRoute = addRoute;
    _webhookBaseUrl = webhookBaseUrl;
  }

  /// Load every already-connected WhatsApp channel from the DB, decrypt
  /// its credential, and register it (and its own webhook route) in
  /// memory. Call before pod.start() so every route exists the moment
  /// the web server starts listening — same ordering reason as
  /// Telegram's bootstrapFromDb().
  Future<void> bootstrapFromDb() async {
    final channels =
        await getIt<ChannelRepository>().listConnectedByPlatform('whatsapp');

    Log.startupInfo(
      'WhatsAppBotRegistry: bootstrapping ${channels.length} connected WhatsApp channel(s)...',
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
        final credential = WhatsAppCredential.decode(decrypted);
        _register(channel: channel, credential: credential);
      } catch (e) {
        Log.error(
          'Failed to bootstrap WhatsApp channel ${channel.id}',
          error: e,
        );
      }
    }
  }

  /// Runtime path — called by ChannelEndpoint.connectWhatsAppChannelManual
  /// once a business has pasted in a token + phone_number_id + waba_id
  /// that have already been validated (a real WhatsAppService.probe()
  /// call, before this is ever reached) and persisted. Registers the
  /// channel's own webhook route immediately — for a NEW channel, the
  /// business needs the resulting URL (webhookUrlFor(channelId)) to
  /// paste into their Meta App Dashboard right after this call returns.
  void connectChannel({
    required Channel channel,
    required WhatsAppCredential credential,
  }) {
    _register(channel: channel, credential: credential);
  }

  /// The exact URL a business must paste into their Meta App Dashboard's
  /// Callback URL field for this channel. Returns null if webhookBaseUrl
  /// hasn't been configured (local dev with no public URL yet) — callers
  /// should show a "set WEBHOOK_BASE_URL first" message rather than a
  /// broken URL in that case.
  String? webhookUrlFor(int channelId) => _webhookBaseUrl.isEmpty
      ? null
      : '$_webhookBaseUrl/webhooks/whatsapp/$channelId';

  void _register({required Channel channel, required WhatsAppCredential credential}) {
    final channelId = channel.id;
    if (channelId == null) {
      throw ArgumentError('Cannot register a Channel with no id');
    }

    final service = WhatsAppService(
      accessToken: credential.accessToken,
      phoneNumberId: credential.phoneNumberId,
    );
    final adapter = WhatsAppServiceAdapter(service);

    _services[channelId] = service;
    _adapters[channelId] = adapter;
    _botIdForChannel[channelId] = channel.botId;
    _channelById[channelId] = channel;
    _phoneNumberIdToChannelId[credential.phoneNumberId] = channelId;
    if (credential.appSecret.isNotEmpty) {
      _appSecrets[channelId] = credential.appSecret;
    } else {
      Log.startupWarning(
        'WhatsApp channel $channelId has no App Secret stored — inbound '
        'webhooks for this channel will fail signature verification '
        'until it is reconnected with an App Secret (see '
        'docs/WHATSAPP_MANUAL_SETUP.md). Sending still works normally.',
      );
    }

    // Every channel — old and new — gets its own route registered.
    // Channels still using the legacy shared route keep working through
    // that route too (see file header); this just means they ALSO have
    // a working per-channel URL ready whenever they choose to migrate.
    _addRoute?.call(
      WhatsAppWebhookRoute(channelId: channelId),
      '/webhooks/whatsapp/$channelId',
    );

    final urlForLog = webhookUrlFor(channelId) ?? '(WEBHOOK_BASE_URL not set)';
    Log.startupSuccess(
      'WhatsApp channel $channelId registered (phone_number_id: '
      '${credential.phoneNumberId}, per-channel webhook: $urlForLog)',
    );
  }

  /// Called by a per-channel WhatsAppWebhookRoute BEFORE any JSON parsing
  /// of the inbound POST body, for the one specific [channelId] its URL
  /// path identifies — only that channel's secret is checked.
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

  /// Legacy-only — called by the one remaining shared WhatsAppWebhookRoute
  /// (channelId == null), which has no URL-derived channel to narrow the
  /// check to, so every registered secret is tried. See file header.
  bool verifyWebhookSignatureLegacy({
    required String rawBody,
    required String? signatureHeader,
  }) {
    return WhatsAppSignatureVerifier.verify(
      rawBody: rawBody,
      signatureHeader: signatureHeader,
      candidateAppSecrets: _appSecrets.values,
    );
  }

  /// Entry point for a per-channel route — [channelId] comes straight
  /// from the URL the route was registered at, not from the payload.
  /// Always returns a result map rather than throwing; the route returns
  /// 200 OK to Meta regardless, same "never trigger a retry storm"
  /// reasoning as Telegram's webhook route.
  Future<Map<String, dynamic>> processWebhook(
    int channelId,
    Map<String, dynamic> value,
  ) async {
    if (!_adapters.containsKey(channelId)) {
      Log.warning('processWebhook: no WhatsApp channel registered for channel $channelId');
      return {'success': false, 'error': 'no channel registered for channel $channelId'};
    }

    await _replyToInboundMessages(channelId: channelId, value: value);
    return {'success': true, 'channelId': channelId};
  }

  /// Legacy-only entry point for the shared route — dispatches by
  /// reading `phone_number_id` out of the payload itself, since that
  /// route's URL carries no channel identity. See file header.
  Future<Map<String, dynamic>> processWebhookLegacy(
    Map<String, dynamic> value,
  ) async {
    final phoneNumberId = value['metadata']?['phone_number_id'] as String?;
    if (phoneNumberId == null) {
      Log.warning('processWebhookLegacy: payload missing metadata.phone_number_id');
      return {'success': false, 'error': 'missing phone_number_id'};
    }

    final channelId = _phoneNumberIdToChannelId[phoneNumberId];
    if (channelId == null) {
      Log.warning(
        'processWebhookLegacy: no WhatsApp channel registered for phone_number_id $phoneNumberId',
      );
      return {
        'success': false,
        'error': 'no channel registered for phone_number_id $phoneNumberId',
      };
    }

    await _replyToInboundMessages(channelId: channelId, value: value);
    return {'success': true, 'channelId': channelId};
  }

  /// Phase 3's escalation-wired bot logic — replaces Phase 2a/2b's
  /// canned reply. Text messages go through InboundMessageHandler
  /// (shared with Telegram — see that file's header) for the full
  /// Conversation/Message/grounding/escalation loop; non-text inbound
  /// (image/location/etc.) still just gets a plain acknowledgement,
  /// since there's no text for BotKnowledgeService to answer against —
  /// same scope line Phase 2b already drew.
  ///
  /// [value] is the webhook's `changes[].value` object — it carries a
  /// `messages` array only when the event IS an inbound message (status
  /// updates like "delivered"/"read" arrive as `statuses` instead, with
  /// no `messages` key, and are silently ignored here). `contacts` is a
  /// sibling array Meta includes alongside `messages`, matched by
  /// wa_id, used here only for a display name — never as an identifier.
  Future<void> _replyToInboundMessages({
    required int channelId,
    required Map<String, dynamic> value,
  }) async {
    final messages = value['messages'] as List<dynamic>?;
    if (messages == null || messages.isEmpty) return;

    final adapter = _adapters[channelId];
    if (adapter == null) {
      Log.warning('_replyToInboundMessages: no adapter for channel $channelId');
      return;
    }

    final botId = _botIdForChannel[channelId];
    final contacts = value['contacts'] as List<dynamic>?;

    for (final message in messages) {
      final map = message as Map<String, dynamic>;
      final from = map['from'] as String?;
      final type = map['type'] as String?;
      if (from == null) continue;

      try {
        if (type == 'text') {
          final text = (map['text'] as Map<String, dynamic>?)?['body'] as String?;
          if (text == null || text.trim().isEmpty) continue;

          if (botId == null) {
            Log.warning('No botId registered for WhatsApp channel $channelId — cannot process message');
            continue;
          }

          final displayName = _contactNameFor(contacts, from);
          final reply = await getIt<InboundMessageHandler>().handle(
            botId: botId,
            channelId: channelId,
            platformType: 'whatsapp',
            externalUserId: from,
            displayName: displayName,
            inboundText: text,
            // Gate 1 provenance/idempotency — see message_repository.dart's
            // create(). map['id'] is WhatsApp's wamid, the same top-level
            // message-id field Meta's docs and this codebase's own
            // markAsRead/replyToMessage calls already key on.
            externalMessageId: map['id'] as String?,
          );
          if (reply != null) {
            await _sendText(adapter: adapter, channelId: channelId, botId: botId, recipient: from, text: reply);
          }
        } else if (type == 'image' || type == 'video') {
          // ── PHOTOS AND VIDEO ──────────────────────────────────────
          //
          // These used to fall into the generic non-text branch below:
          // the customer got "sorry, I can only read text" and NOTHING
          // was stored. For a shop, "do you have this?" attached to a
          // picture is one of the most common messages there is, and it
          // left no trace in Operations at all.
          //
          // Meta sends only a media ID here. The bytes need an
          // authenticated fetch against the Graph API, which is what
          // InboundMediaService does — the handler is given the id and
          // the channel, not a URL.
          final media = map[type] as Map<String, dynamic>?;
          final mediaId = media?['id'] as String?;
          final channel = _channelById[channelId];

          if (mediaId == null || botId == null || channel == null) {
            await _sendText(adapter: adapter, channelId: channelId, botId: botId, recipient: from, text: _nonTextReplyText);
            continue;
          }

          // The caption is the customer's actual question. Absent when
          // they just send the picture — and the message must still be
          // recorded, so a placeholder stands in rather than skipping.
          final caption = (media?['caption'] as String?)?.trim() ?? '';

          final reply = await getIt<InboundMessageHandler>().handle(
            botId: botId,
            channelId: channelId,
            platformType: 'whatsapp',
            externalUserId: from,
            displayName: _contactNameFor(contacts, from),
            inboundText: caption.isEmpty
                ? (type == 'video' ? '[sent a video]' : '[sent a photo]')
                : caption,
            mediaReference: mediaId,
            mediaKind: type,
            mediaMimeType: media?['mime_type'] as String?,
            channel: channel,
            externalMessageId: map['id'] as String?,
          );
          if (reply != null) {
            await _sendText(adapter: adapter, channelId: channelId, botId: botId, recipient: from, text: reply);
          }
        } else {
          // Everything else — audio, documents, location, contacts.
          // Still the Phase 2b ack, because none of those have a
          // handling story yet and pretending otherwise would be worse
          // than saying so.
          await _sendText(adapter: adapter, channelId: channelId, botId: botId, recipient: from, text: _nonTextReplyText);
        }
      } catch (e) {
        Log.error('Failed to process/send WhatsApp reply (channel $channelId)', error: e);
      }
    }
  }

  /// Gate 1 — every outbound WhatsApp send goes through the shared
  /// retry/backoff wrapper (connector_retry.dart) instead of a bare
  /// `adapter.sendText()` call. A transient Graph API blip (rate limit,
  /// brief 5xx) used to mean the reply was just lost; now it retries up
  /// to 3 times with backoff before dead-lettering to
  /// connector_sync_log — PART III's "retry and backoff, with a
  /// dead-letter path. A failed sync must be visible, not silent"
  /// applied to the one outbound path this registry owns. On final
  /// failure this rethrows, matching the original bare call's behavior
  /// — the surrounding try/catch in _replyToInboundMessages still logs
  /// it exactly as before.
  Future<void> _sendText({
    required WhatsAppServiceAdapter adapter,
    required int channelId,
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
      connectorKey: 'whatsapp',
      store: 'channel',
      kind: 'sync',
    );
  }

  String? _contactNameFor(List<dynamic>? contacts, String waId) {
    if (contacts == null) return null;
    for (final contact in contacts) {
      final map = contact as Map<String, dynamic>;
      if (map['wa_id'] == waId) {
        return (map['profile'] as Map<String, dynamic>?)?['name'] as String?;
      }
    }
    return null;
  }

  static const _nonTextReplyText =
      "✅ Got that! We'll get back to you shortly. — Powered by Kola";

  /// Platform-agnostic sender for a connected channel — same contract as
  /// TelegramBotRegistry.messagingFor. Returns null if the channel isn't
  /// currently registered.
  IMessagingService? messagingFor(int channelId) => _adapters[channelId];

  /// Owner-initiated disconnect (2026-08-31) — same role as
  /// TelegramBotRegistry.disconnectChannel. WhatsAppService holds no
  /// polling loop or persistent connection to stop (it's a plain HTTP
  /// wrapper, unlike Telegram's long-poll/webhook-registered Bot), so
  /// there is nothing to dispose — forgetting the maps is the whole job.
  ///
  /// _phoneNumberIdToChannelId is keyed by phone number, not channelId,
  /// so it's cleared by value rather than by key — a small map (one
  /// entry per WhatsApp channel a business has ever connected), so a
  /// linear scan costs nothing real.
  ///
  /// SAME "ROUTE STAYS REGISTERED" REASONING AS TELEGRAM: this channel's
  /// per-channel route keeps existing as a live path; processWebhook's
  /// existing `_adapters.containsKey` check already treats a missing
  /// entry as a normal, logged no-op.
  void disconnectChannel(int channelId) {
    _services.remove(channelId);
    _adapters.remove(channelId);
    _appSecrets.remove(channelId);
    _botIdForChannel.remove(channelId);
    _channelById.remove(channelId);
    _phoneNumberIdToChannelId.removeWhere((_, id) => id == channelId);
    Log.info('WhatsApp channel $channelId disconnected (owner-initiated)');
  }

  /// Used by health checks/diagnostics — not part of any endpoint yet.
  bool isRunning(int channelId) => _services.containsKey(channelId);

  /// Task #82 — the nightly credential health check's WhatsApp probe.
  /// Reuses this channel's already-decrypted, already-registered
  /// WhatsAppService (no re-decryption needed) and calls probe() — the
  /// same real Graph API call ChannelEndpoint.connectWhatsAppChannelManual
  /// makes before ever persisting a token, here re-run periodically
  /// instead of only once at connect time. Returns false for "definitely
  /// unhealthy" AND for "not even registered," same reasoning as
  /// TelegramBotRegistry.checkHealth.
  Future<bool> checkHealth(int channelId) async {
    final service = _services[channelId];
    if (service == null) return false;
    try {
      await service.probe();
      return true;
    } catch (e) {
      Log.warning('WhatsApp health check failed for channel $channelId: $e');
      return false;
    }
  }
}

/// Thrown by ChannelEndpoint when a pasted-in WhatsApp token/phone_number_id
/// pair fails a real probe() call — lets the dashboard show "that token
/// doesn't work" instead of a generic 500. Mirrors
/// InvalidTelegramTokenException's role exactly.
class InvalidWhatsAppCredentialException implements Exception {
  final String message;
  const InvalidWhatsAppCredentialException(this.message);

  @override
  String toString() => 'InvalidWhatsAppCredentialException: $message';
}
