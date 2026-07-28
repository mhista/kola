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
import 'plan_limits.dart';
import 'paystack_service.dart';
import 'flutterwave_service.dart';

const validKolaBillingGateways = {'paystack', 'flutterwave'};

class KolaBillingService {
  KolaBillingCheckoutRepository get _checkouts => getIt<KolaBillingCheckoutRepository>();

  /// Starts a checkout for [workspaceId] to upgrade to 'pro'. Always
  /// prices at [PlanLimits.paidPlanMonthlyPriceKobo] — there is exactly
  /// one paid plan/price today, so there's nothing for a caller to get
  /// wrong here yet (a second tier would add a [plan] param, not change
  /// this method's shape).
  Future<KolaBillingCheckout> initiateUpgrade({
    required int workspaceId,
    required String gateway,
    required String customerEmail,
  }) async {
    if (!validKolaBillingGateways.contains(gateway)) {
      throw ArgumentError(
        'gateway must be one of: ${validKolaBillingGateways.join(", ")}',
      );
    }

    final amountKobo = PlanLimits.paidPlanMonthlyPriceKobo;
    final reference = _generateReference();
    String? checkoutUrl;

    if (gateway == 'paystack') {
      if (Env.paystackSecretKey.isEmpty) {
        throw Exception('Paystack is not configured on this server yet.');
      }
      final result = await PaystackService(secretKey: Env.paystackSecretKey).initializeTransaction(
        email: customerEmail,
        amount: amountKobo,
        reference: reference,
        metadata: {'workspaceId': workspaceId, 'purpose': 'kola_subscription', 'plan': 'pro'},
      );
      checkoutUrl = (result['data'] as Map<String, dynamic>?)?['authorization_url'] as String?;
    } else {
      if (Env.flutterwaveSecretKey.isEmpty) {
        throw Exception('Flutterwave is not configured on this server yet.');
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
