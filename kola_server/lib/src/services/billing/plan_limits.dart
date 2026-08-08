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

  /// PHASE 9 (Layer 2 — Business Memory). Max indexed KnowledgeDocuments
  /// a cappedFree/paused workspace may hold.
  ///
  /// NOT CONFIRMED WITH THE USER — an engineering placeholder, same
  /// honest status as [cappedFreeKnowledgeSeedCharCap] above, and chosen
  /// against a real cost rather than picked from the air: every document
  /// costs embedding calls at ingestion (against Gemini's 1,500/day free
  /// tier) and permanent vector storage, so unlike the seed's character
  /// cap this one has an actual per-unit cost behind it. Five documents
  /// is roughly a policy set — returns, delivery, payment, hours, FAQ —
  /// which is a genuinely useful free tier rather than a token one.
  /// Revisit alongside real pricing.
  static const int cappedFreeKnowledgeDocumentCap = 5;

  /// PHASE 9. Max characters of raw text in ONE document, any plan.
  ///
  /// Not a plan limit but a sanity bound, which is why it isn't named
  /// cappedFree*: a single 5MB paste would chunk into thousands of
  /// passages and exhaust the daily embedding quota in one request,
  /// failing in a way that looks like a broken product rather than a
  /// document that was too big. 200,000 characters is roughly 60–80
  /// pages — far beyond any realistic policy document, so this rejects
  /// accidents (a pasted database dump) without rejecting real use.
  static const int maxDocumentCharacters = 200000;

  /// SUPERSEDED — DO NOT USE FOR NEW CODE. Use PlanPricing.forRegion()
  /// in plan_pricing.dart instead.
  ///
  /// This was Kola's single, naira-only Pro price. Pricing is now
  /// regional: a workspace is billed in its own market's currency, at
  /// rough purchasing-power parity, through whichever of Kola's gateway
  /// accounts can collect there. A number that works in Lagos is trivial
  /// in London and impossible in Nairobi, so one global figure cannot be
  /// right anywhere but here.
  ///
  /// Kept because it IS still the correct Nigerian price and removing it
  /// would silently change behaviour anywhere it is still read. The real
  /// risk it guards against is someone reaching for a familiar constant
  /// and charging every customer in the world ₦10,000 — hence this note
  /// rather than a quiet deletion.
  ///
  /// Kola's own paid ("pro") plan price — CONFIRMED WITH THE USER
  /// (2026-07-27), not a guess, unlike the general PRD.md §10 note that
  /// pricing numbers were "explicitly not final." In kobo (NGN's minor
  /// unit), same convention PaymentTransaction.amountKobo already uses —
  /// ₦10,000/month. See kola_billing_service.dart for where this is
  /// actually charged.
  static const int paidPlanMonthlyPriceKobo = 1000000;
}
