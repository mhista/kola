// whatsapp_credential.dart
//
// The WhatsApp-specific credential shape stored inside
// Channel.encryptedCredential (JSON-encoded, then AES-256-GCM encrypted
// via ChannelCredentialEncryptionService — same column, same encryption
// service Telegram already uses).
//
// WHY A JSON BLOB, NOT A BARE STRING LIKE TELEGRAM'S TOKEN:
//   Telegram only ever needs one secret — the bot token. WhatsApp needs
//   several pieces of information together to actually place an API
//   call and verify inbound webhooks. Rather than add five new encrypted
//   columns to the Channel model (a schema migration for every platform
//   whose credential shape differs), this wraps all of them as one JSON
//   object inside the single opaque encryptedCredential string column —
//   channel.spy.yaml's original design already anticipated exactly this
//   ("Encrypted channel credential... Wired up in Phase 2").
//
// WHY appId/appSecret WERE ADDED (not in the original Phase 2b build):
//   accessToken + phoneNumberId + wabaId are everything needed to SEND a
//   message — that's all the original credential carried. But
//   RECEIVING messages safely needs one more thing: appSecret is the key
//   Meta uses to sign every inbound webhook POST with an
//   X-Hub-Signature-256 header (see whatsapp_signature_verifier.dart).
//   Without checking that signature, the shared /webhooks/whatsapp route
//   (see whatsapp_bot_registry.dart's header on why it's shared, not
//   per-channel) would accept a POST from literally anyone who found the
//   URL, not just real Meta traffic — since the URL itself is not a
//   secret. appId isn't used by the signature check itself, but is kept
//   alongside appSecret since Meta's own dashboard always surfaces them
//   together (App Settings → Basic) and appId is what a future
//   debug_token call (see WhatsAppService.debugToken) needs to check
//   whether a connected token is the short-lived "temporary" kind or a
//   real permanent one — worth storing now rather than asking the
//   business to dig it up a second time later.

import 'dart:convert';

class WhatsAppCredential {
  const WhatsAppCredential({
    required this.accessToken,
    required this.phoneNumberId,
    required this.wabaId,
    required this.appId,
    required this.appSecret,
  });

  final String accessToken;
  final String phoneNumberId;
  final String wabaId;
  final String appId;
  final String appSecret;

  String encode() => jsonEncode({
    'access_token': accessToken,
    'phone_number_id': phoneNumberId,
    'waba_id': wabaId,
    'app_id': appId,
    'app_secret': appSecret,
  });

  factory WhatsAppCredential.decode(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return WhatsAppCredential(
      accessToken: map['access_token'] as String,
      phoneNumberId: map['phone_number_id'] as String,
      wabaId: map['waba_id'] as String,
      // appId/appSecret default to '' when decoding a credential
      // connected before this field existed, rather than throwing — an
      // already-connected channel should keep sending messages
      // uninterrupted; it just won't pass webhook signature
      // verification until reconnected with the new fields filled in
      // (see WhatsAppBotRegistry's signature check: an empty secret is
      // simply never a match, so old channels degrade to "can't
      // receive" rather than "crash at startup").
      appId: map['app_id'] as String? ?? '',
      appSecret: map['app_secret'] as String? ?? '',
    );
  }
}
