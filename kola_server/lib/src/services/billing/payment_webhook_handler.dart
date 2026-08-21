// payment_webhook_handler.dart
//
// Task #127 / Phase 8a — the logic behind both payment webhook routes
// (paystack_webhook_route.dart, flutterwave_webhook_route.dart). Kept as
// one shared handler class, not duplicated per-route, since the flow is
// identical up to the gateway-specific verify call: look up which
// workspace this event belongs to, verify the signature against THAT
// workspace's own stored credential, then confirm via the gateway's own
// verify endpoint before ever marking a transaction completed.
//
// WHY "LOOK UP BY REFERENCE, THEN VERIFY" IS SAFE HERE, NOT A HOLE: this
// reads the payload's reference/tx_ref field before the signature check
// passes — technically trusting unverified input for that one field.
// This is deliberate and bounded, the same shape multi-tenant SaaS
// platforms (Stripe Connect apps routing a webhook to the right
// connected account) already use: the reference alone cannot forge a
// payment, because nothing is EVER marked 'completed' from this lookup
// alone — that only happens after (a) the signature check against the
// correct workspace's own secret passes, AND (b) a fresh call to the
// gateway's own verify endpoint independently confirms status+amount
// (see paystack_service.dart/flutterwave_service.dart headers on why
// the webhook event body is never sufficient proof by itself). A forged
// reference just fails to find a real transaction, or finds one and then
// fails the signature check against the real workspace's real secret —
// either way, nothing gets written.
//
// ALWAYS RETURN 200 ONCE THE SIGNATURE CHECK ITSELF PASSED (same
// reasoning as every other webhook route in this codebase): both
// gateways retry aggressively on non-2xx. A failed signature check is
// the one case that returns a rejection status instead — see each
// route's own handleCall.

import 'dart:convert';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/repository/payment_gateway_credential_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'paystack_service.dart';
import 'flutterwave_service.dart';

class PaymentWebhookHandler {
  PaymentTransactionRepository get _transactions => getIt<PaymentTransactionRepository>();
  PaymentGatewayCredentialRepository get _credentials =>
      getIt<PaymentGatewayCredentialRepository>();
  EventBus get _events => getIt<EventBus>();
  CustomerIdentityResolver get _customerIdentity => getIt<CustomerIdentityResolver>();

  /// Returns true if the request should be treated as a genuine,
  /// correctly-signed event (regardless of which event type it was, or
  /// whether it matched a transaction Kola actually knows about) — the
  /// route uses this to decide 200-vs-403, never to decide what to do
  /// next.
  Future<bool> processPaystack({
    required String rawBody,
    required String? signatureHeader,
  }) async {
    final payload = _tryDecode(rawBody);
    if (payload == null) return false;

    final reference = ((payload['data'] as Map<String, dynamic>?) ?? const {})['reference']
        as String?;
    if (reference == null) {
      Log.warning('Paystack webhook missing data.reference — ignoring');
      return true; // not malformed enough to reject outright, just nothing to do
    }

    final transaction = await _transactions.findByReference(reference);
    if (transaction == null) {
      // Could be a Paystack event on this business's account entirely
      // unrelated to a Kola-initiated checkout (e.g. their own dashboard
      // activity) — correctly none of Kola's business, not an error.
      Log.info('Paystack webhook for unknown reference $reference — ignoring');
      return true;
    }

    final credential =
        await _credentials.findByWorkspaceAndGateway(transaction.workspaceId, 'paystack');
    if (credential == null) {
      Log.warning(
        'Paystack webhook for reference $reference but workspace '
        '${transaction.workspaceId} has no paystack credential on file — rejecting',
      );
      return false;
    }

    final secretKey = ChannelCredentialEncryptionService.decrypt(credential.encryptedSecretKey);
    final service = PaystackService(secretKey: secretKey);
    if (!service.verifyWebhookSignature(rawBody: rawBody, signatureHeader: signatureHeader)) {
      Log.warning('Paystack webhook signature verification failed for reference $reference');
      return false;
    }

    final eventType = payload['event'] as String?;
    if (eventType == 'charge.success') {
      await _confirmAndMarkPaystack(service, transaction.reference);
    } else if (eventType == 'charge.failed') {
      await _transactions.markFailed(reference);
    } else {
      Log.info('Paystack webhook event "$eventType" — no handler, ignoring');
    }
    return true;
  }

