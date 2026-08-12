// telegram_service_adapter.dart
//
// Adapter that makes TelegramService satisfy IMessagingService.
//
// PLAIN ENGLISH:
//   This is the translation layer. Bot logic (Bot Mother, the Errand
//   engine, proactive notifications) calls `messagingService.sendText(...)`
//   without knowing or caring it's Telegram underneath. This file is the
//   ONLY place that knows both "the generic interface" and "the
//   Telegram-specific service" at once. When the Phase 2b WhatsApp
//   adapter is added, a WhatsAppServiceAdapter implementing the same
//   IMessagingService goes right next to this one — nothing else in the
//   bot changes.
//
// Ported near-verbatim from degenbot_server's telegram_service_adapter.dart
// — this file has no Degenbot-specific logic in it to begin with, it's
// already fully generic (SRS.md §9).

import 'package:televerse/telegram.dart' show Message, InlineKeyboardButton, ParseMode, ChatAction, InputPollOption;
import '../messaging_result.dart';
import '../messaging_service_interface.dart';
import 'telegram_service.dart';

class TelegramServiceAdapter implements IMessagingService {
  TelegramServiceAdapter(this._telegramService);

  final TelegramService _telegramService;

  @override
  PlatformType get platformType => PlatformType.telegram;

  // ==================== BASIC MESSAGING ====================

