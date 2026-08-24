// webhook_connection_tester.dart
//
// Gate 5's "guided" half for the webhook fulfillment type (source ==
// 'webhook'): before this, createWebhookErrand committed a business's
// URL and auth header sight-unseen — the first time anyone learned
// whether it actually worked was the first real conversation that tried
// to call it. This fires one real, UNSAVED, UNLOGGED test request
// before the owner commits to creating the Errand, so a typo'd URL or a
// broken endpoint shows up as a red banner in the builder instead of as
// a silent failure weeks later.
//
// Deliberately NOT WebhookErrandExecutor reused directly: that class
// requires a real, already-persisted Errand + ErrandCredential row (it
// logs to ErrandExecutionLog, keyed on errand.id) — there is no Errand
// yet at the point this runs. The request-building logic is copied
// rather than shared for that reason; if the two drift, that's a sign
// this file's logic should be extracted into something both can call,
// not a bug in either one individually.
//
// Bounded response preview only (first 2000 characters) — this is a
// connectivity/shape check, not a data browser. A business's webhook
// can in principle return anything, including something large.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kola_server/kola_logger.dart';

class WebhookTestResult {
  const WebhookTestResult({
    required this.ok,
    required this.latencyMs,
    this.statusCode,
    this.bodyPreview,
    this.errorMessage,
  });

  final bool ok;
  final int latencyMs;
  final int? statusCode;
  final String? bodyPreview;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
    'ok': ok,
    'latencyMs': latencyMs,
    'statusCode': statusCode,
    'bodyPreview': bodyPreview,
    'errorMessage': errorMessage,
  };
}

class WebhookConnectionTester {
  const WebhookConnectionTester();

  static const _maxPreviewChars = 2000;
  static const _timeout = Duration(seconds: 10);

  /// POSTs [sampleInput] as JSON to [url] (with an optional single auth
  /// header, same shape webhook_errand_credential.dart stores) and
  /// reports back what happened — never throws; every outcome, including
  /// a malformed URL, a timeout or a non-2xx status, comes back as a
  /// [WebhookTestResult] with ok == false and an explanation, so the
  /// dashboard has one code path to render regardless of what went
  /// wrong.
  Future<WebhookTestResult> test({
    required String url,
    String? authHeaderName,
    String? authHeaderValue,
    required Map<String, dynamic> sampleInput,
  }) async {
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.isAbsolute) {
      return const WebhookTestResult(
        ok: false,
        latencyMs: 0,
        errorMessage: 'Not a valid absolute URL.',
      );
    }

    final headers = <String, String>{'content-type': 'application/json'};
    if (authHeaderName != null &&
        authHeaderName.isNotEmpty &&
        authHeaderValue != null &&
        authHeaderValue.isNotEmpty) {
      headers[authHeaderName] = authHeaderValue;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .post(parsed, headers: headers, body: jsonEncode(sampleInput))
          .timeout(_timeout);
      stopwatch.stop();

      final ok = response.statusCode >= 200 && response.statusCode < 300;
      final body = response.body;
      final preview = body.length > _maxPreviewChars ? '${body.substring(0, _maxPreviewChars)}…' : body;

      return WebhookTestResult(
        ok: ok,
        statusCode: response.statusCode,
        bodyPreview: preview,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: ok ? null : 'Webhook returned HTTP ${response.statusCode}.',
      );
    } catch (e) {
      stopwatch.stop();
      Log.error('Webhook connection test failed', error: e);
      return WebhookTestResult(
        ok: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e is TypeError
            ? "Webhook didn't return a reachable response."
            : "Couldn't reach this webhook: ${e.runtimeType}.",
      );
    }
  }
}
