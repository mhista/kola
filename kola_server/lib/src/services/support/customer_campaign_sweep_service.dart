// customer_campaign_sweep_service.dart
//
// Task #132 / Phase 8b's other half: actually sending the birthday/
// anniversary greeting a CustomerProfile's saved date implies. Same
// "sweep + act, wired into server.dart on a plain Timer" shape as
// trial_sweep_service.dart / channel_health_check_service.dart /
// support_ticket_sla_sweep_service.dart — DAILY, not hourly (see
// server.dart's own wiring comment): a birthday only needs day-
// granularity detection, unlike an SLA deadline or a trial window.
//
// WHATSAPP — TASK #155, NO LONGER SKIPPED: a birthday ping is business-
// initiated, not a reply inside WhatsApp's open 24h customer-service
// window, so it genuinely needs a pre-approved Meta message template
// (unlike Telegram, which has no such restriction and could always just
// send free text — see below). This service now gets or creates that
// template PER CHANNEL, per greeting kind, via
// WhatsAppTemplateCreationService (task #150/#154's shared submission
// path), and only actually sends once Meta has approved it:
//   - No template row yet for this channel+kind → submit one now (see
//     _sendWhatsAppGreeting below), mark nothing sent this run (Meta's
//     review takes minutes to days — see whatsapp_template_service.dart),
//     and wait for a future sweep to find it approved.
//   - A pending/rejected one already exists → don't resubmit every day;
//     just keep waiting (or stay silently unsent on rejection — a
//     rejected auto-submitted template is a configuration gap worth
//     noticing in logs, not something this sweep can fix on its own).
//   - An approved one exists → send it via WhatsAppService.sendTemplate
//     and mark the greeting sent, same bookkeeping Telegram's path uses.
// TELEGRAM STILL HAS NO EQUIVALENT RESTRICTION — a bot may message any
// user who has ever started a chat with it, no template/window
// requirement, so it keeps sending plain text, no template involved.
//
// GENERIC MESSAGE TEXT, NOT PER-WORKSPACE-CUSTOMIZABLE — v1 sends a
// fixed template with only the workspace's own name substituted in. A
// real "compose your own birthday message" setting is a natural v2, not
// guessed at here. Both platforms share the same generic wording.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/customer_profile_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/whatsapp_message_template_repository.dart';
import 'package:kola_server/src/services/messaging/telegram/telegram_bot_registry.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_template_creation_service.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_credential.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_service.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';

class CustomerCampaignSweepService {
  CustomerCampaignSweepService({
    required CustomerProfileRepository profiles,
    required ConversationRepository conversations,
    required WorkspaceRepository workspaces,
    required ChannelRepository channels,
    required WhatsAppMessageTemplateRepository whatsAppTemplateRepo,
    required WhatsAppTemplateCreationService whatsAppTemplates,
  }) : _profiles = profiles,
       _conversations = conversations,
       _workspaces = workspaces,
       _channels = channels,
       _whatsAppTemplateRepo = whatsAppTemplateRepo,
       _whatsAppTemplates = whatsAppTemplates;

  final CustomerProfileRepository _profiles;
  final ConversationRepository _conversations;
  final WorkspaceRepository _workspaces;
  final ChannelRepository _channels;
  final WhatsAppMessageTemplateRepository _whatsAppTemplateRepo;
  final WhatsAppTemplateCreationService _whatsAppTemplates;

  /// Checks every profile with a saved date and sends a greeting for
  /// any birthday/anniversary that lands on [now]'s month+day and
  /// hasn't already been greeted this year. Per-profile try/catch: one
  /// bad row (a deleted conversation, a send failure) must never stop
  /// the rest of the sweep. Returns how many greetings actually went
  /// out this run.
  Future<int> sweepOnce({DateTime? now}) async {
    final n = (now ?? DateTime.now()).toUtc();
    final profiles = await _profiles.listWithUpcomingDates();

    var sent = 0;
    for (final profile in profiles) {
      try {
        if (await _maybeSend(profile, isBirthday: true, date: profile.birthday, now: n)) {
          sent++;
        }
        if (await _maybeSend(profile, isBirthday: false, date: profile.anniversary, now: n)) {
          sent++;
        }
      } catch (e) {
        Log.error('CustomerCampaignSweepService: failed for profile ${profile.id}', error: e);
      }
    }
    return sent;
  }

  Future<bool> _maybeSend(
    CustomerProfile profile, {
    required bool isBirthday,
    required DateTime? date,
    required DateTime now,
  }) async {
    if (date == null) return false;
    if (date.month != now.month || date.day != now.day) return false;

    final lastSentYear =
        isBirthday ? profile.lastBirthdayGreetingYear : profile.lastAnniversaryGreetingYear;
    if (lastSentYear == now.year) return false; // already greeted this year

    final conversation = await _conversations.findByIdScoped(profile.conversationId, profile.workspaceId);
    if (conversation == null) {
      Log.warning('CustomerCampaignSweepService: profile ${profile.id} has no conversation ${profile.conversationId} — skipping');
      return false;
    }

    final workspace = await _workspaces.findById(profile.workspaceId);
    final businessName = (workspace?.name.isNotEmpty ?? false) ? workspace!.name : 'us';

    if (conversation.platformType == 'telegram') {
      return _sendTelegramGreeting(
        conversation: conversation,
        profile: profile,
        isBirthday: isBirthday,
        businessName: businessName,
        now: now,
      );
    }

    if (conversation.platformType == 'whatsapp') {
      return _sendWhatsAppGreeting(
        conversation: conversation,
        profile: profile,
        isBirthday: isBirthday,
        businessName: businessName,
        now: now,
      );
    }

    Log.warning(
      'CustomerCampaignSweepService: unrecognized platformType "${conversation.platformType}" '
      'for conversation ${conversation.id} — skipping',
    );
    return false;
  }

