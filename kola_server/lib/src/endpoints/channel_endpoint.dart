// channel_endpoint.dart
//
// Phase 2a's one real write path for messaging channels: connecting a
// business's own Telegram bot (created via @BotFather — the Telegram
// equivalent of WhatsApp's "bring your own number" story in
// META_CONNECT_FLOW.md) to one of their Bots.
//
// WHY VALIDATE THE TOKEN BEFORE PERSISTING ANYTHING: a business pasting
// in a bot token is exactly the kind of input that's easy to get wrong
// (extra whitespace, copying the wrong line from BotFather's reply,
// revoking and regenerating a token after copying the old one). Probing
// it with a real getMe() call first means a bad paste fails loudly with
// a clear error, instead of silently sitting in the DB as a 'connected'
// channel that will never actually receive a message.
//
// WHY THE HOT-CONNECT MATTERS: TelegramBotRegistry.connectChannel()
// starts talking to Telegram immediately, in the same request — a
// business shouldn't have to wait for the next server restart for their
// bot to start replying.

import 'package:serverpod/serverpod.dart';
import 'package:televerse/telegram.dart' show User;
import 'package:televerse/televerse.dart' show Bot;
import 'package:kola_server/src/generated/protocol.dart' hide Bot;
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/messaging/telegram/telegram_bot_registry.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_bot_registry.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_credential.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_service.dart';
import 'package:kola_server/src/services/messaging/instagram/instagram_bot_registry.dart';
import 'package:kola_server/src/services/messaging/instagram/instagram_credential.dart';
import 'package:kola_server/src/services/messaging/instagram/instagram_service.dart';
import 'package:kola_server/src/services/connectors/contract/agent_lifecycle_events.dart';
import 'package:kola_server/kola_logger.dart';

class ChannelEndpoint extends Endpoint {
  BotRepository get _bots => getIt<BotRepository>();
  ChannelRepository get _channels => getIt<ChannelRepository>();
  AgentLifecycleEvents get _agentEvents => getIt<AgentLifecycleEvents>();

  /// Connects [botToken] (a token from @BotFather) as the Telegram
  /// channel for [botId] inside [workspaceId]. Returns the resulting
  /// Channel row, now in 'connected' status with a real, encrypted
  /// credential and a live webhook already registered with Telegram.
  ///
  /// NOTE ON ROLE SCOPING: deliberately open to any workspace member for
  /// now (like WorkspaceEndpoint.getWorkspace), not owner-only — connecting
  /// the one bot a small business runs isn't a sensitive-enough action to
  /// gate by role at this phase. Revisit once the 'staff'/'developer'
  /// role split actually needs enforcing here (SRS.md §5).
  Future<Channel> connectTelegramChannel(
    Session session,
    String accessToken,
    int workspaceId,
    int botId,
    String botToken,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final bot = await _bots.findByIdScoped(botId, workspaceId);
    if (bot == null) {
      throw KolaException(message: 'Bot $botId not found in workspace $workspaceId');
    }

    final trimmedToken = botToken.trim();
    if (trimmedToken.isEmpty) {
      throw const InvalidTelegramTokenException('Bot token cannot be empty.');
    }

    // ── Probe against Telegram's real API before touching the DB ────────
    User telegramUser;
    try {
      telegramUser = await Bot(trimmedToken).api.getMe();
    } catch (e) {
      throw InvalidTelegramTokenException(
        'Could not verify this Telegram bot token with Telegram — double-check '
        'it was copied exactly as @BotFather sent it. ($e)',
      );
    }

    // ── Reuse the existing Telegram channel row for this bot if one
    //    already exists (e.g. reconnecting after a revoked token),
    //    otherwise create a fresh 'pending' row first. ──────────────────
    final existing = await _channels.findByBotAndPlatform(botId, 'telegram');
    final channel = existing ??
        await _channels.create(botId: botId, platformType: 'telegram');

    final encryptedCredential =
        ChannelCredentialEncryptionService.encrypt(trimmedToken);

    final connectedChannel = await _channels.setCredential(
      channelId: channel.id!,
      encryptedCredential: encryptedCredential,
      displayName: '@${telegramUser.username}',
    );

    // ── Hot-connect — the business starts receiving real messages from
    //    this request onward, no server restart required. ───────────────
    await TelegramBotRegistry.instance.connectChannel(
      channel: connectedChannel,
      botToken: trimmedToken,
    );

    // Bot Mother/the onboarding wizard flips a bot from 'draft' to 'live'
    // once a channel is actually connected — bot.spy.yaml's header
    // comment anticipated exactly this moment.
    if (bot.status == 'draft') {
      final publishedBot = await _bots.setStatus(botId, 'live');
      // Gate 2 — event bus. See agent_lifecycle_events.dart's header.
      await _agentEvents.recordPublished(publishedBot);
    }

    Log.success(
      'Telegram channel connected',
      data: {
        'workspaceId': workspaceId,
        'botId': botId,
        'channelId': connectedChannel.id,
        'telegramUsername': telegramUser.username,
      },
      session: session,
    );

    return connectedChannel;
  }

