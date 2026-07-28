// whatsapp_service_adapter.dart
//
// Adapter that makes WhatsAppService satisfy IMessagingService — same
// role as telegram_service_adapter.dart. Bot logic (Bot Mother, the
// Errand engine, proactive notifications) calls
// `messagingService.sendText(...)` without knowing or caring it's
// WhatsApp underneath.

import 'package:kola_server/kola_logger.dart';
import '../messaging_result.dart';
import '../messaging_service_interface.dart';
import 'whatsapp_service.dart';

class WhatsAppServiceAdapter implements IMessagingService {
  WhatsAppServiceAdapter(this._whatsAppService);

  final WhatsAppService _whatsAppService;

  @override
  PlatformType get platformType => PlatformType.whatsapp;

  @override
  Future<MessagingResult> sendText({
    required String recipient,
    required String text,
    bool? previewUrl,
    String? parseMode,
  }) async {
    // parseMode is ignored — WhatsApp's plain text messages have no
    // Markdown/HTML mode concept (Telegram-specific), it just sends body.
    try {
      final result = await _whatsAppService.sendText(
        to: recipient,
        body: text,
        previewUrl: previewUrl ?? false,
      );
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
    try {
      final result = await _whatsAppService.sendMedia(
        to: recipient,
        mediaUrl: mediaUrl,
        type: mediaType.name,
        caption: caption,
      );
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
  }) async {
    // WhatsApp caps interactive reply buttons at 3 — truncate rather than
    // let the API reject the whole message outright over a caller
    // passing e.g. 5 buttons built for a Telegram inline keyboard.
    final capped = buttons.length > 3 ? buttons.sublist(0, 3) : buttons;
    if (capped.length < buttons.length) {
      Log.warning(
        'WhatsApp sendButtons: truncated ${buttons.length} buttons to 3 (platform limit)',
      );
    }
    try {
      final result = await _whatsAppService.sendButtons(
        to: recipient,
        bodyText: bodyText,
        buttons: capped,
        headerText: headerText,
        footerText: footerText,
      );
      return _success(result, recipient);
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  @override
  Future<MessagingResult> sendList({
    required String recipient,
    required String bodyText,
    required String buttonText,
    required List<ListSection> sections,
    String? headerText,
    String? footerText,
  }) async {
    try {
      final result = await _whatsAppService.sendList(
        to: recipient,
        bodyText: bodyText,
        buttonText: buttonText,
        sections: sections,
        headerText: headerText,
        footerText: footerText,
      );
      return _success(result, recipient);
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  @override
  Future<MessagingResult> sendLocation({
    required String recipient,
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) async {
    try {
      final result = await _whatsAppService.sendLocation(
        to: recipient,
        latitude: latitude,
        longitude: longitude,
        name: name,
        address: address,
      );
      return _success(result, recipient);
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  @override
  Future<bool> markAsRead({required String messageId}) =>
      _whatsAppService.markAsRead(messageId: messageId);

  @override
  Future<MessagingResult> replyToMessage({
    required String recipient,
    required String messageId,
    required String text,
    bool? previewUrl,
  }) async {
    try {
      final result = await _whatsAppService.replyToMessage(
        to: recipient,
        messageId: messageId,
        body: text,
      );
      return _success(result, recipient);
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  @override
  Future<bool> sendTypingIndicator({
    required String recipient,
    TypingIndicatorType? type,
  }) async {
    // WhatsApp has no standalone typing-indicator call — it rides along
    // with markAsRead's optional typing_indicator field, which needs a
    // real inbound message_id to attach to. Nothing to mark as read here
    // (this method only gets a recipient, not a message id), so this is
    // a no-op returning false — same honest "not supported this way"
    // pattern as Telegram's markAsRead no-op for read receipts.
    return false;
  }

  @override
  void dispose() {
    // No persistent connection/socket to close — WhatsAppService is a
    // stateless HTTP wrapper, unlike Televerse's Bot which owns a
    // long-polling/webhook lifecycle. Present for interface parity.
  }

  MessagingResult _success(Map<String, dynamic> apiResponse, String recipient) {
    final messages = apiResponse['messages'] as List<dynamic>?;
    final messageId = (messages != null && messages.isNotEmpty)
        ? messages.first['id'] as String?
        : null;
    return MessagingResult.success(
      messageId: messageId ?? '',
      recipient: recipient,
      platform: platformType,
      metadata: apiResponse,
    );
  }
}
