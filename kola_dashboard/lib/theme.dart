// theme.dart — the Kola Design System, as Dart constants.
//
// Extracted value-for-value from `Kola Design System.dc.html`, which is
// the design lab's own token page rather than colours read off a screen.
// Nothing here was inferred.
//
// ── WHAT CHANGED FROM THE PREVIOUS DASHBOARD ─────────────────────────
//
// 1. THE TYPEFACES ARE DIFFERENT. The old build was Inter throughout.
//    The redesign uses Space Grotesk for display and Plus Jakarta Sans
//    for UI, with IBM Plex Mono unchanged. This is not a detail — it is
//    the most visible single difference between old and new, and using
//    Inter anywhere would make a screen look immediately wrong next to a
//    correct one.
//
// 2. THERE ARE REAL SEMANTIC COLOURS NOW. success / danger / warning
//    exist as first-class tokens with proper light-mode counterparts.
//    The old system had one green and improvised the rest, which is why
//    every status badge looked slightly different.
//
// 3. LIGHT MODE IS A DESIGNED PAIR, not an unused token set. Every dark
//    token below has a light sibling that was chosen, not derived.
//
// ── HOW TO USE THIS ──────────────────────────────────────────────────
// Components read [KolaTokens] through the active [KolaTheme], never
// [KolaDark] or [KolaLight] directly. That indirection is the entire
// reason a theme switch is possible at all — a component that hardcodes
// `KolaDark.bg` cannot be themed, and there is no way to find it later
// except by reading every file.

/// One complete set of colour values. Dark and light are two instances.
class KolaTokens {
  const KolaTokens({
    required this.bg,
    required this.card,
    required this.border,
    required this.text,
    required this.mutedStrong,
    required this.muted,
    required this.accent,
    required this.accentFill,
    required this.accentText,
    required this.success,
    required this.danger,
    required this.warning,
    required this.pill,
    required this.categoryTints,
  });

  /// Page background.
  final String bg;

  /// Raised surfaces — cards, panels, inputs.
  final String card;

  /// Hairlines and dividers. NEVER use for text; it does not pass
  /// contrast against any background here and is not meant to.
  final String border;

  /// Primary text.
  final String text;

  /// Secondary text — still comfortably readable.
  final String mutedStrong;

  /// Tertiary text — labels, timestamps, hints.
  final String muted;

  /// Brand. Used for emphasis and active state.
  final String accent;

  /// A darker accent for FILLED surfaces. Exists because [accent] behind
  /// white text is only 4.27:1 — fine for large text, short of AA at
  /// body size. Use this for filled buttons; use [accent] for text and
  /// borders.
  final String accentFill;

  /// Text on an accent-filled surface.
  final String accentText;

  final String success;
  final String danger;
  final String warning;

  /// Inert chips and badges.
  final String pill;

  /// Four surface/icon pairs used in rotation for categorical colour.
  /// Deliberately a fixed set: categorical colour that is generated
  /// rather than chosen drifts, and two adjacent categories end up
  /// indistinguishable.
  final List<KolaCategoryTint> categoryTints;
}

class KolaCategoryTint {
  const KolaCategoryTint({required this.surface, required this.icon});
  final String surface;
  final String icon;
}

// ── RAW VALUES ───────────────────────────────────────────────────────
// The hex values live here ONCE, as private static consts, and both the
// token sets below and the deprecated compatibility layer at the bottom
// of this file read them from here.
//
// This indirection is not decoration. Dart does not permit instance
// field access inside a constant expression — `static const x =
// SomeConstObject.field;` does not compile — so the compatibility layer
// physically cannot read `KolaDark.tokens.bg`. Without these, the old
// names would have to repeat the literals, and the two copies would
// drift the first time a colour was corrected in one place only.

