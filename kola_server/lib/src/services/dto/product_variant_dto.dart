// product_variant_dto.dart
//
// Serverpod model ↔ Supabase row for `product_variants` (migration 029).
//
// priceMinor null means INHERIT THE PARENT, which is a different null
// from Product.priceMinor's "on request" — see product_variant.spy.yaml.
// Neither is resolved here. A DTO that quietly substituted the parent's
// price would make it impossible to tell a variant that was deliberately
// left to inherit from one that was priced identically by hand, and the
// first is something the owner can change in one place.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ProductVariantDto extends BaseDto<ProductVariant> {
  const ProductVariantDto();

  @override
  ProductVariant fromRow(Map<String, dynamic> row) {
    return ProductVariant(
      id: row['id'] as int?,
      productId: row['product_id'] as int,
      label: row['label'] as String,
      sku: row['sku'] as String?,
      priceMinor: row['price_minor'] as int?,
      stock: row['stock'] as int?,
      position: row['position'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(ProductVariant model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'product_id': model.productId,
      'label': model.label,
      'sku': model.sku,
      'price_minor': model.priceMinor,
      'stock': model.stock,
      'position': model.position,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
