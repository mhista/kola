// interop.dart
//
// JS interop bindings for web/script.js's DOM helpers. Centralized here
// rather than scattered per-component so there's exactly one place that
// knows these functions exist on `window` — mirrors the interop section
// at the top of kopicat_landing/lib/main.dart.
//
// WHY registerRevealCallback EXISTS (fixed a real bug — read before
// touching the scroll-reveal wiring):
//   The scroll-reveal animation used to work by having script.js's
//   IntersectionObserver call `element.classList.add('kola-reveal-in')`
//   directly — a plain DOM mutation Jaspr's own render tree knows
//   nothing about. That's broken: _LandingAppState.build() returns the
//   whole page fresh on every setState() (closing the banner, toggling
//   the FAQ, the pricing monthly/yearly switch, submitting any form —
//   literally any button), and when Jaspr re-renders a `.kola-reveal`
//   element it writes its `classes` attribute from Dart's own (static)
//   value, which never included '-in'. That silently wiped the
//   externally-added class on every unrelated click, snapping already
//   -revealed sections back to their hidden state — exactly the "click
//   any button and some sections disappear" bug.
//
//   The fix: the "is this section revealed" fact now lives in Dart state
//   (_LandingAppState._revealed, see app.dart), so Dart's own render
//   always includes the right class and there's nothing left for an
//   unrelated rebuild to clobber. script.js's observer only reports
//   *that* a section became visible; registerRevealCallback is how it
//   reports that back into Dart, using Function.toJS — the documented
//   "export a Dart function to JS" pattern (dart.dev/interop/js-interop/
//   usage#export), not a class-mutation workaround.

import 'dart:js_interop';

@JS('kolaFieldValue')
external JSString _fieldValue(String id);

@JS('kolaSetFieldValue')
external void _setFieldValue(String id, JSString value);

@JS('kolaScrollToId')
external void _scrollToId(String id);

@JS('kolaInitScrollReveal')
external void _initScrollReveal();

@JS('kolaOnReveal')
external set _kolaOnReveal(JSFunction value);

@JS('kolaBrowserLanguages')
external JSArray<JSString> _browserLanguages();

@JS('kolaSetHtmlLang')
external void _setHtmlLang(JSString lang, JSString dir);

/// Reads the current `.value` of the DOM element with [id]. Used at
/// submit time for uncontrolled form fields — see script.js's header
/// comment for why fields aren't mirrored into Dart state live.
String fieldValue(String id) {
  try {
    return _fieldValue(id).toDart;
  } catch (_) {
    return '';
  }
}

/// Clears (or sets) a field's value directly in the DOM — used to reset
/// a form after a successful submit without needing controlled-input
/// state.
void setFieldValue(String id, String value) {
  try {
    _setFieldValue(id, value.toJS);
  } catch (_) {}
}

/// Smooth-scrolls to the element with [id] — used by "Join waitlist"
/// pricing-card buttons and quick-pill chips to jump to the waitlist form.
void scrollToId(String id) {
  try {
    _scrollToId(id);
  } catch (_) {}
}

/// Starts (or re-scans for) the scroll-triggered reveal animation on every
/// `.kola-reveal` element currently in the DOM. Safe to call repeatedly —
/// see script.js's kolaInitScrollReveal for why. Call once after first
/// paint. Call registerRevealCallback BEFORE this, not after — the
/// observer may fire for an already-in-view section immediately on
/// `.observe()`, before this function even returns.
void initScrollReveal() {
  try {
    _initScrollReveal();
  } catch (_) {}
}

/// Registers [onReveal] as the target of script.js's IntersectionObserver
/// callback — called with a section's DOM `id` the first time it scrolls
/// into view. See this file's header comment for why this exists instead
/// of letting JS mutate a class directly. The caller (app.dart) is
/// expected to setState() inside [onReveal] so the newly-revealed id
/// actually makes it into the next render.
void registerRevealCallback(void Function(String id) onReveal) {
  try {
    _kolaOnReveal = ((JSString id) => onReveal(id.toDart)).toJS;
  } catch (_) {}
}


/// The visitor's language preferences, most-preferred first — the
/// `navigator.languages` list, e.g. ['fr-CI', 'fr', 'en'].
///
/// Returns an empty list when the browser does not expose it, which
/// callers treat as "no preference" and fall back to English. Never
/// throws: a language lookup must not be able to break page render.
List<String> browserLanguages() {
  try {
    return _browserLanguages().toDart.map((s) => s.toDart).toList();
  } catch (_) {
    return const [];
  }
}

/// Sets `<html lang>` and `<html dir>`.
///
/// BOTH matter, and not only for correctness: `lang` is what a screen
/// reader uses to choose a voice, and what a browser uses to offer
/// translation. `dir` is the single attribute that makes a right-to-left
/// language lay out correctly — setting it here means adding an RTL
/// language later is a language pack, not a rewrite. See
/// i18n/locale.dart on why RTL support exists before any RTL language
/// does.
void setHtmlLang(String lang, String dir) {
  try {
    _setHtmlLang(lang.toJS, dir.toJS);
  } catch (_) {
    // Cosmetic and assistive — never worth failing a render over.
  }
}
