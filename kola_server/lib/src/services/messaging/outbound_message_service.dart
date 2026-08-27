// outbound_message_service.dart — Gate 8. The business logic behind
// POST /v1/messages: send ONE personalized message via a connected
// WhatsApp or Telegram channel on behalf of a workspace, and record it
// on the business graph exactly the way every other outbound path in
// this codebase does (ConversationEndpoint.sendHumanReply is the
// closest sibling — same findOrCreate -> send -> persist -> touch ->
// emit shape).
//
// DELIBERATELY SINGLE-SEND, TEXT-ONLY, v1:
//   docs/Kolaa_Connections_Backbone_Direction_v5.pdf Part VI scopes Gate
//   8 to one personalized message per call — broadcast/bulk sending is
//   Gate 9, sequences are Gate 10, both separate and much larger. This
//   service sends free-form text through the SAME IMessagingService
//   .sendText(...) path sendHumanReply already uses, rather than adding
//   WhatsApp template selection here. That is a real scope line, not a
//   shortcut: WhatsApp's 24-hour customer-service-window rule means a
//   business-initiated free-text send outside that window is genuinely
//   rejected by Meta — WhatsAppService's own error surfaces through
//   MessagingResult.success == false in that case, and this service
//   reports that failure back to the caller rather than silently
//   swallowing or working around it. Template-based sends (the only way
//   to reach a customer outside the window) are a real follow-up, not
//   built here, because the template-selection contract (which
//   templateId, which variables) deserves its own design pass rather
//   than being bolted onto this one.
//
// WORKSPACE -> CHANNEL RESOLUTION, v1: a workspace may run more than one
// bot, and a bot may have more than one channel per platform is not
// possible (Channel is unique per (botId, platformType)) but a
// workspace CAN have multiple bots each with their own channel for the
// same platform. This service sends through the first CONNECTED channel
// it finds for the requested platform, in bot-list order — there is no
// per-message "which bot" control in the request shape yet. Documented
// here as a known v1 limitation rather than silently decided: a
// workspace running two live WhatsApp numbers has no way to pick one
// through this endpoint today.

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/message_repository.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_bot_registry.dart';
import 'package:kola_server/src/services/messaging/telegram/telegram_bot_registry.dart';
import 'package:kola_server/kola_logger.dart';

class OutboundMessageService {
  OutboundMessageService({
    required BotRepository bots,
    required ChannelRepository channels,
    required ConversationRepository conversations,
    required MessageRepository messages,
    required CustomerIdentityResolver customerIdentity,
    required EventBus events,
  }) : _bots = bots,
       _channels = channels,
       _conversations = conversations,
       _messages = messages,
       _customerIdentity = customerIdentity,
       _events = events;

  final BotRepository _bots;
  final ChannelRepository _channels;
  final ConversationRepository _conversations;
  final MessageRepository _messages;
  final CustomerIdentityResolver _customerIdentity;
  final EventBus _events;

  static const supportedPlatforms = <String>['whatsapp', 'telegram'];

