// instagram_service.dart
//
// Low-level wrapper around Meta's Instagram Messaging API (Instagram API
// with Instagram Login) — plain HTTPS calls via package:http, same
// no-SDK approach as whatsapp_service.dart. One instance per connected
// Instagram channel.
//
// VERIFIED AGAINST META'S REAL DOCS (fetched live, 30 Aug 2026):
// https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api
//   • Base host is graph.instagram.com — NOT graph.facebook.com. This is
//     a genuine difference from WhatsApp, not a typo; Meta's Instagram
//     Login API family hosts its endpoints separately from the classic
//     Graph API WhatsApp/Messenger use.
//   • Send endpoint: POST /<IG_ID>/messages, body
//     {"recipient":{"id":"<IGSID>"},"message":{"text":"..."}}.
//   • Auth: `Authorization: Bearer <INSTAGRAM_USER_ACCESS_TOKEN>` — same
//     bearer-token shape as WhatsApp, different token type.
//   • API version pinned to v22.0 for consistency with whatsapp_service.dart
//     (Meta's docs show examples against v25.0/v26.0 as of this writing;
//     v22.0 is still a live, supported version — bump centrally here,
//     same convention as WhatsApp's own pinned-version comment).
//
// THE 24-HOUR MESSAGING WINDOW: per Meta's docs, "your app has 24 hours
// to respond to any message sent from an Instagram user." This service
// does not enforce or track that window itself — same division of
// responsibility as WhatsApp's own service class, which doesn't police
// WhatsApp's messaging-window rules either. A send attempted outside the
// window fails with a real error from Meta's API, which _post already
// surfaces as an Exception; nothing here swallows it.
//
// SCOPE CUT — NO EQUIVALENT OF WhatsAppService.debugToken(): WhatsApp's
// debug_token check tells a business whether they've connected a
// temporary (~24h) token instead of a permanent one, up front. Meta's
// Instagram Messaging docs don't document an equivalent affordance in
// the same reachable way for this API family, and this pass didn't
// invent one speculatively. A token that expires will simply start
// failing sends with a clear Meta error at that point — visible, not
// silent, just not warned about in advance the way WhatsApp's is.

import 'dart:convert';
import 'package:http/http.dart' as http;

class InstagramService {
  InstagramService({required this.accessToken, required this.igUserId});

  final String accessToken;
  final String igUserId;

  static const _apiVersion = 'v22.0';
  static const _host = 'graph.instagram.com';

  Uri _messagesUri() => Uri.https(_host, '/$_apiVersion/$igUserId/messages');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  /// Confirms the token + igUserId combination is real and belongs
  /// together, by fetching the account's own basic profile fields. Used
  /// by ChannelEndpoint.connectInstagramChannelManual to validate before
  /// persisting anything — same role as WhatsAppService.probe().
  Future<Map<String, dynamic>> probe() async {
    final uri = Uri.https(_host, '/$_apiVersion/$igUserId', {
      'fields': 'username,name',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Instagram probe failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Enables webhook delivery for this account, per Meta's "Enable
  /// Subscriptions" step — a POST to /<IG_ID>/subscribed_apps with the
  /// fields this channel actually needs. Without this call, Meta's App
  /// Dashboard-level webhook subscription is not enough on its own; each
  /// individual Instagram professional account must separately opt in.
  /// Called once at connect time by ChannelEndpoint.connectInstagramChannelManual
  /// — failure here doesn't block the connection (send still works), it
  /// just means inbound messages won't arrive until retried, logged the
  /// same "visible, not silent" way as every other soft-fail in this file.
  Future<void> enableSubscription() async {
    final uri = Uri.https(_host, '/$_apiVersion/$igUserId/subscribed_apps', {
      'subscribed_fields': 'messages',
      'access_token': accessToken,
    });
    final response = await http.post(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Instagram subscribed_apps failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Sends a plain text (or link) message. Meta's docs cap message text
  /// at 1000 bytes UTF-8 — not enforced here (same "the API rejects it
  /// with a real error" division of responsibility as everywhere else in
  /// this file); a caller sending customer-facing bot replies through
  /// InstagramBotRegistry is expected to keep replies reasonably short
  /// regardless.
  Future<Map<String, dynamic>> sendText({
    required String to,
    required String body,
  }) => _post({
    'recipient': {'id': to},
    'message': {'text': body},
  });

  /// Sends a single image by URL — the one non-text send this pass
  /// implements for real, since it's a two-line difference from sendText
  /// per Meta's docs (attachment.type=image, payload.url) and images are
  /// common enough in a shop's customer conversations to be worth having.
  Future<Map<String, dynamic>> sendImage({
    required String to,
    required String imageUrl,
  }) => _post({
    'recipient': {'id': to},
    'message': {
      'attachments': {
        'type': 'image',
        'payload': {'url': imageUrl},
      },
    },
  });

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final response = await http.post(
      _messagesUri(),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Instagram API call failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
