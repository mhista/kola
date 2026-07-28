// payment_transaction_repository.dart
//
// All database read/write operations for PaymentTransaction records —
// one row per checkout a bot's "collect payment" Errand initiates. See
// payment_transaction.spy.yaml's header on why holdStatus is bookkeeping
// only, not real fund custody.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/payment_transaction_dto.dart';
import 'supabase_client.dart';

final _log = Logger('PaymentTransactionRepository');

const _dto = PaymentTransactionDto();

class PaymentTransactionRepository {
  const PaymentTransactionRepository();

  /// The one lookup PaymentWebhookHandler actually needs — reference is
  /// globally unique (see the model's own header), so this is enough to
  /// find both the transaction AND, via its workspaceId, which gateway
  /// credential to verify the webhook's signature against.
  Future<PaymentTransaction?> findByReference(String reference) async {
    _log.fine('findByReference($reference)');
    final response = await supabase
        .from('payment_transactions')
        .select()
        .eq('reference', reference)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  Future<PaymentTransaction?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, $workspaceId)');
    final response = await supabase
        .from('payment_transactions')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  Future<PaymentTransaction> create({
    required int workspaceId,
    required String gateway,
    required String reference,
    required int amountKobo,
    required String currency,
    required String customerEmail,
    String? customerPhone,
    int? conversationId,
    int? channelId,
    String? checkoutUrl,
    String? metadataJson,
    String holdStatus = 'notHeld',
  }) async {
    final now = DateTime.now().toUtc();
    _log.info('Creating payment transaction workspaceId=$workspaceId reference=$reference');

    final transaction = PaymentTransaction(
      workspaceId: workspaceId,
      gateway: gateway,
      reference: reference,
      amountKobo: amountKobo,
      currency: currency,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      status: 'pending',
      holdStatus: holdStatus,
      conversationId: conversationId,
      channelId: channelId,
      checkoutUrl: checkoutUrl,
      metadataJson: metadataJson,
      createdAt: now,
      updatedAt: now,
    );

    final row = _dto.toRow(transaction, includeId: false);
    row['created_at'] = now.toIso8601String();

    final response = await supabase
        .from('payment_transactions')
        .insert(row)
        .select()
        .single();
    return _dto.fromRow(response);
  }

  /// Called by PaymentWebhookHandler once a gateway's own verify call has
  /// independently confirmed the payment — never from the webhook payload
  /// alone (see paystack_service.dart/flutterwave_service.dart headers).
  Future<PaymentTransaction> markCompleted({
    required String reference,
    required String gatewayTransactionId,
    required DateTime paidAt,
  }) async {
    _log.info('Marking payment transaction completed reference=$reference');
    final response = await supabase
        .from('payment_transactions')
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

  Future<PaymentTransaction> markFailed(String reference) async {
    _log.info('Marking payment transaction failed reference=$reference');
    final response = await supabase
        .from('payment_transactions')
        .update({
          'status': 'failed',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('reference', reference)
        .select()
        .single();
    return _dto.fromRow(response);
  }

  /// Flips a held transaction to released — PaymentEndpoint.releaseHold's
  /// only job, and it independently re-checks status == 'completed'
  /// before calling this (never trust a caller-supplied precondition).
  Future<PaymentTransaction> releaseHold(int id) async {
    _log.info('Releasing payment hold id=$id');
    final response = await supabase
        .from('payment_transactions')
        .update({
          'hold_status': 'released',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return _dto.fromRow(response);
  }
}