abstract class _D {
  static const bg = '#121214';
  static const card = '#1B1B1E';
  static const border = '#2C2A28';
  static const text = '#F3EEE7';
  static const mutedStrong = '#B9B3AC';
  static const muted = '#9C9691';
  static const accent = '#C1552E';
  static const accentFill = '#9C4520';
  static const accentText = '#FFF6EE';
  static const success = '#34A37E';
  static const danger = '#E5484D';
  static const warning = '#E2A33D';
  static const pill = '#242220';

  static const tint0Surface = '#241A14';
  static const tint0Icon = '#3A2A1E';
  static const tint1Surface = '#12261F';
  static const tint1Icon = '#1F3B30';
  static const tint2Surface = '#1B2430';
  static const tint2Icon = '#28374A';
  static const tint3Surface = '#241F14';
  static const tint3Icon = '#3A331F';
}

abstract class _L {
  static const bg = '#FAF6EF';
  static const card = '#FFFFFF';
  static const border = '#E8E1D6';
  static const text = '#1C1815';
  static const mutedStrong = '#5B554F';
  static const muted = '#7A736C';
  static const accent = '#C1552E';
  static const accentFill = '#9C4520';
  static const accentText = '#FFF6EE';
  static const success = '#227A5B';
  static const danger = '#C4373D';
  static const warning = '#9C6A14';
  static const pill = '#F1EAE0';

  static const tint0Surface = '#FBEFE6';
  static const tint0Icon = '#F3D9C4';
  static const tint1Surface = '#EAF6F0';
  static const tint1Icon = '#CFEEE0';
  static const tint2Surface = '#EAF1FB';
  static const tint2Icon = '#CFE0F3';
  static const tint3Surface = '#FBF3E6';
  static const tint3Icon = '#F3E3BE';
}

/// Dark — the shipped default.
abstract class KolaDark {
  static const tokens = KolaTokens(
    bg: _D.bg,
    card: _D.card,
    border: _D.border,
    text: _D.text,
    mutedStrong: _D.mutedStrong,
    muted: _D.muted,
    accent: _D.accent,
    accentFill: _D.accentFill,
    accentText: _D.accentText,
    success: _D.success,
    danger: _D.danger,
    warning: _D.warning,
    pill: _D.pill,
    categoryTints: [
      KolaCategoryTint(surface: _D.tint0Surface, icon: _D.tint0Icon),
      KolaCategoryTint(surface: _D.tint1Surface, icon: _D.tint1Icon),
      KolaCategoryTint(surface: _D.tint2Surface, icon: _D.tint2Icon),
      KolaCategoryTint(surface: _D.tint3Surface, icon: _D.tint3Icon),
    ],
  );

  /// Backgrounds for status text on dark. Paired with the semantic
  /// colours above — a status badge is a tinted surface plus a coloured
  /// label, never colour alone (see KolaStatus).
  static const successBg = _D.tint1Surface;
  static const dangerBg = '#2A1414';
  static const warningBg = _D.tint3Surface;
  static const infoBg = _D.tint2Surface;
  static const infoText = '#7CB0E9';

  /// A brighter success for text on the darkest surfaces, where the
  /// standard success reads muddy.
  static const successBright = '#7ED8B0';
}

/// Light — a designed pair, not a derivation.
abstract class KolaLight {
  static const tokens = KolaTokens(
    bg: _L.bg,
    card: _L.card,
    border: _L.border,
    text: _L.text,
    mutedStrong: _L.mutedStrong,
    muted: _L.muted,
    accent: _L.accent,
    accentFill: _L.accentFill,
    accentText: _L.accentText,
    success: _L.success,
    danger: _L.danger,
    warning: _L.warning,
    pill: _L.pill,
    categoryTints: [
      KolaCategoryTint(surface: _L.tint0Surface, icon: _L.tint0Icon),
      KolaCategoryTint(surface: _L.tint1Surface, icon: _L.tint1Icon),
      KolaCategoryTint(surface: _L.tint2Surface, icon: _L.tint2Icon),
      KolaCategoryTint(surface: _L.tint3Surface, icon: _L.tint3Icon),
    ],
  );

