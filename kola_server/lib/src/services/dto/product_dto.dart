// product_dto.dart
//
// Serverpod model ↔ Supabase row for `products` (migration 029).
//
// ── THE NULLS ARE COPIED, NEVER DEFAULTED ────────────────────────────
//
// priceMinor and stock are nullable on both sides and mean something
// specific: "price on request" and "not stock-tracked". The obvious
// convenience here — `row['price_minor'] as int? ?? 0` — would turn a
// service priced on request into a free one, and an untracked product
// into a sold-out one. Both are false facts a customer would act on.
//
// So no `?? 0` appears in this file, and none should be added.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ProductDto extends BaseDto<Product> {
  const ProductDto();

  @override
  Product fromRow(Map<String, dynamic> row) {
    return Product(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      name: row['name'] as String,
      description: row['description'] as String?,
      archetype: row['archetype'] as String,
      sku: row['sku'] as String?,
      tag: row['tag'] as String?,
      // Postgres bigint arrives as int through postgrest-dart; the
      // explicit `as int?` keeps a surprise double from being silently
      // truncated somewhere further downstream instead of failing here.
      priceMinor: row['price_minor'] as int?,
      priceCurrency: row['price_currency'] as String,
      priceUnit: row['price_unit'] as String?,
      costMinor: row['cost_minor'] as int?,
      stock: row['stock'] as int?,
      lowStockThreshold: row['low_stock_threshold'] as int,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Product model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'name': model.name,
      'description': model.description,
      'archetype': model.archetype,
      'sku': model.sku,
      'tag': model.tag,
      'price_minor': model.priceMinor,
      'price_currency': model.priceCurrency,
      'price_unit': model.priceUnit,
      'cost_minor': model.costMinor,
      'stock': model.stock,
      'low_stock_threshold': model.lowStockThreshold,
      'status': model.status,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