  @override
  Future<MessagingResult> sendText({
    required String recipient,
    required String text,
    bool? previewUrl,
    String? parseMode,
  }) async {
    try {
      final message = await _telegramService.sendTextMessage(
        chatId: int.parse(recipient),
        text: text,
        parseMode: _convertParseMode(parseMode) ?? ParseMode.markdown,
        disableWebPagePreview: previewUrl == false,
      );

      return MessagingResult.success(
        messageId: message.messageId.toString(),
        recipient: recipient,
        platform: platformType,
        metadata: {'chat_id': message.chat.id.toString()},
      );
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
      Message message;
      switch (mediaType) {
        case MediaType.image:
          message = await _telegramService.sendPhoto(
            chatId: int.parse(recipient),
            photoUrl: mediaUrl,
            caption: caption,
          );
        case MediaType.video:
          message = await _telegramService.sendVideo(
            chatId: int.parse(recipient),
            videoUrl: mediaUrl,
            caption: caption,
          );
        case MediaType.audio:
          message = await _telegramService.sendAudio(
            chatId: int.parse(recipient),
            audioUrl: mediaUrl,
            caption: caption,
          );
        case MediaType.document:
          message = await _telegramService.sendDocument(
            chatId: int.parse(recipient),
            documentUrl: mediaUrl,
            caption: caption,
          );
        case MediaType.sticker:
          message = await _telegramService.sendSticker(
            chatId: int.parse(recipient),
            stickerUrl: mediaUrl,
          );
      }

      return MessagingResult.success(
        messageId: message.messageId.toString(),
        recipient: recipient,
        platform: platformType,
      );
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  // ==================== INTERACTIVE MESSAGES ====================

  @override
  Future<MessagingResult> sendButtons({
    required String recipient,
    required String bodyText,
    required List<MessageButton> buttons,
    String? headerText,
    String? footerText,
    Map<String, dynamic>? headerInteractive,
  }) async {
    try {
      final fullText = _combineText(headerText, bodyText, footerText);
      final keyboard = <List<InlineKeyboardButton>>[];

      for (final btn in buttons) {
        if (btn.url != null) {
          keyboard.add([InlineKeyboardButton(text: btn.text, url: btn.url!)]);
        } else {
          keyboard.add([
            InlineKeyboardButton(text: btn.text, callbackData: btn.callbackData ?? btn.id),
          ]);
        }
      }

      final message = await _telegramService.sendInlineKeyboard(
        chatId: int.parse(recipient),
        text: fullText,
        keyboard: keyboard,
        parseMode: ParseMode.markdown,
      );

      return MessagingResult.success(
        messageId: message.messageId.toString(),
        recipient: recipient,
        platform: platformType,
      );
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
      // Telegram has no native list widget — render as a labeled inline keyboard.
      final fullText = _combineText(headerText, bodyText, footerText);
      final keyboard = <List<InlineKeyboardButton>>[];

      for (final section in sections) {
        keyboard.add([
          InlineKeyboardButton(text: '📂 ${section.title}', callbackData: 'section_${section.title}'),
        ]);
        for (final row in section.rows) {
          keyboard.add([InlineKeyboardButton(text: row.title, callbackData: row.id)]);
        }
      }

      final message = await _telegramService.sendInlineKeyboard(
        chatId: int.parse(recipient),
        text: fullText,
        keyboard: keyboard,
        parseMode: ParseMode.markdown,
      );

      return MessagingResult.success(
        messageId: message.messageId.toString(),
        recipient: recipient,
        platform: platformType,
      );
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  // ==================== LOCATION ====================

  @override
  Future<MessagingResult> sendLocation({
    required String recipient,
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) async {
    try {
      final message = await _telegramService.sendLocation(
        chatId: int.parse(recipient),
        latitude: latitude,
        longitude: longitude,
      );

      if (name != null || address != null) {
        final locationText = [if (name != null) '📍 *$name*', if (address != null) address].join('\n');
        await _telegramService.sendTextMessage(
          chatId: int.parse(recipient),
          text: locationText,
          parseMode: ParseMode.markdown,
        );
      }

      return MessagingResult.success(
        messageId: message.messageId.toString(),
        recipient: recipient,
        platform: platformType,
      );
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  // ==================== MESSAGE ACTIONS ====================

  @override
  Future<bool> markAsRead({required String messageId}) async => true; // no-op: Telegram bots have no read receipts

  @override
  Future<MessagingResult> replyToMessage({
    required String recipient,
    required String messageId,
    required String text,
    bool? previewUrl,
  }) async {
    try {
      final message = await _telegramService.sendTextMessage(
        chatId: int.parse(recipient),
        text: text,
        replyToMessageId: int.tryParse(messageId),
        disableWebPagePreview: previewUrl == false,
      );

      return MessagingResult.success(
        messageId: message.messageId.toString(),
        recipient: recipient,
        platform: platformType,
      );
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  @override
  Future<bool> sendTypingIndicator({
    required String recipient,
    TypingIndicatorType? type,
  }) async {
    try {
      return await _telegramService.sendChatAction(
        chatId: int.parse(recipient),
        action: _convertTypingType(type),
      );
    } catch (_) {
      return false;
    }
  }

  // ==================== TELEGRAM-SPECIFIC EXTRAS ====================
  // Not part of IMessagingService — available when callers know they're
  // specifically on Telegram (polls have no cross-platform equivalent).

  Future<MessagingResult> sendPoll({
    required String recipient,
    required String question,
    required List<String> options,
    bool? isAnonymous,
    bool? allowsMultipleAnswers,
  }) async {
    try {
      final inputOptions = options.map((opt) => InputPollOption(text: opt)).toList();
      final message = await _telegramService.sendPoll(
        chatId: int.parse(recipient),
        question: question,
        options: inputOptions,
        isAnonymous: isAnonymous,
        allowsMultipleAnswers: allowsMultipleAnswers,
      );
      return MessagingResult.success(
        messageId: message.messageId.toString(),
        recipient: recipient,
        platform: platformType,
      );
    } catch (e) {
      return MessagingResult.error(message: e.toString(), platform: platformType);
    }
  }

  // ==================== LIFECYCLE ====================

  @override
  void dispose() => _telegramService.dispose();

  // ==================== HELPERS ====================

  ParseMode? _convertParseMode(String? mode) {
    if (mode == null) return null;
    switch (mode.toLowerCase()) {
      case 'markdown':
        return ParseMode.markdown;
      case 'html':
        return ParseMode.html;
      default:
        return null;
    }
  }

  ChatAction _convertTypingType(TypingIndicatorType? type) {
    switch (type) {
      case TypingIndicatorType.recording:
        return ChatAction.recordVoice;
      case TypingIndicatorType.uploadingPhoto:
        return ChatAction.uploadPhoto;
      case TypingIndicatorType.uploadingVideo:
        return ChatAction.uploadVideo;
      case TypingIndicatorType.uploadingDocument:
        return ChatAction.uploadDocument;
      case TypingIndicatorType.typing:
      case null:
        return ChatAction.typing;
    }
  }

  String _combineText(String? header, String body, String? footer) {
    final parts = <String>[];
    if (header != null && header.isNotEmpty) parts.add('*$header*\n');
    parts.add(body);
    if (footer != null && footer.isNotEmpty) parts.add('\n\n_${footer}_');
    return parts.join();
  }
}
