// kola_billing_webhook_handler.dart
//
// Task #148 — confirms a Kola subscription checkout and, only once
// genuinely confirmed, upgrades the paying workspace. Mirrors
// payment_webhook_handler.dart's shape closely (look up by reference,
// verify signature, re-confirm via the gateway's own verify endpoint
// before ever writing 'completed') but verifies against KOLA'S OWN
// Env.paystackSecretKey/flutterwaveSecretKey — never a per-workspace
// credential, since this is Kola's own gateway account, not a
// business's. See kola_billing_checkout.spy.yaml's header for why this
// is a fully separate handler/table from PaymentWebhookHandler's.
//
// ALWAYS RETURN true (→ 200) ONCE THE SIGNATURE CHECK ITSELF PASSED —
// same reasoning as every other webhook handler in this codebase: both
// gateways retry aggressively on non-2xx. A failed signature check is
// the one case the route should reject instead.

import 'dart:convert';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/repository/kola_billing_checkout_repository.dart';
import 'package:kola_server/src/services/repository/subscription_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'paystack_service.dart';
import 'flutterwave_service.dart';

class KolaBillingWebhookHandler {
  KolaBillingCheckoutRepository get _checkouts => getIt<KolaBillingCheckoutRepository>();
  SubscriptionRepository get _subscriptions => getIt<SubscriptionRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();

  Future<bool> processPaystack({
    required String rawBody,
    required String? signatureHeader,
  }) async {
    final payload = _tryDecode(rawBody);
    if (payload == null) return false;

    final reference = ((payload['data'] as Map<String, dynamic>?) ?? const {})['reference']
        as String?;
    if (reference == null) {
      Log.warning('Kola billing (Paystack) webhook missing data.reference — ignoring');
      return true;
    }

    final checkout = await _checkouts.findByReference(reference);
    if (checkout == null) {
      // Not every Paystack event on Kola's own account is a subscription
      // checkout (e.g. a stray dashboard test charge) — correctly none
      // of this handler's business.
      Log.info('Kola billing (Paystack) webhook for unknown reference $reference — ignoring');
      return true;
    }

    if (Env.paystackSecretKey.isEmpty) {
      Log.warning('Kola billing (Paystack) webhook received but PAYSTACK_SECRET_KEY is not set — rejecting');
      return false;
    }
    final service = PaystackService(secretKey: Env.paystackSecretKey);
    if (!service.verifyWebhookSignature(rawBody: rawBody, signatureHeader: signatureHeader)) {
      Log.warning('Kola billing (Paystack) webhook signature verification failed for $reference');
      return false;
    }

    final eventType = payload['event'] as String?;
    if (eventType == 'charge.success') {
      await _confirmAndUpgrade(
        gateway: 'paystack',
        checkout: checkout,
        verify: () => service.verifyTransaction(reference),
        extractStatusOk: (data) => data['status'] == 'success',
        extractTransactionId: (data) => data['id']?.toString() ?? '',
        extractPaidAt: (data) =>
            data['paid_at'] != null ? DateTime.parse(data['paid_at'] as String) : DateTime.now(),
      );
    } else if (eventType == 'charge.failed') {
      await _checkouts.markFailed(reference);
    } else {
      Log.info('Kola billing (Paystack) webhook event "$eventType" — no handler, ignoring');
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
      Log.warning('Kola billing (Flutterwave) webhook missing data.tx_ref — ignoring');
      return true;
    }

    final checkout = await _checkouts.findByReference(reference);
    if (checkout == null) {
      Log.info('Kola billing (Flutterwave) webhook for unknown reference $reference — ignoring');
      return true;
    }

    if (Env.flutterwaveSecretKey.isEmpty || Env.flutterwaveWebhookSecretHash.isEmpty) {
      Log.warning(
        'Kola billing (Flutterwave) webhook received but FLUTTERWAVE_SECRET_KEY/'
        'FLUTTERWAVE_WEBHOOK_SECRET_HASH are not both set — rejecting',
      );
      return false;
    }
    final service = FlutterwaveService(secretKey: Env.flutterwaveSecretKey);
    if (!service.verifyWebhookSignature(
      verifHashHeader: verifHashHeader,
      configuredSecretHash: Env.flutterwaveWebhookSecretHash,
    )) {
      Log.warning('Kola billing (Flutterwave) webhook verif-hash mismatch for $reference');
      return false;
    }

    final status = data['status'] as String?;
    if (status == 'successful') {
      final transactionId = data['id'];
      if (transactionId == null) {
        Log.warning('Kola billing (Flutterwave) webhook had no data.id for $reference — cannot verify');
        return true;
      }
      await _confirmAndUpgrade(
        gateway: 'flutterwave',
        checkout: checkout,
        verify: () => service.verifyTransaction(transactionId.toString()),
        extractStatusOk: (d) => d['status'] == 'successful',
        extractTransactionId: (d) => d['id']?.toString() ?? '',
        extractPaidAt: (_) => DateTime.now(),
      );
    } else if (status == 'failed') {
      await _checkouts.markFailed(reference);
    } else {
      Log.info('Kola billing (Flutterwave) webhook status "$status" — no handler, ignoring');
    }
    return true;
  }

