// trial_state_machine.dart — Phase 5b: the explicit, testable state
// machine PRD.md §10's two-stage trial mechanic and workspace.spy.yaml's
// own header comment both call for, replacing "implicit date-math
// scattered across the codebase" with one place that answers "what
// tier is this workspace actually in right now."
//
// WHY effectiveTier IS A PURE READ-TIME DERIVATION, NOT A STORED FIELD:
// Workspace.status only has three real values ('trialing' | 'active' |
// 'paused' — see workspace.spy.yaml). The 48-hour full-access → capped
// mark is NOT a status transition at all — a workspace is still
// 'trialing' the entire 14 days, it's just entitled to less once
// trialFullAccessEndsAt passes. So there is nothing to persist at hour
// 48: any caller just compares `now` against the two stored dates,
// every time, via [effectiveTier] below. The ONLY real status
// transition this state machine drives is trialing → paused at day 14
// — see [needsTransition]/trial_sweep_service.dart for where that
// actually gets written.
//
// WHAT THIS FILE DELIBERATELY DOES NOT DO: it does not define the exact
// numeric caps (message volume, Errand count, knowledge size) PRD.md
// §10 says apply during [EffectiveTier.cappedFree] — those live in
// plan_limits.dart (PlanLimits), not here, so this file stays pure
// state-derivation logic. Call sites gate on [EffectiveTier.cappedFree]
// (or [EffectiveTier.paused] — see plan_limits.dart's header on why both)
// from here, then check the actual number from PlanLimits: see
// inbound_message_handler.dart (message cap), errand_endpoint.dart
// (Errand cap), and bot_endpoint.dart's setKnowledgeSeed (knowledge cap).

import 'package:kola_server/src/generated/protocol.dart';

/// What a workspace is actually entitled to right now, derived from its
/// status + trial dates — never read directly off a stored field.
enum EffectiveTier {
  /// Inside the first 48 hours — full Pro-tier feature access (PRD.md
  /// §10 stage 1).
  fullTrial,

  /// Hours 48 through day 14 — bot keeps working, at capped Free-tier
  /// limits (PRD.md §10 stage 2). See this file's header for why the
  /// exact caps aren't defined here.
  cappedFree,

  /// status == 'active' — a paying workspace, full access.
  paid,

  /// status == 'paused', OR a 'trialing' workspace whose 14-day window
  /// has already passed but hasn't been swept yet (see
  /// [needsTransition]) — either way, PRD.md §10 stage 3: the bot stops
  /// responding on live channels, data is retained.
  paused,
}

class TrialStateMachine {
  const TrialStateMachine();

  /// The single source of truth for "what can this workspace's bot do
  /// right now" — every enforcement point (InboundMessageHandler today;
  /// Errand-count/knowledge-size checks once those caps exist) should
  /// call this rather than re-deriving the same date comparisons.
  EffectiveTier effectiveTier(Workspace workspace, {DateTime? now}) {
    final n = (now ?? DateTime.now()).toUtc();

    switch (workspace.status) {
      case 'active':
        return EffectiveTier.paid;
      case 'paused':
        return EffectiveTier.paused;
      case 'trialing':
        if (n.isBefore(workspace.trialFullAccessEndsAt)) return EffectiveTier.fullTrial;
        if (n.isBefore(workspace.trialEndsAt)) return EffectiveTier.cappedFree;
        // Trial window has fully elapsed but trial_sweep_service.dart
        // hasn't persisted the transition yet (it runs on an interval,
        // not instantly at the exact expiry moment) — treat it as
        // already paused so behavior is correct even in that gap,
        // rather than waiting for the next sweep tick to matter.
        return EffectiveTier.paused;
      default:
        // An unrecognized status is a data problem, not a green light —
        // fail closed (paused) rather than silently granting access.
        return EffectiveTier.paused;
    }
  }

  /// True when this workspace's stored `status` no longer matches what
  /// its dates say — i.e. it's due for trial_sweep_service.dart to
  /// persist trialing → paused. Only ever true past trialEndsAt; the
  /// 48-hour mark never needs a write (see this file's header).
  bool needsTransition(Workspace workspace, {DateTime? now}) {
    final n = (now ?? DateTime.now()).toUtc();
    return workspace.status == 'trialing' && !n.isBefore(workspace.trialEndsAt);
  }
}
