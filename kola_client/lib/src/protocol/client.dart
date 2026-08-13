/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:kola_client/src/protocol/bot.dart' as _i3;
import 'package:kola_client/src/protocol/channel.dart' as _i4;
import 'package:kola_client/src/protocol/connector_status.dart' as _i5;
import 'package:kola_client/src/protocol/conversation.dart' as _i6;
import 'package:kola_client/src/protocol/message.dart' as _i7;
import 'package:kola_client/src/protocol/errand.dart' as _i8;
import 'package:kola_client/src/protocol/knowledge_document.dart' as _i9;
import 'package:kola_client/src/protocol/knowledge_search_hit.dart' as _i10;
import 'package:kola_client/src/protocol/owner_notification_settings.dart'
    as _i11;
import 'package:kola_client/src/protocol/payment_gateway_credential.dart'
    as _i12;
import 'package:kola_client/src/protocol/payment_transaction.dart' as _i13;
import 'package:kola_client/src/protocol/api_key.dart' as _i14;
import 'package:kola_client/src/protocol/created_api_key.dart' as _i15;
import 'package:kola_client/src/protocol/webhook_endpoint.dart' as _i16;
import 'package:kola_client/src/protocol/support_ticket.dart' as _i17;
import 'package:kola_client/src/protocol/waitlist_signup.dart' as _i18;
import 'package:kola_client/src/protocol/whatsapp_message_template.dart'
    as _i19;
import 'package:kola_client/src/protocol/workspace.dart' as _i20;
import 'package:kola_client/src/protocol/kola_billing_checkout.dart' as _i21;
import 'protocol.dart' as _i22;

/// {@category Endpoint}
class EndpointBot extends _i1.EndpointRef {
  EndpointBot(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'bot';

  /// Creates a new Bot inside a workspace, starting life as 'draft' (see
  /// bot_repository.dart's create() for the full lifecycle note). This is
  /// the step Bot Mother/the onboarding wizard calls right after
  /// WorkspaceEndpoint.createWorkspace — the resulting Bot.id is what
  /// every ChannelEndpoint method needs to connect a Telegram or
  /// WhatsApp channel to it.
  _i2.Future<_i3.Bot> createBot(
    String accessToken,
    int workspaceId,
    String name,
    String archetype,
  ) => caller.callServerEndpoint<_i3.Bot>(
    'bot',
    'createBot',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'archetype': archetype,
    },
  );

  /// TASK #139 — the dashboard home page's composer ("What do you want
  /// kola to help with today?") calls this instead of [createBot] when
  /// a business just describes what they want in plain language rather
  /// than filling in CreateBotPage's name/archetype form directly. Uses
  /// [BotMotherService] to turn [description] into that same
  /// {name, archetype, knowledgeSeed} shape, then persists it through
  /// the EXACT SAME rules [createBot] already enforces (name can't be
  /// empty after drafting — can't happen given BotMotherService's own
  /// fallback naming, but checked anyway rather than trusting an AI
  /// service's output blindly) and the same starting 'draft' status.
  /// This is a drafting step layered on top of [createBot]'s existing
  /// contract, not a parallel bot-creation path with different rules.
  ///
  /// A REAL, BUT DELIBERATELY NARROW, SLICE OF "BOT MOTHER": full Bot
  /// Mother (DEVELOPMENT_PLAN.md §8c) means a whole WhatsApp/Telegram-
  /// native onboarding conversation — genuinely unscoped product work,
  /// still not started. This is the specific, concretely-scoped gap the
  /// composer already implied by sitting right above a "Create a new
  /// bot" quick action: describe it once here, get a real Bot back.
  _i2.Future<_i3.Bot> createBotFromDescription(
    String accessToken,
    int workspaceId,
    String description,
  ) => caller.callServerEndpoint<_i3.Bot>(
    'bot',
    'createBotFromDescription',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'description': description,
    },
  );

  /// Every bot belonging to a workspace — the dashboard's bot list/
  /// switcher, and the prerequisite lookup before a Channels page can
  /// call ChannelEndpoint.listChannelsForBot for any one of them.
  _i2.Future<List<_i3.Bot>> listBotsForWorkspace(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i3.Bot>>(
    'bot',
    'listBotsForWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Fetch one bot by id — access-checked via its workspace, same
  /// "never leak existence to a non-member" posture as
  /// WorkspaceEndpoint.getWorkspace and BotRepository.findByIdScoped.
  _i2.Future<_i3.Bot> getBot(
    String accessToken,
    int workspaceId,
    int botId,
  ) => caller.callServerEndpoint<_i3.Bot>(
    'bot',
    'getBot',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
    },
  );

  /// Renames a bot and/or changes its archetype. Deliberately does NOT
  /// allow changing status through this method — status is a lifecycle
  /// transition driven by real events (a channel connecting via
  /// ChannelEndpoint, a workspace pausing on trial expiry), not a
  /// free-form field an owner edits directly. See
  /// bot_repository.dart's setStatus for where that actually happens.
  _i2.Future<_i3.Bot> updateBot(
    String accessToken,
    int workspaceId,
    int botId,
    String name,
    String archetype,
  ) => caller.callServerEndpoint<_i3.Bot>(
    'bot',
    'updateBot',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'name': name,
      'archetype': archetype,
    },
  );

  /// Sets (or clears, by passing an empty string) the bot's minimal
  /// knowledge seed — see bot.spy.yaml's header on why this is a plain
  /// pasted-in text field, not real KnowledgeDocument retrieval. Kept as
  /// its own method rather than folded into updateBot for the same
  /// reason status has its own setStatus: this is a distinct, purposeful
  /// action ("teach the bot this"), not a generic field edit.
  ///
  /// Phase 5 plan limits: a cappedFree/paused workspace's knowledge seed
  /// is capped at PlanLimits.cappedFreeKnowledgeSeedCharCap characters —
  /// see that constant's own comment on why, unlike the message/Errand
  /// caps, this particular number is a placeholder, not a confirmed
  /// product decision.
  _i2.Future<_i3.Bot> setKnowledgeSeed(
    String accessToken,
    int workspaceId,
    int botId,
    String knowledgeSeed,
  ) => caller.callServerEndpoint<_i3.Bot>(
    'bot',
    'setKnowledgeSeed',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'knowledgeSeed': knowledgeSeed,
    },
  );

  /// Sets (or clears, by passing an empty string) either or both of the
  /// cost-saving handoff fields — see bot.spy.yaml's header on why these
  /// exist and why a bot only ever mentions what's actually filled in
  /// here. Kept as its own method for the same reason [setKnowledgeSeed]
  /// is: a distinct, purposeful action, not a generic field edit folded
  /// into [updateBot].
  _i2.Future<_i3.Bot> setCostSavingContacts(
    String accessToken,
    int workspaceId,
    int botId,
    String telegramLink,
    String alternateWhatsapp,
  ) => caller.callServerEndpoint<_i3.Bot>(
    'bot',
    'setCostSavingContacts',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'telegramLink': telegramLink,
      'alternateWhatsapp': alternateWhatsapp,
    },
  );
}

