// broadcast_recipient_dto.dart
//
// Translates between:
//   Serverpod model  → BroadcastRecipient  (generated/broadcast_recipient.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: broadcast_recipients
// Schema: docs/migrations/049_broadcasts.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class BroadcastRecipientDto extends BaseDto<BroadcastRecipient> {
  const BroadcastRecipientDto();

  @override
  BroadcastRecipient fromRow(Map<String, dynamic> row) {
    return BroadcastRecipient(
      id: row['id'] as int?,
      broadcastId: row['broadcast_id'] as int,
      workspaceId: row['workspace_id'] as int,
      to: row['to'] as String,
      customerId: row['customer_id'] as int?,
      variablesJson: row['variables_json'] as String?,
      state: row['state'] as String,
      attemptCount: row['attempt_count'] as int,
      lastError: row['last_error'] as String?,
      messageId: row['message_id'] as int?,
      lastAttemptedAt:
          row['last_attempted_at'] == null ? null : DateTime.parse(row['last_attempted_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(BroadcastRecipient model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'broadcast_id': model.broadcastId,
      'workspace_id': model.workspaceId,
      'to': model.to,
      'customer_id': model.customerId,
      'variables_json': model.variablesJson,
      'state': model.state,
      'attempt_count': model.attemptCount,
      'last_error': model.lastError,
      'message_id': model.messageId,
      'last_attempted_at': model.lastAttemptedAt?.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