  /// Every channel connected to one of the caller's own bots — for the
  /// dashboard's "Channels" page. Deliberately takes botId (not
  /// workspaceId alone) since Channel.botId is the actual foreign key;
  /// findByIdScoped on the bot is what proves workspace ownership.
  Future<List<Channel>> listChannelsForBot(
    Session session,
    String accessToken,
    int workspaceId,
    int botId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final bot = await _bots.findByIdScoped(botId, workspaceId);
    if (bot == null) {
      throw KolaException(message: 'Bot $botId not found in workspace $workspaceId');
    }

    return _channels.listByBot(botId);
  }

  /// Connects a WhatsApp number the MANUAL way — the business has
  /// already gone through Meta's App Dashboard themselves (per
  /// docs/WHATSAPP_MANUAL_SETUP.md) and generated their own access
  /// token, phone_number_id, and WABA id from their own small Meta App.
  ///
  /// WHY THIS NEEDS ZERO APP REVIEW ON KOLA'S SIDE: a WhatsApp Cloud API
  /// bearer token's validity is checked by Meta against the token's own
  /// grants (which app issued it, what assets that app's System User has
  /// Standard Access to) — never against which server makes the HTTP
  /// call. The business's token was issued by THEIR app, over THEIR own
  /// number, so it works from Kola's servers exactly as it would from
  /// theirs — see whatsapp_service.dart's header for the same reasoning
  /// from the calling-code side. This is deliberately built as the
  /// primary path (not a fallback) per the product decision to lead
  /// with manual connect and treat Embedded Signup as an automatic
  /// alternative layered in later, not a dependency this path needs.
  ///
  /// WHY PROBE BEFORE PERSISTING: identical reasoning to
  /// connectTelegramChannel's getMe() call — a pasted-in token/ID
  /// combination is easy to get wrong (copying the App's access token
  /// instead of the System User's, mismatching phone_number_id and
  /// waba_id from different numbers). probe() calls Meta for real before
  /// anything touches the DB, so a bad paste fails with a clear message
  /// instead of sitting as a 'connected' channel that can never send.
  ///
  /// WHY appId/appSecret ARE NOW REQUIRED TOO (added after the initial
  /// build): appSecret is what lets WhatsAppBotRegistry verify the
  /// X-Hub-Signature-256 header on inbound webhooks — without it, this
  /// channel could send messages fine but couldn't safely trust anything
  /// arriving at the shared /webhooks/whatsapp route as really being from
  /// Meta (see whatsapp_signature_verifier.dart's header for the full
  /// reasoning). appId is stored alongside it mainly so debugToken()
  /// below has what it needs without asking the business to dig it up
  /// twice. Both live in the same App Dashboard → Settings → Basic page
  /// docs/WHATSAPP_MANUAL_SETUP.md's Step 5a walks through.
  Future<Channel> connectWhatsAppChannelManual(
    Session session,
    String accessToken,
    int workspaceId,
    int botId,
    String whatsappAccessToken,
    String phoneNumberId,
    String wabaId,
    String whatsappAppId,
    String whatsappAppSecret,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final bot = await _bots.findByIdScoped(botId, workspaceId);
    if (bot == null) {
      throw KolaException(message: 'Bot $botId not found in workspace $workspaceId');
    }

    final trimmedToken = whatsappAccessToken.trim();
    final trimmedPhoneNumberId = phoneNumberId.trim();
    final trimmedWabaId = wabaId.trim();
    final trimmedAppId = whatsappAppId.trim();
    final trimmedAppSecret = whatsappAppSecret.trim();
    if (trimmedToken.isEmpty ||
        trimmedPhoneNumberId.isEmpty ||
        trimmedWabaId.isEmpty ||
        trimmedAppId.isEmpty ||
        trimmedAppSecret.isEmpty) {
      throw const InvalidWhatsAppCredentialException(
        'Access token, phone number ID, WhatsApp Business Account ID, App ID, '
        'and App Secret are all required.',
      );
    }

    // ── Probe against Meta's real API before touching the DB ────────────
    final whatsAppService = WhatsAppService(
      accessToken: trimmedToken,
      phoneNumberId: trimmedPhoneNumberId,
    );
    Map<String, dynamic> phoneInfo;
    try {
      phoneInfo = await whatsAppService.probe();
    } catch (e) {
      throw InvalidWhatsAppCredentialException(
        'Could not verify this WhatsApp number with Meta — double-check the '
        'access token and phone number ID were copied exactly from your Meta '
        'App Dashboard. ($e)',
      );
    }

    // ── Token freshness check — NOT blocking, just informational. A
    //    business following docs/WHATSAPP_MANUAL_SETUP.md's Step 5
    //    should already have a permanent token, but the default token
    //    Meta shows on the API Setup page is a 24-hour temporary one,
    //    and connecting with it accidentally is an easy mistake that
    //    fails silently a day later otherwise. debug_token itself
    //    failing (e.g. a wrong App ID/Secret pairing) doesn't block the
    //    connection either — appId/appSecret are still validated for
    //    real the moment the first inbound webhook signature check runs. ──
    try {
      final tokenInfo = await whatsAppService.debugToken(
        appId: trimmedAppId,
        appSecret: trimmedAppSecret,
      );
      if (!tokenInfo.isPermanent) {
        Log.warning(
          'WhatsApp channel for bot $botId was connected with a TEMPORARY '
          'access token (expires ${tokenInfo.expiresAt}) — messages will '
          'stop sending when it expires. Generate a permanent System User '
          'token per docs/WHATSAPP_MANUAL_SETUP.md Step 5 and reconnect '
          'before then.',
        );
      }
    } catch (e) {
      Log.warning(
        'WhatsApp debug_token check failed for bot $botId (connection still '
        'proceeds — this only affects the temporary-vs-permanent warning, '
        'not whether the channel works): $e',
      );
    }

    // ── Reuse the existing WhatsApp channel row for this bot if one
    //    already exists (e.g. reconnecting after a revoked token),
    //    otherwise create a fresh 'pending' row first. ──────────────────
    final existing = await _channels.findByBotAndPlatform(botId, 'whatsapp');
    final channel = existing ??
        await _channels.create(botId: botId, platformType: 'whatsapp');

    final credential = WhatsAppCredential(
      accessToken: trimmedToken,
      phoneNumberId: trimmedPhoneNumberId,
      wabaId: trimmedWabaId,
      appId: trimmedAppId,
      appSecret: trimmedAppSecret,
    );
    final encryptedCredential =
        ChannelCredentialEncryptionService.encrypt(credential.encode());

    final displayName = phoneInfo['verified_name'] as String? ??
        phoneInfo['display_phone_number'] as String?;

    final connectedChannel = await _channels.setCredential(
      channelId: channel.id!,
      encryptedCredential: encryptedCredential,
      displayName: displayName,
    );

    // ── Hot-connect — the business can send/receive from this request
    //    onward, no server restart required. No Telegram-style setWebhook
    //    handshake needed: the shared WhatsApp route is already live and
    //    Meta already has it configured at the App level. ────────────────
    WhatsAppBotRegistry.instance.connectChannel(
      channel: connectedChannel,
      credential: credential,
    );

    if (bot.status == 'draft') {
      final publishedBot = await _bots.setStatus(botId, 'live');
      // Gate 2 — event bus. See agent_lifecycle_events.dart's header.
      await _agentEvents.recordPublished(publishedBot);
    }

    Log.success(
      'WhatsApp channel connected (manual)',
      data: {
        'workspaceId': workspaceId,
        'botId': botId,
        'channelId': connectedChannel.id,
        'phoneNumberId': trimmedPhoneNumberId,
        'displayName': displayName,
      },
      session: session,
    );

    return connectedChannel;
  }

