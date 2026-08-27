// message_suppression_dto.dart
//
// Translates between:
//   Serverpod model  → MessageSuppression  (generated/message_suppression.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: message_suppressions
// Schema: docs/migrations/049_broadcasts.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class MessageSuppressionDto extends BaseDto<MessageSuppression> {
  const MessageSuppressionDto();

  @override
  MessageSuppression fromRow(Map<String, dynamic> row) {
    return MessageSuppression(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      platform: row['platform'] as String,
      addressNormalized: row['address_normalized'] as String,
      reason: row['reason'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(MessageSuppression model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'platform': model.platform,
      'address_normalized': model.addressNormalized,
      'reason': model.reason,
    };
  }
}
