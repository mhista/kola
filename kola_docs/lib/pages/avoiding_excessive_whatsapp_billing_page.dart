// avoiding_excessive_whatsapp_billing_page.dart — '/billing/avoiding-
// excessive-whatsapp-billing'.
//
// Written in response to a direct owner request: "we will also add in
// the documentation, detailed explanation on how to avoid excessive
// billing. a full page dedicated to that will be great." Triggered by
// Meta's own July 2026 announcement that free WhatsApp service-window
// replies end October 1, 2026 (Meta's official pricing docs:
// developers.facebook.com/documentation/business-messaging/whatsapp/pricing,
// updated Mar 30 2026; corroborated by third-party coverage dated Jul
// 2026 — sources cited inline where a specific number/date is given).
//
// AUDIENCE: business owners using Kola's dashboard (not developers
// integrating an API) — the only page in this site written for that
// audience rather than an API-integration one. Lives under a new
// "Billing" nav section rather than "Reference," which is otherwise all
// developer-facing.
//
// EVERY NUMBER HERE IS EITHER: (a) Meta's own published rate, cited to
// Meta's own pricing page, (b) Kola's own confirmed price
// (PlanLimits.paidPlanMonthlyPriceKobo, CONFIRMED WITH THE USER
// 2026-07-27), or (c) explicitly marked illustrative. Nothing is
// invented — same discipline this whole codebase already holds itself
// to for pricing (see kola_server/lib/src/services/billing/plan_limits.dart's
// own "CONFIRMED WITH THE USER" vs "NOT CONFIRMED" comments).

import 'package:jaspr/jaspr.dart';
import '../components/doc_page_kit.dart';

class AvoidingExcessiveWhatsAppBillingPage extends StatelessComponent {
  const AvoidingExcessiveWhatsAppBillingPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Avoiding excessive WhatsApp billing'),
      docLede(
        'WhatsApp messaging through Kola is billed by Meta, not by Kola — and Meta is changing how it '
        'charges. This page explains exactly what changes, when, and what you can actually do about it.',
      ),

      docWarning(
        "From October 1, 2026, Meta starts charging for every reply sent inside WhatsApp's 24-hour "
        'customer-service window — today, that specific kind of reply is free. This is Meta\'s change, '
        'announced July 2026, and it applies to every business on the official WhatsApp Business Platform, '
        'not something specific to Kola.',
      ),

      docH2("How WhatsApp billing actually works today"),
      docP(
        'Since July 2025, Meta bills per message, not per "conversation." Three things matter: whether a '
        'message is a plain reply or a template, whether an open 24-hour service window exists, and which '
        'category a template falls under.',
      ),
      docList([
        'A customer messages your bot first → this opens a 24-hour "customer service window."',
        "A plain-text reply inside that window (what Kola's bots send when just answering a question) is "
            'FREE — today. This changes October 1, 2026 (see below).',
        'A message sent to someone OUTSIDE an open window must be a pre-approved template, and templates '
            'are always billed, categorized as Utility, Marketing, or Authentication.',
        'Utility templates (a reply to something the customer specifically asked for or is owed — an order '
            "update, a requested price list) cost less than Marketing templates (a cold promotional push) "
            "on every market's rate card, Nigeria included.",
      ]),
      docNote(
        'Sending someone an ad or a broadcast they did not ask for is always a Marketing template, always '
        'the most expensive category, and always needs the customer to have opted in first — that is a '
        "Meta policy requirement, not something Kola enforces separately.",
      ),

      docH2('What changes October 1, 2026'),
      docP(
        'Meta announced this July 1, 2026. Today, a plain-text reply inside an open service window is '
        'free — that ends. From October 1, 2026, Meta charges for those replies too, at the same per-'
        'message rate as Utility/Authentication templates (no published volume discount for this specific '
        'message type). The 24-hour window itself does not change, and the free 72-hour window after '
        'someone clicks a "Click to WhatsApp" ad is unaffected.',
      ),
      docNote(
        "Separately, and unrelated to Kola: Meta's own competing AI product (\"Meta Business Agent\") starts "
        'billing by usage from August 1, 2026. That is not something Kola bots use or are affected by — '
        "it's Meta's own first-party AI tool, mentioned here only so it isn't confused with Kola's pricing.",
      ),

