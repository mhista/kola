// conversation_dto.dart
//
// Translates between:
//   Serverpod model  → Conversation  (generated/conversation.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: conversations
// Schema: docs/migrations/006_conversations_and_notifications.sql (source
// of truth — not duplicated here to avoid the two drifting apart over time).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ConversationDto extends BaseDto<Conversation> {
  const ConversationDto();

  @override
  Conversation fromRow(Map<String, dynamic> row) {
    return Conversation(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      botId: row['bot_id'] as int,
      channelId: row['channel_id'] as int,
      platformType: row['platform_type'] as String,
      externalUserId: row['external_user_id'] as String,
      displayName: row['display_name'] as String?,
      status: row['status'] as String,
      // Gate 3 (migration 039).
      customerId: row['customer_id'] as int?,
      // Gate 10 (migration 050).
      broadcastId: row['broadcast_id'] as int?,
      lastMessageAt: DateTime.parse(row['last_message_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Conversation model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'bot_id': model.botId,
      'channel_id': model.channelId,
      'platform_type': model.platformType,
      'external_user_id': model.externalUserId,
      'display_name': model.displayName,
      'status': model.status,
      'customer_id': model.customerId,
      'broadcast_id': model.broadcastId,
      'last_message_at': model.lastMessageAt.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
