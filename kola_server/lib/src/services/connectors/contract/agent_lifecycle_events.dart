// agent_lifecycle_events.dart — Gate 2. Emits the agent_drafted /
// agent_published / agent_paused events onto the event bus.
//
// PRODUCT-FACING NAMING ONLY: "agent" here names the EVENT, matching the
// user-confirmed product-language rename (bot -> agent). The underlying
// `Bot` class, `BotRepository`, `BotEndpoint`, the `bots` table and
// every `bot_id` foreign key are UNTOUCHED — this file takes a `Bot`
// parameter and reads `Bot.status` ('draft'/'live'/'paused') exactly as
// it already exists. See event.spy.yaml's header for the full reasoning
// on why this is scoped as a naming change only.
//
// WHY A SEPARATE THIN CLASS AND NOT EventBus.emit() CALLED DIRECTLY AT
// EACH SITE: three call sites (BotEndpoint.createBot,
// BotEndpoint.createBotFromDescription, ChannelEndpoint's two
// setStatus(botId, 'live') calls) all need the exact same fingerprint
// shape and payload shape. Inlining that at each site risks the same
// drift connector_catalog.dart's own header warns about elsewhere in
// this codebase — two call sites quietly disagreeing about what an
// agent_published event's payload contains. One place decides the
// shape; every call site just says which transition happened.

import 'package:kola_server/src/generated/protocol.dart';
import 'event_bus.dart';

class AgentLifecycleEvents {
  AgentLifecycleEvents({required EventBus events}) : _events = events;

  final EventBus _events;

  /// A brand-new Bot always starts 'draft' (BotRepository.create hard-
  /// codes it) — called right after BOTH BotEndpoint.createBot and
  /// .createBotFromDescription's own `_bots.create(...)` call.
  ///
  /// Fingerprint has no timestamp component: a given agent is only ever
  /// drafted once (creation is a one-time event, unlike
  /// publish/pause, which can cycle), so deduplicating retries on
  /// botId alone is correct here.
  Future<void> recordDrafted(Bot bot) async {
    final botId = bot.id;
    if (botId == null) return;
    await _events.emit(
      workspaceId: bot.workspaceId,
      eventType: 'agent_drafted',
      fingerprint: 'agent_drafted:$botId',
      payload: _payload(bot),
    );
  }

  /// Called right after ChannelEndpoint's `_bots.setStatus(botId,
  /// 'live')` — the moment a connected channel makes an agent live for
  /// the first time. [bot] must already reflect status: 'live' (the
  /// return value of setStatus, not the pre-transition row).
  Future<void> recordPublished(Bot bot) => _recordTransition(bot, 'agent_published');

  /// Not called anywhere yet — see channel_endpoint.dart / bot_repository
  /// .dart's own comments: no pause flow exists for an individual Bot
  /// today (only workspace-level pause, via TrialSweepService, which
  /// pauses the WORKSPACE, not any specific Bot's status column). Wired
  /// here so the day a real per-agent pause is built, it has an obvious,
  /// already-tested place to call into rather than inventing a fourth
  /// fingerprint shape under deadline — the same "add the seam now, fill
  /// it in later" instinct workspace_finding_repository.dart and others
  /// in this codebase already use.
  Future<void> recordPaused(Bot bot) => _recordTransition(bot, 'agent_paused');

  Future<void> _recordTransition(Bot bot, String eventType) async {
    final botId = bot.id;
    if (botId == null) return;
    await _events.emit(
      workspaceId: bot.workspaceId,
      eventType: eventType,
      // updatedAt IS the distinguishing component here, deliberately —
      // unlike agent_drafted, an agent can cycle live -> paused -> live
      // again, and each of those is a genuinely separate occurrence that
      // must NOT be deduplicated against the last time this botId
      // published. Bot.updatedAt changes on every setStatus call
      // (bot_repository.dart's setStatus always stamps it), so it is a
      // reliable per-transition distinguisher without adding a column
      // this gate doesn't otherwise need.
      fingerprint: '$eventType:$botId:${bot.updatedAt.toIso8601String()}',
      payload: _payload(bot),
    );
  }

  Map<String, dynamic> _payload(Bot bot) => {
        'agentId': bot.id,
        'workspaceId': bot.workspaceId,
        'name': bot.name,
        'archetype': bot.archetype,
        'status': bot.status,
      };
}
