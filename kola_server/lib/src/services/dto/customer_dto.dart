// customer_dto.dart — Gate 3.
//
// Supabase table: customers
// Schema: docs/migrations/039_customer_graph.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class CustomerDto extends BaseDto<Customer> {
  const CustomerDto();

  @override
  Customer fromRow(Map<String, dynamic> row) {
    return Customer(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      displayName: row['display_name'] as String?,
      firstSeenSource: row['first_seen_source'] as String,
      firstSeenAt: DateTime.parse(row['first_seen_at'] as String),
      mergedIntoId: row['merged_into_id'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Customer model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'display_name': model.displayName,
      'first_seen_source': model.firstSeenSource,
      'first_seen_at': model.firstSeenAt.toIso8601String(),
      'merged_into_id': model.mergedIntoId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