  static const successBg = _L.tint1Surface;
  static const dangerBg = '#FBEAEA';
  static const warningBg = _L.tint3Surface;
  static const infoBg = _L.tint2Surface;
  static const infoText = '#2C6FB5';
  static const successBright = _L.success;
}

/// Typefaces.
///
/// CHANGED FROM THE PREVIOUS BUILD — see this file's header. Inter is
/// gone; using it anywhere now makes a screen look wrong beside a
/// correct one.
abstract class KolaFonts {
  /// Space Grotesk. Headings, metrics, anything that should read as a
  /// number or a title.
  static const display = "'Space Grotesk', sans-serif";

  /// Plus Jakarta Sans. Body and UI.
  static const sans = "'Plus Jakarta Sans', sans-serif";

  /// IBM Plex Mono. IDs, references, code, and — importantly — money
  /// columns, where tabular figures stop digits jumping between rows.
  static const mono = "'IBM Plex Mono', monospace";

  static const googleFontsHref =
      'https://fonts.googleapis.com/css2'
      '?family=Space+Grotesk:wght@500;600;700'
      '&family=Plus+Jakarta+Sans:wght@400;500;600;700'
      '&family=IBM+Plex+Mono:wght@400;500;600'
      '&display=swap';
}

/// Type scale, from the export's actual usage.
///
/// 13px is the workhorse — the single most-used size across every
/// screen. Sizes below it are labels, above it are headings.
abstract class KolaType {
  static const micro = '11px';
  static const tiny = '12px';
  static const small = '12.5px';
  static const body = '13px';
  static const bodyLg = '13.5px';
  static const ui = '14px';
  static const uiLg = '14.5px';
  static const lead = '15px';
  static const subhead = '16px';
  static const title = '17px';
  static const h3 = '18px';
  static const h2 = '21px';
  static const h1 = '24px';
  static const display = '26px';
}

/// Radii. Named from the design system's own scale.
abstract class KolaRadius {
  static const sm = '8px';
  static const md = '12px';
  static const lg = '16px';
  static const xl = '22px';

  /// The signature. Chips, badges, avatars, and every button.
  static const pill = '100px';
  static const circle = '50%';
}

/// Spacing. Note this is NOT a strict 8-point grid — 10px and 14px are
/// heavily used in the designs, and imposing a stricter scale would mean
/// every screen drifting from its export.
abstract class KolaSpace {
  static const xs = '4px';
  static const sm = '8px';
  static const smd = '10px';
  static const md = '12px';
  static const lmd = '14px';
  static const lg = '16px';
  static const xl = '20px';
  static const xxl = '24px';
  static const xxxl = '32px';
}

/// Breakpoints.
///
/// The previous build had exactly one (960px) and no tablet layout —
/// too coarse for a product this size. **360px is the floor**, not 390:
/// Tecno, Infinix and itel devices dominate this market and are commonly
/// 360 logical px wide. See docs/DESIGN_STANDARD_MOBILE.md.
abstract class KolaBreak {
  static const phoneFloor = 360;
  static const phone = 480;
  static const tablet = 768;
  static const desktop = 1024;
  static const wide = 1280;
}

/// Motion. Restrained on purpose — this is a dashboard a shop owner
/// checks twenty times a day, not a showreel. Every duration here is
/// short enough to feel immediate rather than animated.
abstract class KolaMotion {
  static const instant = '80ms';
  static const fast = '140ms';
  static const base = '200ms';
  static const slow = '320ms';
  static const ease = 'cubic-bezier(0.2, 0, 0, 1)';
  static const easeOut = 'cubic-bezier(0, 0, 0.2, 1)';
}

/// Confidence, as used by observations, recommendations and memory
/// matches.
///
/// THREE DOTS PLUS A NUMBER, never colour alone. The design system's own
/// page defines it this way, and it is the right call: a low-confidence
/// claim shown with the same weight as a high-confidence one destroys
/// trust in both, and colour alone fails for anyone who cannot
/// distinguish these particular hues.
enum KolaConfidence { high, medium, low }

