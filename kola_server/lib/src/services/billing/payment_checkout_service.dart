// payment_checkout_service.dart
//
// Task #128 — the core "start a checkout against a workspace's OWN
// connected gateway" logic, extracted out of PaymentEndpoint.
// initializeCheckout so it has exactly ONE caller-agnostic home. Two
// callers use this now:
//   - PaymentEndpoint.initializeCheckout — the dashboard/API-facing
//     surface, which does requireWorkspaceAccess FIRST, then delegates
//     here. Auth belongs there, not in this file.
//   - BuiltinErrandExecutor's 'collectPayment' handler — an
//     AI-orchestrated bot mid-conversation. There is no Session/
//     accessToken in that context, and there shouldn't need to be one:
//     the bot is already running inside a specific, already-resolved
//     workspace (see builtin_errand_executor.dart's new typedef), so
//     re-deriving an access-token check here would be checking a
//     credential that was never collected in the first place, not a
//     missing security boundary.
//
// Everything below is copied, not reinvented, from what
// PaymentEndpoint.initializeCheckout already did correctly — see
// payment_gateway_credential.spy.yaml / payment_transaction.spy.yaml
// for the full BYO-credential / bookkeeping-only-escrow reasoning this
// service's behavior depends on.

import 'dart:convert';
import 'dart:math';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/payment_gateway_credential_repository.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/billing/trial_state_machine.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'paystack_service.dart';
import 'flutterwave_service.dart';
import 'stripe_service.dart';

/// Every gateway a business may CONNECT (see PaymentEndpoint.connectGateway).
/// NOT the same claim as "every gateway kolaa can INITIATE a checkout
/// against" — see [checkoutSupportedGateways] below for that narrower
/// set. Monnify is a real example of the difference: connectable (Gate
/// 11 breadth — sync existing transactions into the graph) but not yet
/// checkout-capable (see monnify_service.dart's header on why that's a
/// deliberate scope cut, not a bug).
///
/// THIS IS THE ONE LIST TO EXTEND when adding another CONNECTABLE
/// gateway. It is mirrored by a CHECK constraint in the database
/// (migration 020, widened again by 051 for Monnify) — both must move
/// together, and the constraint is deliberately kept rather than dropped
/// so a typo ('stipe') fails at connect time rather than at charge time
/// in front of a customer.
const validPaymentGateways = {'paystack', 'flutterwave', 'stripe', 'monnify', 'fincra'};

/// The subset of [validPaymentGateways] this service can actually
/// INITIATE a checkout against. A gateway can be connectable (its
/// transactions sync into the graph) without being checkout-capable yet
/// — see [validPaymentGateways]'s own doc. [initializeCheckout] checks
/// this SEPARATELY from [validPaymentGateways], so adding a fifth
/// connect-only gateway later can extend the wider set without silently
/// also making it a checkout option nobody built.
const checkoutSupportedGateways = {'paystack', 'flutterwave', 'stripe'};

/// Thrown when a checkout is requested against a gateway the workspace
/// hasn't connected yet — lets both callers (PaymentEndpoint, the
/// collectPayment Errand handler) show a clear message instead of a
/// generic 500 or a raw null-check failure.
class InvalidPaymentGatewayCredentialException implements Exception {
  final String message;
  const InvalidPaymentGatewayCredentialException(this.message);

  @override
  String toString() => 'InvalidPaymentGatewayCredentialException: $message';
}

class PaymentCheckoutService {
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  PaymentGatewayCredentialRepository get _credentials =>
      getIt<PaymentGatewayCredentialRepository>();
  PaymentTransactionRepository get _transactions => getIt<PaymentTransactionRepository>();
  TrialStateMachine get _trialStateMachine => getIt<TrialStateMachine>();

  /// See this file's header — callers are responsible for their own
  /// auth/workspace-access check BEFORE calling this; it does none
  /// itself, only the workspace-STATE check (paused) that applies
  /// regardless of who's calling.
  Future<PaymentTransaction> initializeCheckout({
    required int workspaceId,
    required String gateway,
    required int amountKobo,
    required String customerEmail,
    /// ISO-4217. Defaults to NGN so every existing caller keeps its
    /// current, correct behaviour — this service was implicitly
    /// Nigeria-only before Stripe was added.
    ///
    /// NOTE the parameter is still named `amountKobo` for source
    /// compatibility, but it means "amount in the currency's smallest
    /// unit". For most currencies that is 1/100; for JPY, KRW, XOF and
    /// the rest of StripeService.zeroDecimalCurrencies there is no minor
    /// unit and the value IS whole units.
    String currency = 'NGN',
    /// Shown to the customer on the hosted checkout page. Stripe
    /// requires a product name; the others ignore it.
    String? description,
    String? customerPhone,
    bool holdInEscrow = false,
    int? conversationId,
    int? channelId,
    Map<String, dynamic>? metadata,
  }) async {
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw Exception('Workspace $workspaceId not found');
    }
    if (_trialStateMachine.effectiveTier(workspace) == EffectiveTier.paused) {
      throw Exception(
        'This workspace is paused (trial ended, not yet paid) — payment '
        'collection is unavailable until the workspace is reactivated.',
      );
    }

