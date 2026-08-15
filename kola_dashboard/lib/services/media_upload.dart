// media_upload.dart — browser → ImageKit, with real progress.
//
// ── WHY dart:js_interop AND NOT package:web ──────────────────────────
//
// package:web is already a dependency and is used elsewhere here for
// window, localStorage and File. It is NOT used for the upload itself,
// deliberately.
//
// package:web generates its bindings from the WebIDL, and overloaded JS
// methods come out with mangled Dart names — FormData.append(String,
// String) and FormData.append(String, Blob, String) cannot both be
// `append`, so they become something else. What that something else is
// cannot be checked without compiling, and this session has already
// shipped two API guesses that analysed clean and failed: `.style` on an
// Element (threw at runtime and blanked the whole app) and an
// InputType.checkbox with no precedent.
//
// So this file declares the exact browser API it uses. These are not
// guesses about a Dart binding — they are the DOM's own method names,
// which are stable, specified, and the same in every browser. If one
// were wrong it would fail immediately and identically on every upload,
// rather than in a corner nobody exercises.
//
// ── WHY XMLHttpRequest AND NOT fetch ─────────────────────────────────
//
// fetch has no upload progress. There is no way to observe bytes sent
// with it — the promise resolves when the response arrives and tells you
// nothing in between. XHR's upload.onprogress is the only browser API
// that reports it, which is why a progress bar for a 4MB photo on a
// Nigerian mobile connection requires XHR specifically.
//
// ── THE FILE NEVER TOUCHES kola_server ───────────────────────────────
//
// The server signs one-shot credentials (ProductEndpoint
// .getMediaUploadAuth) and the bytes go straight to ImageKit. See
// imagekit_service.dart for the full reasoning; the short version is
// that a Serverpod parameter is JSON, so proxying would base64 every
// photo, send it twice, and still report no progress.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

/// What ImageKit returned for one uploaded file.
class UploadedMedia {
  const UploadedMedia({
    required this.fileId,
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
  });

  final String fileId;
  final String url;
  final String? thumbnailUrl;
  final int? width;
  final int? height;

  static UploadedMedia fromImageKitJson(Map<String, dynamic> json) {
    return UploadedMedia(
      fileId: json['fileId'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );
  }
}

/// Raised with a sentence an owner can act on.
class UploadException implements Exception {
  const UploadException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class MediaUpload {
  /// Sends one file to ImageKit.
  ///
  /// [auth] is the JSON string from ProductEndpoint.getMediaUploadAuth —
  /// passed in rather than fetched here so a bulk import can sign once
  /// and reuse it across a batch, instead of a round trip per photo.
  ///
  /// [onProgress] receives 0.0–1.0. It fires on every chunk the browser
  /// reports, which on a slow connection is often enough to animate.
  static Future<UploadedMedia> send({
    required JSObject file,
    required String fileName,
    required String auth,
    void Function(double)? onProgress,
  }) {
    final decoded = jsonDecode(auth) as Map<String, dynamic>;

    final form = _FormData();
    // Order does not matter to ImageKit, but `file` first keeps the
    // multipart body readable when debugging in the network tab.
    form.append('file', file);
    form.append('fileName', fileName.toJS);
    form.append('publicKey', (decoded['publicKey'] as String).toJS);
    form.append('signature', (decoded['signature'] as String).toJS);
    form.append('expire', '${decoded['expire']}'.toJS);
    form.append('token', (decoded['token'] as String).toJS);
    form.append('folder', (decoded['folder'] as String).toJS);
    // Without this, re-uploading a file with the same name silently
    // overwrites the first one — so two products photographed as
    // "IMG_0042.jpg" would end up sharing an image.
    form.append('useUniqueFileName', 'true'.toJS);

    final completer = Completer<UploadedMedia>();
    final xhr = _XmlHttpRequest();
    xhr.open('POST', decoded['uploadUrl'] as String);

    if (onProgress != null) {
      xhr.upload.addEventListener(
        'progress',
        (_ProgressEvent event) {
          // lengthComputable is false for a chunked body, and total is
          // 0 then — checked rather than divided by.
          final total = event.total;
          if (total > 0) onProgress(event.loaded / total);
        }.toJS,
      );
    }

    xhr.addEventListener(
      'load',
      (JSObject _) {
        final status = xhr.status;
        final body = xhr.responseText;
        if (status >= 200 && status < 300) {
          try {
            final json = jsonDecode(body) as Map<String, dynamic>;
            if (!completer.isCompleted) {
              completer.complete(UploadedMedia.fromImageKitJson(json));
            }
          } catch (_) {
            if (!completer.isCompleted) {
              completer.completeError(const UploadException(
                'That upload finished but came back in a form kolaa did '
                'not recognise. Please try again.',
              ));
            }
          }
        } else {
          // ImageKit puts a human-ish reason in `message`. Surfaced when
          // present, because "file size exceeds the limit" is something
          // the owner can act on and a bare 400 is not.
          String detail = '';
          try {
            final json = jsonDecode(body) as Map<String, dynamic>;
            detail = (json['message'] as String?) ?? '';
          } catch (_) {}
          if (!completer.isCompleted) {
            completer.completeError(UploadException(
              detail.isNotEmpty
                  ? detail
                  : "That photo didn't upload. Please try again.",
            ));
          }
        }
      }.toJS,
    );

    xhr.addEventListener(
      'error',
      (JSObject _) {
        if (!completer.isCompleted) {
          completer.completeError(const UploadException(
            "The upload lost its connection. It'll work once you're back "
            'online — nothing has been saved.',
          ));
        }
      }.toJS,
    );

    xhr.addEventListener(
      'abort',
      (JSObject _) {
        if (!completer.isCompleted) {
          completer.completeError(const UploadException('Upload cancelled.'));
        }
      }.toJS,
    );

    xhr.send(form);
    return completer.future;
  }
}

// ── Declared DOM surface ────────────────────────────────────────────
//
// Exactly what is used above, and nothing more. Every name below is the
// browser's own — see this file's header on why they are declared here
// rather than imported.

@JS('XMLHttpRequest')
extension type _XmlHttpRequest._(JSObject _) implements JSObject {
  external factory _XmlHttpRequest();
  external void open(String method, String url);
  external void send(JSAny? body);
  external void addEventListener(String type, JSFunction listener);
  external int get status;
  external String get responseText;

  /// The upload-side event target. This is the whole reason for XHR:
  /// `xhr.upload` reports bytes sent, and nothing else in the platform
  /// does.
  external _XhrUpload get upload;
}

extension type _XhrUpload._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
}

@JS('FormData')
extension type _FormData._(JSObject _) implements JSObject {
  external factory _FormData();

  /// One declaration covering both JS overloads.
  ///
  /// JS has a single `append` that accepts a string OR a Blob; the
  /// distinction is dynamic. Declaring the value as JSAny models that
  /// honestly, and is precisely the overload collapse that makes
  /// package:web's generated name unpredictable.
  external void append(String name, JSAny value);
}

/// The two fields a progress listener needs.
///
/// Declared rather than reached through getProperty, which would need
/// dart:js_interop_unsafe — an untyped property bag is exactly the kind
/// of dynamic access that failed at runtime earlier in this codebase.
extension type _ProgressEvent._(JSObject _) implements JSObject {
  external int get total;
  external int get loaded;
}