extension KolaConfidenceStyle on KolaConfidence {
  /// Filled dots out of three.
  int get filledDots => switch (this) {
        KolaConfidence.high => 3,
        KolaConfidence.medium => 2,
        KolaConfidence.low => 1,
      };

  String get label => switch (this) {
        KolaConfidence.high => 'High confidence',
        KolaConfidence.medium => 'Medium confidence',
        KolaConfidence.low => 'Low confidence',
      };

  String colorOn(KolaTokens t) => switch (this) {
        KolaConfidence.high => t.success,
        KolaConfidence.medium => t.warning,
        KolaConfidence.low => t.danger,
      };

  /// Thresholds match the design system page's own examples (0.86 high,
  /// 0.58 medium, 0.31 low).
  static KolaConfidence fromScore(double score) {
    if (score >= 0.7) return KolaConfidence.high;
    if (score >= 0.45) return KolaConfidence.medium;
    return KolaConfidence.low;
  }
}

// ─────────────────────────────────────────────────────────────────────
// HOW THEMING ACTUALLY WORKS — READ BEFORE WRITING A COMPONENT
//
// Components must NOT interpolate hex values into style strings. They
// interpolate CSS custom properties, via [KolaVar]:
//
//     'background:${KolaVar.card};color:${KolaVar.text}'
//
// The properties are defined once in web/styles.css — dark under
// `:root`, light under `[data-theme="light"]`. Switching theme is
// therefore ONE attribute write on <html>. No component rebuilds, no
// light/dark branch anywhere in Dart, no token threading through
// constructors.
//
// WHY THIS RATHER THAN PASSING KolaTokens DOWN:
//   The previous build interpolated dark hex straight into inline
//   styles across 37 files. That is the entire reason it has no light
//   mode — adding one meant editing all 37. Passing a KolaTokens object
//   down would fix correctness but not cost: every component would need
//   the object threaded in, and every one would have to re-render on
//   switch. Custom properties are resolved by the browser at paint
//   time; the switch costs one attribute.
//
//   KolaTokens has not become useless — it is still the source of
//   truth, it is what the generator reads, and it is what code that
//   genuinely needs a VALUE rather than a reference uses (canvas
//   drawing, generated SVG, an inline chart fill).
//
// web/styles.css IS GENERATED from the values in this file. Do not hand
// edit the generated block; run `python3 tool/gen_theme_css.py`.
// ─────────────────────────────────────────────────────────────────────

/// CSS custom property references. What components interpolate.
///
/// Every name here mirrors a [KolaTokens] field, so moving between the
/// two is mechanical.
abstract class KolaVar {
  static const bg = 'var(--kola-bg)';
  static const card = 'var(--kola-card)';
  static const border = 'var(--kola-border)';
  static const text = 'var(--kola-text)';
  static const mutedStrong = 'var(--kola-muted-strong)';
  static const muted = 'var(--kola-muted)';
  static const accent = 'var(--kola-accent)';
  static const accentFill = 'var(--kola-accent-fill)';
  static const accentText = 'var(--kola-accent-text)';
  static const success = 'var(--kola-success)';
  static const danger = 'var(--kola-danger)';
  static const warning = 'var(--kola-warning)';
  static const pill = 'var(--kola-pill)';

  /// The Overview glow. A full `background` value, not a colour — assign
  /// it directly, do not interpolate it into a shorthand.
  static const glow = 'var(--kola-glow)';

  static const successBg = 'var(--kola-success-bg)';
  static const dangerBg = 'var(--kola-danger-bg)';
  static const warningBg = 'var(--kola-warning-bg)';
  static const infoBg = 'var(--kola-info-bg)';
  static const infoText = 'var(--kola-info-text)';
  static const successBright = 'var(--kola-success-bright)';

  /// Category tint surface, 0-3. Asserts rather than wrapping with `%`:
  /// an out-of-range index is a bug in the caller's rotation logic, and
  /// silently wrapping it hides that a fifth category exists and is
  /// being drawn identically to the first.
  static String tintSurface(int i) {
    assert(i >= 0 && i < 4, 'category tint index must be 0-3, got $i');
    return 'var(--kola-tint-$i-surface)';
  }

