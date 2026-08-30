// instagram_webhook_route.dart
//
// The HTTP route every connected Instagram professional account's DMs
// arrive on — one instance per connected Channel, registered at
// /webhooks/instagram/<channelId> by InstagramBotRegistry. PER-CHANNEL
// ONLY, unlike whatsapp_webhook_route.dart: there is no legacy shared
// route here, because there is no pre-existing channel verified against
// one — every Instagram channel this codebase will ever have starts on
// its own URL from day one.
//
// GET — VERIFICATION HANDSHAKE: identical mechanics to WhatsApp's (same
// underlying Meta webhooks infrastructure — see
// https://developers.facebook.com/docs/instagram-platform/webhooks,
// fetched live 30 Aug 2026, "Validating Verification Requests" section):
// hub.mode=subscribe, hub.verify_token compared against
// Env.instagramWebhookVerifyToken, hub.challenge echoed back verbatim as
// a plain-text 200. A mismatched token gets 403 — this is the only
// authentication this handshake has.
//
// POST — INBOUND EVENTS: Instagram's `messages` webhook field uses a
// DIFFERENT payload shape than WhatsApp's `changes[].value.messages[]` —
// verified against a real captured payload (via web search, matching the
// shape Meta's own docs describe informally): a top-level `messaging`
// array per entry, each item shaped like
//   {"sender":{"id":IGSID}, "recipient":{"id":IG_ID},
//    "timestamp":..., "message":{"mid":..., "text":..., "is_echo":true?}}
// rather than WhatsApp's nested changes/value/messages structure. This
// route parses that shape directly rather than reusing WhatsApp's
// changes[]-walking logic, which would silently find nothing here.
//
// is_echo — WHY IT MATTERS: per Meta's own "Test setup" section, when
// THIS business's account sends a message (including one this server
// just sent), Meta echoes that event back through the same webhook with
// is_echo:true. Treating an echo as a fresh inbound customer message
// would mean every outbound bot reply re-triggers InboundMessageHandler
// on itself — an infinite loop. Every echo is skipped before it ever
// reaches the registry.
//
// ALWAYS RETURN 200 OK ON POST ONCE THE SIGNATURE CHECKS OUT — same
// "Meta retries aggressively on non-2xx" reasoning as every other Meta
// webhook route in this codebase. A request that FAILS signature
// verification gets 403 instead, deliberately.
//
// SIGNATURE VERIFICATION REUSES WhatsAppSignatureVerifier DIRECTLY, NOT
// A DUPLICATE INSTAGRAM-NAMED COPY: the X-Hub-Signature-256 HMAC-SHA256
// scheme is Meta's shared webhooks infrastructure, not WhatsApp-specific
// — same algorithm, same header, same App Secret concept, just a
// different App per channel. Renaming would only add a file that does
// nothing WhatsAppSignatureVerifier doesn't already do correctly — same
// "reuse before rebuilding" convention this codebase follows elsewhere.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'package:kola_server/src/config/env.dart';
import '../whatsapp/whatsapp_signature_verifier.dart';
import 'instagram_bot_registry.dart';

final _log = Logger('InstagramWebhookRoute');

class InstagramWebhookRoute extends Route {
  InstagramWebhookRoute({required this.channelId})
      : super(methods: {Method.get, Method.post});

  final int channelId;

  @override
  Future<Result> handleCall(Session session, Request request) async {
    if (request.method == Method.get) {
      return _handleVerification(request);
    }
    return _handleInboundEvent(session, request);
  }

  Result _handleVerification(Request request) {
    final params = request.url.queryParameters;
    final mode = params['hub.mode'];
    final token = params['hub.verify_token'];
    final challenge = params['hub.challenge'];

    if (mode == 'subscribe' &&
        token != null &&
        token == Env.instagramWebhookVerifyToken &&
        Env.instagramWebhookVerifyToken.isNotEmpty) {
      _log.info('Instagram webhook verification succeeded (channelId: $channelId)');
      return Response.ok(
        body: Body.fromString(challenge ?? '', mimeType: MimeType.plainText),
      );
    }

    _log.warning(
      'Instagram webhook verification failed (channelId: $channelId, mode=$mode, '
      'token matched: ${token == Env.instagramWebhookVerifyToken})',
    );
    return Response(403);
  }

  Future<Result> _handleInboundEvent(Session session, Request request) async {
    try {
      final body = await request.readAsString();
      if (body.isEmpty) return _ok();

      final rawSignatureValues = request.headers['x-hub-signature-256'];
      final signatureHeader = (rawSignatureValues != null && rawSignatureValues.isNotEmpty)
          ? rawSignatureValues.first
          : null;

      final registry = InstagramBotRegistry.instance;
      final signatureValid = registry.verifyWebhookSignatureForChannel(
        channelId: channelId,
        rawBody: body,
        signatureHeader: signatureHeader,
      );
      if (!signatureValid) {
        _log.warning(
          'Instagram webhook signature verification failed (channelId: $channelId) — '
          'rejecting request without processing it.',
        );
        return Response(403);
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final entries = payload['entry'] as List<dynamic>? ?? [];

      for (final entry in entries) {
        final messaging = (entry as Map<String, dynamic>)['messaging'] as List<dynamic>? ?? [];
        for (final event in messaging) {
          final result = await registry.processWebhookEvent(
            channelId,
            event as Map<String, dynamic>,
          );
          _log.fine('channelId $channelId: webhook event processed success=${result['success']}');
        }
      }

      return _ok();
    } catch (e, stackTrace) {
      _log.severe('Error processing Instagram webhook (channelId: $channelId)', e, stackTrace);
      session.log('Instagram webhook error: $e', stackTrace: stackTrace);
      return _ok();
    }
  }

  Result _ok() => Response.ok(
        body: Body.fromString(jsonEncode({'ok': true}), mimeType: MimeType.json),
      );
}
