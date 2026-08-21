// webhook_delivery_service.dart — Gate 2. The piece PART II's own gap
// table names directly: "Webhooks outbound — PARTIAL. Model + storage
// (026). Delivery worker does not fire." Confirmed before writing this
// file by grepping the whole `lib/src` tree for any caller of
// WebhookEndpointRepository.listActiveForEvent — there was none.
// webhook_endpoints (migration 026) has existed since before Gate 1 with
// nothing ever reading from it. This is that reader.
//
// SIGNING: webhook_endpoint.spy.yaml's own header already commits to the
// scheme — "kola must SIGN every delivery with this secret so the
// receiver can verify the payload came from kola" — this file is what
// actually does it. HMAC-SHA256 over the raw JSON body, hex-encoded, in
// an `X-Kola-Signature` header, verified against the SAME
// ChannelCredentialEncryptionService-decrypted secret on the receiving
// end (whatever that end turns out to be — this is a NEW signing scheme
// this codebase did not have before Gate 2; there is no existing
// "how kola signs outbound requests" precedent to match against, only
// WhatsApp's INCOMING signature verification (whatsapp_signature_
// verifier.dart), which this mirrors the SHAPE of — sha256=<hex> —
// deliberately, so one verification pattern serves both directions.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/webhook_endpoint_repository.dart';
import 'package:kola_server/src/services/repository/connector_sync_log_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'connector_retry.dart';

class WebhookDeliveryService {
  WebhookDeliveryService({
    required WebhookEndpointRepository endpoints,
    required ConnectorSyncLogRepository syncLog,
  }) : _endpoints = endpoints,
       _syncLog = syncLog;

  final WebhookEndpointRepository _endpoints;
  final ConnectorSyncLogRepository _syncLog;

  /// Delivers [payloadJson] to every ACTIVE endpoint in [workspaceId]
  /// subscribed to [eventType] — called by EventBus.emit only on a
  /// genuinely new event (see event_repository.dart's `wasNew`), never
  /// on a deduplicated replay of something already delivered once.
  ///
  /// One endpoint's failure never blocks another's delivery — a business
  /// with two webhook subscribers should not have a broken second one
  /// silently swallow events meant for a working first one.
  Future<void> deliverToSubscribers({
    required int workspaceId,
    required String eventType,
    required String payloadJson,
  }) async {
    final subscribers = await _endpoints.listActiveForEvent(workspaceId, eventType);
    if (subscribers.isEmpty) return;

    for (final endpoint in subscribers) {
      // Failures are handled and logged INSIDE _deliverOne (via
      // ConnectorRetry, which already dead-letters) — this loop must
      // never let one endpoint's exception stop the others.
      try {
        await _deliverOne(endpoint: endpoint, payloadJson: payloadJson);
      } catch (e) {
        Log.error(
          'WebhookDeliveryService: giving up on endpoint ${endpoint.id} '
          '(workspace $workspaceId) after retries',
          error: e,
        );
      }
    }
  }

  Future<void> _deliverOne({
    required WebhookEndpoint endpoint,
    required String payloadJson,
  }) async {
    final endpointId = endpoint.id;
    if (endpointId == null) return;

    await ConnectorRetry.run<void>(
      () async {
        final headers = <String, String>{'content-type': 'application/json'};
        if (endpoint.encryptedSecret != null) {
          final secret = ChannelCredentialEncryptionService.decrypt(endpoint.encryptedSecret!);
          headers['X-Kola-Signature'] = _sign(secret: secret, body: payloadJson);
        }

        final response = await http.post(
          Uri.parse(endpoint.url),
          headers: headers,
          body: payloadJson,
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            'Webhook endpoint returned HTTP ${response.statusCode}',
          );
        }
      },
      deadLetter: _syncLog,
      workspaceId: endpoint.workspaceId,
      // Not a catalog connector key — see connector_sync_log's own
      // header on why store='generic' rows aren't required to name a
      // ConnectorCatalog entry; a webhook subscriber is identified by
      // its own row, not a product-defined connector.
      connectorKey: 'webhook_endpoint:$endpointId',
      store: 'generic',
      kind: 'sync',
    );

    // Only reached if ConnectorRetry.run above did NOT rethrow — i.e.
    // one of the attempts actually succeeded.
    await _endpoints.markDelivered(endpointId);
  }

  /// sha256=<hex hmac> — same "sha256=" prefix shape WhatsApp's own
  /// incoming X-Hub-Signature-256 header uses (see
  /// whatsapp_signature_verifier.dart), so a receiver already familiar
  /// with verifying Meta's webhooks recognizes the pattern immediately.
  static String _sign({required String secret, required String body}) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(body));
    return 'sha256=$digest';
  }
}
