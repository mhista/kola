// payment_endpoint.dart
//
// Task #127 / DEVELOPMENT_PLAN.md Phase 8a — "Live payment collection
// Errand (Paystack/Flutterwave) with escrow-style hold option." The
// dashboard/API-facing surface: connect a workspace's OWN gateway
// account, then initialize a checkout against it. See
// payment_gateway_credential.spy.yaml and payment_transaction.spy.yaml's
// headers for the full BYO-credential / bookkeeping-only-escrow
// reasoning — this file is deliberately thin on top of that.
//
// initializeCheckout's ACTUAL LOGIC LIVES IN PaymentCheckoutService
// (task #128) — this method does requireWorkspaceAccess, then
// delegates. That extraction exists because BuiltinErrandExecutor's new
// 'collectPayment' handler needs the exact same logic from an
// AI-orchestrated bot's context, where there is no Session/accessToken
// to check — see payment_checkout_service.dart's header for the full
// reasoning on why auth belongs here and nowhere else.
//
// WHY connectGateway PROBES BEFORE PERSISTING: same "fail loud on a bad
// paste" discipline as ChannelEndpoint.connectTelegramChannel — a wrong
// secret key sitting in the DB looking connected, only to fail at the
// first real checkout, is worse than rejecting it immediately. Paystack
// and Flutterwave both expose a cheap, side-effect-free authenticated
// call: Paystack's "List Banks" endpoint and Flutterwave's own
// equivalent both just need a valid secret key to succeed — reusing
// PaystackService/FlutterwaveService's HTTP wrapper shape for this
// rather than adding a bespoke "ping" method to either.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/payment_gateway_credential_repository.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/billing/payment_checkout_service.dart';
import 'package:kola_server/src/services/billing/paystack_service.dart';
import 'package:kola_server/src/services/billing/flutterwave_service.dart';
import 'package:kola_server/src/services/billing/stripe_service.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/kola_logger.dart';

class PaymentEndpoint extends Endpoint {
  PaymentGatewayCredentialRepository get _credentials =>
      getIt<PaymentGatewayCredentialRepository>();
  PaymentTransactionRepository get _transactions =>
      getIt<PaymentTransactionRepository>();
  PaymentCheckoutService get _checkout => getIt<PaymentCheckoutService>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();

  /// Connects (or rotates) a workspace's OWN Paystack/Flutterwave secret
  /// key. Probes it against the real gateway before persisting anything.
  Future<PaymentGatewayCredential> connectGateway(
    Session session,
    String accessToken,
    int workspaceId,
    String gateway,
    String secretKey, {
    String? webhookSecret,
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    // Closes the gap DESIGN_DELTA.md recorded: this endpoint used to
    // check workspace access and nothing else, so payments.collect
    // being locked did not actually stop a gateway being connected —
    // matching the gate ConnectorEndpoint.connectConnector already
    // applies for every generic-store connector.
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
    }
    if (!await _features.isEnabled(FeatureKeys.payments, workspace)) {
      throw KolaException(
        message:         'Payment collection is not available on this workspace yet.',
      );
    }

    if (!validPaymentGateways.contains(gateway)) {
      throw ArgumentError('gateway must be one of: ${validPaymentGateways.join(", ")}');
    }
    final trimmedKey = secretKey.trim();
    if (trimmedKey.isEmpty) {
      throw const InvalidPaymentGatewayCredentialException('Secret key cannot be empty.');
    }

    // ── Probe against the real gateway before touching the DB ───────────
    try {
      if (gateway == 'paystack') {
        await PaystackService(secretKey: trimmedKey).probe();
      } else if (gateway == 'stripe') {
        // Retrieving the account is Stripe's cheapest authenticated
        // read — it creates nothing, so probing costs the business
        // nothing and cannot leave a stray object behind.
        await StripeService(secretKey: trimmedKey).retrieveAccount();
      } else {
        await FlutterwaveService(secretKey: trimmedKey).probe();
      }
    } catch (e) {
      throw InvalidPaymentGatewayCredentialException(
        'Could not verify this $gateway secret key — double-check it was copied '
        'exactly from your $gateway dashboard, and that it\'s the SECRET key, '
        'not the public key. ($e)',
      );
    }

    final trimmedWebhookSecret = webhookSecret?.trim();
    if (gateway == 'flutterwave' &&
        (trimmedWebhookSecret == null || trimmedWebhookSecret.isEmpty)) {
      Log.warning(
        'Flutterwave connected for workspaceId=$workspaceId with no webhook '
        'secret hash — inbound webhooks for this workspace will fail signature '
        'verification until one is set (see flutterwave_service.dart\'s header).',
      );
    }

    final encrypted = ChannelCredentialEncryptionService.encrypt(trimmedKey);
    final credential = await _credentials.upsert(
      workspaceId: workspaceId,
      gateway: gateway,
      encryptedSecretKey: encrypted,
      encryptedWebhookSecret: (trimmedWebhookSecret == null || trimmedWebhookSecret.isEmpty)
          ? null
          : ChannelCredentialEncryptionService.encrypt(trimmedWebhookSecret),
    );
    Log.success('Payment gateway connected: workspaceId=$workspaceId gateway=$gateway');
    return credential;
  }

