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
      status: row['status'] as String,
      holdStatus: row['hold_status'] as String,
      conversationId: row['conversation_id'] as int?,
      channelId: row['channel_id'] as int?,
      checkoutUrl: row['checkout_url'] as String?,
      gatewayTransactionId: row['gateway_transaction_id'] as String?,
      metadataJson: row['metadata_json'] as String?,
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
      'status': model.status,
      'hold_status': model.holdStatus,
      'conversation_id': model.conversationId,
      'channel_id': model.channelId,
      'checkout_url': model.checkoutUrl,
      'gateway_transaction_id': model.gatewayTransactionId,
      'metadata_json': model.metadataJson,
      'updated_at': model.updatedAt.toIso8601String(),
      'paid_at': model.paidAt?.toIso8601String(),
    };
  }
}
