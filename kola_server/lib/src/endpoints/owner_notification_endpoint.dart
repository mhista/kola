// owner_notification_endpoint.dart
//
// Where an owner sets up escalation notifications for their workspace —
// without this, OwnerNotificationSettingsRepository.upsert is
// unreachable from outside the server, and the whole notification
// system built for task #94 has no way to ever get configured. Bare-
// bones on purpose (two methods, no dashboard UI), same "full loop but
// not the full Phase 4 dashboard" scope line as ConversationEndpoint.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/owner_notification_settings_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/kola_logger.dart';

class OwnerNotificationEndpoint extends Endpoint {
  OwnerNotificationSettingsRepository get _settings =>
      getIt<OwnerNotificationSettingsRepository>();

  /// Returns null if the workspace has never configured notification
  /// settings yet — callers should treat that as "every channel
  /// disabled," not an error.
  Future<OwnerNotificationSettings?> getSettings(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _settings.findByWorkspaceId(workspaceId);
  }

  /// Create-or-replace — see OwnerNotificationSettingsRepository.upsert.
  /// Any field left null/false simply disables that channel; there's no
  /// partial-update semantics here on purpose, since a settings form
  /// naturally submits the whole shape at once.
  Future<OwnerNotificationSettings> updateSettings(
    Session session,
    String accessToken,
    int workspaceId, {
    String? ownerEmail,
    bool emailEnabled = false,
    String? ownerWhatsappNumber,
    bool whatsappEnabled = false,
    String? telegramChatId,
    bool telegramEnabled = false,
    String? ownerSmsNumber,
    bool smsEnabled = false,
    // Plaintext in — see ChannelCredentialEncryptionService below.
    // Passing null leaves any previously-stored URL untouched only if
    // slackEnabled is also left false; passing an empty string is
    // treated the same as null (clears the channel).
    String? slackWebhookUrl,
    bool slackEnabled = false,
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final trimmedSlackUrl = slackWebhookUrl?.trim();
    final encryptedSlackWebhookUrl = (trimmedSlackUrl == null || trimmedSlackUrl.isEmpty)
        ? null
        : ChannelCredentialEncryptionService.encrypt(trimmedSlackUrl);

    final updated = await _settings.upsert(
      workspaceId: workspaceId,
      ownerEmail: ownerEmail,
      emailEnabled: emailEnabled,
      ownerWhatsappNumber: ownerWhatsappNumber,
      whatsappEnabled: whatsappEnabled,
      telegramChatId: telegramChatId,
      telegramEnabled: telegramEnabled,
      ownerSmsNumber: ownerSmsNumber,
      smsEnabled: smsEnabled,
      encryptedSlackWebhookUrl: encryptedSlackWebhookUrl,
      slackEnabled: slackEnabled,
    );

    Log.success(
      'Owner notification settings updated',
      data: {'workspaceId': workspaceId},
      session: session,
    );

    return updated;
  }
}
