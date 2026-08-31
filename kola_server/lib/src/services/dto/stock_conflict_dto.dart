// stock_conflict_dto.dart
//
// Translates between:
//   Serverpod model  → StockConflict  (generated/stock_conflict.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: stock_conflicts
// Schema: docs/migrations/060_stock_conflicts.sql (Phase 11g-e).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class StockConflictDto extends BaseDto<StockConflict> {
  const StockConflictDto();

  @override
  StockConflict fromRow(Map<String, dynamic> row) {
    return StockConflict(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      productId: row['product_id'] as int,
      saleId: row['sale_id'] as int?,
      oversoldBy: row['oversold_by'] as int,
      detectedAt: DateTime.parse(row['detected_at'] as String),
      status: row['status'] as String,
      resolvedAt: row['resolved_at'] == null
          ? null
          : DateTime.parse(row['resolved_at'] as String),
      resolvedByEmail: row['resolved_by_email'] as String?,
    );
  }

  @override
  Map<String, dynamic> toRow(StockConflict model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'product_id': model.productId,
      'sale_id': model.saleId,
      'oversold_by': model.oversoldBy,
      'detected_at': model.detectedAt.toIso8601String(),
      'status': model.status,
      'resolved_at': model.resolvedAt?.toIso8601String(),
      'resolved_by_email': model.resolvedByEmail,
    };
  }
}
