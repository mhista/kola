// camera_scanner.dart — real camera barcode scanning via the browser's
// native Shape Detection API (`BarcodeDetector`), with hand-written JS
// interop rather than trusting package:web's generated bindings for it.
//
// WHY HAND-WRITTEN, NOT package:web — same reasoning as dom_files.dart's
// own header, which this file follows on purpose: `BarcodeDetector` is
// an experimental API (Chrome/Edge/Android WebView only — no Safari, no
// Firefox, as of this writing) that may or may not have a generated
// binding in whatever package:web version this project has pinned, and
// there is no compiler in the environment that wrote this file to check.
// The names below are the Shape Detection API spec's own — stable
// regardless of package:web's coverage of an experimental API.
//
// getUserMedia / MediaStream / <video> itself, by contrast, ARE trusted
// through package:web below — those are old, universally-implemented
// APIs with no reason to expect a missing or wrong binding.
//
// ── NOT VERIFIED ──────────────────────────────────────────────────────
// No browser, no camera, no Dart toolchain in the environment that wrote
// this file. Reasoned from the W3C Shape Detection API spec
// (https://wicg.github.io/shape-detection-api/) and MDN's documented
// getUserMedia/BarcodeDetector usage, not run. Flagged per this
// codebase's own rule (see every GATE_*_STATUS.md's "what was not
// verified" section) rather than asserted as working. Manual test steps
// are in this feature's status note.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// True if this browser exposes `window.BarcodeDetector` at all. Callers
/// MUST check this before doing anything else here — on an unsupported
/// browser (Safari, Firefox, as of today) the till falls back to its
/// existing manual SKU-entry field, which this file never touches.
bool get barcodeDetectorSupported {
  try {
    return globalContext.has('BarcodeDetector');
  } catch (_) {
    return false;
  }
}

@JS('BarcodeDetector')
extension type _BarcodeDetectorJS._(JSObject _) implements JSObject {
  external factory _BarcodeDetectorJS([JSAny? options]);
  external JSPromise<JSArray<JSObject>> detect(JSObject source);
}

extension type _DetectedBarcodeJS._(JSObject _) implements JSObject {
  external String get rawValue;
}

/// The common 1D/2D formats a shop's own printed labels or a supplier's
/// packaging are realistically in. Passed explicitly rather than
/// omitted — the spec leaves the "no formats given" default up to the
/// browser, and being explicit is the only way to know what this
/// actually scans for.
JSObject _detectorOptions() {
  const formats = [
    'code_128',
    'code_39',
    'code_93',
    'codabar',
    'ean_13',
    'ean_8',
    'itf',
    'upc_a',
    'upc_e',
    'qr_code',
  ];
  final options = JSObject();
  options.setProperty(
    'formats'.toJS,
    formats.map((f) => f.toJS).toList().toJS,
  );
  return options;
}

/// Drives one scanning session: opens the camera, polls for a barcode,
/// and tears down cleanly. Callers create a fresh instance each time the
/// scanner modal opens and dispose it on close — this class holds live
/// hardware state (the camera stream), so it is not meant to be reused.
class CameraScanner {
  web.MediaStream? _stream;
  _BarcodeDetectorJS? _detector;
  bool _stopped = false;

  /// Starts the camera and attaches it to [video]. Returns true only if
  /// the camera actually started (permission granted, a camera exists,
  /// this page is on a secure origin — getUserMedia refuses plain HTTP).
  /// Every failure mode comes back as `false` rather than a thrown
  /// exception, so the caller can fall back to manual entry with a
  /// single `if`, not a try/catch of its own.
  Future<bool> start(web.HTMLVideoElement video) async {
    if (!barcodeDetectorSupported) return false;
    try {
      final videoConstraints = JSObject();
      videoConstraints.setProperty('facingMode'.toJS, 'environment'.toJS);
      final constraints = web.MediaStreamConstraints(video: videoConstraints);

      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;

      if (_stopped) {
        // The modal was closed while the permission prompt was still
        // pending — stop immediately rather than leaving the camera
        // light on with nothing showing it.
        for (final track in stream.getTracks().toDart) {
          track.stop();
        }
        return false;
      }

      _stream = stream;
      video.srcObject = stream;
      video.autoplay = true;
      video.muted = true;
      // Stops iOS Safari from forcing fullscreen playback. Moot today
      // while BarcodeDetector itself is Safari-unsupported, but correct
      // to set regardless, and free — Safari support could land later.
      video.setAttribute('playsinline', 'true');
      await video.play().toDart;

      _detector = _BarcodeDetectorJS(_detectorOptions());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Detects once against the current video frame. Returns the first
  /// barcode's raw text, or null if none is visible right now — callers
  /// poll this on a timer and treat null as "keep looking," not failure.
  Future<String?> detectOnce(web.HTMLVideoElement video) async {
    final detector = _detector;
    if (detector == null || _stopped) return null;
    try {
      final results = await detector.detect(video).toDart;
      final list = results.toDart;
      if (list.isEmpty) return null;
      return (list.first as _DetectedBarcodeJS).rawValue;
    } catch (_) {
      return null;
    }
  }

  /// Stops every camera track. Idempotent and safe to call even if
  /// `start()` never got a stream (denied permission, or closed before
  /// the permission prompt resolved) — always call this on modal close
  /// or component dispose, unconditionally.
  void stop() {
    _stopped = true;
    final stream = _stream;
    if (stream != null) {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
      _stream = null;
    }
    _detector = null;
  }
}
