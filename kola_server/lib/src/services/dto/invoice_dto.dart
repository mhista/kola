// invoice_dto.dart — the A4 invoice.
//
// Supabase table: invoices
// Schema: docs/migrations/047_invoices.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class InvoiceDto extends BaseDto<Invoice> {
  const InvoiceDto();

  @override
  Invoice fromRow(Map<String, dynamic> row) {
    return Invoice(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      customerId: row['customer_id'] as int?,
      saleId: row['sale_id'] as int?,
      reference: row['reference'] as String,
      status: row['status'] as String,
      billToName: row['bill_to_name'] as String,
      billToAddress: row['bill_to_address'] as String?,
      billToPhone: row['bill_to_phone'] as String?,
      linesJson: row['lines_json'] as String,
      subtotalMinor: row['subtotal_minor'] as int,
      taxRateBps: row['tax_rate_bps'] as int,
      taxMinor: row['tax_minor'] as int,
      totalMinor: row['total_minor'] as int,
      paidMinor: row['paid_minor'] as int,
      currency: row['currency'] as String,
      paymentInstructions: row['payment_instructions'] as String?,
      issuedAt: DateTime.parse(row['issued_at'] as String),
      dueAt: row['due_at'] == null ? null : DateTime.parse(row['due_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Invoice model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'customer_id': model.customerId,
      'sale_id': model.saleId,
      'reference': model.reference,
      'status': model.status,
      'bill_to_name': model.billToName,
      'bill_to_address': model.billToAddress,
      'bill_to_phone': model.billToPhone,
      'lines_json': model.linesJson,
      'subtotal_minor': model.subtotalMinor,
      'tax_rate_bps': model.taxRateBps,
      'tax_minor': model.taxMinor,
      'total_minor': model.totalMinor,
      'paid_minor': model.paidMinor,
      'currency': model.currency,
      'payment_instructions': model.paymentInstructions,
      'issued_at': model.issuedAt.toIso8601String(),
      'due_at': model.dueAt?.toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
