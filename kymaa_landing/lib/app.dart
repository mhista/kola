// app.dart
//
// Root component. Owns every piece of page state in one place (mode,
// banner visibility, active tab, FAQ open/closed, and the submit/error
// state of the three waitlist forms) and passes it down to each section
// component — mirrors the single-Component-state shape Kola
// Landing.dc.html itself uses, just expressed as Dart/Jaspr state instead
// of the design tool's own state runtime.
//
// Section components live one-per-file under lib/components/ per the
// working convention against jam-packed pages — this file's job is
// composition and state, not markup.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import 'components/announcement_banner.dart';
import 'components/site_header.dart';
import 'components/hero_section.dart';
import 'components/built_for_strip.dart';
import 'components/how_it_works_section.dart';
import 'components/waitlist_section.dart';
import 'components/integrations_section.dart';
import 'components/channels_section.dart';
import 'components/team_split_section.dart';
import 'components/pricing_section.dart';
import 'i18n/region.dart';
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

  // Set at build time via Env.launchMode ('waitlist' default) — never a
  // runtime UI control. See config/env.dart's header comment: toggling
  // this is a `dart compile js ... -DLAUNCH_MODE=launched` build flag,
  // not something a page visitor (or anyone else) can flip.
  late String _mode = Env.launchMode;

  // Currency and prices. Resolved in ONE place and passed down, so no
  // component hardcodes a symbol — see i18n/region.dart.
  //
  // Fixed at International (USD) rather than detected. Detection needs
  // either an IP lookup (a third-party request on a page that currently
  // makes none) or a timezone guess, and a visitor shown the wrong
  // currency is worse than one shown a clear, explicit USD price.
  final Region _region = Regions.international;

  bool _bannerVisible = true;
  bool _bannerClosing = false;
  String _activeTab = 'conversational';
  bool _billingYearly = false;
  final Set<int> _openFaqIndexes = {0};

  // Which .kola-reveal sections (by their DOM id) have scrolled into view
  // at least once. Deliberately Dart state, not a class script.js adds
  // straight to the DOM — see interop.dart's header comment for the bug
  // that caused (any unrelated setState() here wiped a JS-only class on
  // rebuild, making already-revealed sections vanish on any button
  // click). Living here means _revealClasses always renders correctly no
  // matter what else changes.
  final Set<String> _revealed = {};

  /// Classes for a scroll-reveal wrapper — 'kola-reveal' alone (hidden)
  /// until [sectionId] has been reported visible via _onSectionRevealed,
  /// then 'kola-reveal kola-reveal-in' (visible) forever after.
  String _revealClasses(String sectionId) =>
      _revealed.contains(sectionId) ? 'kola-reveal kola-reveal-in' : 'kola-reveal';

  /// Called by script.js's IntersectionObserver (via interop.dart's
  /// registerRevealCallback) the first time a section scrolls into view.
  void _onSectionRevealed(String sectionId) {
    if (!mounted || _revealed.contains(sectionId)) return;
    setState(() => _revealed.add(sectionId));
  }

  @override
  void initState() {
    super.initState();
    // Must register BEFORE initScrollReveal() runs — the observer can
    // fire for an already-in-view section the moment .observe() is
    // called, before initScrollReveal() even returns.
    interop.registerRevealCallback(_onSectionRevealed);
    // Kick off scroll-reveal after Jaspr's first paint — mirrors the exact
    // technique already proven in kopicat_landing/lib/main.dart's
    // initState (a microtask delay so the DOM nodes actually exist by the
    // time script.js goes looking for .kola-reveal elements).
    Future.microtask(() => interop.initScrollReveal());
  }

  /// Plays the banner's slide-up-and-fade CSS animation, then removes it
  /// from the DOM once the animation has actually finished — a plain
  /// setState(() => _bannerVisible = false) would just snap it away
  /// instantly since Jaspr would unmount the element before any CSS
  /// transition got a chance to run.
  void _closeBanner() {
    setState(() => _bannerClosing = true);
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _bannerVisible = false);
    });
  }

  bool _heroSubmitting = false;
  bool _heroSubmitted = false;
  String? _heroError;

  bool _wlSubmitting = false;
  bool _wlSubmitted = false;
  String? _wlError;

  bool _footerSubmitting = false;
  bool _footerSubmitted = false;

  Future<void> _submitHero(String email, String phone) async {
    if (email.trim().isEmpty) {
      setState(() => _heroError = 'Please enter your email address.');
      return;
    }
    setState(() {
      _heroSubmitting = true;
      _heroError = null;
    });
    try {
      await _waitlistApi.submit(email: email, phone: phone, source: 'hero');
      setState(() {
        _heroSubmitting = false;
        _heroSubmitted = true;
      });
    } catch (e) {
      setState(() {
        _heroSubmitting = false;
        _heroError = 'Something went wrong — please try again.';
      });
    }
  }

  Future<void> _submitWaitlist(String email, String phone) async {
    if (email.trim().isEmpty) {
      setState(() => _wlError = 'Please enter your email address.');
      return;
    }
    setState(() {
      _wlSubmitting = true;
      _wlError = null;
    });
    try {
      await _waitlistApi.submit(
        email: email,
        phone: phone,
        source: 'waitlist_section',
      );
      setState(() {
        _wlSubmitting = false;
        _wlSubmitted = true;
      });
    } catch (e) {
      setState(() {
        _wlSubmitting = false;
        _wlError = 'Something went wrong — please try again.';
      });
    }
  }

  Future<void> _submitFooter(String email) async {
    if (email.trim().isEmpty || _footerSubmitting) return;
    setState(() => _footerSubmitting = true);
    try {
      await _waitlistApi.submit(email: email, source: 'footer');
      setState(() {
        _footerSubmitting = false;
        _footerSubmitted = true;
      });
      interop.setFieldValue('footerEmail', '');
    } catch (e) {
      setState(() => _footerSubmitting = false);
      // Footer form is deliberately low-ceremony — a failed footer signup
      // just silently stays retryable rather than growing its own error
      // banner; the hero and #waitlist forms are the ones that surface
      // errors explicitly.
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'style': "font-family:'Instrument Sans',sans-serif;background:#FAF6EF;"
          'color:#1C1815;width:100%;overflow-x:hidden;position:relative'},
      [
        AnnouncementBanner(
          visible: _bannerVisible,
          closing: _bannerClosing,
          onClose: _closeBanner,
        ),
        const SiteHeader(),
        // Hero is always above the fold on load, so it gets a one-shot
        // fade-up on first paint rather than a scroll-triggered reveal —
        // see kola-fade-up's definition in web/styles.css.
        Component.wrapElement(
          classes: 'kola-fade-up',
          child: HeroSection(
            mode: _mode,
            submitting: _heroSubmitting,
            submitted: _heroSubmitted,
            error: _heroError,
            onSubmit: _submitHero,
          ),
        ),
        // Everything below the fold uses the scroll-triggered .kola-reveal
        // animation instead — Component.wrapElement merges the class onto
        // each section's own root element without adding an extra wrapper
        // div (see Jaspr's docs on wrapElement for why this is safe). Each
        // section keeps a stable `id` on its own root element (set inside
        // its own file) so _revealClasses/_onSectionRevealed can track it
        // — see this file's _revealed field for why the class itself is
        // computed here instead of hardcoded.
        Component.wrapElement(
          classes: _revealClasses('reveal-built-for-strip'),
          child: const BuiltForStrip(),
        ),
        Component.wrapElement(
          classes: _revealClasses('reveal-how-it-works'),
          child: const HowItWorksSection(),
        ),
        WaitlistSection(
          visible: _mode == 'waitlist',
          revealed: _revealed.contains('waitlist'),
          submitting: _wlSubmitting,
          submitted: _wlSubmitted,
          error: _wlError,
          onSubmit: _submitWaitlist,
        ),
        Component.wrapElement(
          classes: _revealClasses('reveal-integrations'),
          child: const IntegrationsSection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('reveal-channels'),
          child: ChannelsSection(
            activeTab: _activeTab,
            onTabChange: (tab) => setState(() => _activeTab = tab),
          ),
        ),
        Component.wrapElement(
          classes: _revealClasses('reveal-team-split'),
          child: const TeamSplitSection(),
        ),
        Component.wrapElement(
          classes: _revealClasses('pricing'),
          child: PricingSection(
            mode: _mode,
            region: _region,
            yearly: _billingYearly,
            onSetMonthly: () => setState(() => _billingYearly = false),
            onSetYearly: () => setState(() => _billingYearly = true),
          ),
        ),
        Component.wrapElement(
          classes: _revealClasses('faq'),
          child: FaqSection(
            openIndexes: _openFaqIndexes,
            onToggle: (i) => setState(() {
              if (_openFaqIndexes.contains(i)) {
                _openFaqIndexes.remove(i);
              } else {
                _openFaqIndexes.add(i);
              }
            }),
          ),
        ),
        SiteFooter(
          mode: _mode,
          submitting: _footerSubmitting,
          submitted: _footerSubmitted,
          onSubmit: _submitFooter,
        ),
      ],
    );
  }
}