/// {@category Endpoint}
class EndpointChannel extends _i1.EndpointRef {
  EndpointChannel(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'channel';

  /// Connects [botToken] (a token from @BotFather) as the Telegram
  /// channel for [botId] inside [workspaceId]. Returns the resulting
  /// Channel row, now in 'connected' status with a real, encrypted
  /// credential and a live webhook already registered with Telegram.
  ///
  /// NOTE ON ROLE SCOPING: deliberately open to any workspace member for
  /// now (like WorkspaceEndpoint.getWorkspace), not owner-only — connecting
  /// the one bot a small business runs isn't a sensitive-enough action to
  /// gate by role at this phase. Revisit once the 'staff'/'developer'
  /// role split actually needs enforcing here (SRS.md §5).
  _i2.Future<_i4.Channel> connectTelegramChannel(
    String accessToken,
    int workspaceId,
    int botId,
    String botToken,
  ) => caller.callServerEndpoint<_i4.Channel>(
    'channel',
    'connectTelegramChannel',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'botToken': botToken,
    },
  );

  /// Every channel connected to one of the caller's own bots — for the
  /// dashboard's "Channels" page. Deliberately takes botId (not
  /// workspaceId alone) since Channel.botId is the actual foreign key;
  /// findByIdScoped on the bot is what proves workspace ownership.
  _i2.Future<List<_i4.Channel>> listChannelsForBot(
    String accessToken,
    int workspaceId,
    int botId,
  ) => caller.callServerEndpoint<List<_i4.Channel>>(
    'channel',
    'listChannelsForBot',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
    },
  );

  /// Connects a WhatsApp number the MANUAL way — the business has
  /// already gone through Meta's App Dashboard themselves (per
  /// docs/WHATSAPP_MANUAL_SETUP.md) and generated their own access
  /// token, phone_number_id, and WABA id from their own small Meta App.
  ///
  /// WHY THIS NEEDS ZERO APP REVIEW ON KOLA'S SIDE: a WhatsApp Cloud API
  /// bearer token's validity is checked by Meta against the token's own
  /// grants (which app issued it, what assets that app's System User has
  /// Standard Access to) — never against which server makes the HTTP
  /// call. The business's token was issued by THEIR app, over THEIR own
  /// number, so it works from Kola's servers exactly as it would from
  /// theirs — see whatsapp_service.dart's header for the same reasoning
  /// from the calling-code side. This is deliberately built as the
  /// primary path (not a fallback) per the product decision to lead
  /// with manual connect and treat Embedded Signup as an automatic
  /// alternative layered in later, not a dependency this path needs.
  ///
  /// WHY PROBE BEFORE PERSISTING: identical reasoning to
  /// connectTelegramChannel's getMe() call — a pasted-in token/ID
  /// combination is easy to get wrong (copying the App's access token
  /// instead of the System User's, mismatching phone_number_id and
  /// waba_id from different numbers). probe() calls Meta for real before
  /// anything touches the DB, so a bad paste fails with a clear message
  /// instead of sitting as a 'connected' channel that can never send.
  ///
  /// WHY appId/appSecret ARE NOW REQUIRED TOO (added after the initial
  /// build): appSecret is what lets WhatsAppBotRegistry verify the
  /// X-Hub-Signature-256 header on inbound webhooks — without it, this
  /// channel could send messages fine but couldn't safely trust anything
  /// arriving at the shared /webhooks/whatsapp route as really being from
  /// Meta (see whatsapp_signature_verifier.dart's header for the full
  /// reasoning). appId is stored alongside it mainly so debugToken()
  /// below has what it needs without asking the business to dig it up
  /// twice. Both live in the same App Dashboard → Settings → Basic page
  /// docs/WHATSAPP_MANUAL_SETUP.md's Step 5a walks through.
  _i2.Future<_i4.Channel> connectWhatsAppChannelManual(
    String accessToken,
    int workspaceId,
    int botId,
    String whatsappAccessToken,
    String phoneNumberId,
    String wabaId,
    String whatsappAppId,
    String whatsappAppSecret,
  ) => caller.callServerEndpoint<_i4.Channel>(
    'channel',
    'connectWhatsAppChannelManual',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'whatsappAccessToken': whatsappAccessToken,
      'phoneNumberId': phoneNumberId,
      'wabaId': wabaId,
      'whatsappAppId': whatsappAppId,
      'whatsappAppSecret': whatsappAppSecret,
    },
  );
}

