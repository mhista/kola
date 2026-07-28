// whatsapp_webhook_route.dart
//
// The HTTP route every connected WhatsApp number's messages arrive on.
//
// TWO MODES, ONE CLASS:
//   WhatsAppWebhookRoute(channelId: ...) — the current design. One
//     instance per connected Channel, registered at
//     /webhooks/whatsapp/<channelId> by WhatsAppBotRegistry, exactly
//     mirroring TelegramWebhookRoute. The channel is known from the URL
//     alone, so signature verification checks only that channel's App
//     Secret and processWebhook dispatches straight to it — see
//     whatsapp_bot_registry.dart's file header for the full reasoning.
//   WhatsAppWebhookRoute() (channelId omitted) — legacy mode. Registered
//     exactly once in server.dart at the original shared
//     /webhooks/whatsapp path, kept alive only because the first channel
//     ever connected is still verified against that exact URL in Meta's
//     dashboard, and re-doing that handshake for zero functional gain
//     isn't worth the churn right now. This mode has no channel identity
//     from the URL, so it verifies against every registered secret and
//     dispatches by reading phone_number_id out of the payload — the
//     original design's approach, unchanged. Safe to delete once every
//     channel has migrated to its own per-channel URL.
//
// GET — VERIFICATION HANDSHAKE (same for both modes):
//   The first time you save a Callback URL in Meta's App Dashboard →
//   WhatsApp → Configuration, Meta sends exactly one GET request to
//   prove you control that URL, with three query params:
//     hub.mode          — always "subscribe"
//     hub.verify_token  — must match WHATSAPP_WEBHOOK_VERIFY_TOKEN
//                          exactly (the string you typed into the same
//                          dashboard field, see .env.example)
//     hub.challenge     — an arbitrary string you must echo back
//                          verbatim, as your response BODY, with a
//                          plain 200 status and text/plain content —
//                          not wrapped in JSON.
//   If verify_token doesn't match, respond 403 — this is the ONLY
//   authentication WhatsApp's webhook has, so getting this comparison
//   right matters. WHATSAPP_WEBHOOK_VERIFY_TOKEN is a single value
//   shared across every business rather than per-channel — that's fine
//   here because this handshake only ever proves domain/URL ownership to
//   Meta itself during setup, it isn't involved in any actual message
//   delivery afterward (that's what the POST signature check is for).
//
// POST — INBOUND EVENTS:
//   Meta batches one or more "entry" objects per request. Each one's
//   changes[].value is handed to the registry — which method depends on
//   mode (see above).
//
// ALWAYS RETURN 200 OK ON POST *ONCE THE SIGNATURE CHECKS OUT* (same
// reasoning as Telegram's route): Meta retries aggressively on non-2xx.
// Every error past that point is caught and logged internally; Meta
// always sees 200 for a genuine delivery it made. A request that FAILS
// signature verification gets 403 instead, deliberately — that's not a
// delivery Meta is retrying, it's either a forged request or a stale
// integration, and letting it fall through to _ok() would silently hide
// exactly the case this check exists to catch.
//
// VERIFIED AGAINST RELIC'S REAL SOURCE (found and fixed real bugs here
// that only surfaced once a real `dart analyze` ran):
//   1. `Response(statusCode: 403)` isn't real — Relic's custom-status
//      constructor takes the code as the first POSITIONAL argument:
//      `Response(403, ...)`.
//   2. `request.headers['x-hub-signature-256']` returns `List<String>?`
//      (the header's raw values), never a bare `String`.
//   3. `request.requestedUri` isn't a real Request property either —
//      Relic's own docs list the query-string property as `request.url`
//      ("full original URI"), not `requestedUri`.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'package:kola_server/src/config/env.dart';
import 'whatsapp_bot_registry.dart';

final _log = Logger('WhatsAppWebhookRoute');

class WhatsAppWebhookRoute extends Route {
  /// [channelId] present → per-channel mode. Omitted → legacy shared
  /// mode. See file header.
  WhatsAppWebhookRoute({this.channelId}) : super(methods: {Method.get, Method.post});

  final int? channelId;

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
        token == Env.whatsappWebhookVerifyToken &&
        Env.whatsappWebhookVerifyToken.isNotEmpty) {
      _log.info('WhatsApp webhook verification succeeded (channelId: $channelId)');
      return Response.ok(
        body: Body.fromString(challenge ?? '', mimeType: MimeType.plainText),
      );
    }

    _log.warning(
      'WhatsApp webhook verification failed (channelId: $channelId, mode=$mode, '
      'token matched: ${token == Env.whatsappWebhookVerifyToken})',
    );
    return Response(403);
  }

  Future<Result> _handleInboundEvent(Session session, Request request) async {
    try {
      final body = await request.readAsString();
      if (body.isEmpty) return _ok();

      // ── Verify BEFORE parsing — see file header. Raw header values are
      //    always List<String>? (the header's raw value list), never a
      //    bare String — take the first entry, if the header is present
      //    at all. ────────────────────────────────────────────────────────
      final rawSignatureValues = request.headers['x-hub-signature-256'];
      final signatureHeader = (rawSignatureValues != null && rawSignatureValues.isNotEmpty)
          ? rawSignatureValues.first
          : null;

      final registry = WhatsAppBotRegistry.instance;
      final signatureValid = channelId != null
          ? registry.verifyWebhookSignatureForChannel(
              channelId: channelId!,
              rawBody: body,
              signatureHeader: signatureHeader,
            )
          : registry.verifyWebhookSignatureLegacy(
              rawBody: body,
              signatureHeader: signatureHeader,
            );
      if (!signatureValid) {
        _log.warning(
          'WhatsApp webhook signature verification failed (channelId: $channelId) — '
          'rejecting request without processing it (forged request, or a channel '
          'connected before appSecret was collected — see '
          'docs/WHATSAPP_MANUAL_SETUP.md).',
        );
        return Response(403);
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final entries = payload['entry'] as List<dynamic>? ?? [];

      for (final entry in entries) {
        final changes = (entry as Map<String, dynamic>)['changes'] as List<dynamic>? ?? [];
        for (final change in changes) {
          final value = (change as Map<String, dynamic>)['value'] as Map<String, dynamic>?;
          if (value == null) continue;

          final result = channelId != null
              ? await registry.processWebhook(channelId!, value)
              : await registry.processWebhookLegacy(value);
          _log.fine('channelId $channelId: webhook processed success=${result['success']}');
        }
      }

      return _ok();
    } catch (e, stackTrace) {
      _log.severe('Error processing WhatsApp webhook (channelId: $channelId)', e, stackTrace);
      session.log('WhatsApp webhook error: $e', stackTrace: stackTrace);
      return _ok();
    }
  }

  Result _ok() => Response.ok(
        body: Body.fromString(jsonEncode({'ok': true}), mimeType: MimeType.json),
      );
}
