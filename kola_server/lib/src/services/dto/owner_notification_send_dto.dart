// owner_notification_send_dto.dart
//
// Translates between:
//   Serverpod model  → OwnerNotificationSend  (generated/owner_notification_send.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: owner_notification_sends
// Schema: docs/migrations/006_conversations_and_notifications.sql.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class OwnerNotificationSendDto extends BaseDto<OwnerNotificationSend> {
  const OwnerNotificationSendDto();

  @override
  OwnerNotificationSend fromRow(Map<String, dynamic> row) {
    return OwnerNotificationSend(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      channel: row['channel'] as String,
      sentAt: DateTime.parse(row['sent_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(OwnerNotificationSend model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'channel': model.channel,
      'sent_at': model.sentAt.toIso8601String(),
    };
  }
}
