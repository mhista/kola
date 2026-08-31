// messenger_credential.dart
//
// The Messenger-specific credential shape stored inside
// Channel.encryptedCredential — same JSON-blob-inside-one-encrypted-column
// pattern as instagram_credential.dart/whatsapp_credential.dart, for the
// same reason: a Facebook Page needs several pieces together to place an
// API call and verify inbound webhooks, and this avoids a schema
// migration for every platform whose credential shape differs
// (channel.spy.yaml already anticipated this).
//
// WHAT THIS CARRIES, AND WHY EACH FIELD IS HERE:
//   pageId          — the Facebook Page's own ID. Every send call targets
//                      /<PAGE_ID>/messages, so this is the one piece that
//                      identifies WHICH Page this credential belongs to.
//   pageAccessToken — a Page access token (NOT a user or app token) —
//                      per Meta's Messenger Platform docs, the token must
//                      belong to the Page itself and carry the
//                      pages_messaging permission. This is what
//                      authorizes every outbound call AND the
//                      subscribed_apps opt-in call.
//   appSecret       — signs every inbound webhook POST via
//                      X-Hub-Signature-256, identical scheme to
//                      WhatsApp's/Instagram's (see
//                      whatsapp_signature_verifier.dart, reused directly
//                      by messenger_bot_registry.dart rather than
//                      duplicated).
//
// WHAT'S DELIBERATELY NOT HERE, SAME AS InstagramCredential: no wabaId
// (WhatsApp-only concept), no appId (WhatsAppService.debugToken's
// temporary-vs-permanent token check has no equivalent built for
// Messenger in this pass, same named scope cut as Instagram's — see
// messenger_service.dart's header).

import 'dart:convert';

class MessengerCredential {
  const MessengerCredential({
    required this.pageId,
    required this.pageAccessToken,
    required this.appSecret,
  });

  final String pageId;
  final String pageAccessToken;
  final String appSecret;

  String encode() => jsonEncode({
    'page_id': pageId,
    'page_access_token': pageAccessToken,
    'app_secret': appSecret,
  });

  factory MessengerCredential.decode(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return MessengerCredential(
      pageId: map['page_id'] as String,
      pageAccessToken: map['page_access_token'] as String,
      // Same graceful-degrade as Whatsapp/InstagramCredential.decode: a
      // channel connected before appSecret was collected keeps sending,
      // it just fails webhook signature verification until reconnected.
      appSecret: map['app_secret'] as String? ?? '',
    );
  }
}
