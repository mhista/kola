// ai_query_route.dart — Gate 12. POST /v1/ai/query.
//
// THE SAME PUBLIC-API SHAPE SendMessageRoute ESTABLISHED FOR GATE 8:
// lives on webServer as a custom Route (not a generated Endpoint — see
// send_message_route.dart's header on why Serverpod's apiServer has no
// API-key auth path), authenticates via `Authorization: Bearer
// sk_live_...` through the same ApiKeyService, returns real HTTP status
// codes rather than always 200 (an external caller needs to tell "bad
// key" from "bad request" from "the query itself failed").
//
// WHAT THIS ACTUALLY EXPOSES: WorkspaceAnswerService.ask — the exact
// same cross-source Q&A the owner dashboard's "Ask kola" box already
// calls (Gate 12 in the Rev 6 roadmap is this capability's PUBLIC
// surface, not a new capability). Same memory retrieval, same catalog/
// connector/sales digests, same citations. This route is a thin
// authentication-and-serialization shell around a service that already
// existed and was already trusted with an owner's own questions.
//
// THE ONE REAL DECISION THIS ROUTE MAKES: SCOPE GATES ACTIONS, NOT JUST
// READS. WorkspaceAnswerService.ask can, per its own header (see rule 3
// there), execute a real tool call — book a calendar event, run an
// Errand — when the model chooses to. That is a WRITE, the same class
// of capability SendMessageRoute already restricts to `full`-scope
// keys. So:
//   - `full` scope  → allowActions: true  — the complete capability,
//     identical to what the owner dashboard gets.
//   - `read_only` scope → allowActions: false — real answers, real
//     citations, but the model is never offered an action tool to call
//     (see WorkspaceAnswerService.ask's new `allowActions` param) —
//     this is what makes "read-only" a promise the platform enforces,
//     not just a label on the key.
//   - `errands_only` scope → rejected with a clear 403. That scope's
//     own name promises the opposite of this endpoint's default
//     (broad Q&A that MAY incidentally trigger an errand) — building a
//     "questions restricted to exactly one named errand" mode is real,
//     separate work this pass didn't do, not something to fake by
//     quietly treating it as read_only or full.
//
// REQUEST BODY: { "question": "<free text>" }
//
// workspaceId is, as in SendMessageRoute, deliberately NOT read from
// the body — the API key is scoped to exactly one workspace.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Message, Logger;
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/platform/api_key_service.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/assistant/workspace_answer_service.dart';

final _log = Logger('AiQueryRoute');

class AiQueryRoute extends Route {
  AiQueryRoute() : super(methods: {Method.post});

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

      final bool allowActions;
      switch (apiKey.scope) {
        case 'full':
          allowActions = true;
        case 'read_only':
          allowActions = false;
        default:
          // 'errands_only' and anything else — see this file's header
          // on why that scope is rejected outright rather than mapped
          // onto either behaviour.
          return _err(
            403,
            'This API key\'s scope ("${apiKey.scope}") cannot query — use a '
            '"full" or "read_only" scoped key.',
          );
      }

      final workspace = await getIt<WorkspaceRepository>().findById(apiKey.workspaceId);
      if (workspace == null) {
        return _err(401, 'The workspace this key belongs to no longer exists.');
      }
      if (!await getIt<FeatureFlagService>().isEnabled(FeatureKeys.publicApi, workspace)) {
        return _err(403, 'The public query API is not available on this workspace yet.');
      }

      final rawBody = await request.readAsString();
      Map<String, dynamic> json;
      try {
        json = rawBody.isEmpty ? {} : jsonDecode(rawBody) as Map<String, dynamic>;
      } catch (_) {
        return _err(400, 'Request body must be valid JSON.');
      }

      final question = (json['question'] as String?) ?? '';
      if (question.trim().isEmpty) {
        return _err(400, '"question" is required and cannot be empty.');
      }

      final answer = await getIt<WorkspaceAnswerService>().ask(
        workspaceId: apiKey.workspaceId,
        question: question,
        allowActions: allowActions,
      );

      return _json(200, {
        'ok': true,
        'answer': answer.answer,
        'productIds': answer.productIds,
        'citations': [
          for (final c in answer.citations)
            {
              'chunkId': c.chunkId,
              'documentId': c.documentId,
              'documentTitle': c.documentTitle,
              'chunkIndex': c.chunkIndex,
              'content': c.content,
              'similarity': c.similarity,
            },
        ],
        'generated': answer.generated,
        'providerName': answer.providerName,
      });
    } catch (e, stackTrace) {
      _log.severe('Unhandled error in POST /v1/ai/query', e, stackTrace);
      session.log('POST /v1/ai/query error: $e', stackTrace: stackTrace);
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
