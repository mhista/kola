// sale_dto.dart — the till.
//
// Supabase table: sales
// Schema: docs/migrations/035_sales.sql, docs/migrations/039_customer_graph.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class SaleDto extends BaseDto<Sale> {
  const SaleDto();

  @override
  Sale fromRow(Map<String, dynamic> row) {
    return Sale(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      customerId: row['customer_id'] as int?,
      reference: row['reference'] as String,
      clientReference: row['client_reference'] as String?,
      subtotalMinor: row['subtotal_minor'] as int,
      taxRateBps: row['tax_rate_bps'] as int,
      taxMinor: row['tax_minor'] as int,
      totalMinor: row['total_minor'] as int,
      currency: row['currency'] as String,
      paymentMethod: row['payment_method'] as String,
      cashReceivedMinor: row['cash_received_minor'] as int?,
      changeMinor: row['change_minor'] as int?,
      status: row['status'] as String,
      soldAt: DateTime.parse(row['sold_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Sale model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'customer_id': model.customerId,
      'reference': model.reference,
      'client_reference': model.clientReference,
      'subtotal_minor': model.subtotalMinor,
      'tax_rate_bps': model.taxRateBps,
      'tax_minor': model.taxMinor,
      'total_minor': model.totalMinor,
      'currency': model.currency,
      'payment_method': model.paymentMethod,
      'cash_received_minor': model.cashReceivedMinor,
      'change_minor': model.changeMinor,
      'status': model.status,
      'sold_at': model.soldAt.toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
