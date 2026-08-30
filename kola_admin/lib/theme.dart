// theme.dart — a small, fixed palette. Unlike kola_dashboard's theme.dart
// there is no light/dark toggle and no user-selectable font here: this is
// an internal operator tool, not a customer-facing surface, so it stays
// on one dark, dense, monospace-leaning look always (see web/index.html's
// header on why IBM Plex was chosen specifically to look nothing like
// the customer dashboard).
abstract class AdminColors {
  static const bg = '#0B0D10';
  static const card = '#14171B';
  static const border = '#262B31';
  static const text = '#E8EAED';
  static const muted = '#8B929B';
  static const accent = '#4FA8FF';
  static const accentText = '#0B0D10';
  static const danger = '#E8A8A8';
  static const dangerBg = '#2A1414';
  static const dangerBorder = '#4A2020';
  static const warn = '#E8D8A8';
  static const warnBg = '#2A2414';
  static const warnBorder = '#4A4020';
  static const ok = '#A8E8B8';
}

abstract class AdminFonts {
  static const mono = "'IBM Plex Mono', ui-monospace, monospace";
  static const sans = "'IBM Plex Sans', system-ui, sans-serif";
}
