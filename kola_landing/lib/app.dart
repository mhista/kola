// app.dart
//
// Root component and the one place page-level state lives — launch
// mode, FAQ open/closed, and the hero waitlist form's submit state.
//
// SECTION ORDER IS AN ARGUMENT, not a list. Each section only works
// because of the one before it:
//   hero       — the claim
//   proof      — the claim demonstrated, before anything is asked of you
//   problems   — why you'd want it
//   how        — the mental model, in four verbs
//   memory     — it knows your business, and can prove where from
//   commerce   — the fastest way it learns, and the offline hook
//   capability — now that it knows, here's what it does with that
//   timeline   — the payoff question
//   security   — the objection, answered before it's raised
//   integrations — what it plugs into
//   pricing    — the ask
//   replaces   — the cost argument, which is what converts an owner
//   faq        — the remaining objections
//
// THE COMMERCE SECTION IS NOT IN THE DESIGN EXPORT. Added deliberately
// and confirmed with the project owner — see commerce_section.dart's
// header for why, and why it sits exactly there.
//
// TESTIMONIALS ARE ABSENT ON PURPOSE. kolaa hasn't launched; there is
// nobody to quote, and inventing quotes would be a real integrity
// problem in anything attached to a grant application.
// proof_demo_section.dart is the honest substitute — a live demo beats
// a stranger's quote for a sceptical buyer.
//
// LANGUAGE AND CURRENCY ARE BOTH RESOLVED HERE, ONCE, and passed down.
// No component detects a locale or hardcodes a currency symbol. That is
// what keeps adding a language switcher a one-line change instead of a
// hunt through every file. See i18n/.
//
// NOTHING ON THIS PAGE IS GEOGRAPHIC. Currency and price come from
// i18n/region.dart; no component hardcodes a symbol, and no copy names a
// country. Payment providers are named only in the integrations list,
// where it is factual rather than positioning.
//
// REMOVED: announcement_banner, built_for_strip, channels_section,
// team_split_section, waitlist_section and changelog_section. None are
// imported any more — their files can be deleted. The changelog moves to
// its own page (Links.changelog) for the evaluator audience; it was not
// doing work on a page whose buyer is a shop owner.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import 'components/site_header.dart';
import 'components/hero_section.dart';
import 'components/proof_demo_section.dart';
import 'components/problems_section.dart';
import 'components/how_it_works_section.dart';
import 'components/memory_section.dart';
import 'components/commerce_section.dart';
import 'components/capabilities_section.dart';
import 'components/timeline_statement_section.dart';
import 'components/security_section.dart';
import 'components/integrations_section.dart';
import 'components/pricing_section.dart';
import 'components/what_it_replaces_section.dart';
import 'i18n/region.dart';
import 'i18n/locale.dart';
import 'i18n/strings.dart';
import 'components/faq_section.dart';
import 'components/site_footer.dart';
import 'config/env.dart';
import 'interop.dart' as interop;
import 'services/waitlist_api_service.dart';

class LandingApp extends StatefulComponent {
  const LandingApp();

  @override
  State<LandingApp> createState() => _LandingAppState();
}

class _LandingAppState extends State<LandingApp> {
  final _waitlistApi = WaitlistApiService();

  // Build-time flag, never a runtime control. The design export has a
  // floating Waitlist/Launched toggle bottom-right — that is design-tool
  // preview chrome and is deliberately NOT carried into the real build:
  // a page visitor must not be able to flip the site into launched mode.
  // Set with `dart compile js ... -DLAUNCH_MODE=launched`; see
  // config/env.dart and build.sh.
  late final String _mode = Env.launchMode;

  final Set<int> _openFaqIndexes = {0};

  // Which region's pricing to show. Fixed to the launch market for now —
  // detecting a visitor's region client-side is a separate decision (an
  // IP lookup is a third-party request on a page that currently makes
  // none). Resolved in ONE place so no component hardcodes a currency;
  // see i18n/region.dart.
  final Region _region = Regions.nigeria;

  // Language. Detected from the browser on first paint, then fixed for
  // the session. Resolved in ONE place and passed down — no component
  // reaches for a locale itself, which is what keeps a language switcher
  // a one-line change later rather than a hunt through fifteen files.
  //
  // Starts at English rather than null so the first frame renders real
  // copy instead of blanks; if the visitor prefers another language the
  // swap happens in initState, before anything is read.
  Strings _s = const Strings();

