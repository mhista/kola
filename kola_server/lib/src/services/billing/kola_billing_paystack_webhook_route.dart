// kola_billing_paystack_webhook_route.dart
//
// Task #148 — the route Kola's OWN Paystack account (not any workspace's)
// sends events to, for subscription checkouts started via
// KolaBillingService.initiateUpgrade. Registered at
// '/webhooks/kola-billing/paystack' in server.dart — deliberately a
// DIFFERENT path from '/webhooks/paystack' (paystack_webhook_route.dart),
// which is where every WORKSPACE's own Paystack account sends events for
// customer payments they collect themselves. Same account can't be
// configured to POST to two URLs for the same event, so these are wired
// into two entirely separate Paystack dashboards: workspaces configure
// their own; Kola configures this one, once, on Kola's own account.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'kola_billing_webhook_handler.dart';

final _log = Logger('KolaBillingPaystackWebhookRoute');
final _handler = KolaBillingWebhookHandler();

class KolaBillingPaystackWebhookRoute extends Route {
  KolaBillingPaystackWebhookRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    try {
      final body = await request.readAsString();
      if (body.isEmpty) return _ok();

      final rawSignatureValues = request.headers['x-paystack-signature'];
      final signatureHeader = (rawSignatureValues != null && rawSignatureValues.isNotEmpty)
          ? rawSignatureValues.first
          : null;

      final accepted = await _handler.processPaystack(
        rawBody: body,
        signatureHeader: signatureHeader,
      );
      if (!accepted) {
        _log.warning('Rejecting Kola billing (Paystack) webhook — signature check failed');
        return Response(403);
      }
      return _ok();
    } catch (e, stackTrace) {
      _log.severe('Error processing Kola billing (Paystack) webhook', e, stackTrace);
      session.log('Kola billing (Paystack) webhook error: $e', stackTrace: stackTrace);
      return _ok();
    }
  }

  Result _ok() =>
      Response.ok(body: Body.fromString(jsonEncode({'ok': true}), mimeType: MimeType.json));
}
