// message_dto.dart
//
// Translates between:
//   Serverpod model  → Message  (generated/message.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: messages
// Schema: docs/migrations/006_conversations_and_notifications.sql (source
// of truth — not duplicated here to avoid the two drifting apart over time).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class MessageDto extends BaseDto<Message> {
  const MessageDto();

  @override
  Message fromRow(Map<String, dynamic> row) {
    return Message(
      id: row['id'] as int?,
      conversationId: row['conversation_id'] as int,
      direction: row['direction'] as String,
      senderType: row['sender_type'] as String,
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Message model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'conversation_id': model.conversationId,
      'direction': model.direction,
      'sender_type': model.senderType,
      'body': model.body,
    };
  }
}
