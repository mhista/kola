// kola_billing_flutterwave_webhook_route.dart
//
// Task #148 — the route Kola's OWN Flutterwave account (not any
// workspace's) sends events to. Registered at
// '/webhooks/kola-billing/flutterwave' — see
// kola_billing_paystack_webhook_route.dart's header for why this is a
// separate path/route from '/webhooks/flutterwave'.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'kola_billing_webhook_handler.dart';

final _log = Logger('KolaBillingFlutterwaveWebhookRoute');
final _handler = KolaBillingWebhookHandler();

class KolaBillingFlutterwaveWebhookRoute extends Route {
  KolaBillingFlutterwaveWebhookRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    try {
      final body = await request.readAsString();
      if (body.isEmpty) return _ok();

      final rawHashValues = request.headers['verif-hash'];
      final verifHashHeader =
          (rawHashValues != null && rawHashValues.isNotEmpty) ? rawHashValues.first : null;

      final accepted = await _handler.processFlutterwave(
        rawBody: body,
        verifHashHeader: verifHashHeader,
      );
      if (!accepted) {
        _log.warning('Rejecting Kola billing (Flutterwave) webhook — verif-hash check failed');
        return Response(403);
      }
      return _ok();
    } catch (e, stackTrace) {
      _log.severe('Error processing Kola billing (Flutterwave) webhook', e, stackTrace);
      session.log('Kola billing (Flutterwave) webhook error: $e', stackTrace: stackTrace);
      return _ok();
    }
  }

  Result _ok() =>
      Response.ok(body: Body.fromString(jsonEncode({'ok': true}), mimeType: MimeType.json));
}
