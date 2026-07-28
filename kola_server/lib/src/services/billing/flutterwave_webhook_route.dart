// flutterwave_webhook_route.dart
//
// The one shared HTTP route every workspace's Flutterwave account sends
// events to — same "one route, dispatch by looking up the payload's own
// reference" shape as paystack_webhook_route.dart. See
// payment_webhook_handler.dart's header for the full reasoning.
//
// Flutterwave's own webhook header is `verif-hash`, not an HMAC signature
// (see flutterwave_service.dart's header) — read the same way every
// other raw header is read in this codebase: `request.headers[...]`
// always returns `List<String>?`, never a bare String.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'payment_webhook_handler.dart';

final _log = Logger('FlutterwaveWebhookRoute');
final _handler = PaymentWebhookHandler();

class FlutterwaveWebhookRoute extends Route {
  FlutterwaveWebhookRoute() : super(methods: {Method.post});

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
        _log.warning('Rejecting Flutterwave webhook — verif-hash check failed');
        return Response(403);
      }
      return _ok();
    } catch (e, stackTrace) {
      _log.severe('Error processing Flutterwave webhook', e, stackTrace);
      session.log('Flutterwave webhook error: $e', stackTrace: stackTrace);
      return _ok();
    }
  }

  Result _ok() =>
      Response.ok(body: Body.fromString(jsonEncode({'ok': true}), mimeType: MimeType.json));
}
