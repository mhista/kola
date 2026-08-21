// customer_identity_signal_dto.dart — Gate 3.
//
// Supabase table: customer_identity_signals
// Schema: docs/migrations/039_customer_graph.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class CustomerIdentitySignalDto extends BaseDto<CustomerIdentitySignal> {
  const CustomerIdentitySignalDto();

  @override
  CustomerIdentitySignal fromRow(Map<String, dynamic> row) {
    return CustomerIdentitySignal(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      customerId: row['customer_id'] as int,
      signalType: row['signal_type'] as String,
      normalizedValue: row['normalized_value'] as String,
      source: row['source'] as String,
      sourceRef: row['source_ref'] as String?,
      firstSeenAt: DateTime.parse(row['first_seen_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(CustomerIdentitySignal model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'customer_id': model.customerId,
      'signal_type': model.signalType,
      'normalized_value': model.normalizedValue,
      'source': model.source,
      'source_ref': model.sourceRef,
      'first_seen_at': model.firstSeenAt.toIso8601String(),
    };
  }
}