  /// Shared confirm-then-upgrade path for both gateways: re-fetches the
  /// transaction from the gateway directly (never trusts the webhook
  /// body's own status/amount fields alone — same posture
  /// payment_webhook_handler.dart uses), marks the checkout completed,
  /// then does the actual upgrade: Workspace.plan/.status AND the
  /// workspace's Subscription row.
  Future<void> _confirmAndUpgrade({
    required String gateway,
    required KolaBillingCheckout checkout,
    required Future<Map<String, dynamic>> Function() verify,
    required bool Function(Map<String, dynamic>) extractStatusOk,
    required String Function(Map<String, dynamic>) extractTransactionId,
    required DateTime Function(Map<String, dynamic>) extractPaidAt,
  }) async {
    final result = await verify();
    final data = result['data'] as Map<String, dynamic>?;
    if (data == null || !extractStatusOk(data)) {
      Log.warning(
        'Kola billing ($gateway) verify did not confirm success for ${checkout.reference} — not upgrading',
      );
      return;
    }

    final paidAt = extractPaidAt(data);
    await _checkouts.markCompleted(
      reference: checkout.reference,
      gatewayTransactionId: extractTransactionId(data),
      paidAt: paidAt,
    );

    final workspaceId = checkout.workspaceId;
    final plan = checkout.plan;

    await _workspaces.setPlanAndStatus(workspaceId: workspaceId, plan: plan, status: 'active');

    final existingSubscription = await _subscriptions.findByWorkspace(workspaceId);
    final periodEnd = paidAt.add(const Duration(days: 30));
    if (existingSubscription == null) {
      await _subscriptions.create(
        workspaceId: workspaceId,
        plan: plan,
        gatewayProvider: gateway,
        currentPeriodStart: paidAt,
        currentPeriodEnd: periodEnd,
        status: 'active',
      );
    } else {
      // Rebuilt explicitly via the constructor, not copyWith — same
      // convention every other repository write in this codebase
      // follows (see e.g. BotEndpoint.updateBot), so this doesn't rely
      // on an unverified assumption about generated-model helpers.
      await _subscriptions.update(
        Subscription(
          id: existingSubscription.id,
          workspaceId: existingSubscription.workspaceId,
          plan: plan,
          gatewayProvider: gateway,
          gatewayCustomerId: existingSubscription.gatewayCustomerId,
          gatewaySubscriptionId: existingSubscription.gatewaySubscriptionId,
          currentPeriodStart: paidAt,
          currentPeriodEnd: periodEnd,
          status: 'active',
          createdAt: existingSubscription.createdAt,
          updatedAt: existingSubscription.updatedAt,
        ),
      );
    }

    Log.success('Workspace upgraded via Kola billing', data: {
      'workspaceId': workspaceId,
      'gateway': gateway,
      'plan': plan,
    });
  }

  Map<String, dynamic>? _tryDecode(String rawBody) {
    try {
      return jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (e) {
      Log.warning('Kola billing webhook body is not valid JSON: $e');
      return null;
    }
  }
}
