// inbound_message_handler.dart
//
// The ONE place that turns "a customer's text message just arrived on
// some channel" into the full escalation loop — shared by
// TelegramBotRegistry and WhatsAppBotRegistry so neither has to
// duplicate: find-or-create the Conversation, persist both sides of the
// exchange as Messages, skip auto-reply while a human is already
// handling things, ask BotKnowledgeService for a grounded answer, and
// — if that answer decided a human is needed — flip the Conversation to
// 'escalated' and fan out an owner notification.
//
// WHY BOTH REGISTRIES CALL THIS INSTEAD OF INLINING IT: the previous
// Phase 2a/2b canned-reply methods (_registerHardcodedReply,
// _replyToInboundMessages) were platform-specific because there was
// nothing platform-agnostic to share yet. Everything from here on
// (Conversation/Message persistence, grounding, escalation, owner
// notification) genuinely doesn't care whether the message came from
// Telegram or WhatsApp — only the very last "how do I actually send
// this reply back" step does, and that's still each registry's own
// adapter, not this file's job.
//
// PHASE 5B — PAUSED WORKSPACES STAY SILENT: PRD.md §10 stage 3 says a
// workspace past its 14-day trial (or manually paused) has its bot
// "stop responding on live channels" while keeping data intact. This is
// the one place every inbound message from every channel passes
// through, so it's the one place that enforcement belongs — checked via
// TrialStateMachine.effectiveTier right after the message is persisted
// (a paused workspace still gets a record of what the customer said;
// it just gets no reply), before any AI/security-filter work happens.
//
// PHASE 5 PLAN LIMITS — CAPPEDFREE'S DAILY MESSAGE CAP: a cappedFree
// workspace (days 3–14 of trial) isn't silent like a paused one — PRD.md
// §10 stage 2 says the bot "keeps working, just at a visibly reduced
// ceiling." Once that ceiling (PlanLimits.cappedFreeDailyMessageCap) is
// hit for the day, the customer gets one consistent notice back instead
// of an AI reply, rather than silence or an unlimited bot — checked
// right alongside the paused check below, same "before any AI work"
// placement.
//
// PHASE 3D — SECURITY FILTER WIRED IN HERE: every inbound message is
// checked (SecurityFilter.checkInboundMessage) BEFORE it's ever handed
// to BotKnowledgeService/AiOrchestrator — a blocked message never
// reaches the AI at all, the customer gets the filter's safe warning
// text back instead, and no escalation fires (an abusive/malformed
// message isn't a "the bot couldn't help" situation). The AI's own
// answer is separately checked (checkOutboundText) before it's ever
// sent back or persisted — see SRS.md §10's "before any AI-suggested
// Errand call or AI-drafted outbound message" framing, which this file
// now covers BOTH halves of: the outbound-message half (as before), AND
// (as of task #134) the AI-suggested-Errand-call half too, since that
// call now actually happens from inside this file instead of only ever
// being reachable through ErrandEndpoint's Session-authenticated path.
//
// TASK #134 — AI TOOL-CALLING ERRAND ENGINE LANDS HERE: this file used
// to call BotKnowledgeService.answerGrounded() and only ever get plain
// text back. It now calls BotKnowledgeService.decide() with the
// workspace's active Errands converted into an AiTool list (see
// errand_tool_registry.dart) — the model can either answer directly or
// choose to call one of those tools (including the reserved, always-
// available escalation tool). A chosen tool call is dispatched via
// ErrandDispatchService (the same Session-free extraction
// ErrandEndpoint.executeErrand also uses — see that service's header),
// checked through SecurityFilter.checkErrandInput first since the
// arguments were AI-inferred rather than typed by a person, and its
// result turned into a customer-facing reply (a builtin handler's own
// `replyToCustomer` field directly, or a second AI call summarizing a
// webhook/dbCredential Errand's raw JSON result for anything else).
// answerGrounded() itself is untouched — anything else still calling it
// (only tool/test_grounded_qa.dart today) keeps working unchanged.                                                           

import 'package:kola_server/kola_logger.dart';
// Channel, for the media parameters on handle().
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/message_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/usage_record_repository.dart';
import 'package:kola_server/src/services/repository/errand_repository.dart';
import 'package:kola_server/src/services/knowledge/bot_knowledge_service.dart';
import 'package:kola_server/src/services/errand/errand_tool_registry.dart';
import 'package:kola_server/src/services/errand/errand_dispatch_service.dart';
import 'package:kola_server/src/services/notifications/owner_notification_dispatcher.dart';
import 'package:kola_server/src/services/media/inbound_media_service.dart';
import 'package:kola_server/src/services/security/security_filter.dart';
import 'package:kola_server/src/services/billing/trial_state_machine.dart';
import 'package:kola_server/src/services/billing/plan_limits.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';

