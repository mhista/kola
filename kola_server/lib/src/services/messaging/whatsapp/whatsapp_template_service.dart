// whatsapp_template_service.dart
//
// Low-level wrapper around Meta's WhatsApp message-template Graph API —
// plain HTTPS calls via package:http, same style as whatsapp_service.dart
// (no SDK; Meta doesn't ship an official Dart one). This is the piece
// that lets Kola create/check message templates PROGRAMMATICALLY rather
// than asking a business to go create them by hand inside Meta Business
// Manager — task #150.
//
// SCOPE: this only covers templates — the pre-approved message shapes
// Meta requires for a business-INITIATED send outside an open 24-hour
// customer service window. A bot replying to a customer who just
// messaged never needs any of this (see whatsapp_service.dart's
// sendText/sendList — those work unrestricted inside an open window,
// and are free today). Conflating the two would wrongly suggest every
// WhatsApp send needs a template; it doesn't.
//
// AUTH: same token/appId model as WhatsAppService — see that file's
// header AUTH MODEL note. Template endpoints live under the WABA ID
// (WhatsAppCredential.wabaId), not the phone_number_id.
//
// API VERSION: pinned to v22.0, matching WhatsAppService — bump both
// together if Meta deprecates it.

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Meta's response to a template creation call — [id]/[status] are
/// exactly what Meta returns; [status] starts 'PENDING' for essentially
/// every real submission (Meta reviews asynchronously, from minutes to
/// a few days).
class WhatsAppTemplateSubmission {
  const WhatsAppTemplateSubmission({
    required this.metaTemplateId,
    required this.status,
    this.category,
  });

  final String metaTemplateId;
  final String status;
  final String? category;
}

/// One template as Meta currently sees it — used by
/// [WhatsAppTemplateService.fetchTemplateStatus] to refresh a locally
/// stored WhatsAppMessageTemplate row after Meta finishes reviewing it.
class WhatsAppTemplateStatus {
  const WhatsAppTemplateStatus({
    required this.status,
    this.category,
    this.rejectedReason,
  });

  final String status;
  final String? category;
  final String? rejectedReason;
}

class WhatsAppTemplateService {
  WhatsAppTemplateService({required this.accessToken, required this.wabaId});

  final String accessToken;
  final String wabaId;

  static const _apiVersion = 'v22.0';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  /// Submits a new template for Meta's review. [name] must already be
  /// Meta-legal (lowercase letters, digits, underscores only) — callers
  /// (WhatsAppTemplateEndpoint) are responsible for sanitizing a
  /// business-provided label before it reaches here, this method
  /// doesn't re-check it. [bodyText] may contain {{1}}, {{2}}...
  /// placeholders; [bodyExampleValues] supplies one example value per
  /// placeholder, in order — Meta's review REQUIRES a concrete example
  /// for every variable or the submission is rejected outright.
  Future<WhatsAppTemplateSubmission> createTemplate({
    required String name,
    required String category,
    required String language,
    required String bodyText,
    List<String> bodyExampleValues = const [],
  }) async {
    final uri = Uri.parse(
      'https://graph.facebook.com/$_apiVersion/$wabaId/message_templates',
    );

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'language': language,
        'category': category.toUpperCase(),
        'components': [
          {
            'type': 'BODY',
            'text': bodyText,
            if (bodyExampleValues.isNotEmpty)
              'example': {'body_text': [bodyExampleValues]},
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'WhatsApp template creation failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WhatsAppTemplateSubmission(
      metaTemplateId: data['id'] as String,
      status: (data['status'] as String?) ?? 'PENDING',
      category: data['category'] as String?,
    );
  }

  /// Looks up the CURRENT review status of a previously-submitted
  /// template by its Meta template ID — Meta's review is async, so a
  /// row created 'pending' needs this to ever learn it was approved or
  /// rejected. No webhook wiring exists for this yet (see
  /// whatsapp_message_template.spy.yaml's header) — this is the polling
  /// fallback, called on demand from
  /// WhatsAppTemplateEndpoint.refreshTemplateStatus.
  Future<WhatsAppTemplateStatus> fetchTemplateStatus(String metaTemplateId) async {
    final uri = Uri.parse(
      'https://graph.facebook.com/$_apiVersion/$metaTemplateId'
      '?fields=status,category,rejected_reason',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'WhatsApp template status lookup failed (${response.statusCode}): ${response.body}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WhatsAppTemplateStatus(
      status: (data['status'] as String?) ?? 'PENDING',
      category: data['category'] as String?,
      rejectedReason: data['rejected_reason'] as String?,
    );
  }
}