  Future<bool> _sendTelegramGreeting({
    required Conversation conversation,
    required CustomerProfile profile,
    required bool isBirthday,
    required String businessName,
    required DateTime now,
  }) async {
    final adapter = TelegramBotRegistry.instance.messagingFor(conversation.channelId);
    if (adapter == null) return false;

    final message = _greetingText(isBirthday: isBirthday, businessName: businessName);
    final result = await adapter.sendText(recipient: conversation.externalUserId, text: message);
    if (!result.success) {
      Log.warning(
        'CustomerCampaignSweepService: Telegram send failed for conversation ${conversation.id}: ${result.errorMessage}',
      );
      return false;
    }

    if (profile.id != null) {
      await _profiles.markGreetingSent(profile.id!, isBirthday: isBirthday, year: now.year);
    }
    Log.info(
      'CustomerCampaignSweepService: sent ${isBirthday ? "birthday" : "anniversary"} '
      'greeting for conversation ${conversation.id} (Telegram)',
    );
    return true;
  }

  /// See this file's header — WhatsApp needs a Meta-approved template
  /// for a proactive send like this, so this method's first job on any
  /// given channel is making sure one exists, and only sends once Meta
  /// has actually approved it.
  Future<bool> _sendWhatsAppGreeting({
    required Conversation conversation,
    required CustomerProfile profile,
    required bool isBirthday,
    required String businessName,
    required DateTime now,
  }) async {
    final channel = await _channels.findById(conversation.channelId);
    if (channel == null || channel.status != 'connected' || channel.encryptedCredential == null) {
      Log.info(
        'CustomerCampaignSweepService: WhatsApp channel ${conversation.channelId} not connected — skipping greeting',
      );
      return false;
    }

    final label = isBirthday ? 'birthday_greeting' : 'anniversary_greeting';
    final existing = await _whatsAppTemplateRepo.listByChannel(channel.id!);
    final matches = existing.where((t) => t.metaTemplateName.startsWith(label)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    WhatsAppMessageTemplate? approved;
    for (final t in matches) {
      if (t.status == 'approved') {
        approved = t;
        break;
      }
    }

    if (approved == null) {
      if (matches.isNotEmpty) {
        // Already submitted (pending or rejected) — don't resubmit every
        // sweep. A rejected one staying rejected forever is a real
        // configuration gap, but re-trying automatically with the same
        // wording would just be rejected again; surfacing it in logs is
        // honest, silently retrying wouldn't fix anything.
        Log.info(
          'CustomerCampaignSweepService: ${matches.first.status} $label template already exists '
          'for channel ${channel.id} — waiting (or needs manual attention if rejected)',
        );
        return false;
      }

      // Nothing submitted yet for this channel+kind — submit it now.
      // Meta's review takes minutes to days, so this run never sends;
      // a future sweep will find it approved and send then.
      try {
        final submitted = await _whatsAppTemplates.createTemplate(
          workspaceId: profile.workspaceId,
          channelId: channel.id!,
          label: label,
          category: 'utility',
          language: 'en_US',
          bodyText: _greetingText(isBirthday: isBirthday, businessName: '{{1}}'),
          bodyExampleValues: [businessName],
        );
        Log.info(
          'CustomerCampaignSweepService: submitted $label template '
          '(${submitted.metaTemplateName}) for channel ${channel.id} — awaiting Meta review',
        );
      } on InvalidWhatsAppChannelException catch (e) {
        Log.warning('CustomerCampaignSweepService: could not submit $label template: $e');
      }
      return false;
    }

    final credential = WhatsAppCredential.decode(
      ChannelCredentialEncryptionService.decrypt(channel.encryptedCredential!),
    );
    try {
      await WhatsAppService(
        accessToken: credential.accessToken,
        phoneNumberId: credential.phoneNumberId,
      ).sendTemplate(
        to: conversation.externalUserId,
        templateName: approved.metaTemplateName,
        language: approved.language,
        bodyParams: [businessName],
      );
    } catch (e) {
      Log.warning('CustomerCampaignSweepService: WhatsApp template send failed for conversation ${conversation.id}: $e');
      return false;
    }

    if (profile.id != null) {
      await _profiles.markGreetingSent(profile.id!, isBirthday: isBirthday, year: now.year);
    }
    Log.info(
      'CustomerCampaignSweepService: sent ${isBirthday ? "birthday" : "anniversary"} '
      'greeting for conversation ${conversation.id} (WhatsApp, template ${approved.metaTemplateName})',
    );
    return true;
  }

  String _greetingText({required bool isBirthday, required String businessName}) {
    return isBirthday
        ? '🎉 Happy Birthday from $businessName! We\'re glad to have you as a customer.'
        : '🎉 Happy Anniversary from $businessName! Thanks for being with us.';
  }
}