class InboundMessageHandler {
  InboundMessageHandler({
    required BotRepository bots,
    required ConversationRepository conversations,
    required MessageRepository messages,
    required WorkspaceRepository workspaces,
    required UsageRecordRepository usageRecords,
    required ErrandRepository errands,
    required BotKnowledgeService knowledgeService,
    required ErrandDispatchService errandDispatch,
    required OwnerNotificationDispatcher notificationDispatcher,
    required InboundMediaService inboundMedia,
    required EventBus events,
    required CustomerIdentityResolver customerIdentity,
    SecurityFilter? securityFilter,
    TrialStateMachine? trialStateMachine,
  }) : _bots = bots,
       _conversations = conversations,
       _messages = messages,
       _workspaces = workspaces,
       _usageRecords = usageRecords,
       _errands = errands,
       _knowledge = knowledgeService,
       _errandDispatch = errandDispatch,
       _notifications = notificationDispatcher,
       _inboundMedia = inboundMedia,
       _events = events,
       _customerIdentity = customerIdentity,
       _security = securityFilter ?? SecurityFilter(),
       _trialStateMachine = trialStateMachine ?? const TrialStateMachine();

  final BotRepository _bots;
  final ConversationRepository _conversations;
  final MessageRepository _messages;
  final WorkspaceRepository _workspaces;
  final UsageRecordRepository _usageRecords;
  final ErrandRepository _errands;
  final BotKnowledgeService _knowledge;
  final ErrandDispatchService _errandDispatch;
  final OwnerNotificationDispatcher _notifications;

  /// Turns a Telegram file_id or WhatsApp media id into an ImageKit URL.
  /// See inbound_media_service.dart on why the bytes go through us.
  final InboundMediaService _inboundMedia;

  /// Gate 2 — event bus. See event_bus.dart's header on why emit() is
  /// safe to call unconditionally here: the fingerprint
  /// ('new_conversation:{conversationId}') dedupes every message after
  /// the first in a conversation, so this handler doesn't need to know
  /// whether findOrCreate just created a row or found an existing one.
  final EventBus _events;

  /// Gate 3 — resolves/creates the Customer this conversation belongs
  /// to. See CustomerIdentityResolver's header for the matching
  /// algorithm and this file's own call site for why it only runs once
  /// per conversation.
  final CustomerIdentityResolver _customerIdentity;

  final SecurityFilter _security;
  final TrialStateMachine _trialStateMachine;

