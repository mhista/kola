// messenger_webhook_route.dart
//
// The HTTP route every connected Facebook Page's Messenger DMs arrive
// on — one instance per connected Channel, registered at
// /webhooks/messenger/<channelId> by MessengerBotRegistry. PER-CHANNEL
// ONLY, same design as instagram_webhook_route.dart — no legacy shared
// route, every Messenger channel this codebase will ever have starts on
// its own URL from day one.
//
// GET — VERIFICATION HANDSHAKE: identical mechanics to WhatsApp's/
// Instagram's (same underlying Meta webhooks infrastructure): hub.mode=
// subscribe, hub.verify_token compared against
// Env.messengerWebhookVerifyToken, hub.challenge echoed back verbatim
// as a plain-text 200. A mismatched token gets 403 — this is the only
// authentication this handshake has.
//
// POST — INBOUND EVENTS: Messenger's webhook payload shares the SAME
// shape family as Instagram's — verified via web search, 31 Aug 2026 —
// a top-level `messaging` array per entry, each item shaped like
//   {"sender":{"id":PSID}, "recipient":{"id":PAGE_ID},
//    "timestamp":..., "message":{"mid":..., "text":..., "is_echo":true?}}
// rather than WhatsApp's nested changes/value/messages structure. This
// route parses that shape directly, same as instagram_webhook_route.dart
// — the two are close enough in shape that a shared parser would be
// tempting, but they're deliberately kept as separate routes/registries
// throughout this codebase (own credential shape, own signature
// verification key, own registry) rather than merged, same "each
// platform is its own small file" convention Telegram/WhatsApp/
// Instagram already established.
//
// is_echo — WHY IT MATTERS: same reasoning as Instagram's — when THIS
// Page's app sends a message (including one this server just sent),
// Meta echoes that event back through the same webhook with
// is_echo:true. Every echo is skipped before it ever reaches the
// registry, to avoid an infinite reply loop.
//
// ALWAYS RETURN 200 OK ON POST ONCE THE SIGNATURE CHECKS OUT — same
// "Meta retries aggressively on non-2xx" reasoning as every other Meta
// webhook route in this codebase. A request that FAILS signature
// verification gets 403 instead, deliberately.
//
// SIGNATURE VERIFICATION REUSES WhatsAppSignatureVerifier DIRECTLY, SAME
// AS INSTAGRAM'S: the X-Hub-Signature-256 HMAC-SHA256 scheme is Meta's
// shared webhooks infrastructure, not WhatsApp-specific.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'package:kola_server/src/config/env.dart';
import '../whatsapp/whatsapp_signature_verifier.dart';
import 'messenger_bot_registry.dart';

final _log = Logger('MessengerWebhookRoute');

class MessengerWebhookRoute extends Route {
  MessengerWebhookRoute({required this.channelId})
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
        token == Env.messengerWebhookVerifyToken &&
        Env.messengerWebhookVerifyToken.isNotEmpty) {
      _log.info('Messenger webhook verification succeeded (channelId: $channelId)');
      return Response.ok(
        body: Body.fromString(challenge ?? '', mimeType: MimeType.plainText),
      );
    }

    _log.warning(
      'Messenger webhook verification failed (channelId: $channelId, mode=$mode, '
      'token matched: ${token == Env.messengerWebhookVerifyToken})',
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

      final registry = MessengerBotRegistry.instance;
      final signatureValid = registry.verifyWebhookSignatureForChannel(
        channelId: channelId,
        rawBody: body,
        signatureHeader: signatureHeader,
      );
      if (!signatureValid) {
        _log.warning(
          'Messenger webhook signature verification failed (channelId: $channelId) — '
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
      _log.severe('Error processing Messenger webhook (channelId: $channelId)', e, stackTrace);
      session.log('Messenger webhook error: $e', stackTrace: stackTrace);
      return _ok();
    }
  }

  Result _ok() => Response.ok(
        body: Body.fromString(jsonEncode({'ok': true}), mimeType: MimeType.json),
      );
}