  Future<bool> processFlutterwave({
    required String rawBody,
    required String? verifHashHeader,
  }) async {
    final payload = _tryDecode(rawBody);
    if (payload == null) return false;

    final data = (payload['data'] as Map<String, dynamic>?) ?? const {};
    final reference = data['tx_ref'] as String?;
    if (reference == null) {
      Log.warning('Flutterwave webhook missing data.tx_ref — ignoring');
      return true;
    }

    final transaction = await _transactions.findByReference(reference);
    if (transaction == null) {
      Log.info('Flutterwave webhook for unknown reference $reference — ignoring');
      return true;
    }

    final credential =
        await _credentials.findByWorkspaceAndGateway(transaction.workspaceId, 'flutterwave');
    if (credential == null || credential.encryptedWebhookSecret == null) {
      Log.warning(
        'Flutterwave webhook for reference $reference but workspace '
        '${transaction.workspaceId} has no webhook secret hash on file — rejecting '
        '(see payment_gateway_credential.spy.yaml)',
      );
      return false;
    }

    final secretKey = ChannelCredentialEncryptionService.decrypt(credential.encryptedSecretKey);
    final configuredHash =
        ChannelCredentialEncryptionService.decrypt(credential.encryptedWebhookSecret!);
    final service = FlutterwaveService(secretKey: secretKey);
    if (!service.verifyWebhookSignature(
      verifHashHeader: verifHashHeader,
      configuredSecretHash: configuredHash,
    )) {
      Log.warning('Flutterwave webhook verif-hash mismatch for reference $reference');
      return false;
    }

    final status = data['status'] as String?;
    if (status == 'successful') {
      await _confirmAndMarkFlutterwave(service, transaction.reference, data['id']);
    } else if (status == 'failed') {
      await _transactions.markFailed(reference);
    } else {
      Log.info('Flutterwave webhook status "$status" — no handler, ignoring');
    }
    return true;
  }

  /// Re-fetches the transaction from Paystack directly rather than
  /// trusting the webhook body's own status/amount fields — see this
  /// file's header and paystack_service.dart's own doc comment on why.
  Future<void> _confirmAndMarkPaystack(PaystackService service, String reference) async {
    final result = await service.verifyTransaction(reference);
    final data = result['data'] as Map<String, dynamic>?;
    if (data == null || data['status'] != 'success') {
      Log.warning('Paystack verify did not confirm success for $reference — not marking completed');
      return;
    }
    final txn = await _transactions.markCompleted(
      reference: reference,
      gatewayTransactionId: data['id']?.toString() ?? '',
      paidAt: data['paid_at'] != null ? DateTime.parse(data['paid_at'] as String) : DateTime.now(),
    );
    await _emitPaymentConfirmed(txn);
  }

  Future<void> _confirmAndMarkFlutterwave(
    FlutterwaveService service,
    String reference,
    Object? transactionId,
  ) async {
    if (transactionId == null) {
      Log.warning('Flutterwave webhook had no data.id for $reference — cannot verify');
      return;
    }
    final result = await service.verifyTransaction(transactionId.toString());
    final data = result['data'] as Map<String, dynamic>?;
    if (data == null || data['status'] != 'successful') {
      Log.warning('Flutterwave verify did not confirm success for $reference — not marking completed');
      return;
    }
    final txn = await _transactions.markCompleted(
      reference: reference,
      gatewayTransactionId: data['id']?.toString() ?? '',
      paidAt: DateTime.now(), // Flutterwave's verify response has no dedicated paid-at field.
    );
    await _emitPaymentConfirmed(txn);
  }

  /// Gate 2 — event bus. Shared by both gateways' confirm paths so the
  /// payload shape can never drift between them. Fingerprint is the
  /// transaction id alone — a given transaction is only ever confirmed
  /// once (markCompleted is the terminal write for a successful payment;
  /// nothing in this codebase un-confirms and re-confirms one), so
  /// deduplicating a retried webhook delivery on transactionId is
  /// correct, not just convenient.
  Future<void> _emitPaymentConfirmed(PaymentTransaction txn) async {
    final txnId = txn.id;
    if (txnId == null) return;

    // Gate 3 — resolve/create the Customer this payment belongs to.
    // Phone is primary (matches the resolver's own priority order),
    // email secondary — a payment carries both when the gateway
    // collects them, so a phone match against one existing customer and
    // an email match against a DIFFERENT existing customer is exactly
    // the conflict CustomerIdentityResolver raises a merge proposal for
    // rather than guessing. See its header.
    if (txn.customerId == null) {
      final primary = txn.customerPhone != null && txn.customerPhone!.trim().isNotEmpty
          ? IdentitySignal(
              type: 'phone',
              value: CustomerIdentityResolver.normalizePhone(txn.customerPhone!),
              sourceRef: txn.reference,
            )
          : IdentitySignal(
              type: 'email',
              value: CustomerIdentityResolver.normalizeEmail(txn.customerEmail),
              sourceRef: txn.reference,
            );
      final secondary = txn.customerPhone != null && txn.customerPhone!.trim().isNotEmpty
          ? IdentitySignal(
              type: 'email',
              value: CustomerIdentityResolver.normalizeEmail(txn.customerEmail),
              sourceRef: txn.reference,
            )
          : null;

      final customerId = await _customerIdentity.resolve(
        workspaceId: txn.workspaceId,
        primary: primary,
        secondary: secondary,
        source: txn.gateway,
      );
      if (customerId != null) {
        await getIt<PaymentTransactionRepository>().setCustomer(txnId, customerId);
      }
    }

    await _events.emit(
      workspaceId: txn.workspaceId,
      eventType: 'payment_confirmed',
      fingerprint: 'payment_confirmed:$txnId',
      payload: {
        'transactionId': txnId,
        'workspaceId': txn.workspaceId,
        'gateway': txn.gateway,
        'reference': txn.reference,
        'amountKobo': txn.amountKobo,
        'currency': txn.currency,
        'conversationId': txn.conversationId,
      },
      occurredAt: txn.paidAt,
    );
  }

  Map<String, dynamic>? _tryDecode(String rawBody) {
    try {
      return jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (e) {
      Log.warning('Payment webhook body is not valid JSON: $e');
      return null;
    }
  }
}
