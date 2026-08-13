// main.dart — entry point. Kept to exactly this per the working
// convention (see kola_landing/lib/main.dart) that pages/components
// live in their own files; all real content lives in app.dart and
// lib/components/.
//
// The one exception is the appearance restore below, and it is here
// rather than in a component on purpose — see _restoreAppearance.

import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import 'app.dart';
import 'services/local_storage.dart';
import 'theme.dart';

void main() {
  // WRAPPED, AND THAT IS NOT DEFENSIVE PROGRAMMING FOR ITS OWN SAKE.
  //
  // Anything that runs before runApp can take the whole app down: if it
  // throws, runApp is never reached and the browser shows an empty
  // document with no error anyone but a developer would find. That is
  // exactly what happened — see _restoreAppearance's own note — and the
  // failure was PERSISTENT, because the thing that triggered it was a
  // stored preference that got re-read on every single load. The owner
  // had no way back in.
  //
  // A preference failing to restore is worth a default. It is never
  // worth a dead app.
  try {
    _restoreAppearance();
  } catch (_) {
    // Deliberately swallowed. The app boots on its defaults.
  }
  runApp(const DashboardApp());
}

/// Re-applies the theme and body font the owner chose in Settings.
///
/// ── WHY BEFORE runApp, AND NOT IN A COMPONENT ────────────────────────
///
/// Both are attributes on the root <html> element, so they take effect
/// the moment they are set — before any component mounts. Restoring them
/// from a component's initState would mean the first frame paints with
/// the default dark theme and the default face, and someone who chose
/// light gets a dark flash on every single page load. Doing it here
/// costs one synchronous LocalStorage read and removes that entirely.
///
/// Deliberately silent on failure. A stored value that no longer maps to
/// anything, or storage being unavailable, should leave the app on its
/// defaults rather than stop it booting — nobody should be locked out of
/// their dashboard by a font preference.
void _restoreAppearance() {
  final root = web.document.documentElement;
  if (root == null) return;

  final theme = LocalStorage.getItem('kola_theme');
  // 'system' and null are the same instruction: remove the attribute and
  // let the prefers-color-scheme rule in styles.css decide. See
  // KolaTheme.followSystem.
  if (theme == KolaTheme.light || theme == KolaTheme.dark) {
    root.setAttribute(KolaTheme.attribute, theme!);
  }

  final font = LocalStorage.getItem('kola_font');
  if (font != null) {
    final family = switch (font) {
      'Inter' => "'Inter', sans-serif",
      'System default' => 'system-ui, sans-serif',
      'Plus Jakarta Sans' => "'Plus Jakarta Sans', sans-serif",
      _ => null,
    };
    if (family != null) {
      // ── THIS LINE IS WHY LOGGING OUT SHOWED A BLANK PAGE ────────────
      //
      // It used to be `(root as dynamic).style.setProperty(...)`. That
      // ANALYSED CLEAN and threw at runtime. package:web models DOM
      // types as extension types over JS objects, and they are erased
      // when compiled — so a `dynamic` member access looks for a Dart
      // member named `style` on a plain JS object, finds nothing, and
      // throws. dart analyze cannot see it because `dynamic` is
      // unanalysable by definition.
      //
      // I chose `as dynamic` over `as web.HTMLElement` on the grounds
      // that ask_kola.dart already did it and "demonstrably compiles".
      // Compiling is not running. That file does the same thing inside
      // an input handler, where the throw is swallowed by the event
      // loop and looks like nothing at all; here it ran before runApp,
      // where the same throw kills the entire app.
      //
      // setAttribute is on Element, needs no cast, and is the exact
      // method used two lines above for data-theme — so its behaviour
      // here is established by the line that already works. Clobbering
      // the style attribute is safe: index.html sets none on <html>,
      // and this and Settings are its only writers.
      root.setAttribute('style', '--kola-font-sans: $family');
    }
  }
}
