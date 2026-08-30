// instagram_credential.dart
//
// The Instagram-specific credential shape stored inside
// Channel.encryptedCredential — same JSON-blob-inside-one-encrypted-column
// pattern as whatsapp_credential.dart, for the same reason: an Instagram
// professional account needs several pieces together to place an API call
// and verify inbound webhooks, and this avoids a schema migration for
// every platform whose credential shape differs (channel.spy.yaml already
// anticipated this).
//
// WHAT THIS CARRIES, AND WHY EACH FIELD IS HERE:
//   igUserId    — the Instagram professional account's own ID (<IG_ID> in
//                 Meta's docs). Every send call and the webhook-subscribe
//                 call both target /<IG_ID>/..., so this is the one piece
//                 that identifies WHICH account this credential belongs to.
//   accessToken — an Instagram User access token, requested from someone
//                 who can send messages from the account (per Meta's
//                 "Send Messages" guide, Access tokens section). This is
//                 what authorizes every outbound call.
//   appSecret   — signs every inbound webhook POST via X-Hub-Signature-256,
//                 identical scheme to WhatsApp's (see
//                 whatsapp_signature_verifier.dart, reused directly by
//                 instagram_bot_registry.dart rather than duplicated).
//                 Without it, this channel could send messages fine but
//                 couldn't safely trust anything arriving at its webhook
//                 route as really being from Meta.
//
// WHAT'S DELIBERATELY NOT HERE, UNLIKE WhatsAppCredential:
//   No wabaId (WhatsApp Business Account) — Instagram has no equivalent
//   concept; the professional account IS the top-level thing. No appId —
//   WhatsAppCredential keeps it only so WhatsAppService.debugToken can
//   distinguish a temporary token from a permanent one; that check isn't
//   built for Instagram in this pass (see instagram_service.dart's header
//   — a named, deliberate scope cut, not an oversight).

import 'dart:convert';

class InstagramCredential {
  const InstagramCredential({
    required this.igUserId,
    required this.accessToken,
    required this.appSecret,
  });

  final String igUserId;
  final String accessToken;
  final String appSecret;

  String encode() => jsonEncode({
    'ig_user_id': igUserId,
    'access_token': accessToken,
    'app_secret': appSecret,
  });

  factory InstagramCredential.decode(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return InstagramCredential(
      igUserId: map['ig_user_id'] as String,
      accessToken: map['access_token'] as String,
      // Same graceful-degrade as WhatsAppCredential.decode: a channel
      // connected before appSecret was collected keeps sending, it just
      // fails webhook signature verification until reconnected.
      appSecret: map['app_secret'] as String? ?? '',
    );
  }
}
