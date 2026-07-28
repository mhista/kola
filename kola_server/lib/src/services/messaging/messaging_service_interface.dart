// messaging_service_interface.dart
//
// The contract EVERY messaging platform adapter must implement.
//
// PLAIN ENGLISH:
//   This is the "shape" both Telegram and WhatsApp must fit into. Bot
//   Mother, the Errand engine, and any future proactive-notification code
//   call methods on THIS interface — never on Televerse or a WhatsApp SDK
//   directly. That indirection is what lets Kola add a platform (Phase
//   2b's WhatsApp adapter, then Instagram/SMS in Phase 3) without a
//   single bot-logic file needing to change.
//
// Ported near-verbatim from degenbot_server's messaging_service_interface.dart
// — SRS.md §9 explicitly calls for reusing this exact interface shape
// rather than re-deriving it, since it's already battle-tested for
// feature-parity gaps between platforms.

import 'messaging_result.dart';

abstract class IMessagingService {
  PlatformType get platformType;

  Future<MessagingResult> sendText({
    required String recipient,
    required String text,
    bool? previewUrl,
    String? parseMode,
  });

  Future<MessagingResult> sendMedia({
    required String recipient,
    required String mediaUrl,
    required MediaType mediaType,
    String? caption,
  });

  Future<MessagingResult> sendButtons({
    required String recipient,
    required String bodyText,
    required List<MessageButton> buttons,
    String? headerText,
    String? footerText,
    Map<String, dynamic>? headerInteractive,
  });

  Future<MessagingResult> sendList({
    required String recipient,
    required String bodyText,
    required String buttonText,
    required List<ListSection> sections,
    String? headerText,
    String? footerText,
  });

  Future<MessagingResult> sendLocation({
    required String recipient,
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  });

  Future<bool> markAsRead({required String messageId});

  Future<MessagingResult> replyToMessage({
    required String recipient,
    required String messageId,
    required String text,
    bool? previewUrl,
  });

  Future<bool> sendTypingIndicator({
    required String recipient,
    TypingIndicatorType? type,
  });

  void dispose();
}
