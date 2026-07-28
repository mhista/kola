// theme.dart — design tokens for kola_docs.
//
// DESIGN_PROMPT.md §12 calls for dark-mode-first (deep near-black bg,
// warm terracotta/amber accent used sparingly, serif display + clean
// sans + monospace for code), matching the brand direction already
// built for kola_dashboard rather than kola_landing's light marketing
// palette — the docs site is desktop-primary developer content, not the
// warm cream marketing surface. Values below are kola_dashboard's own
// dark palette (theme.dart), duplicated here rather than imported —
// same "each Jaspr package owns its own theme file" precedent kola_landing
// already set, since these are separate deployable static sites with no
// shared build step.

abstract class KolaDocsColors {
  static const bg = '#121214';
  static const surface = '#18181B';
  static const card = '#1C1B19';
  static const border = '#2C2A28';
  static const text = '#F3EEE7';
  static const textMuted = '#B9B3AC';
  static const textFaint = '#7A736C';
  static const accent = '#C1552E';
  static const accentText = '#FFFFFF';
  static const accentSoft = '#3A2A1E';
  static const codeBg = '#0B0B0C';
  static const codeText = '#D8D2C9';
  static const codeAccent = '#7ED8B0';
  static const warningBg = '#241F14';
  static const warningBorder = '#3A331F';
  static const warningText = '#E9C87C';
}

abstract class KolaDocsFonts {
  static const display = "'Newsreader', serif";
  static const sans = "'Inter', sans-serif";
  static const mono = "ui-monospace, 'SF Mono', Menlo, Consolas, monospace";

  /// Matches kola_dashboard's own choice of Inter for UI text (task #115)
  /// plus Newsreader for display headings (kola_landing's serif, kept
  /// here since docs headings benefit from the same editorial feel).
  /// mono is a native stack, no web font load, same reasoning
  /// kola_dashboard's theme.dart already documents for its own mono.
  static const googleFontsHref =
      'https://fonts.googleapis.com/css2?family=Newsreader:opsz,wght@6..72,500;6..72,600;6..72,700&family=Inter:wght@400;500;600;700&display=swap';
}
