// file_intake.dart — deciding what an uploaded file IS, and getting text
// out of it when that is possible in the browser.
//
// ── WHY IDENTIFYING THE FILE MATTERS MORE THAN ACCEPTING IT ──────────
//
// A business will upload anything: a price list as .xlsx, a policy as
// .docx, a supplier invoice as a photo, a catalogue as a 40-page PDF.
// Accepting all of them and failing silently on most is worse than
// accepting none, because the owner believes kolaa has been taught
// something it cannot read.
//
// So every file gets CLASSIFIED first, and the classification decides
// what happens and — critically — what the owner is told.
//
// ── EXTENSION ALONE IS NOT ENOUGH ────────────────────────────────────
//
// A file named notes.txt can be anything, and a file with no extension
// is common on phones. So classification uses three signals in order of
// trustworthiness:
//
//   1. MAGIC BYTES — the first few bytes of the actual content. A ZIP
//      always starts PK\x03\x04, a PDF always %PDF. This cannot be
//      faked by renaming, which is why it goes first.
//   2. MIME TYPE reported by the browser.
//   3. FILE EXTENSION, last, because it is the easiest to be wrong.
//
// The magic-byte check also catches the case that matters most here:
// .docx and .xlsx ARE zip archives. Anything that identifies them by
// extension alone will happily hand a zip binary to a text parser and
// store mojibake as business knowledge.
//
// ── WHAT THIS CAN AND CANNOT DO TODAY ────────────────────────────────
//
// Text-family files are read here, in the browser, and sent as text.
// Everything else needs SERVER-SIDE EXTRACTION that does not exist yet
// (PDF text layers, docx/xlsx unzip + XML parse, OCR for images,
// transcription for audio). Those are classified, refused, and the
// owner is told exactly why and what to do instead — never accepted and
// quietly mangled.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// What a file is, in terms of what kolaa can do with it.
enum FileKind {
  /// Readable as text right now, in the browser.
  text,

  /// Real document formats that need server-side extraction.
  document,

  /// Tabular. Extraction is different from prose — a spreadsheet needs
  /// its structure preserved, not flattened into a paragraph.
  spreadsheet,

  /// Needs OCR or a vision model.
  image,

  /// Needs transcription.
  media,

  /// Archives. Never ingested directly — they contain other files, and
  /// the right behaviour is to ask the owner to extract them.
  archive,

  /// Identified as something we know is not knowledge (executables etc).
  rejected,

  /// Genuinely unrecognised.
  unknown,
}

class FileAssessment {
  const FileAssessment({
    required this.name,
    required this.sizeBytes,
    required this.kind,
    required this.label,
    required this.canIngestNow,
    required this.explanation,
  });

  final String name;
  final int sizeBytes;
  final FileKind kind;

  /// Human name for the format — "Word document", "Spreadsheet".
  final String label;

  /// Whether text can be obtained from it in the browser today.
  final bool canIngestNow;

  /// What to tell the owner. Written for a shop owner, not a developer,
  /// and it always says what to do next rather than only what failed.
  final String explanation;
}

abstract class FileIntake {
  /// Beyond this, reading the file in the browser will stall the tab and
  /// the resulting document would blow past any sane chunking budget
  /// anyway. Matches PlanLimits.maxDocumentCharacters' intent.
  static const maxBytes = 2 * 1024 * 1024; // 2 MB of text

  /// Magic-byte signatures, checked against the first bytes of content.
  ///
  /// Ordered longest-first so a more specific signature wins over a
  /// prefix of it.
  static const _magic = <String, List<int>>{
    'pdf': [0x25, 0x50, 0x44, 0x46], // %PDF
    'zip': [0x50, 0x4B, 0x03, 0x04], // PK.. — also docx/xlsx/pptx
    'zip_empty': [0x50, 0x4B, 0x05, 0x06],
    'png': [0x89, 0x50, 0x4E, 0x47],
    'jpg': [0xFF, 0xD8, 0xFF],
    'gif': [0x47, 0x49, 0x46, 0x38],
    'rtf': [0x7B, 0x5C, 0x72, 0x74], // {\rt
    'ole': [0xD0, 0xCF, 0x11, 0xE0], // legacy .doc/.xls
    'exe': [0x4D, 0x5A], // MZ
    'elf': [0x7F, 0x45, 0x4C, 0x46],
  };