  Future<OutboundSendResult> send({
    required int workspaceId,
    required String platform,
    required String to,
    required String text,
    String? idempotencyKey,
  }) async {
    if (!supportedPlatforms.contains(platform)) {
      return OutboundSendResult.failure(
        'Unsupported platform "$platform" — must be one of $supportedPlatforms.',
      );
    }
    final recipient = to.trim();
    if (recipient.isEmpty) {
      return OutboundSendResult.failure('"to" is required.');
    }
    final body = text.trim();
    if (body.isEmpty) {
      return OutboundSendResult.failure('"text" is required.');
    }

    final channel = await _resolveChannel(workspaceId: workspaceId, platform: platform);
    if (channel == null) {
      return OutboundSendResult.failure(
        'No connected $platform channel for this workspace.',
      );
    }
    final channelId = channel.id!;

    final adapter = platform == 'whatsapp'
        ? WhatsAppBotRegistry.instance.messagingFor(channelId)
        : TelegramBotRegistry.instance.messagingFor(channelId);
    if (adapter == null) {
      return OutboundSendResult.failure(
        'Channel $channelId ($platform) is registered but not currently connected — cannot send.',
      );
    }

    final conversation = await _conversations.findOrCreate(
      workspaceId: workspaceId,
      botId: channel.botId,
      channelId: channelId,
      platformType: platform,
      externalUserId: recipient,
    );
    final conversationId = conversation.id;
    if (conversationId == null) {
      return OutboundSendResult.failure('Failed to resolve a conversation for this recipient.');
    }

    // Idempotency (caller-supplied, optional): namespaced so it can never
    // collide with a real inbound wamid/Telegram message id sharing the
    // same conversation — see message_repository.dart's create() header
    // for why (conversationId, externalMessageId) is already a safe
    // upsert key (migration 036, Gate 1).
    final externalMessageId =
        (idempotencyKey == null || idempotencyKey.trim().isEmpty) ? null : 'api:${idempotencyKey.trim()}';

    // Checked BEFORE sending, not just before writing — a retried call
    // with the same key must not dispatch a second real message to the
    // customer. See message_repository.dart's findByConversationAndExternalId.
    if (externalMessageId != null) {
      final existing = await _messages.findByConversationAndExternalId(
        conversationId: conversationId,
        externalMessageId: externalMessageId,
      );
      if (existing != null) {
        return OutboundSendResult.ok(existing, deduped: true);
      }
    }

    // Gate 3 — link this conversation's customer the same way every
    // other intake path does. 'manual': this send was triggered by an
    // API caller, not by the customer messaging in first.
    if (conversation.customerId == null) {
      final signal = platform == 'whatsapp'
          ? IdentitySignal(
              type: 'phone',
              value: CustomerIdentityResolver.normalizePhone(recipient),
            )
          : IdentitySignal(
              type: 'platform_user',
              value: CustomerIdentityResolver.normalizePlatformUser('telegram', recipient),
            );
      final customerId = await _customerIdentity.resolve(
        workspaceId: workspaceId,
        primary: signal,
        source: 'manual',
      );
      if (customerId != null) {
        await _conversations.setCustomer(conversationId, customerId);
      }
    }

    final result = await adapter.sendText(recipient: recipient, text: body);
    if (!result.success) {
      Log.warning('Gate 8 send failed workspaceId=$workspaceId platform=$platform: ${result.errorMessage}');
      return OutboundSendResult.failure(result.errorMessage ?? 'Send failed for an unknown reason.');
    }

    final message = await _messages.create(
      conversationId: conversationId,
      direction: 'outbound',
      senderType: 'api',
      body: body,
      sourcePlatform: platform,
      externalMessageId: externalMessageId,
      permissionScope: 'workspace',
    );
    await _conversations.touchLastMessageAt(conversationId);

    await _events.emit(
      workspaceId: workspaceId,
      eventType: 'message_sent',
      fingerprint: 'message_sent:${message.id}',
      payload: {
        'conversationId': conversationId,
        'messageId': message.id,
        'platform': platform,
        'to': recipient,
      },
    );

    Log.success(
      'Gate 8 message sent',
      data: {'workspaceId': workspaceId, 'platform': platform, 'conversationId': conversationId},
    );

    return OutboundSendResult.ok(message);
  }

  Future<Channel?> _resolveChannel({required int workspaceId, required String platform}) async {
    final bots = await _bots.listByWorkspace(workspaceId);
    for (final bot in bots) {
      final botId = bot.id;
      if (botId == null) continue;
      final channel = await _channels.findByBotAndPlatform(botId, platform);
      if (channel != null && channel.status == 'connected') {
        return channel;
      }
    }
    return null;
  }
}

/// Plain result type — same "no Serverpod serialization needed" reasoning
/// as MessagingResult (see that file's header): this never crosses the
/// generated-Endpoint boundary, only the hand-built JSON in
/// send_message_route.dart, so it doesn't need a .spy.yaml.
class OutboundSendResult {
  const OutboundSendResult._({required this.success, this.message, this.error, this.deduped = false});

  factory OutboundSendResult.ok(Message message, {bool deduped = false}) =>
      OutboundSendResult._(success: true, message: message, deduped: deduped);

  factory OutboundSendResult.failure(String error) => OutboundSendResult._(success: false, error: error);

  final bool success;
  final Message? message;
  final String? error;
  final bool deduped;
}
