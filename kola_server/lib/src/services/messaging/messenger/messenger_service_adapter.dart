// messenger_service_adapter.dart
//
// Adapter that makes MessengerService satisfy IMessagingService — same
// role as instagram_service_adapter.dart/whatsapp_service_adapter.dart/
// telegram_service_adapter.dart. Bot Mother, the Errand engine, and any
// future proactive-notification code call `messagingService.sendText(...)`
// without knowing or caring it's Messenger underneath.
//
// REAL, NAMED SCOPE CUTS — METHODS THAT DON'T DO WHAT THEIR NAME
// SUGGESTS: same set, same reasoning as InstagramServiceAdapter's own
// header — Messenger's real interactive-message payloads (generic
// template, quick replies) exist but aren't a mechanical translation of
// MessageButton/ListSection, so sendButtons/sendList render plain-text
// fallbacks, sendLocation returns an honest error, replyToMessage sends
// plain text and ignores messageId, sendTypingIndicator/markAsRead
// honestly return false/no-op (Messenger DOES have a real
// sender_action:typing_on/mark_seen call in Meta's docs, but wiring it
// is follow-up work, not built speculatively in this pass — same
// discipline as everywhere else in this codebase, not a claim that no
// such API exists).

import '../messaging_result.dart';
import '../messaging_service_interface.dart';
import 'messenger_service.dart';

class MessengerServiceAdapter implements IMessagingService {
  MessengerServiceAdapter(this._messengerService);

  final MessengerService _messengerService;

  @override
  PlatformType get platformType => PlatformType.messenger;

  @override
  Future<MessagingResult> sendText({
    required String recipient,
    required String text,
    bool? previewUrl,
    String? parseMode,
  }) async {
    // previewUrl/parseMode ignored — Messenger's text messages have no
    // link-preview toggle or Markdown/HTML mode concept to pass through,
    // same "adapter accepts the shared shape, platform just doesn't use
    // every field" pattern as InstagramServiceAdapter/WhatsAppServiceAdapter.
    try {
      final result = await _messengerService.sendText(to: recipient, body: text);
      return _success(result, recipient);
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  @override
  Future<MessagingResult> sendMedia({
    required String recipient,
    required String mediaUrl,
    required MediaType mediaType,
    String? caption,
  }) async {
    if (mediaType != MediaType.image) {
      // See file header — only image is implemented for real this pass.
      return MessagingResult.error(
        message: 'Messenger sendMedia only supports images in this build '
            '(got ${mediaType.name}).',
        platform: platformType,
      );
    }
    try {
      final result = await _messengerService.sendImage(to: recipient, imageUrl: mediaUrl);
      // Messenger's send API has no separate caption field on an image
      // attachment (see messenger_service.dart's sendImage) — a caption,
      // if given, follows as its own plain text message rather than
      // being silently dropped, same as InstagramServiceAdapter.sendMedia.
      if (caption != null && caption.trim().isNotEmpty) {
        await _messengerService.sendText(to: recipient, body: caption);
      }
      return _success(result, recipient);
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  @override
  Future<MessagingResult> sendButtons({
    required String recipient,
    required String bodyText,
    required List<MessageButton> buttons,
    String? headerText,
    String? footerText,
    Map<String, dynamic>? headerInteractive,
  }) {
    // See file header — plain-text fallback, not a real interactive send.
    final lines = [
      if (headerText != null) headerText,
      bodyText,
      for (final b in buttons) '• ${b.text}',
      if (footerText != null) footerText,
    ];
    return sendText(recipient: recipient, text: lines.join('\n'));
  }

  @override
  Future<MessagingResult> sendList({
    required String recipient,
    required String bodyText,
    required String buttonText,
    required List<ListSection> sections,
    String? headerText,
    String? footerText,
  }) {
    // See file header — plain-text fallback, not a real interactive send.
    final lines = <String>[
      if (headerText != null) headerText,
      bodyText,
      for (final section in sections) ...[
        section.title,
        for (final row in section.rows)
          '• ${row.title}${row.description != null ? ' — ${row.description}' : ''}',
      ],
      if (footerText != null) footerText,
    ];
    return sendText(recipient: recipient, text: lines.join('\n'));
  }

  @override
  Future<MessagingResult> sendLocation({
    required String recipient,
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) async {
    // See file header — no sensible text fallback for a map pin; honest
    // error rather than a fabricated "success" or a useless text message.
    return MessagingResult.error(
      message: 'Messenger sendLocation is not implemented in this build.',
      platform: platformType,
    );
  }

  @override
  Future<bool> markAsRead({required String messageId}) async => false;

  @override
  Future<MessagingResult> replyToMessage({
    required String recipient,
    required String messageId,
    required String text,
    bool? previewUrl,
  }) {
    // See file header — messageId is accepted for interface compliance
    // but not used; not wired to Messenger's real reply-quoting shape
    // this pass.
    return sendText(recipient: recipient, text: text);
  }

  @override
  Future<bool> sendTypingIndicator({
    required String recipient,
    TypingIndicatorType? type,
  }) async => false;

  @override
  void dispose() {
    // No persistent connection/socket to close — MessengerService is a
    // stateless HTTP wrapper, same as InstagramServiceAdapter/
    // WhatsAppServiceAdapter's dispose().
  }

  MessagingResult _success(Map<String, dynamic> apiResponse, String recipient) {
    // Per Meta's docs, a successful send returns
    // {"recipient_id": "PSID", "message_id": "mid.xxx"} — same flat
    // shape as Instagram's response, unlike WhatsApp's nested
    // `messages: [{id: ...}]` array.
    final messageId = apiResponse['message_id'] as String?;
    return MessagingResult.success(
      messageId: messageId ?? '',
      recipient: recipient,
      platform: platformType,
      metadata: apiResponse,
    );
  }
}
