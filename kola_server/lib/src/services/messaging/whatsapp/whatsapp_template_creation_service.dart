// whatsapp_template_creation_service.dart
//
// Task #154 — the core "submit a template against a workspace's own
// connected WhatsApp channel" logic, extracted out of
// WhatsAppTemplateEndpoint.createTemplate so it has exactly ONE caller-
// agnostic home — same extraction PaymentCheckoutService already did for
// PaymentEndpoint.initializeCheckout (see that file's header, identical
// reasoning). Two callers use this now:
//   - WhatsAppTemplateEndpoint — the dashboard-facing surface, which does
//     requireWorkspaceAccess FIRST, then delegates here. Auth belongs
//     there, not in this file.
//   - BuiltinErrandExecutor's 'createProductListTemplate' handler — an
//     AI-orchestrated bot mid-conversation, PROGRAMMATICALLY deciding to
//     submit a template on the business's behalf, not the business
//     filling in a dashboard form. There is no Session/accessToken in
//     that context, and there shouldn't need to be one — same reasoning
//     PaymentCheckoutService's header already gives for 'collectPayment'.
//
// THIS IS THE ANSWER TO "can we programmatically create a template for
// the user, not the business doing it themselves": before this file
// existed, WhatsAppTemplateEndpoint.createProductListTemplate could only
// be triggered by a human clicking a button on the Integrations page —
// a real gap the owner pointed at directly. Now BuiltinErrandExecutor can
// call the identical logic mid-conversation, no dashboard visit required.
// The manual dashboard form still works too (some businesses will
// legitimately want to submit a template proactively, not only when the
// AI decides to) — this file is the one place both paths actually run.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/whatsapp_message_template_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'whatsapp_credential.dart';
import 'whatsapp_template_service.dart';

const validWhatsAppTemplateCategories = {'utility', 'marketing', 'authentication'};

/// Thrown when [channelId] isn't a connected WhatsApp channel belonging
/// to the expected workspace — lets both callers (the dashboard endpoint,
/// the builtin Errand handler) show a clear message instead of a raw
/// null-check failure or a generic 500.
class InvalidWhatsAppChannelException implements Exception {
  final String message;
  const InvalidWhatsAppChannelException(this.message);

  @override
  String toString() => 'InvalidWhatsAppChannelException: $message';
}

class WhatsAppTemplateCreationService {
  BotRepository get _bots => getIt<BotRepository>();
  ChannelRepository get _channels => getIt<ChannelRepository>();
  WhatsAppMessageTemplateRepository get _templates =>
      getIt<WhatsAppMessageTemplateRepository>();

  /// See this file's header — callers are responsible for their own
  /// auth/workspace-access check BEFORE calling this (WhatsAppTemplateEndpoint
  /// does; BuiltinErrandExecutor's caller is already running inside a
  /// specific, already-resolved workspace's bot, so there's no separate
  /// credential to check). This method itself only validates that
  /// [channelId] genuinely belongs to [workspaceId] and is connected.
  Future<WhatsAppMessageTemplate> createTemplate({
    required int workspaceId,
    required int channelId,
    required String label,
    required String category,
    required String language,
    required String bodyText,
    List<String> bodyExampleValues = const [],
  }) async {
    if (!validWhatsAppTemplateCategories.contains(category)) {
      throw ArgumentError(
        'category must be one of: ${validWhatsAppTemplateCategories.join(", ")}',
      );
    }
    final trimmedBody = bodyText.trim();
    if (trimmedBody.isEmpty) {
      throw ArgumentError('Template body cannot be empty.');
    }

    final credential = await _requireConnectedWhatsAppChannel(workspaceId, channelId);
    final name = _sanitizeTemplateName(label);

    final submission = await WhatsAppTemplateService(
      accessToken: credential.accessToken,
      wabaId: credential.wabaId,
    ).createTemplate(
      name: name,
      category: category,
      language: language,
      bodyText: trimmedBody,
      bodyExampleValues: bodyExampleValues,
    );

    final saved = await _templates.create(
      workspaceId: workspaceId,
      channelId: channelId,
      metaTemplateName: name,
      requestedCategory: category,
      language: language,
      bodyText: trimmedBody,
      metaTemplateId: submission.metaTemplateId,
      status: submission.status.toLowerCase(),
    );

    Log.success('WhatsApp template submitted', data: {
      'workspaceId': workspaceId,
      'channelId': channelId,
      'metaTemplateId': submission.metaTemplateId,
      'category': category,
    });

    return saved;
  }

  /// Convenience wrapper for the specific case the owner asked about —
  /// see WhatsAppTemplateEndpoint's original doc comment for the full
  /// framing (a 'utility'-category reply to a requested product list).
  Future<WhatsAppMessageTemplate> createProductListTemplate({
    required int workspaceId,
    required int channelId,
    required String businessLabel,
    required String customerNameExample,
    required String productListExample,
  }) async {
    const bodyText = "Hi {{1}}, here's the product list you asked about:\n\n{{2}}";

    return createTemplate(
      workspaceId: workspaceId,
      channelId: channelId,
      label: businessLabel.trim().isEmpty ? 'product_list' : businessLabel,
      category: 'utility',
      language: 'en_US',
      bodyText: bodyText,
      bodyExampleValues: [customerNameExample, productListExample],
    );
  }

  Future<WhatsAppCredential> _requireConnectedWhatsAppChannel(
    int workspaceId,
    int channelId,
  ) async {
    final channel = await _channels.findById(channelId);
    if (channel == null || channel.platformType != 'whatsapp') {
      throw const InvalidWhatsAppChannelException('This channel is not a WhatsApp channel.');
    }
    final bot = await _bots.findByIdScoped(channel.botId, workspaceId);
    if (bot == null) {
      throw InvalidWhatsAppChannelException(
        'Channel $channelId does not belong to workspace $workspaceId.',
      );
    }
    if (channel.status != 'connected' || channel.encryptedCredential == null) {
      throw const InvalidWhatsAppChannelException('This WhatsApp channel is not connected yet.');
    }
    return WhatsAppCredential.decode(
      ChannelCredentialEncryptionService.decrypt(channel.encryptedCredential!),
    );
  }

  /// Meta requires lowercase letters, digits, and underscores only, plus
  /// per-WABA+language uniqueness — a millisecond-timestamp suffix
  /// guarantees the latter without asking the caller to manage it.
  String _sanitizeTemplateName(String label) {
    final base = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final safeBase = base.isEmpty ? 'template' : base;
    return '${safeBase}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
