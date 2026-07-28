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

const validPaymentGateways = {'paystack', 'flutterwave'};

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
    if (amountKobo <= 0) {
      throw ArgumentError('amountKobo must be positive');
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
      currency: 'NGN',
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
