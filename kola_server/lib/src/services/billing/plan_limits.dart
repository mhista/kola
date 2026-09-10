// plan_limits.dart — the numeric caps trial_state_machine.dart's own
// header explicitly declined to define ("inventing them here would be a
// guess dressed up as a decision"). Two of the three cappedFree numbers
// below ARE real decisions — confirmed directly with the user rather
// than guessed — the rest are engineering placeholders. See each
// constant's own comment for which is which.
//
// SCOPE: the cappedFree* constants apply to EffectiveTier.cappedFree
// (PRD.md §10 stage 2, days 3–14 of trial) and, per the enforcement
// call sites' own choice, to EffectiveTier.paused too — a paused
// workspace's dashboard writes shouldn't be MORE permissive than a
// still-capped one just because it stopped replying on live channels.
//
// CORRECTED (2026-09-09): fullTrial and paid ("Growth") used to be
// unlimited by these constants — nothing gated them at all. The user
// asked for Growth to have real, if generous, caps rather than being
// marketed as unlimited with no enforcement behind it (see the landing
// page redesign that prompted this). The growth* constants below now
// cover fullTrial and paid the same way the cappedFree* ones cover
// cappedFree/paused — every enforcement call site checks one pair or
// the other, never neither. None of the growth* numbers were
// individually confirmed with the user the way cappedFreeDailyMessageCap
// and cappedFreeErrandCap were; they're set generously above the free
// caps so a real trading business is unlikely to hit them in practice,
// while still being a real ceiling rather than an empty promise.
// Revisit once there's real Growth-tier usage data to size against.

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

  /// Max Bots ANY workspace may have in total, regardless of tier —
  /// CORRECTED (2026-08-22): originally a cappedFree/paused-only limit
  /// (see the name), now applied unconditionally by bot_endpoint.dart's
  /// _enforceBotCap since a workspace has exactly one agent, period —
  /// not a free-tier restriction paid plans escape. Kept this name
  /// rather than renaming to avoid an unrelated diff across every call
  /// site; read it as "the bot cap" now, not "the free-tier bot cap".
  /// That one bot may still connect BOTH Telegram and WhatsApp channels
  /// (this caps bot COUNT, not channel count per bot — see
  /// channel_endpoint.dart, unaffected by this). See bot_endpoint.dart's
  /// createBot/createBotFromDescription for where this is enforced.
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

  // ── GROWTH (fullTrial / paid) ────────────────────────────────────────
  // See this file's header (2026-09-09 note) for why these exist now.

  /// Daily inbound-message cap for fullTrial/paid ("Growth") workspaces.
  /// 20x cappedFree's 50/day — generous enough that a real trading
  /// business shouldn't notice it, while still protecting against a
  /// runaway integration or abuse driving unbounded per-message AI/
  /// channel cost. See inbound_message_handler.dart for enforcement.
  static const int growthDailyMessageCap = 1000;

  /// Max ACTIVE Errands a fullTrial/paid workspace may have. Well above
  /// cappedFree's 3 — enough room for every connector-native capability
  /// (payments, calendar, transaction lookups) plus a real set of
  /// business-specific custom Errands. See errand_endpoint.dart.
  static const int growthErrandCap = 25;

  /// Max characters in Bot.knowledgeSeed for a fullTrial/paid workspace.
  /// 10x cappedFree's 2,000 — see bot_endpoint.dart's setKnowledgeSeed.
  static const int growthKnowledgeSeedCharCap = 20000;

  /// Max indexed KnowledgeDocuments for a fullTrial/paid workspace. Well
  /// above cappedFree's 5 — business memory is a core sell for the paid
  /// plan, so this is sized to feel like real capacity, not a token
  /// bump. See knowledge_endpoint.dart.
  static const int growthKnowledgeDocumentCap = 200;

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
  /// and charging every customer in the world the Nigerian price — hence
  /// this note rather than a quiet deletion.
  ///
  /// Kola's own paid ("Growth") plan price. Originally ₦10,000/month,
  /// CONFIRMED WITH THE USER (2026-07-27); UPDATED WITH THE USER
  /// (2026-09-09) to ₦15,000/month alongside the landing page redesign
  /// and the growth* caps above — must be kept in sync with
  /// PlanPricing.nigeria in plan_pricing.dart by hand, since this field
  /// is a legacy read path that duplicates rather than derives from it.
  /// In kobo (NGN's minor unit), same convention
  /// PaymentTransaction.amountKobo already uses. See
  /// kola_billing_service.dart for where the real (regional) price is
  /// actually charged.
  static const int paidPlanMonthlyPriceKobo = 1500000;
}
