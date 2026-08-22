// bot_endpoint.dart
//
// Creating and managing Bot records within a workspace — the missing
// link between "a workspace exists" (WorkspaceEndpoint.createWorkspace)
// and "a channel is connected" (ChannelEndpoint.connectTelegramChannel /
// connectWhatsAppChannelManual, both of which REQUIRE an existing
// botId). This endpoint didn't exist before — BotRepository always had
// create()/listByWorkspace()/update()/setStatus(), but nothing exposed
// them through an authenticated, workspace-scoped endpoint, so there was
// no real way to reach a connectable Bot at all without hand-inserting a
// row. Closing that gap is this file's whole purpose.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/billing/trial_state_machine.dart';
import 'package:kola_server/src/services/billing/plan_limits.dart';
import 'package:kola_server/src/services/knowledge/bot_mother_service.dart';
import 'package:kola_server/src/services/connectors/contract/agent_lifecycle_events.dart';
import 'package:kola_server/src/services/agents/agent_archetypes.dart';
import 'package:kola_server/kola_logger.dart';

/// Bot.archetype's allowed values — reads from [AgentArchetypes], the
/// single source of truth (see that file's header), mirroring the check
/// constraint enforced at the database level (docs/migrations/001_initial
/// _schema.sql, widened by 038_agent_archetypes.sql) so a bad value fails
/// here with a clear message, not as a raw Postgres constraint violation
/// surfaced to the dashboard. Was a locally-declared literal set before
/// Phase A of the agent architecture correction; kept as a local alias so
/// every call site below didn't need touching.
final _validArchetypes = AgentArchetypes.allKeys;

class BotEndpoint extends Endpoint {
  BotRepository get _bots => getIt<BotRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  TrialStateMachine get _trialStateMachine => getIt<TrialStateMachine>();
  BotMotherService get _botMother => getIt<BotMotherService>();
  AgentLifecycleEvents get _agentEvents => getIt<AgentLifecycleEvents>();

  /// CORRECTED (2026-08-22): a workspace has exactly one agent, full
  /// stop — not a free-tier limit that paid plans escape. The old
  /// multi-bot model (several specialised bots sharing one workspace)
  /// belonged to Kola's earlier life as a bot platform; it was dropped
  /// because every bot in a workspace reads from the SAME knowledge base
  /// and connectors, so a second bot cannot behave differently from the
  /// first — it can only confuse the owner about which one to talk to.
  /// A second agent now only ever comes from creating a second
  /// *workspace* (WorkspaceEndpoint.createWorkspace), which brings its
  /// own agent with it. This cap applies to EVERY tier, unconditionally
  /// — [PlanLimits.cappedFreeBotCap] (1) happens to already be the right
  /// number, so it's reused here rather than introducing a second
  /// "always 1" constant, but the tier branch that used to guard this is
  /// gone: fullTrial/paid workspaces are capped too now. Shared by
  /// [createBot] and [createBotFromDescription] so neither creation path
  /// can bypass the other's limit.
  Future<void> _enforceBotCap(int workspaceId) async {
    final existingCount = (await _bots.listByWorkspace(workspaceId)).length;
    if (existingCount >= PlanLimits.cappedFreeBotCap) {
      throw KolaException(
        message: 'This workspace already has an agent. Kola gives each '
            'workspace exactly one — rename the existing one instead of '
            'creating another, or create a new workspace if you need a '
            'fully separate agent with its own knowledge base.',
      );
    }
  }

  /// Creates a new Bot inside a workspace, starting life as 'draft' (see
  /// bot_repository.dart's create() for the full lifecycle note). This is
  /// the step Bot Mother/the onboarding wizard calls right after
  /// WorkspaceEndpoint.createWorkspace — the resulting Bot.id is what
  /// every ChannelEndpoint method needs to connect a Telegram or
  /// WhatsApp channel to it.
  Future<Bot> createBot(
    Session session,
    String accessToken,
    int workspaceId,
    String name,
    String archetype,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    await _enforceBotCap(workspaceId);

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw KolaException(message: 'Bot name cannot be empty.');
    }
    if (!_validArchetypes.contains(archetype)) {
      throw KolaException(
        message:         'Invalid archetype "$archetype" — must be one of: '
        '${_validArchetypes.join(", ")}',
      );
    }

