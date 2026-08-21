// agent_orchestrator.dart
//
// PHASE B of the agent architecture correction (follows Phase A's
// AgentArchetypes registry). The owner's ask: agents "perform their
// tasks simultaneously without disrupting the system, they can share
// results, collaborate... the engine knows when to orchestrate each."
// This file is the foundation slice of that — not the whole thing. See
// the two sections below for exactly what is and isn't built yet.
//
// ── CONCURRENT DISPATCH: ALREADY TRUE, NOT NEWLY BUILT ───────────────
//
// Checked directly before writing this file: InboundMessageHandler.handle
// and everything it calls (ErrandDispatchService, OwnerNotificationDispatcher)
// hold no static/global mutable state, no locks, no in-memory queue —
// every call is a self-contained pass through constructor-injected,
// stateless repository wrappers over Supabase. Two different agents
// (Bots) in the same workspace, each with their own channel, already
// process inbound messages fully concurrently today: nothing serializes
// them, because nothing ever assumed there was only one Bot to serialize
// around. There is deliberately no `dispatchConcurrently`-style wrapper
// here — writing one would be wrapping `Future.wait` around something
// that was never sequential, for the appearance of having "added
// concurrency" rather than the fact of it.
//
// ── SHARED CONTEXT: THE ACTUAL GAP THIS FILE CLOSES ───────────────────
//
// Nothing before this let one agent know what another agent in the same
// workspace just did. Gate 2's `events` table is already workspace-
// scoped, not bot-scoped (see event.spy.yaml) — so the data has been
// there since Gate 2; nothing read it back into an agent's own
// reasoning. [AgentOrchestrator.sharedContextBlock] is that read path:
// BotKnowledgeService splices its output into the system prompt, so an
// agent's answer can be informed by "a payment was confirmed 10 minutes
// ago" even if a different agent's channel is what actually confirmed
// it.
//
// Deliberately coarse-grained: this reads event TYPE and timing only,
// not payload contents (payload shapes are not yet consistent enough
// across all six event types to safely interpolate customer-specific
// detail into a prompt without risk of leaking the wrong customer's
// information into the wrong conversation). Enriching this with real
// per-customer/per-conversation correlation is real follow-up work, not
// done here.
//
// ── WHAT IS DELIBERATELY NOT HERE ─────────────────────────────────────
//
// No rule table deciding "event X from agent A should trigger agent B."
// No AI-driven routing across agents. No swarm mode (agents actively
// negotiating one task together). Each of those is a real product
// decision (which events should hand off to which role, and what
// "collaborate" concretely means at execution time) that deserves its
// own scoped pass, not something to invent silently inside a foundation
// commit. This file makes agents able to SEE each other; making them
// ACT on what they see is the next increment.

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/event_repository.dart';

class AgentOrchestrator {
  AgentOrchestrator({required EventRepository events}) : _events = events;

  final EventRepository _events;

  /// Event types worth surfacing to another agent's prompt. Deliberately
  /// a subset, not every event Gate 2 emits — `new_conversation` fires on
  /// every single inbound message across every channel in a workspace;
  /// including it here would flood the shared-context block with noise
  /// that tells an agent nothing useful about what a SIBLING agent did.
  static const _significantEventTypes = {
    'payment_confirmed',
    'errand_executed',
    'agent_published',
    'agent_paused',
  };

  /// The most recent significant events across an entire workspace, most
  /// recent first. Not filtered by which Bot originated them — Event
  /// rows don't uniformly carry that attribution today (see this file's
  /// header) — so this is "what's been happening in this business
  /// recently," not "what agent X specifically did."
  Future<List<Event>> recentActivity({
    required int workspaceId,
    Duration within = const Duration(hours: 24),
    int limit = 5,
  }) async {
    final since = DateTime.now().toUtc().subtract(within);
    final events = await _events.listByWorkspace(
      workspaceId: workspaceId,
      since: since,
      // Fetched ascending (EventRepository's own order) with headroom
      // above [limit] so filtering down to significant types still
      // leaves enough to take the most recent [limit] from.
      limit: 200,
    );
    final significant = [
      for (final e in events)
        if (_significantEventTypes.contains(e.eventType)) e,
    ];
    // listByWorkspace orders ascending by occurred_at; reverse for
    // "most recent first" before capping.
    return significant.reversed.take(limit).toList();
  }

  /// A short, prompt-ready block summarizing recent workspace activity,
  /// or an empty string when there is nothing worth mentioning — callers
  /// should append this directly, no extra spacing needed either way.
  ///
  /// Never throws: called from inside prompt construction on the
  /// customer-facing reply path, where a failure here must degrade to
  /// "no shared context" rather than break answering the customer at
  /// all — same fail-open posture bot_knowledge_service.dart already
  /// uses for its own AI calls.
  Future<String> sharedContextBlock({
    required Bot forBot,
    int limit = 5,
  }) async {
    try {
      final recent = await recentActivity(
        workspaceId: forBot.workspaceId,
        limit: limit,
      );
      if (recent.isEmpty) return '';

      final lines = [
        for (final e in recent) '- ${_describe(e)} (${_ago(e.occurredAt)})',
      ];
      return '\n\n--- RECENT ACTIVITY IN THIS WORKSPACE ---\n'
          'Other things that have happened recently in this business, '
          'possibly through a different agent. Background only — do not '
          'mention this list to the customer unless it is directly '
          'relevant to what they are asking.\n'
          '${lines.join('\n')}';
    } catch (_) {
      return '';
    }
  }

  String _describe(Event e) => switch (e.eventType) {
        'payment_confirmed' => 'A payment was confirmed',
        'errand_executed' => 'A task was completed',
        'agent_published' => 'An agent went live',
        'agent_paused' => 'An agent was paused',
        _ => e.eventType,
      };

  /// Same "Xm ago" / "Xh ago" phrasing used across the dashboard (e.g.
  /// product_detail_page.dart's own `_ago`) — not shared code, matching
  /// this codebase's existing convention of small per-file time
  /// formatters rather than a shared utility.
  String _ago(DateTime when) {
    final diff = DateTime.now().toUtc().difference(when.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
