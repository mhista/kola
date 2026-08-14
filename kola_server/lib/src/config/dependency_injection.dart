// dependency_injection.dart
//
// get_it-based service locator. Repositories are stateless (they just hold
// a DTO instance and talk to the global `supabase` client — see
// supabase_client.dart), so registering them as lazy singletons here is
// mostly about giving endpoints one consistent place to obtain them
// instead of doing `const WorkspaceRepository()` scattered everywhere.
//
// GROWS PER PHASE: this file registers only what Phase 1 needs today.
// Phase 2 adds messaging service registrations (Telegram/WhatsApp
// adapters), Phase 3 adds the AI orchestrator and Errand execution
// services, following the same `getIt.registerLazySingleton<T>(...)`
// shape — no restructuring needed, just more registrations.

import 'package:get_it/get_it.dart';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/workspace_member_repository.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/connectors/connector_service.dart';
import 'package:kola_server/src/services/repository/api_key_repository.dart';
import 'package:kola_server/src/services/repository/webhook_endpoint_repository.dart';
import 'package:kola_server/src/services/platform/api_key_service.dart';
import 'package:kola_server/src/services/repository/waitlist_signup_repository.dart';
import 'package:kola_server/src/services/repository/errand_repository.dart';
import 'package:kola_server/src/services/repository/errand_credential_repository.dart';
import 'package:kola_server/src/services/repository/errand_execution_log_repository.dart';
import 'package:kola_server/src/services/errand/builtin_errand_executor.dart';
import 'package:kola_server/src/services/errand/webhook_errand_executor.dart';
import 'package:kola_server/src/services/errand/db_credential_errand_executor.dart';
import 'package:kola_server/src/services/errand/errand_dispatch_service.dart';
import 'package:kola_server/src/services/ai/ai_orchestrator.dart';
import 'package:kola_server/src/services/assistant/workspace_answer_service.dart';
import 'package:kola_server/src/services/observation/workspace_sweep_service.dart';
import 'package:kola_server/src/services/repository/workspace_finding_repository.dart';
import 'package:kola_server/src/services/knowledge/bot_knowledge_service.dart';
import 'package:kola_server/src/services/knowledge/bot_mother_service.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/message_repository.dart';
import 'package:kola_server/src/services/repository/owner_notification_settings_repository.dart';
import 'package:kola_server/src/services/repository/owner_notification_send_repository.dart';
import 'package:kola_server/src/services/notifications/notification_rate_limiter.dart';
import 'package:kola_server/src/services/notifications/owner_notification_dispatcher.dart';
import 'package:kola_server/src/services/conversations/inbound_message_handler.dart';
import 'package:kola_server/src/services/security/security_filter.dart';
import 'package:kola_server/src/services/billing/trial_state_machine.dart';
import 'package:kola_server/src/services/billing/trial_sweep_service.dart';
import 'package:kola_server/src/services/repository/subscription_repository.dart';
import 'package:kola_server/src/services/repository/usage_record_repository.dart';
import 'package:kola_server/src/services/billing/paystack_service.dart';
import 'package:kola_server/src/services/billing/flutterwave_service.dart';
import 'package:kola_server/src/services/messaging/channel_health_check_service.dart';
import 'package:kola_server/src/services/repository/payment_gateway_credential_repository.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/billing/payment_checkout_service.dart';
import 'package:kola_server/src/services/repository/support_ticket_repository.dart';
import 'package:kola_server/src/services/support/support_ticket_sla_sweep_service.dart';
import 'package:kola_server/src/services/repository/customer_profile_repository.dart';
import 'package:kola_server/src/services/support/customer_campaign_sweep_service.dart';
import 'package:kola_server/src/services/repository/otp_code_repository.dart';
import 'package:kola_server/src/services/otp/otp_service.dart';
import 'package:kola_server/src/services/repository/whatsapp_message_template_repository.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_template_creation_service.dart';
import 'package:kola_server/src/services/repository/kola_billing_checkout_repository.dart';
import 'package:kola_server/src/services/billing/kola_billing_service.dart';
import 'package:kola_server/src/config/env.dart';
// Phase 9 (Layer 2 — Business Memory).
import 'package:kola_server/src/services/memory/embedding_orchestrator.dart';
import 'package:kola_server/src/services/memory/document_ingestion_service.dart';
import 'package:kola_server/src/services/memory/memory_retrieval_service.dart';
import 'package:kola_server/src/services/repository/knowledge_document_repository.dart';
import 'package:kola_server/src/services/repository/knowledge_chunk_repository.dart';
// Phase 10 (Release Control).
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/feature_flag_repository.dart';
import 'package:kola_server/src/services/repository/workspace_feature_override_repository.dart';
import 'package:kola_server/src/services/repository/product_repository.dart';
import 'package:kola_server/src/services/media/imagekit_service.dart';
import 'package:kola_server/src/services/media/inbound_media_service.dart';

