// whatsapp_service.dart
//
// Low-level wrapper around Meta's WhatsApp Cloud API — plain HTTPS calls
// via package:http, no SDK (Meta doesn't ship an official Dart SDK).
// One instance per connected WhatsApp channel, same role as
// TelegramService: everything else talks to WhatsApp THROUGH this,
// never builds a graph.facebook.com URL directly.
//
// AUTH MODEL — WHY THIS SERVICE DOESN'T CARE WHOSE APP ISSUED THE TOKEN:
//   Unlike Telegram (where the bot token IS the whole identity), a
//   WhatsApp Cloud API bearer token's validity is checked against the
//   token's own grants — not against which server happens to be making
//   the HTTP call. A business can generate this token themselves, from
//   their own small Meta App, with Standard Access over their own asset
//   (see channel_endpoint.dart's connectWhatsAppChannelManual for the
//   full reasoning on why that needs zero App Review on Kola's side).
//   This service just needs a valid token + phone_number_id; it has no
//   opinion on how they were obtained, same as this file would work
//   unchanged once real Embedded-Signup-issued tokens exist too.
//
// API VERSION: pinned to v22.0 — bump centrally here if Meta deprecates it.
//
// FEATURE CONFIDENCE NOTE: sendText/sendMedia/sendButtons/sendList/
// sendLocation/replyToMessage/markAsRead all use Meta's long-standing,
// well-documented message-send payload shapes. The `typing_indicator`
// field in markAsRead is a newer addition — not yet runtime-verified
// against a live app here. If your API version rejects it, that call
// still marks the message read; only the extra typing-indicator effect
// would silently not apply (see that method's try/catch).

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../messaging_result.dart';

final _log = Logger('WhatsAppService');

/// Result of WhatsAppService.debugToken() — see that method's doc
/// comment for why appId/appSecret (not just the access token itself)
/// are needed to produce this.
class WhatsAppTokenInfo {
  const WhatsAppTokenInfo({required this.isPermanent, this.expiresAt});
  final bool isPermanent;
  final DateTime? expiresAt;
}

class WhatsAppService {
  WhatsAppService({required this.accessToken, required this.phoneNumberId});

  final String accessToken;
  final String phoneNumberId;

  static const _apiVersion = 'v22.0';

