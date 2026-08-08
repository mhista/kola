// links.dart
//
// EVERY outbound/cross-site URL on the landing page, in one file.
//
// WHY THIS EXISTS: the real URLs for docs, social and company pages
// weren't settled when this page was built. Rather than scatter
// placeholders through a dozen component files (and then hunt for them
// later), every link lives here. Filling in a real URL is a one-line
// change in this file — no component needs touching.
//
// ANYTHING STILL null IS NOT RENDERED. That is deliberate: a link that
// goes nowhere is worse than an absent one, especially in a footer where
// a dead "Careers" link signals a company that doesn't check its own
// site. Components ask [isLive] before rendering.

abstract class Links {
  // ── Live and real ───────────────────────────────────────────────────
  /// In-page anchors — always safe, they resolve to sections on this page.
  static const product = '#memory';
  static const commerce = '#commerce';
  static const pricing = '#pricing';
  static const changelog = '#changelog';
  static const faq = '#faq';

  // ── Awaiting real URLs ──────────────────────────────────────────────
  // Set these and they appear automatically.

  /// The developer documentation site (kola_docs). Deployed, but the
  /// public hostname isn't confirmed — left null rather than guessing at
  /// docs.kola.ng and shipping a broken nav item.
  static const String? docs = null;

  /// Company pages that do not exist yet.
  static const String? about = null;
  static const String? careers = null;
  static const String? contact = null;
  static const String? privacy = null;
  static const String? terms = null;

  /// Social.
  static const String? twitter = null;
  static const String? linkedin = null;
  static const String? instagram = null;

  /// True when a link is safe to render.
  static bool isLive(String? url) => url != null && url.isNotEmpty;
}