  /// Connects an Instagram professional account — the final channel of
  /// the Connections Backbone build (Rev 5/6's Gate 11 explicitly
  /// deferred this one, scoped separately from that gate's sync()-shaped
  /// connectors since Instagram DMs are push-driven like WhatsApp/
  /// Telegram — see instagram_bot_registry.dart's header).
  ///
  /// Same manual-connect shape as connectWhatsAppChannelManual: the
  /// business has already created a Meta App, generated an Instagram
  /// User access token with instagram_business_basic +
  /// instagram_business_manage_messages permissions, and knows their own
  /// Instagram professional account's ID and that App's App Secret.
  /// Probed against Meta's real API (InstagramService.probe()) before
  /// anything touches the DB — same "a bad paste fails loudly, not as a
  /// silently-broken 'connected' row" reasoning as every other manual
  /// connect flow in this file.
  ///
  /// enableSubscription() is attempted right after probing succeeds —
  /// per Meta's docs, an App-level webhook subscription alone isn't
  /// enough; each individual Instagram account must separately opt in
  /// via POST /<IG_ID>/subscribed_apps. A failure there does NOT block
  /// the connection (sending still works; see instagram_service.dart's
  /// own doc on that method) — only logged, same soft-fail posture as
  /// WhatsApp's debug_token check above.
  Future<Channel> connectInstagramChannelManual(
    Session session,
    String accessToken,
    int workspaceId,
    int botId,
    String instagramAccessToken,
    String igUserId,
    String instagramAppSecret,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final bot = await _bots.findByIdScoped(botId, workspaceId);
    if (bot == null) {
      throw KolaException(message: 'Bot $botId not found in workspace $workspaceId');
    }

    final trimmedToken = instagramAccessToken.trim();
    final trimmedIgUserId = igUserId.trim();
    final trimmedAppSecret = instagramAppSecret.trim();
    if (trimmedToken.isEmpty || trimmedIgUserId.isEmpty || trimmedAppSecret.isEmpty) {
      throw const InvalidInstagramCredentialException(
        'Access token, Instagram professional account ID, and App Secret are all required.',
      );
    }

    // ── Probe against Meta's real API before touching the DB ────────────
    final instagramService = InstagramService(
      accessToken: trimmedToken,
      igUserId: trimmedIgUserId,
    );
    Map<String, dynamic> accountInfo;
    try {
      accountInfo = await instagramService.probe();
    } catch (e) {
      throw InvalidInstagramCredentialException(
        'Could not verify this Instagram account with Meta — double-check the '
        'access token and account ID were copied exactly from your Meta App '
        'Dashboard. ($e)',
      );
    }

    // ── Enable webhook delivery for this account — see method doc above
    //    on why this is a soft failure, not a blocking one. ──────────────
    try {
      await instagramService.enableSubscription();
    } catch (e) {
      Log.warning(
        'Instagram subscribed_apps call failed for bot $botId (connection still '
        'proceeds — sending works either way, but inbound messages will not '
        'arrive until this is retried): $e',
      );
    }

    // ── Reuse the existing Instagram channel row for this bot if one
    //    already exists (e.g. reconnecting after a revoked token),
    //    otherwise create a fresh 'pending' row first. ──────────────────
    final existing = await _channels.findByBotAndPlatform(botId, 'instagram');
    final channel = existing ??
        await _channels.create(botId: botId, platformType: 'instagram');

    final credential = InstagramCredential(
      igUserId: trimmedIgUserId,
      accessToken: trimmedToken,
      appSecret: trimmedAppSecret,
    );
    final encryptedCredential =
        ChannelCredentialEncryptionService.encrypt(credential.encode());

    final displayName = accountInfo['username'] as String? ??
        accountInfo['name'] as String?;

    final connectedChannel = await _channels.setCredential(
      channelId: channel.id!,
      encryptedCredential: encryptedCredential,
      displayName: displayName,
    );

    // ── Hot-connect — registers this channel's webhook route
    //    immediately; the business needs InstagramBotRegistry
    //    .instance.webhookUrlFor(connectedChannel.id) right after this
    //    call returns, to paste into their Meta App Dashboard. ──────────
    InstagramBotRegistry.instance.connectChannel(
      channel: connectedChannel,
      credential: credential,
    );

    if (bot.status == 'draft') {
      final publishedBot = await _bots.setStatus(botId, 'live');
      // Gate 2 — event bus. See agent_lifecycle_events.dart's header.
      await _agentEvents.recordPublished(publishedBot);
    }

    Log.success(
      'Instagram channel connected (manual)',
      data: {
        'workspaceId': workspaceId,
        'botId': botId,
        'channelId': connectedChannel.id,
        'igUserId': trimmedIgUserId,
        'displayName': displayName,
      },
      session: session,
    );

    return connectedChannel;
  }
}