  static const _textExts = {
    'txt', 'md', 'markdown', 'csv', 'tsv', 'json', 'yaml', 'yml',
    'log', 'text', 'rtfd', 'htm', 'html', 'xml',
  };
  static const _docExts = {'pdf', 'doc', 'docx', 'odt', 'pages', 'rtf'};
  static const _sheetExts = {'xls', 'xlsx', 'ods', 'numbers'};
  static const _imageExts = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'bmp', 'tif', 'tiff'};
  static const _mediaExts = {'mp3', 'm4a', 'wav', 'ogg', 'mp4', 'mov', 'avi', 'webm'};
  static const _archiveExts = {'zip', 'rar', '7z', 'tar', 'gz'};
  static const _rejectExts = {'exe', 'dll', 'so', 'bin', 'app', 'msi', 'dmg', 'apk'};

  /// Classifies [file], reading its first bytes for a magic-number check.
  static Future<FileAssessment> assess(web.File file) async {
    final name = file.name;
    final size = file.size;
    final ext = _extension(name);
    final mime = file.type.toLowerCase();

    if (size > maxBytes) {
      return FileAssessment(
        name: name,
        sizeBytes: size,
        kind: FileKind.rejected,
        label: 'Too large',
        canIngestNow: false,
        explanation:
            'That file is ${_mb(size)} — the limit is ${_mb(maxBytes)}. '
            'Split it into sections and add them separately; kolaa answers '
            'more accurately from several focused documents than one huge '
            'one anyway.',
      );
    }

    final magic = await _readMagic(file);
    final sig = _matchMagic(magic);

    // Magic bytes first — they cannot be faked by renaming.
    if (sig == 'pdf') return _doc(name, size, 'PDF');
    if (sig == 'ole') return _doc(name, size, 'Word or Excel document');
    if (sig == 'exe' || sig == 'elf') {
      return FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.rejected,
        label: 'Program file', canIngestNow: false,
        explanation: 'That is a program, not a document. Nothing in it is '
            'business knowledge, so kolaa will not store it.',
      );
    }
    if (sig == 'png' || sig == 'jpg' || sig == 'gif') {
      return _image(name, size);
    }
    if (sig == 'zip' || sig == 'zip_empty') {
      // .docx / .xlsx / .pptx are zips. Extension disambiguates WHICH,
      // but the zip signature is what proves it is not readable text.
      if (_sheetExts.contains(ext)) return _sheet(name, size);
      if (_docExts.contains(ext) || ext == 'pptx') {
        return _doc(name, size, 'Word document');
      }
      return FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.archive,
        label: 'Archive', canIngestNow: false,
        explanation: 'That is a compressed folder. Unzip it and add the '
            'documents inside individually — kolaa needs to know what each '
            'one is to cite it properly.',
      );
    }

    // No decisive signature. Fall back to MIME, then extension.
    if (mime.startsWith('text/') ||
        mime == 'application/json' ||
        mime == 'application/xml' ||
        _textExts.contains(ext)) {
      return FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.text,
        label: _textLabel(ext), canIngestNow: true,
        explanation: 'Readable as text.',
      );
    }
    if (mime.startsWith('image/') || _imageExts.contains(ext)) {
      return _image(name, size);
    }
    if (mime.startsWith('audio/') || mime.startsWith('video/') ||
        _mediaExts.contains(ext)) {
      return FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.media,
        label: 'Audio or video', canIngestNow: false,
        explanation: 'kolaa cannot listen to files yet. If there is a '
            'transcript, paste that instead.',
      );
    }
    if (_sheetExts.contains(ext)) return _sheet(name, size);
    if (_docExts.contains(ext)) return _doc(name, size, 'Document');
    if (_archiveExts.contains(ext)) {
      return FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.archive,
        label: 'Archive', canIngestNow: false,
        explanation: 'Unzip it and add the documents inside individually.',
      );
    }
    if (_rejectExts.contains(ext)) {
      return FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.rejected,
        label: 'Program file', canIngestNow: false,
        explanation: 'That is a program, not a document.',
      );
    }

    // Unknown, but it might still be text. Probe the bytes we already
    // read: if they are all printable, treat it as text rather than
    // refusing a perfectly readable file for lacking an extension —
    // which is the normal case for files shared from a phone.
    if (magic.isNotEmpty && _looksTextual(magic)) {
      return FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.text,
        label: 'Text', canIngestNow: true,
        explanation: 'No file type given, but the contents read as text.',
      );
    }

    return FileAssessment(
      name: name, sizeBytes: size, kind: FileKind.unknown,
      label: 'Unrecognised', canIngestNow: false,
      explanation: 'kolaa could not tell what kind of file that is, so it '
          'will not guess. If you can open it and copy the text, paste it '
          'instead.',
    );
  }

  /// Reads a text file's contents.
  ///
  /// Only call when [FileAssessment.canIngestNow] is true — on anything
  /// else this returns bytes reinterpreted as characters, which is how
  /// binary garbage ends up stored as business knowledge.
  /// The file as base64, for anything that is not plain text.
  ///
  /// ── readAsDataURL, NOT readAsArrayBuffer ───────────────────────────
  ///
  /// An ArrayBuffer would mean converting a JS typed array into Dart
  /// bytes and then re-encoding — two interop hops, and interop is
  /// exactly where this codebase has been bitten. readAsDataURL returns
  /// a STRING the browser has already base64-encoded:
  ///
  ///   data:application/vnd...sheet;base64,UEsDBBQAB...
  ///
  /// Stripping everything up to the comma leaves precisely what the
  /// server wants, using the same FileReader shape readText already
  /// uses and no new API at all.
  static Future<String> readBase64(web.File file) {
    final completer = Completer<String>();
    final reader = web.FileReader();

    reader.onload = (web.Event _) {
      final result = reader.result;
      if (result == null) {
        completer.complete('');
        return;
      }
      final url = (result as JSString).toDart;
      final comma = url.indexOf(',');
      // No comma means it is not a data URL, which should be impossible
      // after readAsDataURL — treated as empty rather than sending the
      // header along as if it were file content.
      completer.complete(comma < 0 ? '' : url.substring(comma + 1));
    }.toJS;

    reader.onerror = (web.Event _) {
      completer.completeError(
        StateError('That file could not be read. It may be in use by '
            'another program, or the browser was denied access.'),
      );
    }.toJS;

    reader.readAsDataURL(file);
    return completer.future;
  }

  static Future<String> readText(web.File file) {
    final completer = Completer<String>();
    final reader = web.FileReader();

    reader.onload = (web.Event _) {
      final result = reader.result;
      completer.complete(result == null ? '' : (result as JSString).toDart);
    }.toJS;

    reader.onerror = (web.Event _) {
      completer.completeError(
        StateError('That file could not be read. It may be in use by '
            'another program, or the browser was denied access.'),
      );
    }.toJS;

    reader.readAsText(file);
    return completer.future;
  }

  // ── internals ──────────────────────────────────────────────────────

  /// First 16 bytes, which is enough for every signature above.
  static Future<List<int>> _readMagic(web.File file) async {
    try {
      final slice = file.slice(0, 16);
      final buffer = await slice.arrayBuffer().toDart;
      final bytes = buffer.toDart.asUint8List();
      return bytes.toList();
    } catch (_) {
      // A browser that refuses the slice should not block the upload —
      // classification falls through to MIME and extension.
      return const [];
    }
  }

  static String? _matchMagic(List<int> bytes) {
    for (final entry in _magic.entries) {
      final sig = entry.value;
      if (bytes.length < sig.length) continue;
      var match = true;
      for (var i = 0; i < sig.length; i++) {
        if (bytes[i] != sig[i]) {
          match = false;
          break;
        }
      }
      if (match) return entry.key;
    }
    return null;
  }

  /// Whether bytes look like text — printable ASCII, common whitespace,
  /// or high bytes (which are almost certainly UTF-8 continuation).
  static bool _looksTextual(List<int> bytes) {
    for (final b in bytes) {
      final printable = b >= 0x20 && b < 0x7F;
      final whitespace = b == 0x09 || b == 0x0A || b == 0x0D;
      final utf8Tail = b >= 0x80;
      if (!printable && !whitespace && !utf8Tail) return false;
    }
    return true;
  }

  static FileAssessment _doc(String name, int size, String label) =>
      FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.document,
        label: label, canIngestNow: false,
        explanation: 'kolaa can see it is a $label, but reading text out of '
            'one is not built yet. Open it, copy the text, and paste it in '
            'above — that works today and gives exactly the same result.',
      );

  /// .xlsx now reads; the older .xls does not.
  ///
  /// The refusal this replaces was right at the time — a spreadsheet
  /// flattened into a wall of words is worse than useless, because the
  /// columns ARE the meaning. XlsxExtractor keeps them: each row becomes
  /// "Selling Price: 4500" lines, which survive chunking as facts.
  ///
  /// .xls is a genuinely different format — the old OLE binary, not a
  /// zip of XML — so it needs a different reader and is still refused,
  /// with the one-step fix named.
  static FileAssessment _sheet(String name, int size) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.xlsx') || lower.endsWith('.xlsm')) {
      return FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.spreadsheet,
        label: 'Spreadsheet', canIngestNow: true,
        explanation: '',
      );
    }
    return FileAssessment(
      name: name, sizeBytes: size, kind: FileKind.spreadsheet,
      label: 'Spreadsheet', canIngestNow: false,
      explanation: lower.endsWith('.xls')
          ? 'That is the older Excel format. Open it and use Save As → '
              'Excel Workbook (.xlsx), then add it again.'
          : 'kolaa cannot read that kind of spreadsheet yet. Saving it as '
              '.xlsx or CSV works today.',
    );
  }

  static FileAssessment _image(String name, int size) => FileAssessment(
        name: name, sizeBytes: size, kind: FileKind.image,
        label: 'Image', canIngestNow: false,
        explanation: 'kolaa cannot read text out of pictures yet. If it is a '
            'photo of a price list, typing the prices in is more accurate '
            'than any scan would be.',
      );

  static String _textLabel(String ext) => switch (ext) {
        'csv' || 'tsv' => 'Table (text)',
        'md' || 'markdown' => 'Markdown',
        'json' || 'yaml' || 'yml' || 'xml' => 'Structured text',
        'htm' || 'html' => 'Web page',
        _ => 'Text file',
      };

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static String _mb(int bytes) {
    final mb = bytes / (1024 * 1024);
    return mb >= 1 ? '${mb.toStringAsFixed(1)} MB' : '${(bytes / 1024).round()} KB';
  }
}
