// payment_gateway_credential_dto.dart
//
// Translates between:
//   Serverpod model  → PaymentGatewayCredential  (generated/payment_gateway_credential.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: payment_gateway_credentials
// Schema: docs/migrations/009_payment_transactions.sql
//
// NOTE: encrypted_secret_key is ciphertext only — see
//       payment_gateway_credential.spy.yaml's header. This DTO never
//       decrypts; that happens one layer up, only when a checkout is
//       actually being initialized.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class PaymentGatewayCredentialDto extends BaseDto<PaymentGatewayCredential> {
  const PaymentGatewayCredentialDto();

  @override
  PaymentGatewayCredential fromRow(Map<String, dynamic> row) {
    return PaymentGatewayCredential(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      gateway: row['gateway'] as String,
      encryptedSecretKey: row['encrypted_secret_key'] as String,
      encryptedWebhookSecret: row['encrypted_webhook_secret'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(
    PaymentGatewayCredential model, {
    bool includeId = false,
  }) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'gateway': model.gateway,
      'encrypted_secret_key': model.encryptedSecretKey,
      'encrypted_webhook_secret': model.encryptedWebhookSecret,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
