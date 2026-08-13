// kola_billing_service.dart
//
// Task #148 — Kola's OWN SaaS subscription checkout: a workspace paying
// KOLA ₦10,000/month (PlanLimits.paidPlanMonthlyPriceKobo — CONFIRMED
// WITH THE USER 2026-07-27) to upgrade off the free/capped tier.
//
// WHY THIS DOESN'T REUSE PaymentCheckoutService: that file is explicitly
// "start a checkout against a workspace's OWN connected gateway" — it
// looks up a PaymentGatewayCredential row belonging to the WORKSPACE and
// decrypts THAT secret key. This service does the opposite: it always
// uses Kola's OWN Env.paystackSecretKey/flutterwaveSecretKey, because
// the money is flowing TO Kola, not through Kola on a business's
// behalf. See kola_billing_checkout.spy.yaml's header for the full
// reasoning on why these needed a separate table too.
//
// BOTH GATEWAYS AT ONCE, PER THE USER'S OWN CHOICE — the dashboard's
// upgrade flow lets a workspace pick either.

import 'dart:math';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/repository/kola_billing_checkout_repository.dart';
import 'paystack_service.dart';
import 'plan_pricing.dart';
import 'stripe_service.dart';
import 'flutterwave_service.dart';

/// Gateways KOLA'S OWN subscription billing can collect through — not
/// the same list as validPaymentGateways, which is what a BUSINESS may
/// connect for its own customers. These are Kola's accounts.
const validKolaBillingGateways = {'paystack', 'flutterwave', 'stripe'};

class KolaBillingService {
  KolaBillingCheckoutRepository get _checkouts => getIt<KolaBillingCheckoutRepository>();

  /// Starts a checkout for [workspaceId] to upgrade to 'pro'.
  ///
  /// PRICE COMES FROM THE WORKSPACE'S REGION, not a single constant —
  /// see plan_pricing.dart on why Kola prices per region at rough
  /// purchasing-power parity rather than converting one figure.
  ///
  /// [region] is passed in by the caller (which reads it off the
  /// workspace) rather than looked up here, so this service stays
  /// Session-free and testable — the same reason PaymentCheckoutService
  /// takes its inputs rather than fetching them.
  ///
  /// THE SERVER IS AUTHORITATIVE ON PRICE. A client can choose a
  /// gateway; it can never influence the amount.
  Future<KolaBillingCheckout> initiateUpgrade({
    required int workspaceId,
    required String gateway,
    required String customerEmail,
    String region = 'NG',
  }) async {
    if (!validKolaBillingGateways.contains(gateway)) {
      throw ArgumentError(
        'gateway must be one of: ${validKolaBillingGateways.join(", ")}',
      );
    }

    final price = PlanPricing.forRegion(region);

    // Fail here, with a message that says what to do, rather than at the
    // gateway API where the error is opaque. Kola's Paystack account
    // cannot charge a card in Brazil, and Stripe is not the practical
    // choice for naira — the gateway genuinely varies by market.
    if (!PlanPricing.gatewaySupports(gateway, price)) {
      throw ArgumentError(
        'Workspaces in ${price.regionCode} are billed in ${price.currency} '
        'via ${price.gateway}, not $gateway.',
      );
    }

    final amountKobo = price.amountMinor;
    final reference = _generateReference();
    String? checkoutUrl;

    if (gateway == 'paystack') {
      if (Env.paystackSecretKey.isEmpty) {
        throw KolaException(
          code: 'gateway_unconfigured',
          message: 'Paystack is not set up on kola yet, so this cannot be '
              'charged. Nothing was taken from your account.');
      }
      final result = await PaystackService(secretKey: Env.paystackSecretKey).initializeTransaction(
        email: customerEmail,
        amount: amountKobo,
        reference: reference,
        metadata: {'workspaceId': workspaceId, 'purpose': 'kola_subscription', 'plan': 'pro'},
      );
      checkoutUrl = (result['data'] as Map<String, dynamic>?)?['authorization_url'] as String?;
    } else if (gateway == 'stripe') {
      if (Env.stripeSecretKey.isEmpty) {
        throw KolaException(
          code: 'gateway_unconfigured',
          message: 'Stripe is not set up on kola yet, so this cannot be '
              'charged. Nothing was taken from your account.');
      }
      final result = await StripeService(secretKey: Env.stripeSecretKey).createCheckoutSession(
        currency: price.currency,
        amount: amountKobo,
        productName: 'kola Pro — monthly',
        customerEmail: customerEmail,
        clientReferenceId: reference,
        metadata: {
          'workspaceId': workspaceId.toString(),
          'purpose': 'kola_subscription',
          'plan': 'pro',
        },
      );
      checkoutUrl = result['url'] as String?;
    } else {
      if (Env.flutterwaveSecretKey.isEmpty) {
        throw KolaException(
          code: 'gateway_unconfigured',
          message: 'Flutterwave is not set up on kola yet, so this cannot be '
              'charged. Nothing was taken from your account.');
      }
      // Major-unit decimal string — see payment_checkout_service.dart on
      // why this path refuses zero-decimal currencies rather than
      // dividing by 100 and charging 100x.
      if (StripeService.isZeroDecimal(price.currency)) {
        throw ArgumentError(
          '${price.currency} has no minor unit and cannot go through the '
          'Flutterwave path.',
        );
      }
      final amountMajor = (amountKobo / 100).toStringAsFixed(2);
      final result = await FlutterwaveService(secretKey: Env.flutterwaveSecretKey).initializePayment(
        txRef: reference,
        amount: amountMajor,
        redirectUrl: '',
        customerEmail: customerEmail,
        meta: {'workspaceId': workspaceId, 'purpose': 'kola_subscription', 'plan': 'pro'},
      );
      checkoutUrl = (result['data'] as Map<String, dynamic>?)?['link'] as String?;
    }

    final checkout = await _checkouts.create(
      workspaceId: workspaceId,
      gateway: gateway,
      reference: reference,
      amountKobo: amountKobo,
      plan: 'pro',
      checkoutUrl: checkoutUrl,
    );

    Log.success('Kola billing checkout initiated', data: {
      'workspaceId': workspaceId,
      'gateway': gateway,
      'reference': reference,
    });

    return checkout;
  }

  /// Same generation approach as PaymentCheckoutService's own
  /// _generateReference — a distinct 'kola-sub-' prefix (vs. that file's
  /// plain 'kola-' prefix) so a webhook payload's reference alone is
  /// visually distinguishable in logs between "a business's customer
  /// paid them" and "a workspace paid Kola," even though the two never
  /// share a table or a lookup path.
  String _generateReference() {
    final rng = Random.secure();
    final randomHex = List.generate(8, (_) => rng.nextInt(16).toRadixString(16)).join();
    return 'kola-sub-${DateTime.now().millisecondsSinceEpoch}-$randomHex';
  }
}
