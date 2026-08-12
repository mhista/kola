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
import 'package:kola_server/src/services/conversations/inbound_message_handler.dart';
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
  const errandExecutionLogs = ErrandExecutionLogRepository();
  final builtinExecutor = BuiltinErrandExecutor(
    executionLogs: errandExecutionLogs,
    paymentCheckout: PaymentCheckoutService(),
    supportTickets: const SupportTicketRepository(),
    customerProfiles: const CustomerProfileRepository(),
    otpService: OtpService(otpCodes: const OtpCodeRepository()),
    whatsAppTemplates: WhatsAppTemplateCreationService(),
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
  );

  final handler = InboundMessageHandler(
    bots: bots,
    conversations: const ConversationRepository(),
    messages: const MessageRepository(),
    workspaces: workspaces,
    usageRecords: const UsageRecordRepository(),
    errands: const ErrandRepository(),
    knowledgeService: BotKnowledgeService(aiOrchestrator: AiOrchestrator()),
    errandDispatch: errandDispatch,
    notificationDispatcher: OwnerNotificationDispatcher(
      settingsRepo: const OwnerNotificationSettingsRepository(),
      workspaces: workspaces,
      rateLimiter: NotificationRateLimiter(sends: const OwnerNotificationSendRepository()),
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
