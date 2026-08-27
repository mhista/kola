// send_message_route.dart — Gate 8. POST /v1/messages.
//
// THE FIRST REAL CALLER OF ApiKeyService.verify(). Everything else in
// this codebase authenticates via requireWorkspaceAccess's dashboard
// session token; this route is the one entry point meant for an
// external, non-Kola-dashboard caller, so it authenticates the way
// Stripe/GitHub-style platforms do: `Authorization: Bearer sk_live_...`.
//
// LIVES ON webServer, NOT AS A GENERATED Endpoint — see server.dart's
// header on why Serverpod's apiServer only dispatches generated
// Endpoints (accessToken/session based) and has no API-key auth path.
// Modeled closely on paystack_webhook_route.dart's shape, but this is
// NOT a webhook: an external caller is asking Kola to DO something, not
// notifying Kola something already happened, so unlike every webhook
// route in this codebase this one returns REAL HTTP status codes
// (401/403/400/502) rather than always 200 — there is no "provider
// retries aggressively on non-2xx" concern here, and a caller building
// against this API needs to be able to distinguish "bad key" from "bad
// request" from "the send itself failed."
//
// REQUEST BODY:
//   { "platform": "whatsapp" | "telegram",
//     "to": "<phone or chat id>",
//     "text": "<message body>",
//     "idempotencyKey": "<optional caller-chosen string>" }
//
// workspaceId is deliberately NOT read from the body — the API key
// itself is scoped to exactly one workspace (see api_key.spy.yaml), so
// trusting a body-supplied workspaceId over the key's own would be a
// second, weaker source of truth for the one thing that must never be
// ambiguous on an authenticated write.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Message, Logger;
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/platform/api_key_service.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/messaging/outbound_message_service.dart';

final _log = Logger('SendMessageRoute');

class SendMessageRoute extends Route {
  // Method.post only — matches every other custom Route in this codebase
  // (paystack_webhook_route.dart etc.). No existing route in this project
  // declares/handles Method.options, so this doesn't invent a new pattern;
  // a browser-based caller doing a CORS preflight isn't the expected
  // client for a server-to-server, Bearer-token API like this one.
  SendMessageRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    try {
      final presentedKey = _bearerToken(request);
      if (presentedKey == null) {
        return _err(401, 'Missing or malformed Authorization header — expected "Bearer sk_live_...".');
      }

      final apiKey = await getIt<ApiKeyService>().verify(presentedKey);
      if (apiKey == null || apiKey.revokedAt != null) {
        return _err(401, 'Invalid or revoked API key.');
      }
      if (apiKey.scope != 'full') {
        return _err(403, 'This API key\'s scope ("${apiKey.scope}") cannot send messages — a "full" scope key is required.');
      }

      final workspace = await getIt<WorkspaceRepository>().findById(apiKey.workspaceId);
      if (workspace == null) {
        return _err(401, 'The workspace this key belongs to no longer exists.');
      }
      if (!await getIt<FeatureFlagService>().isEnabled(FeatureKeys.messagingSend, workspace)) {
        return _err(403, 'The messaging send API is not available on this workspace yet.');
      }

      final rawBody = await request.readAsString();
      Map<String, dynamic> json;
      try {
        json = rawBody.isEmpty ? {} : jsonDecode(rawBody) as Map<String, dynamic>;
      } catch (_) {
        return _err(400, 'Request body must be valid JSON.');
      }

      final platform = (json['platform'] as String?)?.trim().toLowerCase() ?? '';
      final to = (json['to'] as String?) ?? '';
      final text = (json['text'] as String?) ?? '';
      final idempotencyKey = json['idempotencyKey'] as String?;

      final result = await getIt<OutboundMessageService>().send(
        workspaceId: apiKey.workspaceId,
        platform: platform,
        to: to,
        text: text,
        idempotencyKey: idempotencyKey,
      );

      if (!result.success) {
        // A validation problem (bad platform/empty field) vs. the send
        // itself failing (channel not connected, WhatsApp window/Meta
        // rejection) both surface as OutboundSendResult.failure — the
        // distinction matters to a caller deciding whether to retry, so
        // it's drawn here on the one signal available: whether Kola ever
        // reached a channel to attempt a send.
        final reachedChannel = result.error?.contains('not currently connected') == true ||
            result.error?.contains('Send failed') == true;
        return _err(reachedChannel ? 502 : 400, result.error ?? 'Send failed.');
      }

      final message = result.message!;
      return _json(200, {
        'ok': true,
        'messageId': message.id,
        'conversationId': message.conversationId,
        'deduped': result.deduped,
      });
    } catch (e, stackTrace) {
      _log.severe('Unhandled error in POST /v1/messages', e, stackTrace);
      session.log('POST /v1/messages error: $e', stackTrace: stackTrace);
      return _err(500, 'Internal error.');
    }
  }

  String? _bearerToken(Request request) {
    final values = request.headers['authorization'];
    final header = (values != null && values.isNotEmpty) ? values.first : null;
    if (header == null || !header.startsWith('Bearer ')) return null;
    final token = header.substring('Bearer '.length).trim();
    return token.isEmpty ? null : token;
  }

  Headers _corsHeaders() => Headers.build((h) {
        h['access-control-allow-origin'] = ['*'];
        h['access-control-allow-methods'] = ['POST, OPTIONS'];
        h['access-control-allow-headers'] = ['Content-Type, Authorization'];
      });

  Result _json(int status, Map<String, dynamic> body) {
    final encoded = jsonEncode(body);
    final headers = _corsHeaders();
    return status == 200
        ? Response.ok(body: Body.fromString(encoded, mimeType: MimeType.json), headers: headers)
        : Response(status, body: Body.fromString(encoded, mimeType: MimeType.json), headers: headers);
  }

  Result _err(int status, String message) => _json(status, {'ok': false, 'error': message});
}
