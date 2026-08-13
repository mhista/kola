// rate_limits_page.dart — '/rate-limits'. Numbers sourced directly from
// plan_limits.dart's constants, not restated from memory — two of the
// three are real product decisions, one is an explicitly-flagged
// engineering placeholder, and this page says which is which rather
// than presenting all three with equal confidence.

import 'package:jaspr/jaspr.dart';
import '../components/doc_page_kit.dart';

class RateLimitsPage extends StatelessComponent {
  const RateLimitsPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Rate limits & plans'),
      docLede(
        "Every workspace starts on a two-stage trial, not a hard paywall from day one. What a "
        "workspace can actually do at any moment is a live calculation (TrialStateMachine), not "
        'a field you can just read off the workspace record.',
      ),

      docH2('The trial'),
      docList([
        'Hours 0–48: full access — every Errand type, no message cap, no knowledge-size cap.',
        "Hours 48 through day 14: capped — 50 inbound messages per day, at most 3 active "
            "Errands, and a knowledge-seed length cap (see the note below on that specific "
            'number). Past the cap, the bot sends one consistent notice instead of a reply for '
            'the rest of that day; nothing is deleted.',
        'Day 14 onward: paused — the bot stops responding on any channel entirely, but every '
            'conversation, bot, and Errand is retained. Paying reactivates immediately with '
            'everything intact.',
      ]),

      docH2('The exact numbers'),
      docP(
        'The 50-message and 3-Errand caps above were confirmed as real product decisions, not '
        'guessed. The knowledge-seed character cap was not — it\'s an engineering placeholder '
        "(2,000 characters) chosen so enforcement wasn't left two-thirds finished, pending a "
        "real number. Treat that one specific figure as provisional.",
      ),

      docH2('Paid plans'),
      docWarning(
        "Paystack and Flutterwave integrations exist as HTTP service wrappers (initialize/"
        'verify transaction, tested against each provider\'s real documented API shape) but '
        "there is no live checkout anywhere — no \"Upgrade\" button, no priced plan tiers, no "
        "webhook route processing a completed payment. Nothing you build against today can "
        'actually charge a card. This section will describe real tiers and prices once that '
        'exists.',
      ),
    ]);
  }
}