  Uri _messagesUri() => Uri.parse(
    'https://graph.facebook.com/$_apiVersion/$phoneNumberId/messages',
  );

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  /// Confirms the token + phone_number_id combination is real and
  /// belongs together, by fetching the phone number's own metadata.
  /// Used by ChannelEndpoint.connectWhatsAppChannelManual to validate
  /// before persisting anything — same role as
  /// TelegramService.start()'s getMe() call.
  Future<Map<String, dynamic>> probe() async {
    final uri = Uri.parse(
      'https://graph.facebook.com/$_apiVersion/$phoneNumberId'
      '?fields=display_phone_number,verified_name',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'WhatsApp probe failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Introspects [accessToken] via Meta's debug_token endpoint to tell
  /// apart a short-lived "temporary" token (the default shown on the
  /// API Setup page, valid roughly 24 hours) from a permanent System
  /// User token (Standard Access, no expiry — the kind
  /// docs/WHATSAPP_MANUAL_SETUP.md Step 5 walks a business through
  /// generating). Requires [appId]/[appSecret] because debug_token
  /// authenticates the CALLER via "app_id|app_secret" as its own
  /// access_token query param — a deliberately different check from the
  /// one every send call above passes just by having a valid bearer
  /// token (see this file's header AUTH MODEL note). Used by
  /// ChannelEndpoint.connectWhatsAppChannelManual to warn a business
  /// up front if they've connected a token that's about to silently
  /// expire, rather than letting them find out when messages stop
  /// sending.
  Future<WhatsAppTokenInfo> debugToken({
    required String appId,
    required String appSecret,
  }) async {
    final uri = Uri.parse('https://graph.facebook.com/$_apiVersion/debug_token')
        .replace(
          queryParameters: {
            'input_token': accessToken,
            'access_token': '$appId|$appSecret',
          },
        );
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'WhatsApp debug_token failed (${response.statusCode}): ${response.body}',
      );
    }
    final data =
        (jsonDecode(response.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    final expiresAtEpoch = data['expires_at'] as int? ?? 0;
    return WhatsAppTokenInfo(
      isPermanent: expiresAtEpoch == 0,
      expiresAt: expiresAtEpoch == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              expiresAtEpoch * 1000,
              isUtc: true,
            ),
    );
  }

  // ==================== BASIC MESSAGING ====================

  Future<Map<String, dynamic>> sendText({
    required String to,
    required String body,
    bool previewUrl = false,
  }) => _post({
    'messaging_product': 'whatsapp',
    'recipient_type': 'individual',
    'to': to,
    'type': 'text',
    'text': {'preview_url': previewUrl, 'body': body},
  });

  /// [type] is one of 'image' | 'video' | 'audio' | 'document' | 'sticker'
  /// — matches MediaType.name from messaging_result.dart so the adapter
  /// can pass it straight through.
  Future<Map<String, dynamic>> sendMedia({
    required String to,
    required String mediaUrl,
    required String type,
    String? caption,
  }) => _post({
    'messaging_product': 'whatsapp',
    'recipient_type': 'individual',
    'to': to,
    'type': type,
    type: {'link': mediaUrl, if (caption != null) 'caption': caption},
  });

  /// WhatsApp caps interactive reply buttons at 3 — the adapter is
  /// responsible for truncating/rejecting beyond that, this method just
  /// sends whatever list it's given.
  Future<Map<String, dynamic>> sendButtons({
    required String to,
    required String bodyText,
    required List<MessageButton> buttons,
    String? headerText,
    String? footerText,
  }) => _post({
    'messaging_product': 'whatsapp',
    'recipient_type': 'individual',
    'to': to,
    'type': 'interactive',
    'interactive': {
      'type': 'button',
      if (headerText != null) 'header': {'type': 'text', 'text': headerText},
      'body': {'text': bodyText},
      if (footerText != null) 'footer': {'text': footerText},
      'action': {
        'buttons': [
          for (final b in buttons)
            {
              'type': 'reply',
              'reply': {'id': b.callbackData ?? b.id, 'title': b.text},
            },
        ],
      },
    },
  });

  Future<Map<String, dynamic>> sendList({
    required String to,
    required String bodyText,
    required String buttonText,
    required List<ListSection> sections,
    String? headerText,
    String? footerText,
  }) => _post({
    'messaging_product': 'whatsapp',
    'recipient_type': 'individual',
    'to': to,
    'type': 'interactive',
    'interactive': {
      'type': 'list',
      if (headerText != null) 'header': {'type': 'text', 'text': headerText},
      'body': {'text': bodyText},
      if (footerText != null) 'footer': {'text': footerText},
      'action': {
        'button': buttonText,
        'sections': [
          for (final s in sections)
            {
              'title': s.title,
              'rows': [
                for (final r in s.rows)
                  {
                    'id': r.id,
                    'title': r.title,
                    if (r.description != null) 'description': r.description,
                  },
              ],
            },
        ],
      },
    },
  });

  /// Sends a previously Meta-APPROVED message template — the only kind
  /// of proactive, business-initiated WhatsApp send Meta allows outside
  /// an open 24h customer-service window (see
  /// whatsapp_template_service.dart's header for the create/review side
  /// of this). [templateName] must be the exact name Meta approved
  /// (WhatsAppMessageTemplate.metaTemplateName), [language] the exact
  /// language code the template was submitted under. [bodyParams]
  /// supplies one value per `{{n}}` placeholder in the template's body,
  /// in order — caller's responsibility to pass the right count; Meta
  /// rejects a mismatch. Task #155 — CustomerCampaignSweepService's
  /// birthday/anniversary greetings are the first real caller.
  Future<Map<String, dynamic>> sendTemplate({
    required String to,
    required String templateName,
    required String language,
    List<String> bodyParams = const [],
  }) => _post({
    'messaging_product': 'whatsapp',
    'recipient_type': 'individual',
    'to': to,
    'type': 'template',
    'template': {
      'name': templateName,
      'language': {'code': language},
      if (bodyParams.isNotEmpty)
        'components': [
          {
            'type': 'body',
            'parameters': [for (final p in bodyParams) {'type': 'text', 'text': p}],
          },
        ],
    },
  });

  Future<Map<String, dynamic>> sendLocation({
    required String to,
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) => _post({
    'messaging_product': 'whatsapp',
    'recipient_type': 'individual',
    'to': to,
    'type': 'location',
    'location': {
      'latitude': latitude,
      'longitude': longitude,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
    },
  });

  /// Quotes an earlier message via `context.message_id` — WhatsApp's
  /// equivalent of Telegram's replyToMessageId.
  Future<Map<String, dynamic>> replyToMessage({
    required String to,
    required String messageId,
    required String body,
  }) => _post({
    'messaging_product': 'whatsapp',
    'recipient_type': 'individual',
    'to': to,
    'context': {'message_id': messageId},
    'type': 'text',
    'text': {'body': body},
  });

  /// Marks an inbound message read. [typing] additionally requests the
  /// "typing…" indicator for up to ~25 seconds — see this file's header
  /// note on why that specific field isn't runtime-verified yet.
  Future<bool> markAsRead({required String messageId, bool typing = false}) async {
    try {
      await _post({
        'messaging_product': 'whatsapp',
        'status': 'read',
        'message_id': messageId,
        if (typing) 'typing_indicator': {'type': 'text'},
      });
      return true;
    } catch (e) {
      _log.warning('markAsRead failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final response = await http.post(
      _messagesUri(),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'WhatsApp API call failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
