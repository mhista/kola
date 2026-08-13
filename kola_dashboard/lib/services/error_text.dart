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

abstract class ErrorText {
  /// The sentence to show the owner.
  ///
  /// A KolaException carries a message written for them. Anything else
  /// is a bug, a network failure, or a server fault — none of which have
  /// an owner-readable explanation, so they get a generic line rather
  /// than a leaked stack frame.
  static String of(Object error) {
    if (error is KolaException) return error.message;

    // Deliberately vague. If this branch is reached the cause is NOT
    // something the owner did or can fix, and showing them
    // "NoSuchMethodError: The getter 'id' was called on null" teaches
    // them nothing except that the product is broken.
    return 'Something went wrong on our side. Please try again — and if '
        'it keeps happening, this one is on us to fix.';
  }

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