      docH2('What this actually costs'),
      docP(
        'Meta prices per message, by country and template category, and updates rates quarterly. Nigeria '
        'has its own rate row on Meta\'s official rate card — check it directly, since Kola cannot quote a '
        'number that stays accurate as Meta\'s own rates change: ',
        ),
      docList([
        'Meta\'s official, current rate card: business.whatsapp.com/products/platform-pricing (interactive, kept up to date by Meta directly)',
        'Meta\'s own pricing documentation: developers.facebook.com/documentation/business-messaging/whatsapp/pricing',
      ]),
      docP(
        "As a general shape (not a Nigeria-specific number): third-party analysis of Meta's post-October-"
        '2026 rate card puts a typical service reply at a fraction of a cent (illustrative figure widely '
        'cited: roughly \$0.0068 per message in markets without a special lower rate) — small per message, '
        'real money at high volume. The number that actually matters for your business is cost per '
        'CONVERSATION THAT LEADS TO A SALE, not cost per message in isolation.',
      ),

      docH2('What you can actually do about it'),

      docH2('1. Keep replies inside the free/cheap 24-hour window'),
      docP(
        "This is the single biggest lever, and it costs nothing to use: as long as a customer messaged "
        'you within the last 24 hours, your bot replying to them (even with a rich list of options, not '
        'just plain text) stays in the cheapest category Meta offers for that message type. Nothing extra '
        "to configure — this is simply how Kola's bots already work.",
      ),

      docH2('2. Use Kola to submit "utility" templates, not "marketing," for anything outside the window'),
      docP(
        "If you genuinely need to reach a customer who hasn't messaged recently — following up on a "
        'requested product list, for example — Kola can submit that as a Meta template for you '
        "programmatically, from your dashboard's Integrations page, under your connected WhatsApp channel. "
        'Requesting the "utility" category (a reply to something specifically asked for) costs less than '
        '"marketing" on every market\'s rate card. Meta\'s own review has the final say on the approved '
        'category, regardless of what\'s requested.',
      ),
      docNote(
        'This only applies to reaching out first. A customer who already messaged you recently never needs '
        'a template at all — see point 1.',
      ),

      docH2('3. Hand off long conversations to a channel with no per-message fee'),
      docP(
        "Telegram carries no Meta messaging fee at all — none. If your bot is having a long, back-and-forth "
        'conversation with a customer on WhatsApp, and you have a Telegram bot connected too, Kola can have '
        'your bot gently suggest continuing there instead, once, without being pushy. You configure this on '
        "the Knowledge page for your bot: paste in your Telegram link (or an alternate WhatsApp number/"
        "instruction, if that's what you'd rather offer) under \"Cost-saving handoff.\" Leave both blank and "
        "your bot never mentions this at all — it only ever offers what you've actually provided.",
      ),

      docH2("4. Consider Messenger and Instagram for lower-cost, lower-intent conversations"),
      docP(
        "Meta's Messenger and Instagram messaging APIs are part of the same Meta Business Platform family "
        'as WhatsApp Cloud API, and priced separately from it — for many message types, a business can '
        'reply for free or at a lower rate than WhatsApp\'s service-reply charge. If a chunk of your '
        "WhatsApp volume is lower-intent, high-frequency chat (browsing questions rather than closing a "
        'sale), moving some of it to Messenger/Instagram can reduce your total Meta bill. This is on Kola\'s '
        'own roadmap, not available to connect yet — check back here once it ships.',
      ),

      docH2('5. Track cost against revenue, not in isolation'),
      docP(
        'A per-message fee is only alarming looked at alone. Compare it against what a conversation is '
        "worth: if closing a sale takes 15 messages at a fraction of a cent each, that's a rounding error "
        "against the sale itself. If it takes 20 messages to sell something worth very little, and only 1 "
        'in 20 conversations converts, that is worth knowing and acting on — shortening the conversation, '
        'consolidating multiple message bubbles into one, or moving that specific flow to Telegram.',
      ),

      docH2('Where this leaves Kola\'s own pricing'),
      docP(
        "Kola's own subscription price is separate from Meta's messaging fees — Kola charges for the "
        "platform (bot hosting, AI, dashboard, Errands); Meta charges separately, directly, for messages "
        "sent through WhatsApp's official API. Kola's paid plan is priced with real headroom against "
        "Meta's upcoming per-message charge, not assuming today's near-zero pass-through cost holds "
        "forever.",
      ),
    ]);
  }
}
