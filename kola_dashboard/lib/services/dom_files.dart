// dom_files.dart — reading files off an <input type="file"> safely.
//
// ── THIS EXISTS BECAUSE THE DYNAMIC VERSION DOES NOT RUN ─────────────
//
// Every file picker in this app reads its files like this:
//
//     final list = (e.target as dynamic).files;
//     list.item(i) as web.File
//
// It analyses clean. It does not work. `dart:js_interop` extension types
// are ERASED at compile time, so a `dynamic` member access looks for a
// Dart member named `files` on a plain JS object, finds nothing, and
// throws NoSuchMethodError.
//
// This is not a theory. The identical pattern in main.dart —
// `(root as dynamic).style.setProperty(...)` — analysed clean, threw at
// runtime, and left the entire app as a blank page. The same pattern in
// ask_kola.dart silently breaks the composer's auto-grow.
//
// The difference between those two is only WHERE the throw lands. In
// main.dart it ran before runApp, so it killed everything and was
// obvious. Inside a `change` handler the exception is swallowed by the
// event loop — the picker opens, the owner chooses a file, and nothing
// happens at all. No error, no progress, no upload.
//
// Which is exactly the reported behaviour of Knowledge upload.
//
// ── WHY DECLARED TYPES AND NOT package:web ───────────────────────────
//
// package:web would probably work here: `files` is not an overloaded
// name, so its generated binding is likely just `files`. "Likely" is the
// problem — the cast to HTMLInputElement is the part this codebase has
// got wrong before, and there is no way to check it without compiling.
//
// The names below are the DOM's own, from the File API spec. They are
// stable, identical in every browser, and if one were wrong it would
// fail immediately and visibly rather than in a corner.

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

extension type _FileList._(JSObject _) implements JSObject {
  external int get length;
  external JSObject? item(int index);
}

extension type _FileInput._(JSObject _) implements JSObject {
  external _FileList? get files;

  /// Clearing this is what makes re-picking the SAME file fire `change`
  /// again. Without it, an owner whose first upload failed can choose
  /// the identical file and get no response at all, because the input's
  /// value has not changed.
  external set value(String v);
}

/// The files a `change` event's input is holding.
///
/// Returns `web.File`, NOT a bespoke type. FileIntake already takes
/// web.File and reads it with typed package:web calls (FileReader,
/// .name, .size, .type) — those work fine. Only the EXTRACTION was
/// broken, so this replaces exactly that and leaves everything
/// downstream untouched.
///
/// The cast is between extension types over the same JSObject
/// representation, which is a compile-time reinterpretation rather than
/// a checked conversion — there is no runtime coercion here that could
/// fail on a real File.
///
/// Returns an empty list rather than null when nothing was chosen, so
/// callers never branch on two kinds of nothing.
List<web.File> filesFrom(JSObject target) {
  final input = target as _FileInput;
  final list = input.files;
  if (list == null) return const [];

  return [
    for (var i = 0; i < list.length; i++)
      if (list.item(i) case final file?) file as web.File,
  ];
}

/// A textarea's current value.
///
/// `(e.target as dynamic).value` is the same erased-extension-type trap
/// as `.files` — it analyses clean and throws. create_bot_page.dart's
/// header already documents that the events-map form of this did not
/// bind; this is the safe way to read it when a typed onInput is not
/// available.
String valueOf(JSObject target) => (target as _TextArea).value;

/// Grows a textarea to fit its content, up to whatever max-height CSS
/// imposes.
///
/// Resets to `auto` first, or the box can only ever get taller and never
/// shorter when text is deleted.
void autoGrow(JSObject target) {
  final el = target as _TextArea;
  el.style.height = 'auto';
  el.style.height = '${el.scrollHeight}px';
}

extension type _TextArea._(JSObject _) implements JSObject {
  external String get value;
  external int get scrollHeight;
  external _InlineStyle get style;
}

extension type _InlineStyle._(JSObject _) implements JSObject {
  external set height(String v);
}

/// Resets the input so choosing the same file again re-fires `change`.
///
/// Call after handling a pick. See the note on `value` above — without
/// this, retrying a failed upload with the same file appears to do
/// nothing, which reads as the product being broken twice over.
void resetFileInput(JSObject target) {
  (target as _FileInput).value = '';
}

// ── DOWNLOADING A FILE THE APP GENERATED ─────────────────────────────
//
// Same discipline as the rest of this file, and for the same reason:
// `web.document.createElement('a') as web.HTMLAnchorElement` is a cast
// across an extension type, which is the exact shape this file exists to
// avoid guessing at. `href`, `download` and `click` are the DOM's own
// names from the HTML spec — stable, unambiguous, and wrong loudly
// rather than quietly if they were not.

extension type _Anchor._(JSObject _) implements JSObject {
  external set href(String v);

  /// The attribute that makes the browser SAVE the target instead of
  /// navigating to it, and supplies the filename. Without it a data:
  /// URL opens the CSV as a page of text.
  external set download(String v);

  external void click();
}

/// Saves [content] to the visitor's downloads as [fileName].
///
/// The anchor is never added to the document. A detached element still
/// dispatches a click, and appending would mean removing it afterwards —
/// a cleanup step that leaves stray nodes behind the first time someone
/// forgets it.
void downloadText(
  String content, {
  required String fileName,
  String mimeType = 'text/csv',
}) {
  // A BOM, deliberately. Without it Excel on Windows reads the file as
  // the system codepage and any ₦ an owner types into a filled-in
  // template comes back as mojibake. Sheets and LibreOffice ignore it.
  final bytes = utf8.encode('\u{FEFF}$content');
  final url = 'data:$mimeType;charset=utf-8;base64,${base64Encode(bytes)}';

  final anchor = web.document.createElement('a') as _Anchor;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
}
