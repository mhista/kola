// product_media_dto.dart
//
// Serverpod model ↔ Supabase row for `product_media` (migration 031).
//
// Nothing here is computed. Every field is a value ImageKit returned at
// upload and the browser handed back — see product_media.spy.yaml.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ProductMediaDto extends BaseDto<ProductMedia> {
  const ProductMediaDto();

  @override
  ProductMedia fromRow(Map<String, dynamic> row) {
    return ProductMedia(
      id: row['id'] as int?,
      productId: row['product_id'] as int,
      kind: row['kind'] as String,
      imagekitFileId: row['imagekit_file_id'] as String,
      url: row['url'] as String,
      thumbnailUrl: row['thumbnail_url'] as String?,
      width: row['width'] as int?,
      height: row['height'] as int?,
      position: row['position'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(ProductMedia model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'product_id': model.productId,
      'kind': model.kind,
      'imagekit_file_id': model.imagekitFileId,
      'url': model.url,
      'thumbnail_url': model.thumbnailUrl,
      'width': model.width,
      'height': model.height,
      'position': model.position,
    };
  }
}