/// {@category Endpoint}
class EndpointConnector extends _i1.EndpointRef {
  EndpointConnector(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'connector';

  /// Every connector in the catalog with this workspace's state resolved
  /// onto it — all 15, always. A connector the workspace cannot use yet
  /// comes back as `soon` rather than being omitted, because the
  /// marketplace draws it either way.
  ///
  /// Unlike FeatureEndpoint.listEnabledFeatures, this DOES disclose the
  /// existence of unreleased capabilities — that is the design's
  /// coming-soon tile, and it is a deliberate exception to the
  /// absence-not-false rule rather than an oversight. The exception is
  /// narrow: connector names only. No flag key, no state, nothing about
  /// the rest of the roadmap.
  _i2.Future<List<_i5.ConnectorStatus>> listConnectors(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i5.ConnectorStatus>>(
    'connector',
    'listConnectors',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Connects a generic-store connector by storing the values from its
  /// catalog-defined form.
  ///
  /// [values] is keyed by ConnectorField.key. Anything not declared on
  /// the connector's own definition is DROPPED rather than stored —
  /// a caller cannot invent fields, so the encrypted blob's shape stays
  /// the one the catalog describes.
  _i2.Future<_i5.ConnectorStatus> connectConnector(
    String accessToken,
    int workspaceId,
    String connectorKey,
    Map<String, String> values,
  ) => caller.callServerEndpoint<_i5.ConnectorStatus>(
    'connector',
    'connectConnector',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'values': values,
    },
  );

  /// Disconnects, clearing the stored credential but keeping the row —
  /// 'disconnected' and "never connected" are different states, and the
  /// row is the only record that this business ever had it working.
  _i2.Future<_i5.ConnectorStatus> disconnectConnector(
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) => caller.callServerEndpoint<_i5.ConnectorStatus>(
    'connector',
    'disconnectConnector',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
    },
  );
}

/// {@category Endpoint}
class EndpointConversation extends _i1.EndpointRef {
  EndpointConversation(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'conversation';

  /// Every escalated conversation for a workspace, most recently active
  /// first — the inbox's main queue.
  _i2.Future<List<_i6.Conversation>> listEscalated(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i6.Conversation>>(
    'conversation',
    'listEscalated',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Every conversation for a workspace regardless of status — for a
  /// future "all conversations" view beyond just the escalated queue.
  _i2.Future<List<_i6.Conversation>> listAll(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i6.Conversation>>(
    'conversation',
    'listAll',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// The full message thread for one conversation, oldest first.
  _i2.Future<List<_i7.Message>> getMessages(
    String accessToken,
    int workspaceId,
    int conversationId,
  ) => caller.callServerEndpoint<List<_i7.Message>>(
    'conversation',
    'getMessages',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
    },
  );

  /// The human's reply — persisted as a Message (senderType 'human')
  /// and actually sent back to the customer over whichever platform
  /// (Telegram/WhatsApp) the conversation is on, via that platform's
  /// registry (same messagingFor(channelId) adapters the bot itself
  /// uses to send). Does NOT change the conversation's status — it
  /// stays 'escalated' until the human explicitly closes it (see
  /// [closeConversation]), since one reply doesn't necessarily resolve
  /// things.
  _i2.Future<_i7.Message> sendHumanReply(
    String accessToken,
    int workspaceId,
    int conversationId,
    String body,
  ) => caller.callServerEndpoint<_i7.Message>(
    'conversation',
    'sendHumanReply',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'body': body,
    },
  );

  /// Marks a conversation resolved — status flips to 'closed', so the
  /// bot resumes auto-replying if the customer messages again (see
  /// ConversationRepository.findOrCreate's reopen-on-new-message logic).
  _i2.Future<_i6.Conversation> closeConversation(
    String accessToken,
    int workspaceId,
    int conversationId,
  ) => caller.callServerEndpoint<_i6.Conversation>(
    'conversation',
    'closeConversation',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
    },
  );
}

/// {@category Endpoint}
class EndpointErrand extends _i1.EndpointRef {
  EndpointErrand(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'errand';

  /// Registers a new built-in Errand — see file header on why only
  /// 'builtin' is accepted today. [builtinHandlerKey] must match one of
  /// BuiltinErrandExecutor's registered handlers (currently just
  /// 'escalateToHuman') — validated against Meta... no, against that
  /// registry directly, so a typo'd key fails here with a clear message
  /// instead of at first invocation.
  _i2.Future<_i8.Errand> createBuiltinErrand(
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String builtinHandlerKey,
    String createdVia, {
    required String permissionScope,
    required String inputSchemaJson,
    required String sensitiveInputKeysJson,
  }) => caller.callServerEndpoint<_i8.Errand>(
    'errand',
    'createBuiltinErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'descriptionForAi': descriptionForAi,
      'builtinHandlerKey': builtinHandlerKey,
      'createdVia': createdVia,
      'permissionScope': permissionScope,
      'inputSchemaJson': inputSchemaJson,
      'sensitiveInputKeysJson': sensitiveInputKeysJson,
    },
  );

  /// Every Errand belonging to a workspace, regardless of status.
  _i2.Future<List<_i8.Errand>> listErrandsForWorkspace(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i8.Errand>>(
    'errand',
    'listErrandsForWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Fetch one Errand by id — access-checked via its workspace, same
  /// posture as BotEndpoint.getBot.
  _i2.Future<_i8.Errand> getErrand(
    String accessToken,
    int workspaceId,
    int errandId,
  ) => caller.callServerEndpoint<_i8.Errand>(
    'errand',
    'getErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
    },
  );

  /// Toggle an Errand active/disabled without deleting its history/logs.
  _i2.Future<_i8.Errand> setErrandStatus(
    String accessToken,
    int workspaceId,
    int errandId,
    String status,
  ) => caller.callServerEndpoint<_i8.Errand>(
    'errand',
    'setErrandStatus',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
      'status': status,
    },
  );

  /// Permanently deletes an Errand — ONLY when it's already 'disabled'.
  /// An owner asked for this directly: "errands that are disabled should
  /// be deletable." A live/active Errand is not deletable through this
  /// method — disable it first (setErrandStatus), same two-step guard
  /// rail every other "destroy something" flow in this codebase already
  /// requires, so nothing mid-conversation ever loses the Errand it's
  /// about to call out from under it. Deletes the Errand's own row AND
  /// its credential row (if any) — see errand_credential_repository.dart
  /// — but deliberately leaves its ErrandExecutionLog history alone
  /// (SRS.md §7.3's execution log is an audit trail; deleting the Errand
  /// that generated an entry shouldn't erase that it happened).
  _i2.Future<void> deleteErrand(
    String accessToken,
    int workspaceId,
    int errandId,
  ) => caller.callServerEndpoint<void>(
    'errand',
    'deleteErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
    },
  );

  /// Runs a 'builtin' Errand right now, synchronously, and returns its
  /// result as a JSON string — same "flexible shape lives in a JSON
  /// string" pattern as inputSchemaJson, since a raw `Map<String,dynamic>`
  /// isn't a type Serverpod's codegen can safely serialize. [inputJson]
  /// is a JSON-encoded Map matching the Errand's inputSchemaJson shape.
  /// Every invocation is logged (success or failure) by
  /// BuiltinErrandExecutor before this method returns/throws — see its
  /// file header.
  _i2.Future<String> executeBuiltinErrand(
    String accessToken,
    int workspaceId,
    int errandId,
    String inputJson,
  ) => caller.callServerEndpoint<String>(
    'errand',
    'executeBuiltinErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
      'inputJson': inputJson,
    },
  );

