// plan_limits.dart — the numeric caps trial_state_machine.dart's own
// header explicitly declined to define ("inventing them here would be a
// guess dressed up as a decision"). Two of the three numbers below ARE
// real decisions now — confirmed directly with the user rather than
// guessed — the third is still an engineering placeholder. See each
// constant's own comment for which is which.
//
// SCOPE: these apply to EffectiveTier.cappedFree (PRD.md §10 stage 2,
// days 3–14 of trial) and, per the enforcement call sites' own choice,
// to EffectiveTier.paused too — a paused workspace's dashboard writes
// shouldn't be MORE permissive than a still-capped one just because it
// stopped replying on live channels. fullTrial and paid are always
// unlimited by these constants; nothing here gates them.

class PlanLimits {
  const PlanLimits._();

  /// Daily inbound-message cap for cappedFree/paused workspaces.
  /// CONFIRMED WITH THE USER (2026-07-23) — not a guess. See
  /// inbound_message_handler.dart for where this is enforced.
  static const int cappedFreeDailyMessageCap = 50;

  /// Max ACTIVE Errands a cappedFree/paused workspace may have.
  /// CONFIRMED WITH THE USER (2026-07-23) — not a guess. Disabled
  /// Errands don't count — they aren't doing anything. See
  /// errand_endpoint.dart for where this is enforced.
  static const int cappedFreeErrandCap = 3;

  /// Max characters in Bot.knowledgeSeed for a cappedFree/paused
  /// workspace.
  ///
  /// NOT CONFIRMED WITH THE USER — unlike the two constants above, this
  /// one is an engineering placeholder, chosen only so enforcement isn't
  /// left two-thirds finished. 2,000 characters is roughly one price
  /// list or a one-page FAQ — enough to be useful, small enough to feel
  /// like a real step down from an unrestricted full-access bot. Treat
  /// this specific number as provisional and revisit it before it's load
  /// bearing for real pricing decisions.
  static const int cappedFreeKnowledgeSeedCharCap = 2000;

  /// Max Bots a cappedFree/paused workspace may have in total.
  /// CONFIRMED WITH THE USER (2026-07-27) — not a guess: one bot per
  /// free workspace, which may still connect BOTH Telegram and WhatsApp
  /// channels to that single bot (this caps bot COUNT, not channel
  /// count per bot — see channel_endpoint.dart, unaffected by this).
  /// See bot_endpoint.dart's createBot/createBotFromDescription for
  /// where this is enforced.
  static const int cappedFreeBotCap = 1;

  /// Kola's own paid ("pro") plan price — CONFIRMED WITH THE USER
  /// (2026-07-27), not a guess, unlike the general PRD.md §10 note that
  /// pricing numbers were "explicitly not final." In kobo (NGN's minor
  /// unit), same convention PaymentTransaction.amountKobo already uses —
  /// ₦10,000/month. See kola_billing_service.dart for where this is
  /// actually charged.
  static const int paidPlanMonthlyPriceKobo = 1000000;
}
