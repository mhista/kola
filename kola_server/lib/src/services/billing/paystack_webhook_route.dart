// paystack_webhook_route.dart
//
// The one shared HTTP route every workspace's Paystack account sends
// events to. ONE route for every workspace (not per-workspace like
// Telegram/WhatsApp) because Paystack's webhook URL is configured once
// per Paystack ACCOUNT in that business's own dashboard — there's no
// Meta-style "one callback URL per App" constraint here, and
// PaymentWebhookHandler already knows how to figure out which
// workspace's credential to verify against by looking up the payload's
// own reference (see that file's header for why that's safe).
//
// ALWAYS 200 ONCE THE SIGNATURE CHECK PASSES, same reasoning as every
// other webhook route in this codebase — Paystack retries aggressively
// on non-2xx. A failed signature check returns 403 instead.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'payment_webhook_handler.dart';

final _log = Logger('PaystackWebhookRoute');
final _handler = PaymentWebhookHandler();

class PaystackWebhookRoute extends Route {
  PaystackWebhookRoute() : super(methods: {Method.post});

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
        _log.warning('Rejecting Paystack webhook — signature check failed');
        return Response(403);
      }
      return _ok();
    } catch (e, stackTrace) {
      _log.severe('Error processing Paystack webhook', e, stackTrace);
      session.log('Paystack webhook error: $e', stackTrace: stackTrace);
      return _ok();
    }
  }

  Result _ok() =>
      Response.ok(body: Body.fromString(jsonEncode({'ok': true}), mimeType: MimeType.json));
}