  bool _heroSubmitting = false;
  bool _heroSubmitted = false;
  String? _heroError;

  // Which scroll-reveal sections have come into view at least once.
  // Deliberately Dart state rather than a class script.js adds straight
  // to the DOM — see interop.dart's header for the bug that caused: any
  // unrelated setState() wiped the JS-only class on rebuild, making
  // already-revealed sections vanish on a button click.
  final Set<String> _revealed = {};

  String _revealClasses(String id) =>
      _revealed.contains(id) ? 'kola-reveal kola-reveal-in' : 'kola-reveal';

  void _onSectionRevealed(String id) {
    if (!mounted || _revealed.contains(id)) return;
    setState(() => _revealed.add(id));
  }

  @override
  void initState() {
    super.initState();
    // Must register BEFORE initScrollReveal — the observer can fire for
    // an already-in-view section the moment .observe() is called, before
    // initScrollReveal() even returns.
    interop.registerRevealCallback(_onSectionRevealed);
    Future.microtask(() => interop.initScrollReveal());
    _resolveLocale();
  }

  /// Picks a language from the visitor's browser preferences and sets
  /// <html lang>/<html dir> to match.
  ///
  /// Deliberately respects the ORDERED preference list rather than
  /// taking navigator.language alone — someone whose browser is set to
  /// ['de','fr','en'] should get French, not English. See
  /// Locales.resolveBest.
  void _resolveLocale() {
    final locale = Locales.resolveBest(interop.browserLanguages());
    interop.setHtmlLang(locale.code, locale.dirAttribute);
    if (locale.code == _s.locale.code) return;
    setState(() => _s = stringsFor(locale));
  }

  Future<void> _submitHero(String email) async {
    if (email.trim().isEmpty) {
      setState(() => _heroError = _s.errorEmailRequired);
      return;
    }
    setState(() {
      _heroSubmitting = true;
      _heroError = null;
    });
    try {
      await _waitlistApi.submit(email: email, source: 'hero');
      setState(() {
        _heroSubmitting = false;
        _heroSubmitted = true;
      });
    } catch (_) {
      setState(() {
        _heroSubmitting = false;
        _heroError = _s.errorGeneric;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': "font-family:'Instrument Sans',sans-serif;background:#FAF6EF;"
            'color:#1C1815;width:100%;overflow-x:hidden;position:relative',
      },
      [
        SiteHeader(s: _s, mode: _mode),

        // Above the fold on load, so a one-shot fade-up rather than a
        // scroll-triggered reveal.
        Component.wrapElement(
          classes: 'kola-fade-up',
          child: HeroSection(
            s: _s,
            mode: _mode,
            submitting: _heroSubmitting,
            submitted: _heroSubmitted,
            error: _heroError,
            onSubmit: _submitHero,
          ),
        ),

        // The demo is deliberately NOT scroll-revealed. It sits just
        // below the fold and is the first thing a visitor should be able
        // to touch — hiding it behind an animation delays the one
        // element on the page actually doing the persuading.
        const ProofDemoSection(),

        Component.wrapElement(
          classes: _revealClasses('problems'),
          child: const ProblemsSection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('how'),
          child: const HowItWorksSection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('memory'),
          child: const MemorySection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('commerce'),
          child: const CommerceSection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('capabilities'),
          child: const CapabilitiesSection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('timeline'),
          child: const TimelineStatementSection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('security'),
          child: const SecuritySection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('integrations'),
          child: const IntegrationsSection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('pricing'),
          child: PricingSection(s: _s, mode: _mode, region: _region),
        ),
        Component.wrapElement(
          classes: _revealClasses('replaces'),
          child: WhatItReplacesSection(s: _s, region: _region),
        ),
        Component.wrapElement(
          classes: _revealClasses('faq'),
          child: FaqSection(
            openIndexes: _openFaqIndexes,
            onToggle: (i) => setState(() {
              if (!_openFaqIndexes.remove(i)) _openFaqIndexes.add(i);
            }),
          ),
        ),
        const SiteFooter(),
      ],
    );
  }
}