  /// Every gateway this workspace has connected (never returns the
  /// decrypted key — this exists so a dashboard can show "Paystack:
  /// connected" without exposing the secret back to any client).
  Future<List<PaymentGatewayCredential>> listConnectedGateways(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _credentials.listByWorkspace(workspaceId);
  }

  /// Starts a checkout against the workspace's OWN connected [gateway]
  /// account. See payment_checkout_service.dart for what actually
  /// happens — this method's only job is the auth check.
  Future<PaymentTransaction> initializeCheckout(
    Session session,
    String accessToken,
    int workspaceId,
    String gateway,
    int amountKobo,
    String customerEmail, {
    String? customerPhone,
    bool holdInEscrow = false,
    int? conversationId,
    int? channelId,
    Map<String, dynamic>? metadata,
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _checkout.initializeCheckout(
      workspaceId: workspaceId,
      gateway: gateway,
      amountKobo: amountKobo,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      holdInEscrow: holdInEscrow,
      conversationId: conversationId,
      channelId: channelId,
      metadata: metadata,
    );
  }

  Future<PaymentTransaction?> getTransaction(
    Session session,
    String accessToken,
    int workspaceId,
    int transactionId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _transactions.findByIdScoped(transactionId, workspaceId);
  }

  /// Flips a held transaction's bookkeeping status to released — see
  /// payment_transaction.spy.yaml's header on why this is NOT a real
  /// fund-movement call. Only valid once the payment itself is
  /// 'completed'; re-checked here even though a caller "should" already
  /// know that, per this codebase's usual "never trust a caller-supplied
  /// precondition" rule (same reasoning as db_credential_errand_executor's
  /// double read-only check).
  Future<PaymentTransaction> releaseHold(
    Session session,
    String accessToken,
    int workspaceId,
    int transactionId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final transaction = await _transactions.findByIdScoped(transactionId, workspaceId);
    if (transaction == null) {
      throw KolaException(message: 'Payment transaction $transactionId not found in workspace $workspaceId');
    }
    if (transaction.status != 'completed') {
      throw KolaException(
        message:         'Cannot release a hold on a transaction that is not completed '
        '(current status: ${transaction.status}).',
      );
    }
    if (transaction.holdStatus != 'held') {
      throw KolaException(
        message:         'Transaction ${transaction.id} has no active hold to release '
        '(current holdStatus: ${transaction.holdStatus}).',
      );
    }
    return _transactions.releaseHold(transactionId);
  }
}

// Both PaystackService.probe() and FlutterwaveService.probe() are now
// real public methods on their own services (Gate 4), reused here and
// by each provider's own ConnectorAdapter.health() — no private
// extensions left to duplicate them.