  /// Registers a new webhook-backed Errand AND collects/encrypts its
  /// credential in one call — a business connecting a webhook Errand
  /// shouldn't be left with a half-registered Errand that has nowhere
  /// to send its calls. [webhookUrl] must be a valid absolute URL (any
  /// scheme — https strongly recommended, but not enforced here, since
  /// local dev/testing against plain http is a real, legitimate case).
  /// [authHeaderName]/[authHeaderValue] are optional and sent together
  /// or not at all — see webhook_errand_credential.dart.
  _i2.Future<_i8.Errand> createWebhookErrand(
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String createdVia,
    String webhookUrl, {
    String? authHeaderName,
    String? authHeaderValue,
    required String permissionScope,
    required String inputSchemaJson,
    required String sensitiveInputKeysJson,
  }) => caller.callServerEndpoint<_i8.Errand>(
    'errand',
    'createWebhookErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'descriptionForAi': descriptionForAi,
      'createdVia': createdVia,
      'webhookUrl': webhookUrl,
      'authHeaderName': authHeaderName,
      'authHeaderValue': authHeaderValue,
      'permissionScope': permissionScope,
      'inputSchemaJson': inputSchemaJson,
      'sensitiveInputKeysJson': sensitiveInputKeysJson,
    },
  );

  /// Registers a new database-credential Errand AND collects/encrypts
  /// its connection string in one call — same "never half-registered"
  /// reasoning as createWebhookErrand. [queryTemplateSql] is the ONE
  /// pre-approved named-parameter query this Errand will ever run (see
  /// errand.spy.yaml's queryTemplateSql header) — if [permissionScope]
  /// is 'readOnly' (the default), it must start with SELECT, checked
  /// here at registration time AND again at execution time by
  /// DbCredentialErrandExecutor (defense in depth against the template
  /// being edited later without a matching permission upgrade).
  _i2.Future<_i8.Errand> createDbCredentialErrand(
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String createdVia,
    String queryTemplateSql,
    String connectionString, {
    required String permissionScope,
    required String inputSchemaJson,
    required String sensitiveInputKeysJson,
  }) => caller.callServerEndpoint<_i8.Errand>(
    'errand',
    'createDbCredentialErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'descriptionForAi': descriptionForAi,
      'createdVia': createdVia,
      'queryTemplateSql': queryTemplateSql,
      'connectionString': connectionString,
      'permissionScope': permissionScope,
      'inputSchemaJson': inputSchemaJson,
      'sensitiveInputKeysJson': sensitiveInputKeysJson,
    },
  );

  /// Runs ANY Errand right now, synchronously, dispatching to the right
  /// executor by errand.source — see file header on why this is one
  /// method rather than three. Same JSON-string-in/JSON-string-out
  /// contract as executeBuiltinErrand.
  _i2.Future<String> executeErrand(
    String accessToken,
    int workspaceId,
    int errandId,
    String inputJson,
  ) => caller.callServerEndpoint<String>(
    'errand',
    'executeErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
      'inputJson': inputJson,
    },
  );
}

