// webhook_errand_credential.dart
//
// The webhook-Errand-specific credential shape stored inside
// ErrandCredential.encryptedCredential (JSON-encoded, then AES-256-GCM
// encrypted via ChannelCredentialEncryptionService — same encryption
// service Channel/Telegram/WhatsApp credentials already use, per
// errand_credential.spy.yaml's header: "same pattern, different secret
// class"). Mirrors whatsapp_credential.dart's encode/decode shape
// exactly, one level down (a webhook Errand needs far less than
// WhatsApp's five fields — just where to POST, and how to prove the
// request came from Kola).

import 'dart:convert';

class WebhookErrandCredential {
  const WebhookErrandCredential({
    required this.url,
    this.authHeaderName,
    this.authHeaderValue,
  });

  final String url;

  // Optional single auth header (e.g. 'Authorization': 'Bearer ...', or a
  // custom 'X-Kola-Signature' style shared secret) sent with every
  // outbound call — the business's own endpoint decides what it wants to
  // require, we just carry whatever they told us to send. Deliberately
  // ONE header, not an arbitrary map: covers the overwhelming majority
  // of real webhook auth schemes (bearer token, API key header, basic
  // auth pre-encoded into one value) without the far larger surface of
  // letting a business register arbitrary header injection.
  final String? authHeaderName;
  final String? authHeaderValue;

  String encode() => jsonEncode({
    'url': url,
    'auth_header_name': authHeaderName,
    'auth_header_value': authHeaderValue,
  });

  factory WebhookErrandCredential.decode(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return WebhookErrandCredential(
      url: map['url'] as String,
      authHeaderName: map['auth_header_name'] as String?,
      authHeaderValue: map['auth_header_value'] as String?,
    );
  }
}
