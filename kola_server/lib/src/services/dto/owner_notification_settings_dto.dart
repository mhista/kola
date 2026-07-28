// owner_notification_settings_dto.dart
//
// Translates between:
//   Serverpod model  → OwnerNotificationSettings  (generated/owner_notification_settings.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: owner_notification_settings
// Schema: docs/migrations/006_conversations_and_notifications.sql,
// plus encrypted_slack_webhook_url/slack_enabled added in
// docs/migrations/010_slack_owner_notifications.sql (task #129).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class OwnerNotificationSettingsDto extends BaseDto<OwnerNotificationSettings> {
  const OwnerNotificationSettingsDto();

  @override
  OwnerNotificationSettings fromRow(Map<String, dynamic> row) {
    return OwnerNotificationSettings(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      ownerEmail: row['owner_email'] as String?,
      emailEnabled: row['email_enabled'] as bool,
      ownerWhatsappNumber: row['owner_whatsapp_number'] as String?,
      whatsappEnabled: row['whatsapp_enabled'] as bool,
      telegramChatId: row['telegram_chat_id'] as String?,
      telegramEnabled: row['telegram_enabled'] as bool,
      ownerSmsNumber: row['owner_sms_number'] as String?,
      smsEnabled: row['sms_enabled'] as bool,
      encryptedSlackWebhookUrl: row['encrypted_slack_webhook_url'] as String?,
      slackEnabled: row['slack_enabled'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(OwnerNotificationSettings model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'owner_email': model.ownerEmail,
      'email_enabled': model.emailEnabled,
      'owner_whatsapp_number': model.ownerWhatsappNumber,
      'whatsapp_enabled': model.whatsappEnabled,
      'telegram_chat_id': model.telegramChatId,
      'telegram_enabled': model.telegramEnabled,
      'owner_sms_number': model.ownerSmsNumber,
      'sms_enabled': model.smsEnabled,
      'encrypted_slack_webhook_url': model.encryptedSlackWebhookUrl,
      'slack_enabled': model.slackEnabled,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
