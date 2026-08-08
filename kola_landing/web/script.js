// script.js — tiny DOM helpers Dart calls via dart:js_interop.
//
// WHY UNCONTROLLED INPUTS: rather than wiring every keystroke through
// Jaspr state (onInput/onChange), form fields here are plain HTML inputs
// read directly from the DOM only at submit time — the exact same
// technique already proven in kopicat_landing's script.js/main.dart for
// its email signup field. Reused, not reinvented, and it sidesteps
// needing every input's live value mirrored in Dart state for forms that
// are otherwise stateless until submit.
//
// Must load before main.dart.js (see index.html's script order) so these
// functions exist on `window` before Dart's compiled bundle runs.

function kolaFieldValue(id) {
  var el = document.getElementById(id);
  return el ? el.value : '';
}

function kolaSetFieldValue(id, val) {
  var el = document.getElementById(id);
  if (el) el.value = val;
}

function kolaScrollToId(id) {
  var el = document.getElementById(id);
  if (el) {
    window.scrollTo({ top: el.getBoundingClientRect().top + window.scrollY - 24, behavior: 'smooth' });
  }
}

// Scroll-triggered reveal animation — same proven IntersectionObserver
// technique already used in kopicat_landing/web/script.js's
// _initScrollReveal, with one deliberate change: this file does NOT add
// the ".kola-reveal-in" class itself anymore. It used to, but that class
// lived only in the DOM, invisible to Jaspr's own render state — any
// unrelated Dart setState() (closing the banner, toggling the FAQ,
// literally any button) re-rendered these elements' class attribute from
// Dart's side and silently wiped the class this file had added,
// snapping already-revealed sections back to hidden. See interop.dart's
// header comment for the full story.
//
// Fix: this file only *reports* that a section became visible, via
// window.kolaOnReveal(id) — Dart (interop.dart's registerRevealCallback,
// wired up in app.dart) is what actually decides to add the class, as
// part of its own state, so nothing external can clobber it on the next
// rebuild.
function kolaInitScrollReveal() {
  var items = document.querySelectorAll('.kola-reveal');

  function reveal(el) {
    if (el.id && typeof window.kolaOnReveal === 'function') {
      window.kolaOnReveal(el.id);
    }
  }

  if (!('IntersectionObserver' in window)) {
    items.forEach(reveal);
    return;
  }
  var io = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          reveal(entry.target);
          io.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15 }
  );
  items.forEach(function (el) { io.observe(el); });
}

/* ── i18n helpers ─────────────────────────────────────────────────────
 * Two small bridges for lib/i18n. Kept here rather than done from Dart
 * because both touch browser APIs that are simpler to read directly than
 * to bind, and neither is worth a package dependency.
 */

/** The visitor's ordered language preferences, e.g. ['fr-CI','fr','en'].
 *  Falls back through navigator.language, then an empty list — which
 *  Dart reads as "no preference" and resolves to English. */
window.kolaBrowserLanguages = function () {
  try {
    if (navigator.languages && navigator.languages.length) {
      return Array.prototype.slice.call(navigator.languages);
    }
    if (navigator.language) return [navigator.language];
  } catch (e) { /* ignore */ }
  return [];
};

/** Sets <html lang> and <html dir>. `dir` is what makes a right-to-left
 *  language lay out correctly; setting it from day one means adding one
 *  later is a language pack rather than a rewrite. */
window.kolaSetHtmlLang = function (lang, dir) {
  try {
    var html = document.documentElement;
    if (lang) html.setAttribute('lang', lang);
    if (dir) html.setAttribute('dir', dir);
  } catch (e) { /* ignore */ }
};
