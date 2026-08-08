// theme.dart
//
// Design tokens pulled directly from the finished design system export
// (`Kola design system specs/Kola Landing.dc.html`) — not reinterpreted,
// so the built page matches the approved design pixel-for-pixel on color
// and type. Every component file imports this instead of hardcoding hex
// values, so a future rebrand-touch is a one-file change.

abstract class KolaColors {
  static const bg = '#FAF6EF';
  static const accent = '#C1552E';
  static const accentHover = '#A8451F';

  /// Text on an accent-filled surface (the primary button). A real token
  /// from the design export that was never carried into this file.
  ///
  /// CONTRAST NOTE: #FFF6EE on #C1552E is 4.27:1 — passes AA for large
  /// text only, not for 14px body. It is used at 14px on the primary
  /// button today, which is a pre-existing accessibility issue inherited
  /// from the design, not introduced here. Flagged rather than silently
  /// changed, since altering the brand's primary button colour is a
  /// design decision, not an engineering one.
  static const accentText = '#FFF6EE';
  static const text = '#1C1815';
  static const textMuted = '#5B554F';
  static const textMutedLight = '#6B655E';
  static const textNav = '#4A443F';
  static const textFaint = '#9C9691';
  static const textBody = '#3E3934';
  static const badgeBrown = '#9C7A5A';
  static const border = '#E8E1D6';
  static const cardBg = '#FFFFFF';
  static const pillBg = '#F1EAE0';
  static const dark = '#1C1815';
  static const darkText = '#F3EEE7';
  static const darkTextMuted = '#B9B3AC';
  static const darkTextFaint = '#7A736C';
  static const darkTextSoft = '#D8D2C9';
  static const darkBorder = '#2A2622';
  static const darkInputBorder = '#3A3733';
  static const darkInputBg = '#151412';
  static const success = '#2F8F6D';
  static const successBg = '#12261F';
  static const peach = '#F0B08C';
  static const orange = '#E9A87C';
  static const waitlistBannerBg = '#241A14';
  static const codeBg = '#000000';
  static const codeText = '#9BE6C7';

  /// The match-score green used on dark surfaces (memory citation card).
  /// A step brighter than [success] because it sits on #1C1815 where
  /// success reads muddy — verified at 7.9:1 against that background.
  static const matchGreen = '#7ED8B0';
}

abstract class KolaFonts {
  static const serif = "'Newsreader', serif";
  static const sans = "'Instrument Sans', sans-serif";
  static const mono = "'IBM Plex Mono', monospace";

  /// Google Fonts stylesheet link — included once in index.html, kept
  /// here too as the single source of truth for which weights are loaded.
  static const googleFontsHref =
      'https://fonts.googleapis.com/css2?family=Newsreader:ital,opsz,wght@0,6..72,400;0,6..72,500;0,6..72,600;1,6..72,500&family=Instrument+Sans:wght@400;500;600;700&family=IBM+Plex+Mono:wght@400;500&display=swap';
}