/// {@category Endpoint}
class EndpointFeature extends _i1.EndpointRef {
  EndpointFeature(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'feature';

  /// Every feature key currently available to this workspace.
  ///
  /// The dashboard calls this once on load and renders navigation and
  /// routes from the result. Keys absent from the list do not exist as
  /// far as that session is concerned — see this file's header on why
  /// absence rather than `false`.
  _i2.Future<List<String>> listEnabledFeatures(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<String>>(
    'feature',
    'listEnabledFeatures',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Whether one specific feature is available. Exists for the case
  /// where a page needs to re-check after a plan upgrade without
  /// reloading the whole set — not as the general mechanism.
  ///
  /// Returns false for an unknown key rather than throwing, matching
  /// FeatureFlagService's fail-closed posture: a dashboard built against
  /// a newer server should degrade to hiding a feature, never to an
  /// error screen.
  _i2.Future<bool> isFeatureEnabled(
    String accessToken,
    int workspaceId,
    String featureKey,
  ) => caller.callServerEndpoint<bool>(
    'feature',
    'isFeatureEnabled',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'featureKey': featureKey,
    },
  );
}

/// {@category Endpoint}
class EndpointKnowledge extends _i1.EndpointRef {
  EndpointKnowledge(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'knowledge';

  /// Every document in the workspace, newest first.
  _i2.Future<List<_i9.KnowledgeDocument>> listDocuments(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i9.KnowledgeDocument>>(
    'knowledge',
    'listDocuments',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Ingests [text] as a new document: dedupe, chunk, embed, index.
  ///
  /// THROWS with an owner-readable message on every non-success path
  /// (duplicate, empty, quota exhausted, embeddings unconfigured) rather
  /// than returning a status object. That's the convention every other
  /// endpoint in this codebase already follows, and it keeps the
  /// generated client's return type honest — a KnowledgeDocument here
  /// always means a document that is actually searchable.
  ///
  /// The one place that's a slightly awkward fit is 'duplicate', which
  /// isn't really an error. The message says so plainly and names the
  /// existing document, so the dashboard can offer "save it anyway"
  /// (which calls this again with [allowDuplicate] true) rather than
  /// presenting a dead end.
  _i2.Future<_i9.KnowledgeDocument> addDocument(
    String accessToken,
    int workspaceId,
    String title,
    String text, {
    required bool allowDuplicate,
  }) => caller.callServerEndpoint<_i9.KnowledgeDocument>(
    'knowledge',
    'addDocument',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'title': title,
      'text': text,
      'allowDuplicate': allowDuplicate,
    },
  );

  /// Removes a document from memory. Its chunks go with it via ON DELETE
  /// CASCADE (migration 017), so the bot genuinely stops knowing this —
  /// there is no path that leaves retrievable chunks behind.
  _i2.Future<void> deleteDocument(
    String accessToken,
    int workspaceId,
    int documentId,
  ) => caller.callServerEndpoint<void>(
    'knowledge',
    'deleteDocument',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'documentId': documentId,
    },
  );

  /// Replaces an existing document's content in place, keeping its id.
  _i2.Future<_i9.KnowledgeDocument> updateDocument(
    String accessToken,
    int workspaceId,
    int documentId,
    String title,
    String text,
  ) => caller.callServerEndpoint<_i9.KnowledgeDocument>(
    'knowledge',
    'updateDocument',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'documentId': documentId,
      'title': title,
      'text': text,
    },
  );

  /// Runs a real memory search and returns what the bot WOULD retrieve
  /// for [query], scores included.
  ///
  /// This is an inspection tool, and it is the reason
  /// knowledge_search_hit.spy.yaml exists — see that file's header. An
  /// owner can type a question a customer actually asked and see exactly
  /// which passages ground the answer, rather than having to trust the
  /// bot or argue with it.
  _i2.Future<List<_i10.KnowledgeSearchHit>> searchMemory(
    String accessToken,
    int workspaceId,
    String query,
  ) => caller.callServerEndpoint<List<_i10.KnowledgeSearchHit>>(
    'knowledge',
    'searchMemory',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'query': query,
    },
  );
}

/// {@category Endpoint}
class EndpointOwnerNotification extends _i1.EndpointRef {
  EndpointOwnerNotification(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'ownerNotification';

  /// Returns null if the workspace has never configured notification
  /// settings yet — callers should treat that as "every channel
  /// disabled," not an error.
  _i2.Future<_i11.OwnerNotificationSettings?> getSettings(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<_i11.OwnerNotificationSettings?>(
    'ownerNotification',
    'getSettings',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Create-or-replace — see OwnerNotificationSettingsRepository.upsert.
  /// Any field left null/false simply disables that channel; there's no
  /// partial-update semantics here on purpose, since a settings form
  /// naturally submits the whole shape at once.
  _i2.Future<_i11.OwnerNotificationSettings> updateSettings(
    String accessToken,
    int workspaceId, {
    String? ownerEmail,
    required bool emailEnabled,
    String? ownerWhatsappNumber,
    required bool whatsappEnabled,
    String? telegramChatId,
    required bool telegramEnabled,
    String? ownerSmsNumber,
    required bool smsEnabled,
    String? slackWebhookUrl,
    required bool slackEnabled,
  }) => caller.callServerEndpoint<_i11.OwnerNotificationSettings>(
    'ownerNotification',
    'updateSettings',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'ownerEmail': ownerEmail,
      'emailEnabled': emailEnabled,
      'ownerWhatsappNumber': ownerWhatsappNumber,
      'whatsappEnabled': whatsappEnabled,
      'telegramChatId': telegramChatId,
      'telegramEnabled': telegramEnabled,
      'ownerSmsNumber': ownerSmsNumber,
      'smsEnabled': smsEnabled,
      'slackWebhookUrl': slackWebhookUrl,
      'slackEnabled': slackEnabled,
    },
  );
}

/// {@category Endpoint}
class EndpointPayment extends _i1.EndpointRef {
  EndpointPayment(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'payment';

  /// Connects (or rotates) a workspace's OWN Paystack/Flutterwave secret
  /// key. Probes it against the real gateway before persisting anything.
  _i2.Future<_i12.PaymentGatewayCredential> connectGateway(
    String accessToken,
    int workspaceId,
    String gateway,
    String secretKey, {
    String? webhookSecret,
  }) => caller.callServerEndpoint<_i12.PaymentGatewayCredential>(
    'payment',
    'connectGateway',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'secretKey': secretKey,
      'webhookSecret': webhookSecret,
    },
  );

  /// Every gateway this workspace has connected (never returns the
  /// decrypted key — this exists so a dashboard can show "Paystack:
  /// connected" without exposing the secret back to any client).
  _i2.Future<List<_i12.PaymentGatewayCredential>> listConnectedGateways(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i12.PaymentGatewayCredential>>(
    'payment',
    'listConnectedGateways',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Starts a checkout against the workspace's OWN connected [gateway]
  /// account. See payment_checkout_service.dart for what actually
  /// happens — this method's only job is the auth check.
  _i2.Future<_i13.PaymentTransaction> initializeCheckout(
    String accessToken,
    int workspaceId,
    String gateway,
    int amountKobo,
    String customerEmail, {
    String? customerPhone,
    required bool holdInEscrow,
    int? conversationId,
    int? channelId,
    Map<String, dynamic>? metadata,
  }) => caller.callServerEndpoint<_i13.PaymentTransaction>(
    'payment',
    'initializeCheckout',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'amountKobo': amountKobo,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'holdInEscrow': holdInEscrow,
      'conversationId': conversationId,
      'channelId': channelId,
      'metadata': metadata,
    },
  );

  _i2.Future<_i13.PaymentTransaction?> getTransaction(
    String accessToken,
    int workspaceId,
    int transactionId,
  ) => caller.callServerEndpoint<_i13.PaymentTransaction?>(
    'payment',
    'getTransaction',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'transactionId': transactionId,
    },
  );

  /// Flips a held transaction's bookkeeping status to released — see
  /// payment_transaction.spy.yaml's header on why this is NOT a real
  /// fund-movement call. Only valid once the payment itself is
  /// 'completed'; re-checked here even though a caller "should" already
  /// know that, per this codebase's usual "never trust a caller-supplied
  /// precondition" rule (same reasoning as db_credential_errand_executor's
  /// double read-only check).
  _i2.Future<_i13.PaymentTransaction> releaseHold(
    String accessToken,
    int workspaceId,
    int transactionId,
  ) => caller.callServerEndpoint<_i13.PaymentTransaction>(
    'payment',
    'releaseHold',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'transactionId': transactionId,
    },
  );
}

/// {@category Endpoint}
class EndpointPlatform extends _i1.EndpointRef {
  EndpointPlatform(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'platform';

  /// Every key for the workspace, revoked ones included — the design
  /// shows them so an owner can see what they turned off.
  _i2.Future<List<_i14.ApiKey>> listApiKeys(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i14.ApiKey>>(
    'platform',
    'listApiKeys',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Creates a key. The response carries the ONLY copy of the plaintext.
  _i2.Future<_i15.CreatedApiKey> createApiKey(
    String accessToken,
    int workspaceId,
    String name,
    String scope,
  ) => caller.callServerEndpoint<_i15.CreatedApiKey>(
    'platform',
    'createApiKey',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'scope': scope,
    },
  );

  /// Revokes immediately. Idempotent — revoking twice keeps the original
  /// timestamp, because when it stopped working is the fact that matters.
  _i2.Future<void> revokeApiKey(
    String accessToken,
    int workspaceId,
    int keyId,
  ) => caller.callServerEndpoint<void>(
    'platform',
    'revokeApiKey',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'keyId': keyId,
    },
  );

  _i2.Future<List<_i16.WebhookEndpoint>> listWebhookEndpoints(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i16.WebhookEndpoint>>(
    'platform',
    'listWebhookEndpoints',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Registers an endpoint, or updates the one already on this URL.
  ///
  /// The signing secret is generated here and encrypted before storage —
  /// unlike an API key, kola must recover this one to sign each delivery.
  _i2.Future<_i16.WebhookEndpoint> saveWebhookEndpoint(
    String accessToken,
    int workspaceId,
    String url,
    List<String> events,
  ) => caller.callServerEndpoint<_i16.WebhookEndpoint>(
    'platform',
    'saveWebhookEndpoint',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'url': url,
      'events': events,
    },
  );

  _i2.Future<void> deleteWebhookEndpoint(
    String accessToken,
    int workspaceId,
    int endpointId,
  ) => caller.callServerEndpoint<void>(
    'platform',
    'deleteWebhookEndpoint',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'endpointId': endpointId,
    },
  );
}

/// {@category Endpoint}
class EndpointSupportTicket extends _i1.EndpointRef {
  EndpointSupportTicket(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'supportTicket';

  /// Every ticket for a workspace, newest first. [status] optionally
  /// narrows to one status (e.g. just the open queue).
  _i2.Future<List<_i17.SupportTicket>> list(
    String accessToken,
    int workspaceId, {
    String? status,
  }) => caller.callServerEndpoint<List<_i17.SupportTicket>>(
    'supportTicket',
    'list',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'status': status,
    },
  );