    if (!validPaymentGateways.contains(gateway)) {
      throw ArgumentError('gateway must be one of: ${validPaymentGateways.join(", ")}');
    }
    // Separate from the check above on purpose — see
    // checkoutSupportedGateways' own doc comment. A connectable-but-not-
    // checkout-capable gateway (Monnify, today) must fail with a clear
    // "not supported for checkout yet" message here, NOT fall through
    // into the if/else chain below and get silently routed through
    // whichever branch's `else` happens to catch it.
    if (!checkoutSupportedGateways.contains(gateway)) {
      throw ArgumentError(
        '$gateway is connected for syncing existing transactions, but kolaa cannot '
        'yet generate a $gateway checkout link. Supported for checkout: '
        '${checkoutSupportedGateways.join(", ")}.',
      );
    }
    if (amountKobo <= 0) {
      throw ArgumentError('amountKobo must be positive');
    }

    // Flutterwave is given a MAJOR-unit decimal string, which means
    // dividing by 100 — valid only for currencies that actually have two
    // minor digits. Refusing here beats charging a customer 100x, which
    // is what silently dividing a zero-decimal amount would do.
    if (gateway == 'flutterwave' && StripeService.isZeroDecimal(currency)) {
      throw ArgumentError(
        '$currency has no minor unit, and the Flutterwave path converts '
        'from minor units by dividing by 100. Use a different gateway for '
        'this currency rather than risking a 100x charge.',
      );
    }

    final credential = await _credentials.findByWorkspaceAndGateway(workspaceId, gateway);
    if (credential == null) {
      throw InvalidPaymentGatewayCredentialException(
        'Workspace $workspaceId has not connected a $gateway account yet — '
        'call PaymentEndpoint.connectGateway first.',
      );
    }
    final secretKey = ChannelCredentialEncryptionService.decrypt(credential.encryptedSecretKey);

    final reference = _generateReference();
    String? checkoutUrl;

    if (gateway == 'paystack') {
      final result = await PaystackService(secretKey: secretKey).initializeTransaction(
        email: customerEmail,
        amount: amountKobo,
        reference: reference,
        metadata: metadata,
      );
      checkoutUrl = (result['data'] as Map<String, dynamic>?)?['authorization_url'] as String?;
    } else if (gateway == 'stripe') {
      // Stripe takes the smallest unit like Paystack does, so no
      // conversion here — but "smallest unit" is NOT always 1/100. JPY,
      // KRW, XOF and others have no minor unit at all, and treating one
      // of those as two-decimal charges the customer 100x. Callers
      // supplying a zero-decimal currency must pass whole units; see
      // StripeService.zeroDecimalCurrencies.
      final result = await StripeService(secretKey: secretKey).createCheckoutSession(
        currency: currency,
        amount: amountKobo,
        productName: description ?? 'Payment',
        customerEmail: customerEmail,
        clientReferenceId: reference,
        metadata: metadata?.map((k, v) => MapEntry(k, v.toString())),
      );
      checkoutUrl = result['url'] as String?;
    } else {
      // Flutterwave wants a major-unit decimal string, not kobo — see
      // flutterwave_service.dart's header. NGN has 2 minor-unit digits,
      // the same assumption PaystackService's own kobo convention makes.
      final amountMajor = (amountKobo / 100).toStringAsFixed(2);
      final result = await FlutterwaveService(secretKey: secretKey).initializePayment(
        txRef: reference,
        amount: amountMajor,
        redirectUrl: '', // Standard flow shows Flutterwave's own success page if empty.
        customerEmail: customerEmail,
        customerPhoneNumber: customerPhone,
        meta: metadata,
      );
      checkoutUrl = (result['data'] as Map<String, dynamic>?)?['link'] as String?;
    }

    final transaction = await _transactions.create(
      workspaceId: workspaceId,
      gateway: gateway,
      reference: reference,
      amountKobo: amountKobo,
      currency: currency,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      conversationId: conversationId,
      channelId: channelId,
      checkoutUrl: checkoutUrl,
      metadataJson: metadata == null ? null : jsonEncode(metadata),
      holdStatus: holdInEscrow ? 'held' : 'notHeld',
    );
    Log.success('Checkout initialized: workspaceId=$workspaceId reference=$reference');
    return transaction;
  }

  /// Same generation as PaymentEndpoint used before this extraction —
  /// kept identical rather than "improved," since there was nothing
  /// wrong with it and changing it here for no reason would just be
  /// churn. Real uniqueness is enforced by the database's own unique
  /// index on payment_transactions.reference (see that model's header);
  /// this only needs to avoid an obviously-guessable value, not provide
  /// credential-grade randomness.
  String _generateReference() {
    final rng = Random.secure();
    final randomHex = List.generate(8, (_) => rng.nextInt(16).toRadixString(16)).join();
    return 'kola-${DateTime.now().millisecondsSinceEpoch}-$randomHex';
  }
}