    final bot = await _bots.create(
      workspaceId: workspaceId,
      name: trimmedName,
      archetype: archetype,
    );

    // Gate 2 — event bus. See agent_lifecycle_events.dart's header for
    // why this lives in one shared class rather than being inlined here.
    await _agentEvents.recordDrafted(bot);

    Log.success(
      'Bot created',
      data: {
        'workspaceId': workspaceId,
        'botId': bot.id,
        'archetype': archetype,
      },
      session: session,
    );

    return bot;
  }

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
  Future<Bot> createBotFromDescription(
    Session session,
    String accessToken,
    int workspaceId,
    String description,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    await _enforceBotCap(workspaceId);

    final trimmedDescription = description.trim();
    if (trimmedDescription.isEmpty) {
      throw KolaException(message: 'Describe what you want this bot to do.');
    }

    final draft = await _botMother.draftFromDescription(trimmedDescription);

    final trimmedName = draft.name.trim();
    if (trimmedName.isEmpty) {
      throw KolaException(message: 'Bot name cannot be empty.');
    }
    if (!_validArchetypes.contains(draft.archetype)) {
      throw KolaException(
        message:         'Invalid archetype "${draft.archetype}" — must be one of: '
        '${_validArchetypes.join(", ")}',
      );
    }

    var bot = await _bots.create(
      workspaceId: workspaceId,
      name: trimmedName,
      archetype: draft.archetype,
    );

    if (draft.knowledgeSeed != null) {
      bot = await _bots.update(
        Bot(
          id: bot.id,
          workspaceId: bot.workspaceId,
          name: bot.name,
          archetype: bot.archetype,
          status: bot.status,
          knowledgeSeed: draft.knowledgeSeed,
          costSavingTelegramLink: bot.costSavingTelegramLink,
          costSavingAlternateWhatsapp: bot.costSavingAlternateWhatsapp,
          createdAt: bot.createdAt,
          updatedAt: bot.updatedAt,
        ),
      );
    }

    // Gate 2 — event bus. Emitted with the FINAL bot (post-knowledgeSeed
    // update if any), same reasoning as everywhere else in this gate:
    // the event should reflect the row as it actually ended up, not an
    // intermediate state.
    await _agentEvents.recordDrafted(bot);

    Log.success(
      'Bot created from description (Bot Mother v1)',
      data: {
        'workspaceId': workspaceId,
        'botId': bot.id,
        'archetype': draft.archetype,
        'seeded': draft.knowledgeSeed != null,
      },
      session: session,
    );

    return bot;
  }

  /// Every bot belonging to a workspace — the dashboard's bot list/
  /// switcher, and the prerequisite lookup before a Channels page can
  /// call ChannelEndpoint.listChannelsForBot for any one of them.
  Future<List<Bot>> listBotsForWorkspace(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    return _bots.listByWorkspace(workspaceId);
  }

  /// Fetch one bot by id — access-checked via its workspace, same
  /// "never leak existence to a non-member" posture as
  /// WorkspaceEndpoint.getWorkspace and BotRepository.findByIdScoped.
  Future<Bot> getBot(
    Session session,
    String accessToken,
    int workspaceId,
    int botId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final bot = await _bots.findByIdScoped(botId, workspaceId);
    if (bot == null) {
      throw KolaException(message: 'Bot $botId not found in workspace $workspaceId');
    }
    return bot;
  }

  /// Renames a bot and/or changes its archetype. Deliberately does NOT
  /// allow changing status through this method — status is a lifecycle
  /// transition driven by real events (a channel connecting via
  /// ChannelEndpoint, a workspace pausing on trial expiry), not a
  /// free-form field an owner edits directly. See
  /// bot_repository.dart's setStatus for where that actually happens.
  Future<Bot> updateBot(
    Session session,
    String accessToken,
    int workspaceId,
    int botId,
    String name,
    String archetype,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final existing = await _bots.findByIdScoped(botId, workspaceId);
    if (existing == null) {
      throw KolaException(message: 'Bot $botId not found in workspace $workspaceId');
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw KolaException(message: 'Bot name cannot be empty.');
    }
    if (!_validArchetypes.contains(archetype)) {
      throw KolaException(
        message:         'Invalid archetype "$archetype" — must be one of: '
        '${_validArchetypes.join(", ")}',
      );
    }

    final updated = await _bots.update(
      Bot(
        id: existing.id,
        workspaceId: existing.workspaceId,
        name: trimmedName,
        archetype: archetype,
        status: existing.status,
        knowledgeSeed: existing.knowledgeSeed,
        costSavingTelegramLink: existing.costSavingTelegramLink,
        costSavingAlternateWhatsapp: existing.costSavingAlternateWhatsapp,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      ),
    );

    Log.success(
      'Bot updated',
      data: {'workspaceId': workspaceId, 'botId': botId},
      session: session,
    );

    return updated;
  }

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
  Future<Bot> setKnowledgeSeed(
    Session session,
    String accessToken,
    int workspaceId,
    int botId,
    String knowledgeSeed,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final existing = await _bots.findByIdScoped(botId, workspaceId);
    if (existing == null) {
      throw KolaException(message: 'Bot $botId not found in workspace $workspaceId');
    }

    final trimmed = knowledgeSeed.trim();

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace != null) {
      final tier = _trialStateMachine.effectiveTier(workspace);
      if ((tier == EffectiveTier.cappedFree || tier == EffectiveTier.paused) &&
          trimmed.length > PlanLimits.cappedFreeKnowledgeSeedCharCap) {
        throw KolaException(
        message:           'This workspace is on the free plan, which allows up to '
          '${PlanLimits.cappedFreeKnowledgeSeedCharCap} characters of knowledge per bot. '
          'Shorten this or upgrade to add more.',
        );
      }
    }

    final updated = await _bots.update(
      Bot(
        id: existing.id,
        workspaceId: existing.workspaceId,
        name: existing.name,
        archetype: existing.archetype,
        status: existing.status,
        knowledgeSeed: trimmed.isEmpty ? null : trimmed,
        costSavingTelegramLink: existing.costSavingTelegramLink,
        costSavingAlternateWhatsapp: existing.costSavingAlternateWhatsapp,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      ),
    );

    Log.success(
      'Bot knowledge seed updated',
      data: {'workspaceId': workspaceId, 'botId': botId, 'length': trimmed.length},
      session: session,
    );

    return updated;
  }

  /// Sets (or clears, by passing an empty string) either or both of the
  /// cost-saving handoff fields — see bot.spy.yaml's header on why these
  /// exist and why a bot only ever mentions what's actually filled in
  /// here. Kept as its own method for the same reason [setKnowledgeSeed]
  /// is: a distinct, purposeful action, not a generic field edit folded
  /// into [updateBot].
  Future<Bot> setCostSavingContacts(
    Session session,
    String accessToken,
    int workspaceId,
    int botId,
    String telegramLink,
    String alternateWhatsapp,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final existing = await _bots.findByIdScoped(botId, workspaceId);
    if (existing == null) {
      throw KolaException(message: 'Bot $botId not found in workspace $workspaceId');
    }

    final trimmedTelegram = telegramLink.trim();
    final trimmedAlternate = alternateWhatsapp.trim();

    final updated = await _bots.update(
      Bot(
        id: existing.id,
        workspaceId: existing.workspaceId,
        name: existing.name,
        archetype: existing.archetype,
        status: existing.status,
        knowledgeSeed: existing.knowledgeSeed,
        costSavingTelegramLink: trimmedTelegram.isEmpty ? null : trimmedTelegram,
        costSavingAlternateWhatsapp: trimmedAlternate.isEmpty ? null : trimmedAlternate,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      ),
    );

    Log.success(
      'Bot cost-saving handoff contacts updated',
      data: {
        'workspaceId': workspaceId,
        'botId': botId,
        'hasTelegramLink': trimmedTelegram.isNotEmpty,
        'hasAlternateWhatsapp': trimmedAlternate.isNotEmpty,
      },
      session: session,
    );

    return updated;
  }
}