  static String tintIcon(int i) {
    assert(i >= 0 && i < 4, 'category tint index must be 0-3, got $i');
    return 'var(--kola-tint-$i-icon)';
  }
}

/// The theme switch itself.
///
/// Deliberately tiny. The whole mechanism is an attribute on the root
/// element; anything more elaborate here would be inventing state that
/// CSS already holds.
abstract class KolaTheme {
  static const attribute = 'data-theme';
  static const light = 'light';
  static const dark = 'dark';

  /// With NO attribute set, the app follows the operating system (see
  /// the `prefers-color-scheme` rule in styles.css). Setting the
  /// attribute is an explicit override that outranks the OS.
  ///
  /// This ordering is the one users expect: a person who has never
  /// touched the setting gets whatever their phone does at night, and a
  /// person who has chosen gets their choice, permanently.
  static const followSystem = null;
}

/// Status badges.
///
/// EXISTS BECAUSE THE OLD BUILD HAD NO SUCH THING and, as a direct
/// result, every status badge looked slightly different — each screen
/// improvised a colour pair. This is the one place a status appearance
/// is decided.
///
/// A badge is ALWAYS a tinted surface plus a coloured label, never
/// colour alone. Colour alone fails for anyone who cannot distinguish
/// these hues, and it fails completely in a printed receipt or report —
/// which this product generates.
enum KolaTone { positive, caution, negative, neutral, info }

extension KolaToneStyle on KolaTone {
  String get fg => switch (this) {
        KolaTone.positive => KolaVar.successBright,
        KolaTone.caution => KolaVar.warning,
        KolaTone.negative => KolaVar.danger,
        KolaTone.neutral => KolaVar.muted,
        KolaTone.info => KolaVar.infoText,
      };

  String get bg => switch (this) {
        KolaTone.positive => KolaVar.successBg,
        KolaTone.caution => KolaVar.warningBg,
        KolaTone.negative => KolaVar.dangerBg,
        KolaTone.neutral => KolaVar.pill,
        KolaTone.info => KolaVar.infoBg,
      };

  /// Ready-to-interpolate badge style.
  String get badgeCss =>
      'display:inline-flex;align-items:center;gap:6px;'
      'padding:3px 10px;border-radius:${KolaRadius.pill};'
      'font-size:${KolaType.micro};font-weight:600;'
      'background:$bg;color:$fg';
}

/// Payment confirmation, rendered.
///
/// THIS IS THE UI HALF OF migration 022's `confirmation_method`. The
/// server draws a hard line between a payment the gateway VERIFIED and
/// a transfer a person MARKED paid, and that line is worthless if both
/// render as a green "Paid" badge.
///
/// A human-marked payment is `caution`, not `positive`, and it says so
/// in words. Not because the person is untrusted — because a rep
/// marking the wrong order paid is an ordinary Tuesday mistake, and
/// this is the only place it becomes visible.
enum KolaConfirmation { gatewayVerified, humanMarked }

extension KolaConfirmationStyle on KolaConfirmation {
  KolaTone get tone => switch (this) {
        KolaConfirmation.gatewayVerified => KolaTone.positive,
        KolaConfirmation.humanMarked => KolaTone.caution,
      };

  String get label => switch (this) {
        KolaConfirmation.gatewayVerified => 'Paid',
        KolaConfirmation.humanMarked => 'Marked paid',
      };

  /// Shown next to the label wherever there is room for it.
  String get detail => switch (this) {
        KolaConfirmation.gatewayVerified => 'Confirmed by the payment provider',
        KolaConfirmation.humanMarked => 'Confirmed by a person, not the bank',
      };

  static KolaConfirmation fromServer(String confirmationMethod) =>
      confirmationMethod == 'gateway_verified'
          ? KolaConfirmation.gatewayVerified
          : KolaConfirmation.humanMarked;
}