  /// Transitions a ticket's status — 'open' | 'inProgress' | 'resolved' |
  /// 'closed'. Setting to 'resolved'/'closed' stamps resolvedAt
  /// automatically (see SupportTicketRepository.setStatus); reopening
  /// back to 'open'/'inProgress' clears it.
  _i2.Future<_i17.SupportTicket> setStatus(
    String accessToken,
    int workspaceId,
    int ticketId,
    String status,
  ) => caller.callServerEndpoint<_i17.SupportTicket>(
    'supportTicket',
    'setStatus',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'ticketId': ticketId,
      'status': status,
    },
  );
}

/// {@category Endpoint}
class EndpointWaitlist extends _i1.EndpointRef {
  EndpointWaitlist(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'waitlist';

  /// Records a waitlist signup from the landing page. [source] identifies
  /// which on-page form submitted it ('hero' | 'waitlist_section' |
  /// 'footer') — see kola_landing's components for the three call sites.
  ///
  /// A basic shape check on [email] happens here rather than trusting the
  /// browser's <input type="email"> alone, since this endpoint is public
  /// and reachable by anything, not just our own landing page.
  _i2.Future<_i18.WaitlistSignup> joinWaitlist(
    String email,
    String source, {
    String? name,
    String? phone,
    String? businessType,
  }) => caller.callServerEndpoint<_i18.WaitlistSignup>(
    'waitlist',
    'joinWaitlist',
    {
      'email': email,
      'source': source,
      'name': name,
      'phone': phone,
      'businessType': businessType,
    },
  );
}

/// {@category Endpoint}
class EndpointWhatsAppTemplate extends _i1.EndpointRef {
  EndpointWhatsAppTemplate(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'whatsAppTemplate';

  /// The general-purpose submission path — [category] must be one of
  /// 'utility' | 'marketing' | 'authentication'. Most callers (the
  /// dashboard's "Create a template" flow) should be able to use this
  /// directly; [createProductListTemplate] below is a thin convenience
  /// wrapper for the one shape the owner specifically asked for.
  /// Auth-checked here, then delegated to WhatsAppTemplateCreationService
  /// — see this file's header.
  _i2.Future<_i19.WhatsAppMessageTemplate> createTemplate(
    String accessToken,
    int workspaceId,
    int channelId,
    String label,
    String category,
    String language,
    String bodyText,
    List<String> bodyExampleValues,
  ) => caller.callServerEndpoint<_i19.WhatsAppMessageTemplate>(
    'whatsAppTemplate',
    'createTemplate',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'channelId': channelId,
      'label': label,
      'category': category,
      'language': language,
      'bodyText': bodyText,
      'bodyExampleValues': bodyExampleValues,
    },
  );

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
  _i2.Future<_i19.WhatsAppMessageTemplate> createProductListTemplate(
    String accessToken,
    int workspaceId,
    int channelId,
    String businessLabel,
    String customerNameExample,
    String productListExample,
  ) => caller.callServerEndpoint<_i19.WhatsAppMessageTemplate>(
    'whatsAppTemplate',
    'createProductListTemplate',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'channelId': channelId,
      'businessLabel': businessLabel,
      'customerNameExample': customerNameExample,
      'productListExample': productListExample,
    },
  );

