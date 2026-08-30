// instagram_service_adapter.dart
//
// Adapter that makes InstagramService satisfy IMessagingService — same
// role as whatsapp_service_adapter.dart and telegram_service_adapter.dart.
// Bot Mother, the Errand engine, and any future proactive-notification
// code call `messagingService.sendText(...)` without knowing or caring
// it's Instagram underneath — the whole point of this interface, per its
// own header, which named "Instagram/SMS in Phase 3" as anticipated
// future platforms from the very first version of this file.
//
// REAL, NAMED SCOPE CUTS — METHODS THAT DON'T DO WHAT THEIR NAME SUGGESTS:
//   sendButtons / sendList / sendLocation — Instagram Messaging's
//   equivalent features (quick replies, generic templates) exist but have
//   a genuinely different payload shape than WhatsApp's interactive
//   messages or Telegram's inline keyboards — mapping MessageButton/
//   ListSection onto them isn't a mechanical translation the way
//   sendText/sendImage were. Rather than force a lossy, half-working
//   mapping, these three fall back to plain text (sendButtons/sendList
//   render their body text with the options listed inline; sendLocation
//   has no text fallback that makes sense, so it returns an honest
//   error). A real interactive-Instagram-message implementation is
//   follow-up work, not invented speculatively here.
//   replyToMessage — Instagram's API has no `context.message_id` quote
//   concept in the same shape WhatsApp's does; this sends a plain
//   sendText and ignores messageId, same "best available, not a perfect
//   match" choice as the interactive fallbacks above.
//   sendTypingIndicator / markAsRead — no equivalent call exists in what
//   this pass built (instagram_service.dart has no read-receipt or
//   typing-indicator method); both honestly return false/no-op, same
//   pattern WhatsAppServiceAdapter.sendTypingIndicator already
//   establishes for "not supported this way."

import '../messaging_result.dart';
import '../messaging_service_interface.dart';
import 'instagram_service.dart';

class InstagramServiceAdapter implements IMessagingService {
  InstagramServiceAdapter(this._instagramService);

  final InstagramService _instagramService;

  @override
  PlatformType get platformType => PlatformType.instagram;

  @override
  Future<MessagingResult> sendText({
    required String recipient,
    required String text,
    bool? previewUrl,
    String? parseMode,
  }) async {
    // previewUrl/parseMode are ignored — Instagram's text messages have
    // no link-preview toggle or Markdown/HTML mode concept to pass
    // through, same "adapter accepts the shared shape, platform just
    // doesn't use every field" pattern as WhatsAppServiceAdapter.
    try {
      final result = await _instagramService.sendText(to: recipient, body: text);
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
        message: 'Instagram sendMedia only supports images in this build '
            '(got ${mediaType.name}).',
        platform: platformType,
      );
    }
    try {
      final result = await _instagramService.sendImage(to: recipient, imageUrl: mediaUrl);
      // Instagram's send API has no separate caption field on an image
      // attachment (see instagram_service.dart's sendImage) — a caption,
      // if given, follows as its own plain text message rather than
      // being silently dropped.
      if (caption != null && caption.trim().isNotEmpty) {
        await _instagramService.sendText(to: recipient, body: caption);
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
      message: 'Instagram sendLocation is not implemented in this build.',
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
    // but not used; Instagram's API has no quote-reply concept this pass
    // wires up.
    return sendText(recipient: recipient, text: text);
  }

  @override
  Future<bool> sendTypingIndicator({
    required String recipient,
    TypingIndicatorType? type,
  }) async => false;

  @override
  void dispose() {
    // No persistent connection/socket to close — InstagramService is a
    // stateless HTTP wrapper, same as WhatsAppServiceAdapter's dispose().
  }

  MessagingResult _success(Map<String, dynamic> apiResponse, String recipient) {
    // Per Meta's docs, a successful send returns
    // {"recipient_id": "IGSID", "message_id": "MESSAGE-ID"} — a flat
    // shape, unlike WhatsApp's nested `messages: [{id: ...}]` array.
    final messageId = apiResponse['message_id'] as String?;
    return MessagingResult.success(
      messageId: messageId ?? '',
      recipient: recipient,
      platform: platformType,
      metadata: apiResponse,
    );
  }
}
