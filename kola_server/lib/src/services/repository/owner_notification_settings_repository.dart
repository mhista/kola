// owner_notification_settings_repository.dart
//
// All database read/write operations for OwnerNotificationSettings — one
// row per workspace (1:1, enforced by a unique index — see
// owner_notification_settings.spy.yaml).

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/owner_notification_settings_dto.dart';
import 'supabase_client.dart';

final _log = Logger('OwnerNotificationSettingsRepository');

const _dto = OwnerNotificationSettingsDto();

class OwnerNotificationSettingsRepository {
  const OwnerNotificationSettingsRepository();

  Future<OwnerNotificationSettings?> findByWorkspaceId(int workspaceId) async {
    _log.fine('findByWorkspaceId($workspaceId)');
    final response = await supabase
        .from('owner_notification_settings')
        .select()
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Create-or-replace — the right call for a settings form, since the
  /// owner editing their notification preferences should never need to
  /// know whether a row already exists yet.
  Future<OwnerNotificationSettings> upsert({
    required int workspaceId,
    String? ownerEmail,
    bool emailEnabled = false,
    String? ownerWhatsappNumber,
    bool whatsappEnabled = false,
    String? telegramChatId,
    bool telegramEnabled = false,
    String? ownerSmsNumber,
    bool smsEnabled = false,
    String? encryptedSlackWebhookUrl,
    bool slackEnabled = false,
  }) async {
    _log.info('Upserting owner notification settings workspaceId=$workspaceId');
    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('owner_notification_settings')
        .upsert({
          'workspace_id': workspaceId,
          'owner_email': ownerEmail,
          'email_enabled': emailEnabled,
          'owner_whatsapp_number': ownerWhatsappNumber,
          'whatsapp_enabled': whatsappEnabled,
          'telegram_chat_id': telegramChatId,
          'telegram_enabled': telegramEnabled,
          'owner_sms_number': ownerSmsNumber,
          'sms_enabled': smsEnabled,
          'encrypted_slack_webhook_url': encryptedSlackWebhookUrl,
          'slack_enabled': slackEnabled,
          'updated_at': now.toIso8601String(),
        }, onConflict: 'workspace_id')
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
