// ignore_for_file: avoid_print
// ^ One-off CLI script: stdout IS the output. avoid_print stays ON for
//   lib/ — this is a targeted ignore rather than an analyzer exclude, so
//   real errors in this file are still reported.
// tool/test_escalation_loop.dart
//
// One-off script exercising the escalation feature's full server-side
// loop WITHOUT needing a live Telegram/WhatsApp channel:
// InboundMessageHandler -> Conversation/Message persistence ->
// BotKnowledgeService's sentinel-token escalation detection ->
// Conversation flips to 'escalated' -> OwnerNotificationDispatcher
// attempts a fan-out (skips every channel if the workspace has no
// OwnerNotificationSettings configured yet — see the printed summary).
// Same "bypass Session/requireWorkspaceAccess, call repositories
// directly" spirit as test_grounded_qa.dart.
//
// USAGE (run from kola_server/):
//   dart run tool/test_escalation_loop.dart \
//     --seed="We're open 9am-6pm Mon-Sat." \
//     --question="I want to speak to a real person right now"
//
// First run creates a throwaway workspace + bot + fake channel (prints
// their ids). Pass --workspace-id=<id> --bot-id=<id> --channel-id=<id>
// on later runs to reuse them.

import 'dart:io';
import 'package:kola_server/src/services/repository/supabase_client.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/message_repository.dart';
import 'package:kola_server/src/services/repository/owner_notification_settings_repository.dart';
import 'package:kola_server/src/services/repository/owner_notification_send_repository.dart';
import 'package:kola_server/src/services/repository/broadcast_repository.dart';
import 'package:kola_server/src/services/notifications/broadcast_reply_digest_service.dart';
import 'package:kola_server/src/services/repository/usage_record_repository.dart';
import 'package:kola_server/src/services/repository/errand_repository.dart';
import 'package:kola_server/src/services/repository/errand_execution_log_repository.dart';
import 'package:kola_server/src/services/repository/errand_credential_repository.dart';
import 'package:kola_server/src/services/repository/support_ticket_repository.dart';
import 'package:kola_server/src/services/repository/customer_profile_repository.dart';
import 'package:kola_server/src/services/repository/otp_code_repository.dart';
import 'package:kola_server/src/services/otp/otp_service.dart';
import 'package:kola_server/src/services/billing/payment_checkout_service.dart';
import 'package:kola_server/src/services/errand/builtin_errand_executor.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_template_creation_service.dart';
import 'package:kola_server/src/services/errand/webhook_errand_executor.dart';
import 'package:kola_server/src/services/errand/db_credential_errand_executor.dart';
import 'package:kola_server/src/services/errand/errand_dispatch_service.dart';
import 'package:kola_server/src/services/notifications/notification_rate_limiter.dart';
import 'package:kola_server/src/services/notifications/owner_notification_dispatcher.dart';
import 'package:kola_server/src/services/ai/ai_orchestrator.dart';
import 'package:kola_server/src/services/knowledge/bot_knowledge_service.dart';
import 'package:kola_server/src/services/media/imagekit_service.dart';
import 'package:kola_server/src/services/media/inbound_media_service.dart';
import 'package:kola_server/src/services/conversations/inbound_message_handler.dart';
import 'package:kola_server/src/services/repository/event_repository.dart';
import 'package:kola_server/src/services/repository/webhook_endpoint_repository.dart';
import 'package:kola_server/src/services/repository/connector_sync_log_repository.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/connectors/contract/webhook_delivery_service.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/repository/customer_repository.dart';
import 'package:kola_server/src/services/repository/customer_identity_signal_repository.dart';
import 'package:kola_server/src/services/repository/customer_merge_proposal_repository.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/repository/payment_gateway_credential_repository.dart';
import 'package:kola_server/src/services/errand/connector_capability_registry.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/repository/calendar_booking_repository.dart';
import 'package:kola_server/src/services/connectors/google/calendar_booking_service.dart';
import 'package:kola_server/src/services/connectors/google/google_oauth_service.dart';
import 'package:kola_server/src/services/errand/errand_row_customer_mapper.dart';
import 'package:kola_server/src/services/repository/errand_entity_mapping_repository.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/generated/protocol.dart';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);
  final question = flags['question'] ?? 'I want to speak to a real person right now';

  await initSupabase();

  final workspaces = const WorkspaceRepository();
  final bots = const BotRepository();
  final channels = const ChannelRepository();

  var workspace = flags.containsKey('workspace-id')
      ? await workspaces.findById(int.parse(flags['workspace-id']!))
      : null;
  workspace ??= await workspaces.create(name: 'Kola Test Workspace (Escalation)');
  print('Workspace: id=${workspace.id} name=${workspace.name}');

  var bot = flags.containsKey('bot-id')
      ? await bots.findByIdScoped(int.parse(flags['bot-id']!), workspace.id!)
      : null;
  bot ??= await bots.create(
    workspaceId: workspace.id!,
    name: 'Kola Test Bot (Escalation)',
    archetype: 'customerCare',
  );
  print('Bot: id=${bot.id} name=${bot.name}');

  if (flags.containsKey('seed')) {
    bot = await bots.update(
      Bot(
        id: bot.id,
        workspaceId: bot.workspaceId,
        name: bot.name,
        archetype: bot.archetype,
        status: bot.status,
        knowledgeSeed: flags['seed'],
        createdAt: bot.createdAt,
        updatedAt: bot.updatedAt,
      ),
    );
    print('Knowledge seed set (${flags['seed']!.length} chars).');
  }

  var channel = flags.containsKey('channel-id')
      ? await channels.findById(int.parse(flags['channel-id']!))
      : null;
  channel ??= await channels.create(botId: bot.id!, platformType: 'telegram', displayName: 'test-channel');
  print('Channel: id=${channel.id} platformType=${channel.platformType}');

  print('');
  print('Question: $question');
  print('');

  // Task #134's AI tool-calling engine added two more required
  // dependencies (errands, errandDispatch) after this script was first
  // written; wired here the same way dependency_injection.dart does,
  // building the full executor stack ErrandDispatchService needs.
  // Task #154 added whatsAppTemplates the same way.
  // Gate 2 — the event bus stack, built by hand here the same way the
  // rest of this script already builds its dependency graph rather than
  // going through get_it (see this file's header on why).
  final eventBus = EventBus(
    events: const EventRepository(),
    webhookDelivery: WebhookDeliveryService(
      endpoints: const WebhookEndpointRepository(),
      syncLog: const ConnectorSyncLogRepository(),
    ),
  );

  // Gate 3 — built by hand the same way every other dependency in this
  // script is, rather than through get_it (see this file's header).
  final customerIdentity = CustomerIdentityResolver(
    customers: const CustomerRepository(),
    signals: const CustomerIdentitySignalRepository(),
    mergeProposals: const CustomerMergeProposalRepository(),
  );

  const errandExecutionLogs = ErrandExecutionLogRepository();
  // paymentTransactions/calendarBookings added to BuiltinErrandExecutor's
  // constructor later still — wired here the same way as the rest of
  // this script's dependency graph (see header), found 2026-08-24 when
  // `serverpod generate` first surfaced this script no longer compiling.
  final calendarBookings = CalendarBookingService(
    connectors: const WorkspaceConnectorRepository(),
    bookings: const CalendarBookingRepository(),
    oauth: GoogleOAuthService(
      clientId: Env.googleOAuthClientId,
      clientSecret: Env.googleOAuthClientSecret,
      redirectUri: Env.googleOAuthRedirectUri,
    ),
  );
  final builtinExecutor = BuiltinErrandExecutor(
    executionLogs: errandExecutionLogs,
    paymentCheckout: PaymentCheckoutService(),
    paymentTransactions: const PaymentTransactionRepository(),
    supportTickets: const SupportTicketRepository(),
    customerProfiles: const CustomerProfileRepository(),
    otpService: OtpService(otpCodes: const OtpCodeRepository()),
    whatsAppTemplates: WhatsAppTemplateCreationService(),
    calendarBookings: calendarBookings,
  );
  // Gate 5's second half — built by hand the same way every other
  // dependency in this script is (see header). No dbCredential Errand
  // exists in this script's scenario, so applyIfMapped will always no-op
  // instantly here — wired anyway because ErrandDispatchService now
  // requires it unconditionally.
  final rowCustomerMapper = ErrandRowCustomerMapper(
    mappings: const ErrandEntityMappingRepository(),
    identity: customerIdentity,
    events: eventBus,
  );
  final errandDispatch = ErrandDispatchService(
    builtinExecutor: builtinExecutor,
    webhookExecutor: WebhookErrandExecutor(
      credentials: const ErrandCredentialRepository(),
      executionLogs: errandExecutionLogs,
    ),
    dbCredentialExecutor: DbCredentialErrandExecutor(
      credentials: const ErrandCredentialRepository(),
      executionLogs: errandExecutionLogs,
    ),
    events: eventBus,
    rowCustomerMapper: rowCustomerMapper,
  );

  final handler = InboundMessageHandler(
    bots: bots,
    conversations: const ConversationRepository(),
    messages: const MessageRepository(),
    workspaces: workspaces,
    usageRecords: const UsageRecordRepository(),
    errands: const ErrandRepository(),
    knowledgeService: BotKnowledgeService(aiOrchestrator: AiOrchestrator()),
    // Required since inbound photos were wired in. This script only
    // exercises the TEXT path, so the service is constructed and never
    // called — but the dependency is deliberately required rather than
    // nullable, so a production wiring mistake fails at startup instead
    // of silently dropping every customer's photo.
    inboundMedia: InboundMediaService(ImageKitService()),
    errandDispatch: errandDispatch,
    notificationDispatcher: OwnerNotificationDispatcher(
      settingsRepo: const OwnerNotificationSettingsRepository(),
      workspaces: workspaces,
      rateLimiter: NotificationRateLimiter(sends: const OwnerNotificationSendRepository()),
    ),
    // Gate 10 — required dependency, never exercised by this script
    // (this workspace's conversations are never broadcast-tagged), same
    // "constructed rather than made nullable just for a test script"
    // spirit as the other required-but-unused deps below.
    broadcastReplyDigest: BroadcastReplyDigestService(
      broadcasts: const BroadcastRepository(),
      notifications: OwnerNotificationDispatcher(
        settingsRepo: const OwnerNotificationSettingsRepository(),
        workspaces: workspaces,
        rateLimiter: NotificationRateLimiter(sends: const OwnerNotificationSendRepository()),
      ),
    ),
    events: eventBus,
    customerIdentity: customerIdentity,
    // Connect Gate, subphase 4b — required dependency, this script only
    // exercises the text/escalation path so no connector is ever
    // connected for the throwaway workspace, meaning forWorkspace()
    // always returns an empty list here. Constructed rather than made
    // nullable for the same "fail at startup, not silently" reasoning
    // as inboundMedia above.
    connectorCapabilities: ConnectorCapabilityRegistry(
      connectors: const WorkspaceConnectorRepository(),
      paymentGateways: const PaymentGatewayCredentialRepository(),
    ),
  );

  try {
    final reply = await handler.handle(
      botId: bot.id!,
      channelId: channel.id!,
      platformType: channel.platformType,
      externalUserId: 'test-user-${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Test Customer',
      inboundText: question,
    );

    print('✅ Reply: ${reply ?? "(none — conversation already escalated)"}');

    final conversation = await const ConversationRepository()
        .listByWorkspace(workspace.id!)
        .then((list) => list.first);
    print('');
    print('Conversation ${conversation.id} status: ${conversation.status}');
    if (conversation.status == 'escalated') {
      print(
        'Escalated as expected. If OwnerNotificationSettings isn\'t set up '
        'for this workspace yet, every notification channel above logged '
        '"skipped" — that\'s expected, not a bug. Call '
        'OwnerNotificationEndpoint.updateSettings first to see a real send.',
      );
    }
    exit(0);
  } catch (e) {
    stderr.writeln('❌ ${e.toString()}');
    exit(1);
  }
}

Map<String, String> _parseFlags(List<String> args) {
  final map = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--') || !arg.contains('=')) continue;
    final eqIndex = arg.indexOf('=');
    map[arg.substring(2, eqIndex)] = arg.substring(eqIndex + 1);
  }
  return map;
}
