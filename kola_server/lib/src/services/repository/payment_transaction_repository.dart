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
    String status = 'pending',
    /// 'gateway_verified' | 'human_marked'. Defaults to verified because
    /// every caller before migration 022 was a gateway path. The manual
    /// path passes 'human_marked' explicitly and can never pass anything
    /// else — see ManualPaymentService.
    String confirmationMethod = 'gateway_verified',
    String? assignedTo,
    DateTime? expectedBy,
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
      status: status,
      holdStatus: holdStatus,
      confirmationMethod: confirmationMethod,
      reminderCount: 0,
      assignedTo: assignedTo,
      expectedBy: expectedBy,
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

  /// Gate 3b — every payment on a customer's unified timeline.
  Future<List<PaymentTransaction>> listByCustomer(int customerId) async {
    _log.fine('listByCustomer($customerId)');
    final response = await supabase
        .from('payment_transactions')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Gate 3 — called from PaymentWebhookHandler._emitPaymentConfirmed
  /// only, i.e. only once a payment has actually confirmed. See
  /// payment_transaction.spy.yaml's header on why identity resolution
  /// waits until then rather than running at checkout-initiation time.
  Future<void> setCustomer(int transactionId, int customerId) async {
    _log.info('setCustomer transactionId=$transactionId customerId=$customerId');
    await supabase
        .from('payment_transactions')
        .update({
          'customer_id': customerId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', transactionId);
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

  /// Records a HUMAN claim that a bank transfer arrived.
  ///
  /// Deliberately separate from [markCompleted], which is only ever
  /// called after a gateway's own verify call independently confirmed
  /// the money moved. Keeping them apart means there is no single method
  /// that can write either kind of confirmation depending on a flag —
  /// the two facts have different weight and different call sites.
  ///
  /// Sets confirmationMethod = 'human_marked' unconditionally. There is
  /// no parameter to override it.
  Future<PaymentTransaction> markHumanConfirmed({
    required int transactionId,
    required String confirmedBy,
    required DateTime confirmedAt,
    String? proofReference,
    String? proofUrl,
  }) async {
    _log.warning('HUMAN-MARKED paid: txn=$transactionId by=$confirmedBy');
    final response = await supabase
        .from('payment_transactions')
        .update({
          'status': 'completed',
          'confirmation_method': 'human_marked',
          'confirmed_by': confirmedBy,
          'confirmed_at': confirmedAt.toIso8601String(),
          'proof_reference': proofReference,
          'proof_url': proofUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', transactionId)
        .select()
        .single();
    return _dto.fromRow(response);
  }

  /// Sets a transaction's status directly. Used by the reminder sweep to
  /// expire an unconfirmed transfer.
  Future<PaymentTransaction> setStatus(int transactionId, String status) async {
    _log.info('setStatus txn=$transactionId status=$status');
    final response = await supabase
        .from('payment_transactions')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', transactionId)
        .select()
        .single();
    return _dto.fromRow(response);
  }

  /// Records that a reminder was sent, advancing the backoff counter.
  Future<void> recordReminderSent(int transactionId, int newCount) async {
    await supabase.from('payment_transactions').update({
      'reminder_count': newCount,
      'last_reminder_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', transactionId);
  }

  /// Every bank transfer still awaiting confirmation, across ALL
  /// workspaces — the reminder sweep needs one query, not one per
  /// workspace. Same precedent as SupportTicketRepository
  /// .listOpenPastDeadline.
  Future<List<PaymentTransaction>> listAwaitingConfirmation() async {
    final response = await supabase
        .from('payment_transactions')
        .select()
        .eq('gateway', 'bank_transfer')
        .eq('status', 'pending');
    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// End-of-day reconciliation: transfers a person marked paid, and
  /// transfers nobody confirmed, for a workspace over a period.
  ///
  /// This is the query that stops errors accumulating silently. Without
  /// it, a wrongly-marked payment is indistinguishable from a real one
  /// forever — and in a payments feature, errors accumulate as money.
  Future<List<PaymentTransaction>> listForReconciliation({
    required int workspaceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await supabase
        .from('payment_transactions')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('gateway', 'bank_transfer')
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String())
        .order('created_at');
    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
