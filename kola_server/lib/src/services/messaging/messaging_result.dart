// messaging_result.dart
//
// Unified result type returned by every messaging platform adapter.
//
// PLAIN ENGLISH:
//   Whether a message goes out through Telegram or (Phase 2b) WhatsApp,
//   the calling code shouldn't have to know which platform it was. This
//   wraps the outcome — success or failure — in one consistent shape so
//   Bot Mother, the Errand engine, and every other piece of bot logic
//   never touch Telegram- or WhatsApp-specific types directly. That's
//   what makes adding WhatsApp (and later Instagram DM/SMS, per SRS.md
//   §9) an additive change instead of a rewrite.
//
// Ported near-verbatim from degenbot_server's messaging_result.dart —
// SRS.md §9 explicitly calls for reusing this exact interface shape
// rather than re-deriving it.

enum PlatformType { telegram, whatsapp, instagram, messenger }

enum MediaType { image, video, audio, document, sticker }

enum MessageType { text, image, video, audio, document, location, sticker }

enum TypingIndicatorType { typing, recording, uploadingPhoto, uploadingVideo, uploadingDocument }

class MessagingResult {
  const MessagingResult({
    required this.success,
    required this.platform,
    this.messageId,
    this.recipient,
    this.errorMessage,
    this.metadata,
  });

  final bool success;
  final PlatformType platform;
  final String? messageId;
  final String? recipient;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  factory MessagingResult.success({
    required String messageId,
    required String recipient,
    required PlatformType platform,
    Map<String, dynamic>? metadata,
  }) {
    return MessagingResult(
      success: true,
      platform: platform,
      messageId: messageId,
      recipient: recipient,
      metadata: metadata,
    );
  }

  factory MessagingResult.error({
    required String message,
    required PlatformType platform,
  }) {
    return MessagingResult(
      success: false,
      platform: platform,
      errorMessage: message,
    );
  }
}

/// A button shown in an interactive message (inline keyboard equivalent).
class MessageButton {
  const MessageButton({
    required this.id,
    required this.text,
    this.callbackData,
    this.url,
  });

  final String id;
  final String text;
  final String? callbackData;
  final String? url;
}

/// A row inside a list section (for sendList).
class ListRow {
  const ListRow({required this.id, required this.title, this.description});
  final String id;
  final String title;
  final String? description;
}

/// A section grouping multiple list rows.
class ListSection {
  const ListSection({required this.title, required this.rows});
  final String title;
  final List<ListRow> rows;
}
