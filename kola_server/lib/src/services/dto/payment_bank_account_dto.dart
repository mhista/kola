// payment_bank_account_dto.dart
//
// Serverpod PaymentBankAccount ↔ Supabase `payment_bank_accounts` row.
// Schema: docs/migrations/022_manual_payments.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class PaymentBankAccountDto extends BaseDto<PaymentBankAccount> {
  const PaymentBankAccountDto();

  @override
  PaymentBankAccount fromRow(Map<String, dynamic> row) {
    return PaymentBankAccount(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      bankName: row['bank_name'] as String,
      accountNumber: row['account_number'] as String,
      accountName: row['account_name'] as String,
      currency: row['currency'] as String,
      // Defaults to NOT verified. If the column were ever missing, the
      // safe reading is "do not share this", never "share it".
      isVerified: (row['is_verified'] as bool?) ?? false,
      isActive: (row['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(PaymentBankAccount model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'bank_name': model.bankName,
      'account_number': model.accountNumber,
      'account_name': model.accountName,
      'currency': model.currency,
      'is_verified': model.isVerified,
      'is_active': model.isActive,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
