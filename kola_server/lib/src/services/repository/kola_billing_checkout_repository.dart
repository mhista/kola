// kola_billing_checkout_repository.dart
//
// All database read/write operations for KolaBillingCheckout records
// (task #148). See kola_billing_checkout.spy.yaml's header for why this
// is a separate table/repository from PaymentTransaction/
// PaymentTransactionRepository — different money direction, different
// credential used to verify.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/kola_billing_checkout_dto.dart';
import 'supabase_client.dart';

final _log = Logger('KolaBillingCheckoutRepository');

const _dto = KolaBillingCheckoutDto();

class KolaBillingCheckoutRepository {
  const KolaBillingCheckoutRepository();

  Future<KolaBillingCheckout?> findByReference(String reference) async {
    _log.fine('findByReference($reference)');
    final response = await supabase
        .from('kola_billing_checkouts')
        .select()
        .eq('reference', reference)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  Future<KolaBillingCheckout> create({
    required int workspaceId,
    required String gateway,
    required String reference,
    required int amountKobo,
    required String plan,
    String? checkoutUrl,
  }) async {
    final now = DateTime.now().toUtc();
    _log.info('Creating Kola billing checkout workspaceId=$workspaceId gateway=$gateway plan=$plan');

    final checkout = KolaBillingCheckout(
      workspaceId: workspaceId,
      gateway: gateway,
      reference: reference,
      amountKobo: amountKobo,
      plan: plan,
      status: 'pending',
      checkoutUrl: checkoutUrl,
      gatewayTransactionId: null,
      createdAt: now,
      updatedAt: now,
      paidAt: null,
    );

    final row = _dto.toRow(checkout, includeId: false);
    row['created_at'] = now.toIso8601String();
    final response =
        await supabase.from('kola_billing_checkouts').insert(row).select().single();
    return _dto.fromRow(response);
  }

  Future<KolaBillingCheckout> markCompleted({
    required String reference,
    required String gatewayTransactionId,
    required DateTime paidAt,
  }) async {
    _log.info('markCompleted reference=$reference');
    final response = await supabase
        .from('kola_billing_checkouts')
        .update({
          'status': 'completed',
          'gateway_transaction_id': gatewayTransactionId,
          'paid_at': paidAt.toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('reference', reference)
        .select()
        .single();
    return _dto.fromRow(response);
  }

  /// Every successfully-paid checkout for [workspaceId], newest first —
  /// the Billing page's "Invoices" table. This row IS the workspace's own
  /// Kola-subscription payment history: see this model's header on why
  /// there is no separate "invoice" table for it — `status: 'completed'`
  /// plus `paidAt` is a real, gateway-confirmed payment record, written
  /// only by KolaBillingWebhookHandler after independently re-verifying
  /// with the gateway (never from the webhook body alone).
  ///
  /// Deliberately excludes 'pending'/'failed' rows — an abandoned or
  /// declined checkout is not something the owner paid for, and showing
  /// it in an "Invoices" list would misstate what was actually charged.
  Future<List<KolaBillingCheckout>> listCompletedByWorkspace(
    int workspaceId,
  ) async {
    _log.fine('listCompletedByWorkspace($workspaceId)');
    final response = await supabase
        .from('kola_billing_checkouts')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('status', 'completed')
        .order('paid_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<KolaBillingCheckout> markFailed(String reference) async {
    _log.info('markFailed reference=$reference');
    final response = await supabase
        .from('kola_billing_checkouts')
        .update({
          'status': 'failed',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('reference', reference)
        .select()
        .single();
    return _dto.fromRow(response);
  }
}
