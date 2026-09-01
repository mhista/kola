// icons.dart — every SVG path the shell draws.
//
// EXTRACTED FROM `Kola Dashboard Shell.dc.html`, not redrawn. These are
// the design's own paths, copied programmatically rather than by hand;
// a mistyped path coordinate produces an icon that is subtly wrong in a
// way nobody notices until it ships.
//
// FORMAT: each value is one or more subpaths separated by a space, meant
// for a 24x24 viewBox with `fill="none"`, `stroke="currentColor"`,
// stroke-width 1.8, and round caps/joins. [KolaIcon.svg] applies all of
// that, so no caller has to remember it — and so an icon cannot end up
// filled-black because someone forgot `fill="none"`.
//
// Paths carrying their own fill (the kolaa droplet) are NOT here; they
// are drawn where they are used, since they do not follow this contract.

abstract class Icons {
  static const activity = 'M2 12h4l3-8 4 16 3-8h6';
  static const arrowRight = 'M4 12h16M14 6l6 6-6 6';
  static const barChart = 'M4 20V10 M10 20V4 M16 20v-7 M2 20h20';
  // Kola Till.dc.html's scanner-button glyph, copied path-for-path —
  // the four corner brackets plus the internal barcode bars.
  static const barcode =
      'M3 7V4h3 M17 4h3v3 M20 17v3h-3 M7 20H4v-3 M7 8v8 M11 8v8 M14 8v2 M14 14v2 M17 8v8';
  static const billing = 'M17 9V7a5 5 0 0 0-10 0v2 M5 9h14v11H5Z';
  static const printer =
      'M6 9V2h12v7 M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2 M6 14h12v8H6Z';
  static const book = 'M4 5c2-1 5-1 8 0v14c-3-1-6-1-8 0Z M20 5c-2-1-5-1-8 0v14c3-1 6-1 8 0Z';
  static const bot = 'M9 3v2 M15 3v2 M9 19v2 M15 19v2 M3 9h2 M3 15h2 M19 9h2 M19 15h2 M6 6h12v12H6Z M9 9h6v6H9Z';
  static const catalog = 'M20 7 12 3 4 7l8 4 8-4Z M4 7v10l8 4 8-4V7 M12 11v10';
  /// A bare tick, for a completed step in a stepper or a done row.
  ///
  /// Added alongside [checkSquare] rather than reusing it: the boxed
  /// version reads as a checkbox the user could toggle, which is wrong
  /// for a state they cannot change.
  static const check = 'M20 6 9 17l-5-5';

  static const checkSquare = 'M9 12l2 2 4-4 M4 4h16v16H4Z';
  static const chevronDown = 'M6 9l6 6 6-6';
  // Added for customers_page.dart's list->detail navigation (Gate 3) —
  // same construction as chevronDown, rotated 90°.
  static const chevronRight = 'M9 6l6 6-6 6';
  static const chevronLeft = 'M15 6l-6 6 6 6';

  /// Dismiss. Added because modals were closing on a literal '×'
  /// character, which does not inherit the icon set's stroke weight and
  /// sits off-centre against real icons beside it.
  static const close = 'M18 6 6 18 M6 6l12 12';

  /// Add. Same reason as [close] — '+' as text is a different weight and
  /// baseline from every icon next to it.
  static const plus = 'M12 5v14 M5 12h14';
  static const diamond = 'M12 2 22 12 12 22 2 12Z';
  static const eye = 'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z';
  // Kola Till.dc.html's product-tile placeholder — a product with no
  // photo yet gets this rather than a blank tile.
  // Added for invoices_page.dart (Phase 14a-4) — a document with a
  // ruled total line, told apart from [printer] (the action of
  // printing) and [book] (Knowledge's stacked-pages mark).
  static const invoice =
      'M7 3h10v18l-3-2-2 2-2-2-3 2Z M9 8h6 M9 12h6 M9 16h3';
  static const imagePlaceholder =
      'M4 16l4.5-4.5a2 2 0 0 1 2.8 0L16 16 M14 14l1.5-1.5a2 2 0 0 1 2.8 0L21 16 M4 4h16v16H4Z';
  static const headset ='M4 13v-1a8 8 0 1 1 16 0v1 M3 13h2v6H4a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1Z M21 13h-2v6h1a1 1 0 0 0 1-1v-4a1 1 0 0 0-1-1Z';
  static const home = 'M3 21h18 M5 21V7l7-4 7 4v14 M9 21v-6h6v6';
  static const list = 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01';

  /// NOTE — identical to [switchWorkspace] in the design export.
  ///
  /// Kept faithful rather than substituted, but it is worth knowing:
  /// these two sit adjacent in the profile menu, and one of them ends
  /// the session. They are told apart only by their label and by log
  /// out being rendered in the danger colour. If that ever proves not
  /// to be enough, this is the value to change — not the layout.
  static const logOut =
      'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4 M16 17l5-5-5-5 M21 12H9';
  static const mic = 'M12 15a3 3 0 0 0 3-3V6a3 3 0 0 0-6 0v6a3 3 0 0 0 3 3Z M19 12a7 7 0 0 1-14 0 M12 19v3';
  static const more = 'M5 12h.01M12 12h.01M19 12h.01';
  static const paperclip = 'M21 11l-8.5 8.5a5 5 0 0 1-7-7L14 4a3.5 3.5 0 0 1 5 5l-8.5 8.5a2 2 0 0 1-3-3L16 6';
  static const plug = 'M9 2v6 M15 2v6 M6 8h12v4a6 6 0 0 1-12 0Z M12 18v4';
  static const salesCounter = 'M2 8h20 M2 6h20a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H2a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1Z M6 15h4';
  static const search = 'M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14Z M21 21l-4.3-4.3';
  static const settings = 'M10.3 3.2a1.6 1.6 0 0 1 3.4 0l.3 1.2a1.6 1.6 0 0 0 1.1 1.1l1.2.3a1.6 1.6 0 0 1 0 3.4l-1.2.3a1.6 1.6 0 0 0-1.1 1.1l-.3 1.2a1.6 1.6 0 0 1-3.4 0l-.3-1.2a1.6 1.6 0 0 0-1.1-1.1l-1.2-.3a1.6 1.6 0 0 1 0-3.4l1.2-.3a1.6 1.6 0 0 0 1.1-1.1Z M12 12a3 3 0 1 0 0 6 3 3 0 0 0 0-6Z';
  static const sparkles = 'M12 3l1.5 4.5L18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5L12 3Z M19 15l.75 2.25L22 18l-2.25.75L19 21l-.75-2.25L16 18l2.25-.75L19 15Z';
  static const switchWorkspace = 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4 M16 17l5-5-5-5 M21 12H9';
  static const terminal = 'M4 5h16v14H4Z M8 9l3 3-3 3 M13 15h4';
  static const user = 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z M4 21c0-4 4-6 8-6s8 2 8 6';
  static const whatsapp = 'M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5Z';
  static const workflow = 'M6 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z M18 22a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z M6 8v4a4 4 0 0 0 4 4h4';
  static const workspaceSetup = 'M3 21h18 M5 21V7l7-4 7 4v14 M9 21v-6h6v6';
}
