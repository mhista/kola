import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;

final _log = Logger('DashboardApiRoute');

// ── CORS headers added to every response ─────────────────────────────────────

Headers _corsHeaders({String? extra}) => Headers.build((h) {
      h['access-control-allow-origin']  = ['*'];
      h['access-control-allow-methods'] = ['GET, POST, OPTIONS'];
      h['access-control-allow-headers'] = ['Content-Type'];
      if (extra != null) h['x-info']    = [extra];
    });

Result _json(Map<String, dynamic> body, {int status = 200}) {
  final encoded = jsonEncode(body);
  final headers = _corsHeaders();
  return status == 200
      ? Response.ok(body: Body.fromString(encoded, mimeType: MimeType.json), headers: headers)
      : Response(status, body: Body.fromString(encoded, mimeType: MimeType.json), headers: headers);
}

// Preflight passthrough — shared by all routes.
Result preflight() => Response.ok(
      body: Body.fromString('', mimeType: MimeType.plainText),
      headers: _corsHeaders(),
    );


// ═══════════════════════════════════════════════════════════════════════════
// GET /api/status
// Response: {
//   "server": "ok",
//   "scanner": { "running": bool, "cycleInProgress": bool, "cycleCount": int }
// }
// The web polls this to know when a scan has finished.
// ═══════════════════════════════════════════════════════════════════════════

class ApiStatusRoute extends Route {
  final String _flagged;

  ApiStatusRoute({required String flagged})
      : _flagged = flagged,
        super(methods: {Method.get, Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    // OPTIONS preflight
    if (request.method == Method.post) return preflight();

    return _json({
      'server': 'ok',
     'info': 'Channel health check: $_flagged channel(s) flagged unhealthy',
    });
  }
}