  /// Every template submitted for this workspace, newest first — the
  /// dashboard's template status list.
  _i2.Future<List<_i19.WhatsAppMessageTemplate>> listTemplatesForWorkspace(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i19.WhatsAppMessageTemplate>>(
    'whatsAppTemplate',
    'listTemplatesForWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Polls Meta for [templateId]'s current review outcome and persists
  /// any change — see whatsapp_template_service.dart's header on why
  /// this is polling, not a webhook, for now.
  _i2.Future<_i19.WhatsAppMessageTemplate> refreshTemplateStatus(
    String accessToken,
    int workspaceId,
    int templateId,
  ) => caller.callServerEndpoint<_i19.WhatsAppMessageTemplate>(
    'whatsAppTemplate',
    'refreshTemplateStatus',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'templateId': templateId,
    },
  );
}

/// {@category Endpoint}
class EndpointWorkspace extends _i1.EndpointRef {
  EndpointWorkspace(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'workspace';

  /// Creates a new workspace and makes the caller its 'owner'. This is the
  /// very first authenticated write path in the product — the moment
  /// signup actually becomes "a business now has a home on Kola."
  ///
  /// Deliberately does NOT go through requireWorkspaceAccess — there's no
  /// workspace to check membership against yet. Only session verification
  /// (proving accessToken is a genuine, current Supabase session) applies.
  ///
  /// [ownerName] and [ownerPhone] come from step 2 of
  /// Kola Create Workspace.dc.html. They were previously not accepted at
  /// all — the wizard asked for both and the server discarded them, which
  /// is worse than not asking.
  ///
  /// Both are optional so the endpoint stays callable from anywhere that
  /// only has a business name, and so an owner who skips step 2 still
  /// gets a workspace.
  /// [industryTag] STAYS POSITIONAL. It was tempting to move it into the
  /// named group with the two new fields, and doing so broke
  /// kymaa_dashboard — the frozen competition entry, which is a pub
  /// workspace member resolving this same generated client and calls
  /// this with three positional arguments.
  ///
  /// A frozen package is frozen: it does not get edited to accommodate a
  /// signature change that had no reason to be breaking. Adding the new
  /// fields as NAMED and optional keeps every existing call valid.
  _i2.Future<_i20.Workspace> createWorkspace(
    String accessToken,
    String name,
    String? industryTag, {
    String? ownerName,
    String? ownerPhone,
  }) => caller.callServerEndpoint<_i20.Workspace>(
    'workspace',
    'createWorkspace',
    {
      'accessToken': accessToken,
      'name': name,
      'industryTag': industryTag,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
    },
  );

  /// Every workspace the caller belongs to, for the dashboard's workspace
  /// switcher (relevant now for a user with zero or one workspace, and
  /// unchanged when the agency/multi-workspace tier adds more).
  _i2.Future<List<_i20.Workspace>> listMyWorkspaces(String accessToken) =>
      caller.callServerEndpoint<List<_i20.Workspace>>(
        'workspace',
        'listMyWorkspaces',
        {'accessToken': accessToken},
      );

  /// Fetch one workspace by id — access-checked, so a user can never read
  /// a workspace they're not a member of by guessing an id.
  _i2.Future<_i20.Workspace> getWorkspace(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<_i20.Workspace>(
    'workspace',
    'getWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Task #139/#8d — a workspace's plan/trial standing plus its current
  /// usage against PlanLimits, as one JSON string. Fills two gaps at
  /// once: the dashboard's "Billing" nav item had nothing real to show
  /// (Subscription — subscription.spy.yaml — stays null until Phase 5c's
  /// gateway integration is actually switched on for a real charge, so
  /// it's the wrong source for "what can this workspace do right now";
  /// Workspace.plan/.status/.trial* + TrialStateMachine.effectiveTier
  /// already ARE that source, same as every enforcement check reads),
  /// and Phase 8d's still-flagged "cross-workspace billing/summary view"
  /// (DEVELOPMENT_PLAN.md §8d) — kola_dashboard's BillingPage calls this
  /// once per workspace the caller belongs to and renders one row each
  /// when there's more than one, the same "only show switcher chrome
  /// when it's earned" posture as SidebarNav's workspace switcher
  /// (task #131).
  ///
  /// JSON STRING, NOT A NEW MODEL: same "flexible shape lives in a JSON
  /// string" pattern already used for Errand.inputSchemaJson and
  /// executeErrandNow's result — avoids a new .spy.yaml + a Serverpod
  /// codegen run just to shuttle a handful of numbers to the dashboard.
  /// Shape:
  ///   { plan, status, effectiveTier,
  ///     trialFullAccessEndsAt, trialEndsAt (null unless 'trialing'),
  ///     messagesToday, messagesDailyCap (null unless capped),
  ///     activeErrandCount, errandCap (null unless capped),
  ///     messagesThisMonth, errandCallsThisMonth }
  _i2.Future<String> getBillingSummary(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<String>(
    'workspace',
    'getBillingSummary',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Task #148 — starts a checkout for [workspaceId] to upgrade to
  /// Kola's paid ('pro') plan, using KOLA'S OWN Paystack/Flutterwave
  /// account (see KolaBillingService's header for why this is a
  /// separate flow from PaymentEndpoint.initializeCheckout, which is a
  /// workspace collecting from ITS OWN customers). [customerEmail] is
  /// the signed-in dashboard user's email — the gateway needs an email
  /// on file for the checkout page/receipt regardless of who's paying.
  _i2.Future<_i21.KolaBillingCheckout> initiateUpgrade(
    String accessToken,
    int workspaceId,
    String gateway,
    String customerEmail,
  ) => caller.callServerEndpoint<_i21.KolaBillingCheckout>(
    'workspace',
    'initiateUpgrade',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'customerEmail': customerEmail,
    },
  );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i22.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    bot = EndpointBot(this);
    channel = EndpointChannel(this);
    connector = EndpointConnector(this);
    conversation = EndpointConversation(this);
    errand = EndpointErrand(this);
    feature = EndpointFeature(this);
    knowledge = EndpointKnowledge(this);
    ownerNotification = EndpointOwnerNotification(this);
    payment = EndpointPayment(this);
    platform = EndpointPlatform(this);
    supportTicket = EndpointSupportTicket(this);
    waitlist = EndpointWaitlist(this);
    whatsAppTemplate = EndpointWhatsAppTemplate(this);
    workspace = EndpointWorkspace(this);
  }

  late final EndpointBot bot;

  late final EndpointChannel channel;

  late final EndpointConnector connector;

  late final EndpointConversation conversation;

  late final EndpointErrand errand;

  late final EndpointFeature feature;

  late final EndpointKnowledge knowledge;

  late final EndpointOwnerNotification ownerNotification;

  late final EndpointPayment payment;

  late final EndpointPlatform platform;

  late final EndpointSupportTicket supportTicket;

  late final EndpointWaitlist waitlist;

  late final EndpointWhatsAppTemplate whatsAppTemplate;

  late final EndpointWorkspace workspace;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'bot': bot,
    'channel': channel,
    'connector': connector,
    'conversation': conversation,
    'errand': errand,
    'feature': feature,
    'knowledge': knowledge,
    'ownerNotification': ownerNotification,
    'payment': payment,
    'platform': platform,
    'supportTicket': supportTicket,
    'waitlist': waitlist,
    'whatsAppTemplate': whatsAppTemplate,
    'workspace': workspace,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
