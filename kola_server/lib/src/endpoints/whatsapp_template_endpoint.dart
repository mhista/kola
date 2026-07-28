// whatsapp_template_endpoint.dart
//
// Task #150 — programmatic WhatsApp message templates. Own endpoint
// file, not folded into ChannelEndpoint, same reasoning
// support_ticket_repository.dart's header gives for SupportTicket
// getting its own endpoint rather than living on ConversationEndpoint:
// this is a distinct concern (Meta template lifecycle) layered ON TOP
// of an already-connected WhatsApp channel, not a channel-connection
// action itself.
//
// WHY THIS EXISTS AT ALL — READ THIS BEFORE WIRING A DASHBOARD BUTTON TO
// IT: a bot replying to a customer who just messaged NEVER needs a
// template — any non-template message inside an open 24-hour customer
// service window is free today (Meta ends that specific freebie Oct 1,
// 2026, at which point it's ~$0.0068/reply — still no template
// required). Templates are ONLY required when a business wants to
// message someone who hasn't messaged recently — no open window.
// createProductListTemplate below exists for exactly that narrower
// case: a business wants to proactively send a customer their product
// list outside a window, as cheaply as Meta allows for that.
//
// WHY 'utility' IS THE DEFAULT, NOT 'marketing': Meta's own category
// definitions make a reply to something a specific customer is owed or
// asked for (an order update, a requested price list) 'utility' —
// materially cheaper than 'marketing' (a cold promotional push) on
// every market's rate card, Nigeria included. Meta's review makes the
// final call regardless of what's requested here — see
// whatsapp_message_template.spy.yaml's header.
//
// TASK #154 — DELEGATES TO WhatsAppTemplateCreationService NOW: the
// owner pointed out templates should be creatable PROGRAMMATICALLY, not
// only via a business filling in a dashboard form — so the actual
// submission logic moved to whatsapp_template_creation_service.dart
// (Session-less, callable from BuiltinErrandExecutor too). This
// endpoint's job is now just what an Endpoint should do:
// requireWorkspaceAccess, then delegate — same split
// PaymentEndpoint/PaymentCheckoutService already established. The
// manual dashboard form this endpoint backs still works; it's simply no
// longer the only way in.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/whatsapp_message_template_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_credential.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_template_service.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_template_creation_service.dart';
import 'package:kola_server/kola_logger.dart';

class WhatsAppTemplateEndpoint extends Endpoint {
  BotRepository get _bots => getIt<BotRepository>();
  ChannelRepository get _channels => getIt<ChannelRepository>();
  WhatsAppMessageTemplateRepository get _templates =>
      getIt<WhatsAppMessageTemplateRepository>();
  WhatsAppTemplateCreationService get _creation =>
      getIt<WhatsAppTemplateCreationService>();

  /// Confirms [channelId] is a connected WhatsApp channel belonging to
  /// [workspaceId], and returns the decrypted credential needed to call
  /// Meta on its behalf. Only [refreshTemplateStatus] below still needs
  /// this directly (polling an existing submission's status is a
  /// different concern from creating one, which now lives entirely in
  /// WhatsAppTemplateCreationService).
  Future<WhatsAppCredential> _requireConnectedWhatsAppChannel(
    int workspaceId,
    int channelId,
  ) async {
    final channel = await _channels.findById(channelId);
    if (channel == null || channel.platformType != 'whatsapp') {
      throw Exception('Channel $channelId is not a WhatsApp channel.');
    }
    final bot = await _bots.findByIdScoped(channel.botId, workspaceId);
    if (bot == null) {
      throw Exception('Channel $channelId does not belong to workspace $workspaceId.');
    }
    if (channel.status != 'connected' || channel.encryptedCredential == null) {
      throw Exception('This WhatsApp channel is not connected yet.');
    }
    return WhatsAppCredential.decode(
      ChannelCredentialEncryptionService.decrypt(channel.encryptedCredential!),
    );
  }

  /// The general-purpose submission path — [category] must be one of
  /// 'utility' | 'marketing' | 'authentication'. Most callers (the
  /// dashboard's "Create a template" flow) should be able to use this
  /// directly; [createProductListTemplate] below is a thin convenience
  /// wrapper for the one shape the owner specifically asked for.
  /// Auth-checked here, then delegated to WhatsAppTemplateCreationService
  /// — see this file's header.
  Future<WhatsAppMessageTemplate> createTemplate(
    Session session,
    String accessToken,
    int workspaceId,
    int channelId,
    String label,
    String category,
    String language,
    String bodyText,
    List<String> bodyExampleValues,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    try {
      final saved = await _creation.createTemplate(
        workspaceId: workspaceId,
        channelId: channelId,
        label: label,
        category: category,
        language: language,
        bodyText: bodyText,
        bodyExampleValues: bodyExampleValues,
      );
      Log.success(
        'WhatsApp template submitted (via dashboard)',
        data: {
          'workspaceId': workspaceId,
          'channelId': channelId,
          'metaTemplateId': saved.metaTemplateId,
          'category': category,
        },
        session: session,
      );
      return saved;
    } on InvalidWhatsAppChannelException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Convenience wrapper for the specific case the owner asked about:
  /// "a business wants to send a list of products without it costing
  /// them a lot." Frames the body as an explicit reply to a customer
  /// request (the honest 'utility' use case — see this file's header)
  /// rather than a cold pitch, which both fits 'utility' review
  /// criteria better AND is what most product-list sends actually are
  /// in practice: a customer asked, the business is following up.
  ///
  /// [customerNameExample]/[productListExample] are just the example
  /// values Meta's review requires for the two placeholders — not sent
  /// to any real customer, only shown to Meta's reviewer alongside the
  /// template.
  Future<WhatsAppMessageTemplate> createProductListTemplate(
    Session session,
    String accessToken,
    int workspaceId,
    int channelId,
    String businessLabel,
    String customerNameExample,
    String productListExample,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    try {
      return await _creation.createProductListTemplate(
        workspaceId: workspaceId,
        channelId: channelId,
        businessLabel: businessLabel,
        customerNameExample: customerNameExample,
        productListExample: productListExample,
      );
    } on InvalidWhatsAppChannelException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Every template submitted for this workspace, newest first — the
  /// dashboard's template status list.
  Future<List<WhatsAppMessageTemplate>> listTemplatesForWorkspace(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _templates.listByWorkspace(workspaceId);
  }

  /// Polls Meta for [templateId]'s current review outcome and persists
  /// any change — see whatsapp_template_service.dart's header on why
  /// this is polling, not a webhook, for now.
  Future<WhatsAppMessageTemplate> refreshTemplateStatus(
    Session session,
    String accessToken,
    int workspaceId,
    int templateId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final existing = await _templates.findByIdScoped(templateId, workspaceId);
    if (existing == null) {
      throw Exception('Template $templateId not found in workspace $workspaceId');
    }
    if (existing.metaTemplateId == null) {
      throw Exception('This template was never successfully submitted to Meta.');
    }

    final credential = await _requireConnectedWhatsAppChannel(
      workspaceId,
      existing.channelId,
    );

    final metaStatus = await WhatsAppTemplateService(
      accessToken: credential.accessToken,
      wabaId: credential.wabaId,
    ).fetchTemplateStatus(existing.metaTemplateId!);

    return _templates.updateStatus(
      templateId: templateId,
      status: metaStatus.status.toLowerCase(),
      metaCategory: metaStatus.category?.toLowerCase(),
      rejectionReason: metaStatus.rejectedReason,
    );
  }
}