final getIt = GetIt.instance;

/// Registers every repository (and, from later phases, every service) the
/// server needs. Call once from server.dart's run(), after initSupabase()
/// but before pod.start() — repositories don't touch Supabase at
/// registration time, only when a method on them is actually called, so
/// ordering relative to Supabase init is a formality here, not a hard
/// requirement — kept early anyway so the dependency graph is obvious
/// reading top-to-bottom.
void setupDependencyInjection() {
  Log.startupInfo('Setting up dependency injection...');

  getIt.registerLazySingleton<WorkspaceRepository>(
    () => const WorkspaceRepository(),
  );
  getIt.registerLazySingleton<WorkspaceMemberRepository>(
    () => const WorkspaceMemberRepository(),
  );
  getIt.registerLazySingleton<BotRepository>(() => const BotRepository());
  getIt.registerLazySingleton<ChannelRepository>(
    () => const ChannelRepository(),
  );
  getIt.registerLazySingleton<WaitlistSignupRepository>(
    () => const WaitlistSignupRepository(),
  );

  // Migration 029 — the catalog. Registered alongside the other
  // repositories rather than behind a commerce check: DI wiring is not
  // access control, and ProductEndpoint does the flag check on every
  // method. A registration that appeared and disappeared with a feature
  // flag would make startup depend on database state.
  // Signs one-shot browser upload credentials; holds the ImageKit
  // private key. Stateless, so a lazy singleton is exactly right.
  getIt.registerLazySingleton<ImageKitService>(() => ImageKitService());

  // Turns a WhatsApp/Telegram media reference into an ImageKit URL.
  // Depends on ImageKitService above; get_it resolves lazily on first
  // USE, so registration order between the two does not matter.
  getIt.registerLazySingleton<InboundMediaService>(
    () => InboundMediaService(getIt<ImageKitService>()),
  );

  getIt.registerLazySingleton<ProductRepository>(
    () => const ProductRepository(),
  );

  // Phase 3b — Errand system repositories.
  getIt.registerLazySingleton<ErrandRepository>(() => const ErrandRepository());
  getIt.registerLazySingleton<ErrandCredentialRepository>(
    () => const ErrandCredentialRepository(),
  );
  getIt.registerLazySingleton<ErrandExecutionLogRepository>(
    () => const ErrandExecutionLogRepository(),
  );
  // Task #128 — collectPayment (see below for full registration) needs
  // PaymentCheckoutService to exist before BuiltinErrandExecutor's
  // factory closure runs; get_it resolves lazily on first USE, not at
  // registration time, so declaring PaymentCheckoutService's
  // registration below this line (rather than moving this whole block)
  // is fine — by the time anything actually calls
  // getIt<BuiltinErrandExecutor>(), setupDependencyInjection() has long
  // since finished and every registration below already exists.
  getIt.registerLazySingleton<BuiltinErrandExecutor>(
    () => BuiltinErrandExecutor(
      executionLogs: getIt<ErrandExecutionLogRepository>(),
      paymentCheckout: getIt<PaymentCheckoutService>(),
      supportTickets: getIt<SupportTicketRepository>(),
      customerProfiles: getIt<CustomerProfileRepository>(),
      otpService: getIt<OtpService>(),
      // Task #154 — 'createProductListTemplate' handler's dependency;
      // see whatsapp_template_creation_service.dart's header. Registered
      // further below (near WhatsAppMessageTemplateRepository) — fine
      // for the same lazy-resolution reason as PaymentCheckoutService
      // above.
      whatsAppTemplates: getIt<WhatsAppTemplateCreationService>(),
    ),
  );

  // Phase 3c — webhook + database-credential Errand fulfillment.
  getIt.registerLazySingleton<WebhookErrandExecutor>(
    () => WebhookErrandExecutor(
      credentials: getIt<ErrandCredentialRepository>(),
      executionLogs: getIt<ErrandExecutionLogRepository>(),
    ),
  );
  getIt.registerLazySingleton<DbCredentialErrandExecutor>(
    () => DbCredentialErrandExecutor(
      credentials: getIt<ErrandCredentialRepository>(),
      executionLogs: getIt<ErrandExecutionLogRepository>(),
    ),
  );
  // Task #134 — the Session-free dispatch core shared by
  // ErrandEndpoint.executeErrand and the AI tool-calling engine
  // (InboundMessageHandler) — see errand_dispatch_service.dart's header.
  getIt.registerLazySingleton<ErrandDispatchService>(
    () => ErrandDispatchService(
      builtinExecutor: getIt<BuiltinErrandExecutor>(),
      webhookExecutor: getIt<WebhookErrandExecutor>(),
      dbCredentialExecutor: getIt<DbCredentialErrandExecutor>(),
    ),
  );

  // Phase 3a — provider-agnostic AI orchestrator. Lazy singleton like
  // everything else here: cheap to construct (just reads Env for API
  // keys), no need for more than one instance server-wide.
  getIt.registerLazySingleton<AiOrchestrator>(() => AiOrchestrator());

  // ── PHASE 10 — RELEASE CONTROL ────────────────────────────────────────────
  //
  // Registered EARLY because everything gated depends on it. See
  // feature_flag_service.dart for the resolution order and why the cache
  // TTL is short (the kill switch has to actually kill).
  //
  // Depends on TrialStateMachine for minimum-plan checks, which is
  // registered further down — safe because registerLazySingleton defers
  // construction until first use, by which point every registration in
  // this function has run.
  getIt.registerLazySingleton<FeatureFlagRepository>(
    () => const FeatureFlagRepository(),
  );
  getIt.registerLazySingleton<WorkspaceFeatureOverrideRepository>(
    () => const WorkspaceFeatureOverrideRepository(),
  );
  getIt.registerLazySingleton<FeatureFlagService>(
    () => FeatureFlagService(
      flags: getIt<FeatureFlagRepository>(),
      overrides: getIt<WorkspaceFeatureOverrideRepository>(),
      trialStateMachine: getIt<TrialStateMachine>(),
    ),
  );

  // ── LAYER 3: CONNECTORS ───────────────────────────────────────────────────
  //
  // Registered after FeatureFlagService because ConnectorService resolves
  // every connector's visible state from its capability flag — see
  // connector_catalog.dart on why release state lives in feature_flags
  // and not in the catalog.
  //
  // ConnectorService reads THREE stores, not one: channels (WhatsApp,
  // Telegram), payment_gateway_credentials (Paystack, Flutterwave,
  // Stripe) and workspace_connectors (everything else).
  //
  // PaymentGatewayCredentialRepository is registered further DOWN this
  // function, not above. That is safe for the same reason the
  // FeatureFlagService block above says it is: registerLazySingleton
  // defers construction until first use, by which point every
  // registration here has run. Resolution order, not registration order,
  // is what matters.
  getIt.registerLazySingleton<WorkspaceConnectorRepository>(
    () => const WorkspaceConnectorRepository(),
  );
  getIt.registerLazySingleton<ConnectorService>(
    () => ConnectorService(
      features: getIt<FeatureFlagService>(),
      bots: getIt<BotRepository>(),
      channels: getIt<ChannelRepository>(),
      gateways: getIt<PaymentGatewayCredentialRepository>(),
      generic: getIt<WorkspaceConnectorRepository>(),
    ),
  );

  // ── PLATFORM: API KEYS + OUTBOUND WEBHOOKS ────────────────────────────────
  //
  // Migration 026. Gated on platform.public_api, which is R6 and locked —
  // so this is built, deployed and invisible, exactly as the release model
  // intends (RELEASE_PHASES.md §0).
  getIt.registerLazySingleton<ApiKeyRepository>(
    () => const ApiKeyRepository(),
  );
  getIt.registerLazySingleton<WebhookEndpointRepository>(
    () => const WebhookEndpointRepository(),
  );
  getIt.registerLazySingleton<ApiKeyService>(
    () => ApiKeyService(keys: getIt<ApiKeyRepository>()),
  );

  // ── PHASE 9 — LAYER 2: BUSINESS MEMORY ────────────────────────────────────
  //
  // Registered BEFORE BotKnowledgeService because that service now takes
  // MemoryRetrievalService as a dependency — the one change to an
  // existing registration in this whole phase.
  //
  // ZERO ADDITIONAL COST BY DESIGN: EmbeddingOrchestrator uses the SAME
  // Env.geminiApiKey the chat-side GeminiProvider already uses — no new
  // credential, no new vendor relationship, and gemini-embedding-001 has
  // a real free tier (1,500 requests/day). If that key is unset, every
  // service below degrades gracefully rather than failing: ingestion
  // returns IngestionStatus.unavailable, retrieval returns an empty
  // context, and BotKnowledgeService falls straight back to the legacy
  // Bot.knowledgeSeed path. Nothing here can start billing on its own.
  getIt.registerLazySingleton<EmbeddingOrchestrator>(() => EmbeddingOrchestrator());
  getIt.registerLazySingleton<KnowledgeDocumentRepository>(
    () => const KnowledgeDocumentRepository(),
  );
  getIt.registerLazySingleton<KnowledgeChunkRepository>(
    () => const KnowledgeChunkRepository(),
  );
  getIt.registerLazySingleton<MemoryRetrievalService>(
    () => MemoryRetrievalService(
      embeddings: getIt<EmbeddingOrchestrator>(),
      chunks: getIt<KnowledgeChunkRepository>(),
      documents: getIt<KnowledgeDocumentRepository>(),
    ),
  );
  getIt.registerLazySingleton<DocumentIngestionService>(
    () => DocumentIngestionService(
      embeddings: getIt<EmbeddingOrchestrator>(),
      documents: getIt<KnowledgeDocumentRepository>(),
      chunks: getIt<KnowledgeChunkRepository>(),
    ),
  );

  // Notices things without being asked — "Needs your attention".
  //
  // Deterministic detectors only; no AI. See finding_kinds.dart on why
  // the Overview is the worst screen in the product for a
  // plausible-sounding mistake.
  getIt.registerLazySingleton<WorkspaceFindingRepository>(
    () => const WorkspaceFindingRepository(),
  );
  getIt.registerLazySingleton<WorkspaceSweepService>(
    () => WorkspaceSweepService(
      findings: getIt<WorkspaceFindingRepository>(),
      products: getIt<ProductRepository>(),
      conversations: getIt<ConversationRepository>(),
      documents: getIt<KnowledgeDocumentRepository>(),
      connectors: getIt<WorkspaceConnectorRepository>(),
      tickets: getIt<SupportTicketRepository>(),
    ),
  );

  // Answers the OWNER, in the dashboard. Distinct from
  // BotKnowledgeService, which answers CUSTOMERS on a channel — see
  // workspace_answer_service.dart on why the two cannot share a posture
  // (one escalates to a human, the other is talking TO the human).
  getIt.registerLazySingleton<WorkspaceAnswerService>(
    () => WorkspaceAnswerService(
      aiOrchestrator: getIt<AiOrchestrator>(),
      memory: getIt<MemoryRetrievalService>(),
      products: getIt<ProductRepository>(),
    ),
  );

  getIt.registerLazySingleton<BotKnowledgeService>(
    () => BotKnowledgeService(
      aiOrchestrator: getIt<AiOrchestrator>(),
      // Phase 9 — real long-term memory, replacing the knowledgeSeed-only
      // grounding this service shipped with in Phase 3b.
      retrieval: getIt<MemoryRetrievalService>(),
    ),
  );
  // Task #139 — Bot Mother v1 (see bot_mother_service.dart's header for
  // exactly how narrow "v1" is here).
  getIt.registerLazySingleton<BotMotherService>(
    () => BotMotherService(aiOrchestrator: getIt<AiOrchestrator>()),
  );

  // Escalation feature — Conversation/Message + owner notification
  // system. See owner_notification_dispatcher.dart for how these all
  // tie together.
  getIt.registerLazySingleton<ConversationRepository>(() => const ConversationRepository());
  getIt.registerLazySingleton<MessageRepository>(() => const MessageRepository());
  getIt.registerLazySingleton<OwnerNotificationSettingsRepository>(
    () => const OwnerNotificationSettingsRepository(),
  );
  getIt.registerLazySingleton<OwnerNotificationSendRepository>(
    () => const OwnerNotificationSendRepository(),
  );
  getIt.registerLazySingleton<NotificationRateLimiter>(
    () => NotificationRateLimiter(sends: getIt<OwnerNotificationSendRepository>()),
  );
  getIt.registerLazySingleton<OwnerNotificationDispatcher>(
    () => OwnerNotificationDispatcher(
      settingsRepo: getIt<OwnerNotificationSettingsRepository>(),
      workspaces: getIt<WorkspaceRepository>(),
      rateLimiter: getIt<NotificationRateLimiter>(),
    ),
  );
  // Phase 3d — pattern-based security filter (SRS.md §10), the seam the
  // full fraud-prevention engine plugs into later.
  getIt.registerLazySingleton<SecurityFilter>(() => SecurityFilter());

  getIt.registerLazySingleton<InboundMessageHandler>(
    () => InboundMessageHandler(
      bots: getIt<BotRepository>(),
      conversations: getIt<ConversationRepository>(),
      messages: getIt<MessageRepository>(),
      workspaces: getIt<WorkspaceRepository>(),
      usageRecords: getIt<UsageRecordRepository>(),
      // Task #134 — active Errands become this turn's AI tool list, and
      // a chosen tool call dispatches through this same service
      // ErrandEndpoint.executeErrand uses — see inbound_message_handler.
      // dart's header.
      errands: getIt<ErrandRepository>(),
      knowledgeService: getIt<BotKnowledgeService>(),
      errandDispatch: getIt<ErrandDispatchService>(),
      notificationDispatcher: getIt<OwnerNotificationDispatcher>(),
      securityFilter: getIt<SecurityFilter>(),
      trialStateMachine: getIt<TrialStateMachine>(),
    ),
  );

  // Phase 5b — trial state machine + the service that actually sweeps
  // and persists trialing → paused once a workspace's 14-day window
  // passes. See trial_sweep_service.dart's header for why this runs off
  // a plain Timer in server.dart rather than a Serverpod FutureCall.
  getIt.registerLazySingleton<TrialStateMachine>(() => const TrialStateMachine());
  getIt.registerLazySingleton<TrialSweepService>(
    () => TrialSweepService(workspaces: getIt<WorkspaceRepository>()),
  );

  // Phase 5a — billing-gateway record + daily usage-metering rollups.
  // See subscription.spy.yaml / usage_record.spy.yaml for what each is
  // for and why they're separate from Workspace's own plan/status.
  getIt.registerLazySingleton<SubscriptionRepository>(() => const SubscriptionRepository());
  getIt.registerLazySingleton<UsageRecordRepository>(() => const UsageRecordRepository());

  // Phase 5c — gateway HTTP wrappers. Registered here like everything
  // else even though no Endpoint calls them yet (see each service's
  // header for why): the DI graph should be the one place every service
  // this server knows how to construct lives, not just the ones already
  // wired to a caller. Empty secret keys are fine at registration time —
  // these classes don't validate their key until a call is actually made,
  // unlike ChannelCredentialEncryptionService.init's eager check.
  getIt.registerLazySingleton<PaystackService>(
    () => PaystackService(secretKey: Env.paystackSecretKey),
  );
  getIt.registerLazySingleton<FlutterwaveService>(
    () => FlutterwaveService(secretKey: Env.flutterwaveSecretKey),
  );

  // Task #82 — nightly Telegram/WhatsApp credential health check
  // (SRS.md §13). Depends only on repositories + the notification
  // dispatcher already registered above — the actual per-platform probe
  // calls (TelegramBotRegistry.checkHealth / WhatsAppBotRegistry.
  // checkHealth) go through those registries' own singletons
  // (TelegramBotRegistry.instance / WhatsAppBotRegistry.instance), not
  // through get_it, so there's nothing else to inject here.
  getIt.registerLazySingleton<ChannelHealthCheckService>(
    () => ChannelHealthCheckService(
      channels: getIt<ChannelRepository>(),
      bots: getIt<BotRepository>(),
      notifications: getIt<OwnerNotificationDispatcher>(),
    ),
  );

  // Task #127 / Phase 8a — a workspace's OWN Paystack/Flutterwave
  // credentials + the checkouts initiated against them. Deliberately
  // NOT registering per-workspace PaystackService/FlutterwaveService
  // instances here — those need a decrypted secret key that only exists
  // once a specific workspace's credential is loaded, so PaymentEndpoint
  // and PaymentWebhookHandler construct them on demand instead (same
  // "decrypt only at the moment a credential is actually needed" rule
  // every other credential in this codebase already follows).
  getIt.registerLazySingleton<PaymentGatewayCredentialRepository>(
    () => const PaymentGatewayCredentialRepository(),
  );
  getIt.registerLazySingleton<PaymentTransactionRepository>(
    () => const PaymentTransactionRepository(),
  );
  // The actual checkout logic (task #128) — shared by PaymentEndpoint
  // (auth-gated, external callers) and BuiltinErrandExecutor's
  // 'collectPayment' handler (already-trusted, internal caller). See
  // payment_checkout_service.dart's header for why it takes no
  // Session/accessToken itself.
  getIt.registerLazySingleton<PaymentCheckoutService>(() => PaymentCheckoutService());

  // Task #130 / Phase 8b — complaint ticketing with SLA tracking. The
  // sweep depends on ConversationRepository (already registered above)
  // purely to look up a customer's display name for the breach
  // notification body — see support_ticket_sla_sweep_service.dart.
  getIt.registerLazySingleton<SupportTicketRepository>(
    () => const SupportTicketRepository(),
  );
  getIt.registerLazySingleton<SupportTicketSlaSweepService>(
    () => SupportTicketSlaSweepService(
      tickets: getIt<SupportTicketRepository>(),
      conversations: getIt<ConversationRepository>(),
      notifications: getIt<OwnerNotificationDispatcher>(),
    ),
  );

  // Task #132 / Phase 8b — birthday/anniversary campaigns. The sweep
  // depends on ConversationRepository/WorkspaceRepository (already
  // registered above) purely to resolve which channel/platform to send
  // over and whose name to put in the greeting — see
  // customer_campaign_sweep_service.dart for why WhatsApp is skipped.
  getIt.registerLazySingleton<CustomerProfileRepository>(
    () => const CustomerProfileRepository(),
  );
  getIt.registerLazySingleton<CustomerCampaignSweepService>(
    () => CustomerCampaignSweepService(
      profiles: getIt<CustomerProfileRepository>(),
      conversations: getIt<ConversationRepository>(),
      workspaces: getIt<WorkspaceRepository>(),
      // Task #155 — WhatsApp birthday/anniversary greetings now need
      // these to get-or-create an approved Meta template per channel;
      // see customer_campaign_sweep_service.dart's header.
      channels: getIt<ChannelRepository>(),
      whatsAppTemplateRepo: getIt<WhatsAppMessageTemplateRepository>(),
      whatsAppTemplates: getIt<WhatsAppTemplateCreationService>(),
    ),
  );

  // Phase 8b — OTP delivery via email, the last of the three "templated
  // Errand library" sub-features (see otp_service.dart's header for why
  // email, and why its parameters mirror asami_server's own auth_service.dart).
  getIt.registerLazySingleton<OtpCodeRepository>(() => const OtpCodeRepository());
  getIt.registerLazySingleton<OtpService>(
    () => OtpService(otpCodes: getIt<OtpCodeRepository>()),
  );

  // Task #150 — programmatic WhatsApp message templates. No sweep/
  // service to wire alongside this one: template status is refreshed
  // on demand (WhatsAppTemplateEndpoint.refreshTemplateStatus), not on
  // a background timer, since there's no webhook driving it yet — see
  // whatsapp_template_service.dart's header.
  getIt.registerLazySingleton<WhatsAppMessageTemplateRepository>(
    () => const WhatsAppMessageTemplateRepository(),
  );
  // Task #154 — the shared "submit a template" logic behind BOTH
  // WhatsAppTemplateEndpoint (manual, dashboard-triggered) and
  // BuiltinErrandExecutor's 'createProductListTemplate' (AI-triggered,
  // no dashboard visit) — see whatsapp_template_creation_service.dart's
  // header for the full reasoning.
  getIt.registerLazySingleton<WhatsAppTemplateCreationService>(
    () => WhatsAppTemplateCreationService(),
  );

  // Task #148 — Kola's own SaaS subscription checkout (₦10,000/month,
  // CONFIRMED WITH THE USER 2026-07-27) — see kola_billing_service.dart's
  // header for why this is fully separate from PaymentCheckoutService.
  getIt.registerLazySingleton<KolaBillingCheckoutRepository>(
    () => const KolaBillingCheckoutRepository(),
  );
  getIt.registerLazySingleton<KolaBillingService>(() => KolaBillingService());

  Log.startupSuccess(
    'Dependency injection ready (22 repositories, 1 AI orchestrator, 1 knowledge service, '
    '1 errand dispatch service, 1 rate limiter, 1 notification dispatcher, 1 inbound message handler, '
    '1 trial state machine, 1 trial sweep service, 2 payment gateway services, '
    '1 channel health check service, 1 support ticket SLA sweep service, '
    '1 customer campaign sweep service registered)',
  );
}
