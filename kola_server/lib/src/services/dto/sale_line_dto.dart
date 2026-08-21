// sale_line_dto.dart — the till.
//
// Supabase table: sale_lines
// Schema: docs/migrations/035_sales.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class SaleLineDto extends BaseDto<SaleLine> {
  const SaleLineDto();

  @override
  SaleLine fromRow(Map<String, dynamic> row) {
    return SaleLine(
      id: row['id'] as int?,
      saleId: row['sale_id'] as int,
      productId: row['product_id'] as int?,
      name: row['name'] as String,
      unitPriceMinor: row['unit_price_minor'] as int,
      quantity: row['quantity'] as int,
      lineTotalMinor: row['line_total_minor'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(SaleLine model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'sale_id': model.saleId,
      'product_id': model.productId,
      'name': model.name,
      'unit_price_minor': model.unitPriceMinor,
      'quantity': model.quantity,
      'line_total_minor': model.lineTotalMinor,
    };
  }
}
