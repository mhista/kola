// theme.dart — tokens lifted directly from the real design spec:
// "Kola design system specs/kola_admin/exports/admin/Kola Admin Release
// Control.dc.html" (and shared by the other kola_admin/exports/admin/*
// mockups, which use the same palette/fonts/sidebar shape). This
// replaces an earlier ad-hoc dark IBM-Plex-only theme that was NOT
// checked against the actual design spec — this file is the correction.
//
// Fixed, single dark theme, deliberately — no light/dark toggle exists
// in the spec, unlike the customer dashboard.
abstract class AdminColors {
  static const bg = '#0C0C0D';
  static const sidebarItemActiveBg = '#161617';
  static const card = '#161617';
  static const border = '#232323';
  static const borderLight = '#2C2C2E';
  static const rowBorder = '#1B1B1B';
  static const tableHeaderBg = '#131313';
  static const heading = '#F0EEEA';
  static const text = '#D8D6D2';
  static const muted = '#8B8783';
  static const faint = '#5A5754';
  static const accent = '#5B9BD1';
  static const accentHover = '#7CB0E9';
  static const accentText = '#0C0C0D';

  // State pill colors — [background, foreground], exact pairs from
  // STATE_META in the design spec's script block.
  static const lockedBg = '#232323';
  static const lockedFg = '#8B8783';
  static const internalBg = '#1B2430';
  static const internalFg = '#7CB0E9';
  static const betaBg = '#241A14';
  static const betaFg = '#E9A87C';
  static const releasedBg = '#131A16';
  static const releasedFg = '#6FBF95';

  // Reconciliation banner (green — "no drift") reuses released's pair;
  // a red variant is this project's own addition for a genuine drift/
  // error state, since the spec's static mockup only shows the happy
  // path banner.
  static const dangerBg = '#2A1414';
  static const dangerBorder = '#4A2020';
  static const danger = '#E8A8A8';

  static const filterActiveBg = '#1B2430';
  static const filterActiveFg = '#7CB0E9';
  static const filterActiveBorder = '#2A3F52';
}

abstract class AdminFonts {
  static const display = "'Space Grotesk', sans-serif";
  static const body = "'Inter', sans-serif";
  static const mono = "'IBM Plex Mono', ui-monospace, monospace";
}