// ─────────────────────────────────────────────────────────────────────
// COMPATIBILITY LAYER — DEPRECATED, DO NOT USE IN NEW CODE
//
// 37 files were built against the PREVIOUS design system and reference
// `KolaDashboardColors` / `KolaDashboardFonts`. Every one of them is
// being rewritten as part of this redesign, but they have to keep
// compiling until they are: a dashboard that does not build cannot be
// checked against the design as it is rebuilt, screen by screen.
//
// So these map the old names onto the new raw values. Two consequences
// worth stating plainly rather than discovering:
//
//   • THE TYPEFACES ARE DIFFERENT NOW. An unconverted screen renders in
//     Space Grotesk / Plus Jakarta Sans, not Inter. That is correct —
//     it is the new system — but it means an old screen will not look
//     exactly as it did before this change. It will look closer to
//     where it is going, not further.
//
//   • A few old tokens have no exact new equivalent: the nav colours,
//     the avatar background, and the third muted tone. Those keep their
//     original literals or map to the nearest new token, so an
//     unconverted screen is approximately right rather than exactly
//     right. Converting the screen is the fix. Adjusting the mapping is
//     not — it would make the shim a second design system.
//
// Everything here is `const`, matching the old declarations exactly, so
// no existing const context breaks.
//
// DELETE THIS BLOCK when nothing references it. The signal is
// `grep -rn "KolaDashboard" lib/` returning nothing.
// ─────────────────────────────────────────────────────────────────────

@Deprecated('Read KolaTokens through the active theme instead.')
abstract class KolaDashboardColors {
  static const bg = _D.bg;
  static const card = _D.card;
  static const border = _D.border;
  static const text = _D.text;
  static const muted = _D.muted;
  static const mutedStrong = _D.mutedStrong;
  static const accent = _D.accent;
  static const accentText = _D.accentText;
  static const pill = _D.pill;

  /// The old scale had three muted tones; the new one has two.
  /// Collapses to `muted`, which is where the middle tone was closest.
  static const mutedSecondary = _D.muted;

  /// Nav had bespoke tokens before. The new system expresses active nav
  /// as accent-on-tint, so the background maps to the first category
  /// tint; the inactive text colour has no new equivalent and keeps its
  /// original value.
  static const navActiveBg = _D.tint0Surface;
  static const navInactiveText = '#D8D2C9';

  /// No new equivalent — avatars are a tinted surface in the new system.
  static const avatarBg = '#3A3733';

  static const quickActionBgs = [
    _D.tint0Surface,
    _D.tint1Surface,
    _D.tint2Surface,
    _D.tint3Surface,
  ];
  static const quickActionIconBgs = [
    _D.tint0Icon,
    _D.tint1Icon,
    _D.tint2Icon,
    _D.tint3Icon,
  ];

  // Light-mode counterparts. Unused by the old build, but part of its
  // token set, so they are kept rather than silently dropped.
  static const bgLight = _L.bg;
  static const cardLight = _L.card;
  static const borderLight = _L.border;
  static const textLight = _L.text;
  static const mutedLight = _L.muted;
  static const mutedStrongLight = _L.mutedStrong;
  static const pillLight = _L.pill;
  static const navActiveBgLight = _L.pill;
  static const navInactiveTextLight = '#4A443F';
  static const quickActionBgsLight = [
    _L.tint0Surface,
    _L.tint1Surface,
    _L.tint2Surface,
    _L.tint3Surface,
  ];
  static const quickActionIconBgsLight = [
    _L.tint0Icon,
    _L.tint1Icon,
    _L.tint2Icon,
    _L.tint3Icon,
  ];
}

@Deprecated('Use KolaFonts.')
abstract class KolaDashboardFonts {
  static const display = KolaFonts.display;
  static const sans = KolaFonts.sans;
  static const mono = KolaFonts.mono;
  static const googleFontsHref = KolaFonts.googleFontsHref;
}
