// error_text.dart — turning a thrown object into a sentence an owner can
// act on.
//
// ── WHY THIS EXISTS ──────────────────────────────────────────────────
//
// Five pages each had a private `_human(String)` that stripped
// "Exception: " and "ServerpodClientException: " prefixes off
// `'$e'`. That was string-scraping a stack-trace-shaped object, and it
// only ever worked by accident.
//
// The real problem was upstream: Serverpod only transmits exceptions
// declared with `exception:` in a .spy.yaml. The server had 128 throw
// sites and zero of them were serializable, so every owner-facing
// message was logged server-side and delivered as a bare "Internal
// server error". See kola_exception.spy.yaml.
//
// Now that KolaException crosses the wire, this reads `.message`
// directly — no parsing, no prefixes, no guessing.

import 'package:kola_client/kola_client.dart';
import 'package:web/web.dart' as web;

abstract class ErrorText {
  /// The sentence to show the owner.
  ///
  /// A KolaException carries a message written for them. Anything else
  /// is a bug, a network failure, or a server fault — none of which have
  /// an owner-readable explanation, so they get a generic line rather
  /// than a leaked stack frame.
  ///
  /// ── LOSING THE NETWORK IS NOT A FAULT ──────────────────────────────
  ///
  /// It was being reported as one. Dropping Wi-Fi produced, verbatim on
  /// screen: "ServerpodClientException: Unknown server response code.
  /// (ClientException: NetworkError when attempting to fetch resource.,
  /// uri=https://p01--kola--hnnl8wyj78qp.code.run/bot), statusCode = -1".
  ///
  /// That leaks the internal hostname, names an exception class the
  /// owner has no use for, and — worst — implies kola broke. The one
  /// fact that mattered, "you are offline", was the only thing missing.
  /// Someone in a Lagos market on mobile data hits this constantly; it
  /// has to read as a normal, temporary condition.
  static String of(Object error) {
    if (error is KolaException) return error.message;
    if (_looksOffline(error)) {
      // navigator.onLine is DEFINITIVE for this branch, so the sentence
      // can be too — no hedging about "something went wrong".
      return web.window.navigator.onLine
          ? "Can't reach kola right now. Your connection is working, so "
              'this is on our side — it should clear shortly.'
          : "You're offline. This will load as soon as you have a "
              'connection again — nothing has been lost.';
    }

    // Deliberately vague. If this branch is reached the cause is NOT
    // something the owner did or can fix, and showing them
    // "NoSuchMethodError: The getter 'id' was called on null" teaches
    // them nothing except that the product is broken.
    return 'Something went wrong on our side. Please try again — and if '
        'it keeps happening, this one is on us to fix.';
  }

  /// Whether this is a transport failure rather than a server answer.
  ///
  /// ── WHY THIS MATCHES ON TEXT, WHEN THE HEADER SAYS NOT TO ──────────
  ///
  /// This file's header criticises string-scraping `'$e'`, and it was
  /// right to: parsing a message to recover the owner-facing sentence is
  /// guesswork, and KolaException removed the need for it.
  ///
  /// This is a different job. It does not extract anything — it only
  /// CLASSIFIES, in the last step before falling back to a generic
  /// line, and a wrong answer costs one slightly-off sentence rather
  /// than a wrong message. The alternative is `error is
  /// ServerpodClientException`, which is the cleaner test and is
  /// deliberately not used yet: that type comes from serverpod_client's
  /// re-export and its field names could not be verified from here, so
  /// taking it on faith risked a build break for a cosmetic gain.
  /// Worth revisiting once confirmed.
  ///
  /// `statusCode = -1` is Serverpod's own marker for "the request never
  /// got an HTTP response", which is exactly this case.
  static bool _looksOffline(Object error) {
    final s = error.toString();
    return s.contains('statusCode = -1') ||
        s.contains('NetworkError') ||
        s.contains('Failed to fetch') ||
        s.contains('SocketException') ||
        s.contains('Connection refused');
  }

  /// True when the owner should be offered a retry rather than told the
  /// action failed. Transport problems are the retryable kind.
  static bool isOffline(Object error) => _looksOffline(error);

  /// Machine-readable tag when the UI must BRANCH rather than display —
  /// 'plan_limit' to offer an upgrade, 'duplicate' to offer "save it
  /// anyway", 'session_invalid' to send them back to sign-in.
  static String? codeOf(Object error) =>
      error is KolaException ? error.code : null;

  /// Whether this error means the session is gone rather than the action
  /// being wrong. Those need re-authentication, not a retry button.
  static bool isSessionExpired(Object error) =>
      codeOf(error) == 'session_invalid';
}
