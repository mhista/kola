// theme.dart
//
// Design tokens pulled directly from the finished design system export
// (`Kola design system specs/Kola Dashboard Shell.dc.html`'s theme()
// function) — not reinterpreted, same "match the approved design
// pixel-for-pixel" discipline as kola_landing/theme.dart.
//
// TWO FULL PALETTES, DARK DEFAULT: unlike kola_landing (single light
// theme, marketing site), the dashboard design ships both a dark and a
// light palette with a real toggle in the design tool. This shell ships
// dark-only for now — the toggle shown in the design file is a
// design-tool preview control (paired with a Desktop/Mobile toggle,
// both clearly authoring aids, not real product chrome), not evidence
// the shipped product needs a user-facing theme switch on day one. Both
// palettes are kept here as real, complete token sets regardless, so
// adding a genuine theme-switch settings control later (Phase 4e+) is a
// wiring change, not a redesign.
abstract class KolaDashboardColors {
  // ── Dark (default) ──────────────────────────────────────────────────────
  static const bg = '#121214';
  static const card = '#1B1B1E';
  static const border = '#2C2A28';
  static const text = '#F3EEE7';
  static const muted = '#6B655E';
  static const mutedStrong = '#B9B3AC';

  // A second, lighter muted tone — confirmed (not a guess) by
  // Kola Bot Detail Chat.dc.html / Kola Bot Detail Dev.dc.html using
  // #9C9691 for secondary inline text (back links, inactive tabs,
  // mono source text) SIDE BY SIDE with #6B655E (`muted`, above) for
  // more subdued text (uppercase section labels, table headers,
  // timestamps) on the SAME dark pages. Not related to `mutedLight`
  // below, which is a different, currently-unshipped light PALETTE's
  // token — this is a real second dark-palette tone the Dashboard
  // Shell page just never needed.
  static const mutedSecondary = '#9C9691';
  static const pill = '#242220';
  static const navActiveBg = '#241A14';
  static const navInactiveText = '#D8D2C9';

  // Quick-action card backgrounds/icon-backgrounds, dark — index-matched
  // to the four quick actions (Errand, Knowledge, Integrations,
  // Conversations), same order as the design's quickActionDefs.
  static const quickActionBgs = ['#241A14', '#12261F', '#1B2430', '#241F14'];
  static const quickActionIconBgs = ['#3A2A1E', '#1F3B30', '#28374A', '#3A331F'];

  // ── Light (kept as a complete token set, not shipped yet — see header) ──
  static const bgLight = '#FAF6EF';
  static const cardLight = '#FFFFFF';
  static const borderLight = '#E8E1D6';
  static const textLight = '#1C1815';
  static const mutedLight = '#9C9691';
  static const mutedStrongLight = '#5B554F';
  static const pillLight = '#F1EAE0';
  static const navActiveBgLight = '#F1EAE0';
  static const navInactiveTextLight = '#4A443F';
  static const quickActionBgsLight = ['#FBEFE6', '#EAF6F0', '#EAF1FB', '#FBF3E6'];
  static const quickActionIconBgsLight = ['#F3D9C4', '#CFEEE0', '#CFE0F3', '#F3E3BE'];

  // ── Brand accent — same across both palettes ────────────────────────────
  static const accent = '#C1552E';
  static const accentText = '#FFF6EE';
  static const avatarBg = '#3A3733';
}

abstract class KolaDashboardFonts {
  // Swapped from the design export's original Space Grotesk (display) +
  // Plus Jakarta Sans (body) pairing to a single Inter family for both,
  // per the project owner's explicit request ("replace the whole type
  // system") — no longer matching Kola Dashboard Shell.dc.html's font
  // choice pixel-for-pixel, a deliberate deviation, not an oversight.
  static const display = "'Inter', sans-serif";
  static const sans = "'Inter', sans-serif";

  // Inter has no monospace cut, and bot ids/JSON schema blocks/curl
  // snippets genuinely need a monospace font for alignment — rather
  // than pull in a second web font (partly what "I don't like the
  // font" was reacting to), this uses each OS's own native monospace
  // font, no network request needed.
  static const mono = "ui-monospace, 'SF Mono', Menlo, Consolas, monospace";

  static const googleFontsHref = 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap';
}
