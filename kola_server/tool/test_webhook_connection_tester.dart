// ignore_for_file: avoid_print
// ^ One-off CLI script: stdout IS the output. avoid_print stays ON for
//   lib/ — this is a targeted ignore rather than an analyzer exclude, so
//   real errors in this file are still reported.
// tool/test_webhook_connection_tester.dart
//
// Gate 5. Exercises WebhookConnectionTester end to end, entirely
// self-contained — same shape as tool/test_webhook_errand.dart: spins up
// a tiny local HTTP server in this process that echoes back whatever
// JSON it receives plus an auth-header check, then calls
// WebhookConnectionTester.test() against it directly, exactly the way
// ErrandEndpoint.testWebhookErrand does. No workspace/Errand/credential
// row involved — this service runs BEFORE anything is saved.
//
// USAGE (run from kola_server/):
//   dart run tool/test_webhook_connection_tester.dart
//
// Also runs a second call against a deliberately-unreachable port to
// confirm the failure path reports a clean, owner-safe message rather
// than throwing.

import 'dart:convert';
import 'dart:io';
import 'package:kola_server/src/services/errand/webhook_connection_tester.dart';

const _authHeaderName = 'x-kola-test-secret';
const _authHeaderValue = 'test-secret-123';

Future<void> main(List<String> args) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  print('Local echo server listening on localhost:${server.port}');
  server.listen((request) async {
    final body = await utf8.decodeStream(request);
    final receivedAuth = request.headers.value(_authHeaderName);
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'echoed': jsonDecode(body.isEmpty ? '{}' : body),
        'authHeaderReceived': receivedAuth == _authHeaderValue,
      }));
    await request.response.close();
  });

  const tester = WebhookConnectionTester();

  print('');
  print('── Test 1: reachable endpoint, correct auth header ──');
  final ok = await tester.test(
    url: 'http://localhost:${server.port}/',
    authHeaderName: _authHeaderName,
    authHeaderValue: _authHeaderValue,
    sampleInput: {'orderId': '12345'},
  );
  print('ok=${ok.ok} statusCode=${ok.statusCode} latencyMs=${ok.latencyMs}');
  print('bodyPreview=${ok.bodyPreview}');

  print('');
  print('── Test 2: unreachable endpoint — should fail cleanly, not throw ──');
  final failed = await tester.test(
    url: 'http://localhost:1/', // nothing listens on port 1
    sampleInput: {'orderId': '12345'},
  );
  print('ok=${failed.ok} errorMessage=${failed.errorMessage} latencyMs=${failed.latencyMs}');

  await server.close(force: true);

  final pass1 = ok.ok && ok.statusCode == 200;
  final pass2 = !failed.ok && failed.errorMessage != null;
  print('');
  if (pass1 && pass2) {
    print('✅ Both cases behaved as expected.');
    exit(0);
  } else {
    stderr.writeln('❌ One or both cases did not behave as expected — see output above.');
    exit(1);
  }
}
