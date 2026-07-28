// kola_billing_checkout_dto.dart
//
// Translates between:
//   Serverpod model  → KolaBillingCheckout  (generated/kola_billing_checkout.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: kola_billing_checkouts
// Schema: docs/migrations/015_kola_billing_checkouts.sql (task #148).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class KolaBillingCheckoutDto extends BaseDto<KolaBillingCheckout> {
  const KolaBillingCheckoutDto();

  @override
  KolaBillingCheckout fromRow(Map<String, dynamic> row) {
    return KolaBillingCheckout(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      gateway: row['gateway'] as String,
      reference: row['reference'] as String,
      amountKobo: row['amount_kobo'] as int,
      plan: row['plan'] as String,
      status: row['status'] as String,
      checkoutUrl: row['checkout_url'] as String?,
      gatewayTransactionId: row['gateway_transaction_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      paidAt: row['paid_at'] == null ? null : DateTime.parse(row['paid_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(KolaBillingCheckout model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'gateway': model.gateway,
      'reference': model.reference,
      'amount_kobo': model.amountKobo,
      'plan': model.plan,
      'status': model.status,
      'checkout_url': model.checkoutUrl,
      'gateway_transaction_id': model.gatewayTransactionId,
      'updated_at': model.updatedAt.toIso8601String(),
      'paid_at': model.paidAt?.toIso8601String(),
    };
  }
}
