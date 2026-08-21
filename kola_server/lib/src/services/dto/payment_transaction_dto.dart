// payment_transaction_dto.dart
//
// Translates between:
//   Serverpod model  → PaymentTransaction  (generated/payment_transaction.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: payment_transactions
// Schema: docs/migrations/009_payment_transactions.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class PaymentTransactionDto extends BaseDto<PaymentTransaction> {
  const PaymentTransactionDto();

  @override
  PaymentTransaction fromRow(Map<String, dynamic> row) {
    return PaymentTransaction(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      gateway: row['gateway'] as String,
      reference: row['reference'] as String,
      amountKobo: row['amount_kobo'] as int,
      currency: row['currency'] as String,
      customerEmail: row['customer_email'] as String,
      customerPhone: row['customer_phone'] as String?,
      // Gate 3 (migration 039).
      customerId: row['customer_id'] as int?,
      status: row['status'] as String,
      holdStatus: row['hold_status'] as String,
      conversationId: row['conversation_id'] as int?,
      channelId: row['channel_id'] as int?,
      checkoutUrl: row['checkout_url'] as String?,
      gatewayTransactionId: row['gateway_transaction_id'] as String?,
      metadataJson: row['metadata_json'] as String?,
      // Migration 022. Defaults keep a pre-migration row's meaning
      // intact: anything recorded before this existed was gateway-verified.
      confirmationMethod:
          (row['confirmation_method'] as String?) ?? 'gateway_verified',
      confirmedBy: row['confirmed_by'] as String?,
      confirmedAt: row['confirmed_at'] == null
          ? null
          : DateTime.parse(row['confirmed_at'] as String),
      proofReference: row['proof_reference'] as String?,
      proofUrl: row['proof_url'] as String?,
      expectedBy: row['expected_by'] == null
          ? null
          : DateTime.parse(row['expected_by'] as String),
      reminderCount: (row['reminder_count'] as int?) ?? 0,
      lastReminderAt: row['last_reminder_at'] == null
          ? null
          : DateTime.parse(row['last_reminder_at'] as String),
      assignedTo: row['assigned_to'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      paidAt: row['paid_at'] == null
          ? null
          : DateTime.parse(row['paid_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(PaymentTransaction model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'gateway': model.gateway,
      'reference': model.reference,
      'amount_kobo': model.amountKobo,
      'currency': model.currency,
      'customer_email': model.customerEmail,
      'customer_phone': model.customerPhone,
      'customer_id': model.customerId,
      'status': model.status,
      'hold_status': model.holdStatus,
      'conversation_id': model.conversationId,
      'channel_id': model.channelId,
      'checkout_url': model.checkoutUrl,
      'gateway_transaction_id': model.gatewayTransactionId,
      'metadata_json': model.metadataJson,
      'confirmation_method': model.confirmationMethod,
      'confirmed_by': model.confirmedBy,
      'confirmed_at': model.confirmedAt?.toIso8601String(),
      'proof_reference': model.proofReference,
      'proof_url': model.proofUrl,
      'expected_by': model.expectedBy?.toIso8601String(),
      'reminder_count': model.reminderCount,
      'last_reminder_at': model.lastReminderAt?.toIso8601String(),
      'assigned_to': model.assignedTo,
      'updated_at': model.updatedAt.toIso8601String(),
      'paid_at': model.paidAt?.toIso8601String(),
    };
  }
}