  /// Processes one inbound customer text message and returns the reply
  /// text the calling registry should send back — or null if nothing
  /// should be sent right now (the conversation is already escalated to
  /// a human, so the bot stays silent; see conversation_repository.dart's
  /// status state machine).
  ///
  /// [botId]/[channelId] identify which bot+channel received the
  /// message; [externalUserId] is the customer's platform-specific id
  /// (Telegram chat id, WhatsApp wa_id); [platformType] is 'telegram' or
  /// 'whatsapp'.
  Future<String?> handle({
    required int botId,
    required int channelId,
    required String platformType,
    required String externalUserId,
    String? displayName,
    required String inboundText,

    // ── INBOUND MEDIA ───────────────────────────────────────────────
    //
    // Nullable, and the handler stays entirely text-driven when it is
    // null — so every existing caller is unchanged.
    //
    // The REFERENCE is passed, not the bytes: a Telegram file_id or a
    // WhatsApp media id. Resolving it means an authenticated download
    // with the workspace's own credential followed by an upload to
    // ImageKit, and that belongs behind InboundMediaService rather than
    // in a webhook handler. See its header on why ImageKit cannot fetch
    // either URL itself — the Telegram one embeds the bot token, and the
    // WhatsApp one needs an Authorization header.
    String? mediaReference,
    String? mediaKind,
    String? mediaMimeType,
    Channel? channel,

    // ── PROVENANCE + IDEMPOTENCY (migration 036, Gate 1) ────────────
    //
    // WhatsApp's wamid or Telegram's message id — see
    // message_repository.dart's create() on why this is what makes a
    // replayed webhook payload produce one Message row, not two.
    // Nullable and additive: every existing caller that doesn't pass it
    // keeps inserting exactly as before.
    String? externalMessageId,
  }) async {
    final bot = await _bots.findById(botId);
    if (bot == null) {
      Log.error('InboundMessageHandler: no Bot found for botId=$botId — cannot process message');
      return "Sorry, something went wrong on our end. We're looking into it.";
    }
    final workspaceId = bot.workspaceId;

    final conversation = await _conversations.findOrCreate(
      workspaceId: workspaceId,
      botId: botId,
      channelId: channelId,
      platformType: platformType,
      externalUserId: externalUserId,
      displayName: displayName,
    );
    final conversationId = conversation.id!;

    // Gate 3 — resolve/create the Customer this conversation belongs
    // to, once. WhatsApp's externalUserId is a real phone number
    // (signal_type 'phone'); Telegram's is an opaque platform id
    // (signal_type 'platform_user') — see migration 039's header on why
    // these cannot share a signal type. Only runs when the conversation
    // doesn't already have one, so an active thread's tenth message
    // doesn't re-resolve identity on every turn.
    if (conversation.customerId == null) {
      final signal = platformType == 'whatsapp'
          ? IdentitySignal(
              type: 'phone',
              value: CustomerIdentityResolver.normalizePhone(externalUserId),
              sourceRef: conversationId.toString(),
            )
          : IdentitySignal(
              type: 'platform_user',
              value: CustomerIdentityResolver.normalizePlatformUser(platformType, externalUserId),
              sourceRef: conversationId.toString(),
            );
      final customerId = await _customerIdentity.resolve(
        workspaceId: workspaceId,
        primary: signal,
        source: platformType,
      );
      if (customerId != null) {
        await _conversations.setCustomer(conversationId, customerId);
        if (displayName != null && displayName.trim().isNotEmpty) {
          await _customerIdentity.attachSignal(
            workspaceId: workspaceId,
            customerId: customerId,
            signal: IdentitySignal(
              type: 'name',
              value: CustomerIdentityResolver.normalizeName(displayName),
            ),
            source: platformType,
          );
        }
      }
    }

    // Gate 2 — event bus. Fired unconditionally (see _events' own field
    // comment) rather than only when findOrCreate genuinely inserted a
    // row — the fingerprint-level dedup in events makes that distinction
    // unnecessary to compute here.
    await _events.emit(
      workspaceId: workspaceId,
      eventType: 'new_conversation',
      fingerprint: 'new_conversation:$conversationId',
      payload: {
        'conversationId': conversationId,
        'workspaceId': workspaceId,
        'botId': botId,
        'channelId': channelId,
        'platformType': platformType,
        'externalUserId': externalUserId,
      },
    );

    // Resolve the picture BEFORE writing the message, so the row is
    // written once with whatever we ended up with.
    //
    // A failure here returns null and the message is still stored with
    // media_kind set and media_url null — the "it arrived and could not
    // be saved" state migration 032 exists to express. A CDN blip must
    // cost the picture, never the message.
    InboundMedia? media;
    if (mediaReference != null && mediaKind != null && channel != null) {
      try {
        media = platformType == 'telegram'
            ? await _inboundMedia.fromTelegram(
                channel: channel,
                workspaceId: workspaceId,
                fileId: mediaReference,
                kind: mediaKind,
                mimeType: mediaMimeType,
              )
            : await _inboundMedia.fromWhatsApp(
                channel: channel,
                workspaceId: workspaceId,
                mediaId: mediaReference,
                kind: mediaKind,
                mimeType: mediaMimeType,
              );
      } catch (e) {
        Log.error('InboundMessageHandler: could not store inbound media', error: e);
      }
    }

    await _messages.create(
      conversationId: conversationId,
      direction: 'inbound',
      senderType: 'customer',
      body: inboundText,
      mediaKind: mediaKind,
      mediaUrl: media?.url,
      mediaThumbnailUrl: media?.thumbnailUrl,
      mediaImagekitFileId: media?.imagekitFileId,
      mediaMimeType: media?.mimeType ?? mediaMimeType,
      // Gate 1 provenance — only the inbound-from-customer row carries
      // this: it's the one message in this whole flow that actually
      // came from an external platform event. The bot/human outbound
      // replies below are kola's own writes and have no external id.
      sourcePlatform: platformType,
      externalMessageId: externalMessageId,
      permissionScope: 'workspace',
    );
    await _conversations.touchLastMessageAt(conversationId);

    // Phase 5a — one metered 'message' unit per inbound customer message
    // that reaches this far, regardless of what happens next (paused,
    // escalated, security-filtered — it was still received and handled,
    // which is what "message volume" in PRD.md §10's capped-tier
    // description is metering). Fire-and-log: a metering failure must
    // never block the customer's actual reply.
    try {
      await _usageRecords.incrementUsage(workspaceId: workspaceId, usageClass: 'message');
    } catch (e) {
      Log.error('InboundMessageHandler: failed to record message usage for workspace $workspaceId', error: e);
    }

    // Phase 5b — a paused workspace (trial expired without payment, or
    // manually paused) still gets a record of what the customer said
    // (persisted above), it just gets no reply. See
    // trial_state_machine.dart's header for why this is a read-time
    // check, not a stored flag on the message/conversation itself.
    final workspace = await _workspaces.findById(workspaceId);
    final tier = workspace == null ? null : _trialStateMachine.effectiveTier(workspace);
    if (tier == EffectiveTier.paused) {
      Log.info('InboundMessageHandler: workspace $workspaceId is paused — bot staying silent');
      return null;
    }

    // Phase 5 plan limits — cappedFree's daily message cap (see this
    // file's header). sumUsageInRange is called AFTER incrementUsage
    // above, so today's own count already includes the message that
    // just tripped the cap, not just the messages before it.
    if (tier == EffectiveTier.cappedFree) {
      final today = DateTime.now().toUtc();
      final todayUsage = await _usageRecords.sumUsageInRange(
        workspaceId: workspaceId,
        usageClass: 'message',
        from: today,
        to: today,
      );
      if (todayUsage > PlanLimits.cappedFreeDailyMessageCap) {
        Log.info(
          'InboundMessageHandler: workspace $workspaceId hit its cappedFree daily message cap '
          '(${PlanLimits.cappedFreeDailyMessageCap}) — sending cap notice instead of an AI reply',
        );
        const capText =
            "You've reached today's message limit on the free plan. "
            "The bot will reply again once the limit resets, or upgrade for unlimited replies.";
        await _messages.create(
          conversationId: conversationId,
          direction: 'outbound',
          senderType: 'bot',
          body: capText,
        );
        await _conversations.touchLastMessageAt(conversationId);
        return capText;
      }
    }

    // A human is already on this conversation — the bot must not talk
    // over them. See conversation.spy.yaml's status field for the full
    // state machine; task #96's sendHumanReply is how the human's side
    // of this conversation actually gets typed and sent.
    if (conversation.status == 'escalated') {
      Log.info('InboundMessageHandler: conversation $conversationId is escalated — bot staying silent');
      return null;
    }

    // Phase 3d checkpoint #1 — a blocked message never reaches the AI.
    final inboundCheck = _security.checkInboundMessage(
      message: inboundText,
      externalUserId: externalUserId,
    );
    if (!inboundCheck.allowed) {
      Log.warning(
        'InboundMessageHandler: security filter blocked inbound message '
        '(conversation $conversationId, violation: ${inboundCheck.violationType})',
      );
      final warningText = inboundCheck.warningMessage ?? "Sorry, I can't process that message.";
      await _messages.create(
        conversationId: conversationId,
        direction: 'outbound',
        senderType: 'bot',
        body: warningText,
      );
      await _conversations.touchLastMessageAt(conversationId);
      return warningText;
    }

    // TASK #134 — AI tool-calling Errand engine. Build this turn's tool
    // list from the workspace's active Errands (plus the reserved,
    // always-available escalation tool — see errand_tool_registry.dart's
    // header on why that one isn't tied to any Errand row), ask
    // BotKnowledgeService to decide between a direct answer and a tool
    // call, then — if it chose a tool — dispatch it and turn the result
    // into a customer-facing reply. This is what replaces the plain
    // answerGrounded() call this file used before this task; that method
    // itself is untouched for any other caller still using it.
    final activeErrands = await _errands.listActiveByWorkspace(workspaceId);
    final tools = ErrandToolRegistry.buildTools(activeErrands);
    final decision = await _knowledge.decide(bot: bot, tools: tools, question: inboundText);

    String answerText;
    var needsEscalation = false;

    if (!decision.wantsToolCall) {
      answerText = decision.directAnswer ?? '';
    } else {
      final toolCall = decision.toolCall!;
      if (toolCall.toolName == kEscalateToHumanToolName) {
        // The reserved escalation tool has no backing Errand row to
        // dispatch — same fixed reply BuiltinErrandExecutor's own
        // _escalateToHuman handler would return if a workspace HAD
        // registered a real 'escalateToHuman' Errand.
        answerText = "I've flagged this for a member of the team — "
            "they'll follow up with you soon.";
        needsEscalation = true;
        Log.info(
          'InboundMessageHandler: conversation $conversationId called '
          '$kEscalateToHumanToolName (reason: ${toolCall.arguments['reason']})',
        );
      } else {
        final errand = ErrandToolRegistry.findErrandForToolName(toolCall.toolName, activeErrands);
        if (errand == null) {
          // The model named a tool that doesn't (or no longer) exist —
          // treat like an infrastructure gap, not a customer problem to
          // expose.
          Log.warning(
            'InboundMessageHandler: AI called unknown tool "${toolCall.toolName}" '
            '(conversation $conversationId) — escalating instead of guessing',
          );
          answerText = "I'm having trouble with that right now — "
              "I'm connecting you with a person on the team.";
          needsEscalation = true;
        } else {
          // Merge in the context this handler needs that the model was
          // never asked to supply (e.g. conversationId) — see
          // errand_tool_registry.dart's header on why those are excluded
          // from the model's own schema.
          final mergedInput = Map<String, dynamic>.from(toolCall.arguments);
          for (final key in ErrandToolRegistry.contextInjectedKeysFor(errand)) {
            if (key == 'conversationId') mergedInput[key] = conversationId;
            // Task #154 — 'channelId' is the first context-injected key
            // that isn't 'conversationId'; see errand_tool_registry.dart's
            // header on why 'createProductListTemplate' needs it and the
            // model must never supply it itself.
            if (key == 'channelId') mergedInput[key] = channelId;
          }

          // Phase 3d (SRS.md §10): security filter runs before ANY
          // Errand call, regardless of who triggered it — arguably more
          // important here than the human/API-triggered path, since a
          // developer didn't type these values, the AI inferred them.
          final inputCheck = _security.checkErrandInput(mergedInput);
          if (!inputCheck.allowed) {
            Log.warning(
              'InboundMessageHandler: security filter blocked AI-inferred Errand input '
              '(conversation $conversationId, errandId: ${errand.id}, violation: ${inputCheck.violationType})',
            );
            answerText = inputCheck.warningMessage ?? "I'm connecting you with a person on the team.";
            needsEscalation = true;
          } else {
            try {
              final result = await _errandDispatch.dispatch(errand: errand, input: mergedInput);
              final replyToCustomer = result['replyToCustomer'];
              if (replyToCustomer is String && replyToCustomer.isNotEmpty) {
                // Every builtin handler already provides this — use it
                // directly, no extra AI call needed.
                answerText = replyToCustomer;
              } else {
                // A webhook/dbCredential Errand's raw JSON result has no
                // such convention — ask the AI to explain it in plain
                // language instead of ever showing the customer raw JSON.
                final summary = await _knowledge.summarizeToolResult(
                  bot: bot,
                  question: inboundText,
                  result: result,
                );
                answerText = summary.text;
                needsEscalation = summary.needsEscalation;
              }
            } catch (e) {
              Log.error(
                'InboundMessageHandler: Errand dispatch failed '
                '(conversation $conversationId, errandId: ${errand.id})',
                error: e,
              );
              answerText = "Sorry, something went wrong while I was doing that — "
                  "I'm connecting you with a person on the team.";
              needsEscalation = true;
            }
          }
        }
      }
    }

    // Phase 3d checkpoint #3 — the AI's own drafted reply (or an
    // Errand's summarized result) is checked before it's ever sent or
    // persisted. A blocked reply escalates rather than just being
    // swapped for a fallback — something clearly went wrong with the
    // AI's output, which is exactly a "a human should look at this"
    // situation, not a silent substitution.
    final outboundCheck = _security.checkOutboundText(answerText);
    if (!outboundCheck.allowed) {
      Log.warning(
        'InboundMessageHandler: security filter blocked outbound AI reply '
        '(conversation $conversationId, violation: ${outboundCheck.violationType})',
      );
      answerText = outboundCheck.warningMessage ?? "I'm connecting you with a person on the team.";
      needsEscalation = true;
    }

    await _messages.create(
      conversationId: conversationId,
      direction: 'outbound',
      senderType: 'bot',
      body: answerText,
    );
    await _conversations.touchLastMessageAt(conversationId);

    if (needsEscalation) {
      await _conversations.setStatus(conversationId, 'escalated');
      Log.info('InboundMessageHandler: conversation $conversationId escalated (workspaceId=$workspaceId)');

      // Fire-and-log, not fire-and-forget-silently: a notification
      // failure must never block the customer's reply from going out —
      // it already has, above — but it's worth knowing about.
      try {
        await _notifications.notifyEscalation(
          workspaceId: workspaceId,
          customerDisplayName: displayName ?? externalUserId,
          escalationReason: inboundText,
        );
      } catch (e) {
        Log.error('InboundMessageHandler: owner notification dispatch failed for conversation $conversationId', error: e);
      }
    }

    return answerText;
  }
}
