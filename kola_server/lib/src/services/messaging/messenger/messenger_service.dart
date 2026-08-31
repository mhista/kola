// messenger_service.dart
//
// Low-level wrapper around Meta's Messenger Platform Send API — plain
// HTTPS calls via package:http, same no-SDK approach as
// whatsapp_service.dart/instagram_service.dart. One instance per
// connected Facebook Page (Channel).
//
// VERIFIED AGAINST META'S REAL DOCS (fetched live, 31 Aug 2026):
//   • Send endpoint: POST https://graph.facebook.com/<PAGE_ID>/messages,
//     body {"recipient":{"id":"<PSID>"},"messaging_type":"RESPONSE",
//     "message":{"text":"..."}}. Unlike Instagram's graph.instagram.com,
//     Messenger uses the classic Graph API host — graph.facebook.com —
//     the same host WhatsApp uses, just a different node path.
//   • Auth: `Authorization: Bearer <PAGE_ACCESS_TOKEN>` — a Page token,
//     not a user or app token (see messenger_credential.dart's header).
//   • messaging_type is REQUIRED on every send (Instagram's API has no
//     equivalent field) — 'RESPONSE' is used unconditionally here, since
//     every send this service makes is a reply to an inbound customer
//     message via InboundMessageHandler, exactly what RESPONSE means per
//     Meta's docs. A proactive/outside-the-24h-window send would need
//     'MESSAGE_TAG' with a tag instead — not built here, same "not
//     invented speculatively" discipline as everywhere else in this
//     codebase; a send outside the window fails with a real, visible
//     Meta error, same division of responsibility as every sibling
//     service.
//   • API version pinned to v22.0, same convention as WhatsApp's/
//     Instagram's own pinned-version comment — bump centrally here.
//
// THE 24-HOUR STANDARD MESSAGING WINDOW: same as Instagram's — this
// service does not enforce or track it; a send attempted outside the
// window fails with a real error from Meta's API, surfaced as an
// Exception, nothing swallowed.
//
// SUBSCRIBED_APPS IS REQUIRED HERE, NOT SOFT LIKE INSTAGRAM'S: per
// Meta's Messenger Platform docs (confirmed via web search, 31 Aug
// 2026), a Page must explicitly opt the app in via
// POST /<PAGE_ID>/subscribed_apps?subscribed_fields=messages before ANY
// webhook events for that Page will ever arrive — there is no
// App-Dashboard-level subscription that covers every Page the way
// Instagram's account-level opt-in is closer to being covered already.
// enableSubscription() below is still called as a best-effort step at
// connect time (same "send still works even if this fails" reasoning),
// but the comment is honest that inbound will not work at all until it
// succeeds — see messenger_bot_registry.dart's connect path.
//
// SCOPE CUT — NO EQUIVALENT OF WhatsAppService.debugToken(): same named
// cut as instagram_service.dart — a Page token that's actually a
// short-lived user token will simply start failing sends with a clear
// Meta error, not warned about in advance.

import 'dart:convert';
import 'package:http/http.dart' as http;

class MessengerService {
  MessengerService({required this.pageAccessToken, required this.pageId});

  final String pageAccessToken;
  final String pageId;

  static const _apiVersion = 'v22.0';
  static const _host = 'graph.facebook.com';

  Uri _messagesUri() => Uri.https(_host, '/$_apiVersion/$pageId/messages');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $pageAccessToken',
    'Content-Type': 'application/json',
  };

  /// Confirms the token + pageId combination is real and belongs
  /// together, by fetching the Page's own basic profile fields. Used by
  /// ChannelEndpoint.connectMessengerChannelManual to validate before
  /// persisting anything — same role as InstagramService.probe()/
  /// WhatsAppService.probe().
  Future<Map<String, dynamic>> probe() async {
    final uri = Uri.https(_host, '/$_apiVersion/$pageId', {
      'fields': 'name',
      'access_token': pageAccessToken,
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Messenger probe failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Opts this Page's app in to receiving `messages` webhook events — see
  /// file header on why this is required (not merely helpful) for
  /// Messenger. Called once at connect time by
  /// ChannelEndpoint.connectMessengerChannelManual — failure here doesn't
  /// block the connection (send still works), it just means inbound
  /// messages won't arrive until retried, logged the same "visible, not
  /// silent" way as every other soft-fail in this file.
  Future<void> enableSubscription() async {
    final uri = Uri.https(_host, '/$_apiVersion/$pageId/subscribed_apps', {
      'subscribed_fields': 'messages',
      'access_token': pageAccessToken,
    });
    final response = await http.post(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Messenger subscribed_apps failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Sends a plain text (or link) message. Meta's docs cap message text
  /// at 2000 characters — not enforced here (same "the API rejects it
  /// with a real error" division of responsibility as everywhere else in
  /// this file).
  Future<Map<String, dynamic>> sendText({
    required String to,
    required String body,
  }) => _post({
    'recipient': {'id': to},
    'messaging_type': 'RESPONSE',
    'message': {'text': body},
  });

  /// Sends a single image by URL — same one-non-text-send-implemented
  /// scope cut as InstagramService.sendImage.
  Future<Map<String, dynamic>> sendImage({
    required String to,
    required String imageUrl,
  }) => _post({
    'recipient': {'id': to},
    'messaging_type': 'RESPONSE',
    'message': {
      'attachment': {
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
        'Messenger API call failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
