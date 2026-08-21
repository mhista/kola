// google_identity.dart — thin JS interop over Google Identity Services
// (GIS), the `google.accounts.id` API loaded by web/index.html's
// <script src="https://accounts.google.com/gsi/client">.
//
// WHY THIS EXISTS INSTEAD OF REDIRECTING THROUGH SUPABASE'S /authorize —
// the first version of Google sign-in here did `web.window.location.assign`
// to Supabase's own `/auth/v1/authorize?provider=google`, which sends the
// WHOLE BROWSER to Google via a URL whose origin is
// jwyrmptiehkkizwjbqtg.supabase.co. Google's consent screen then reads
// "Sign in to jwyrmptiehkkizwjbqtg.supabase.co" — the raw Supabase project
// ID, not this dashboard, and not "kolaa" — because that redirect's origin
// IS what Google shows, full stop; no Supabase setting fixes that short of
// a paid custom domain. It also depended on Supabase's Site
// URL/redirect-allow-list configuration being correct, which it wasn't
// (see AuthCallbackPage's removal — that bug sent the token to
// http://localhost:3000 instead of this dashboard).
//
// This version instead loads Google's own script DIRECTLY on
// dash.kolaa.co, gets an ID token back without ever leaving this origin,
// and POSTs that token to Supabase ourselves (AuthService.
// signInWithGoogleIdToken, grant_type=id_token). Google's consent screen
// then reads "Sign in to dash.kolaa.co" — our own domain — because the
// request never touched Supabase's origin at all. No /auth/callback page,
// no redirect-URL allow-list, no race with a stale LocalStorage session.
//
// Reference: https://supabase.com/docs/guides/auth/social-login/auth-google
// ("Google pre-built" / signInWithIdToken section) — fetched and read in
// full before writing this file, not reconstructed from memory.
//
// NOT COMPILE-TESTED. No Dart/Flutter toolchain was available in the
// session that wrote this. The nested-extension-type-over-JSObject shape
// and the `@JS('google')` top-level global getter both match dart.dev's
// own current JS interop guide (fetched directly, not recalled), and
// follow the SAME "external members with the API's own stable names, no
// `dynamic`" discipline dom_files.dart already established in this
// project for exactly this reason — but run `dart analyze` / a real build
// before trusting this in production, per this project's own rule that
// guessed APIs have been the single largest source of bugs here.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// The `google` global GIS's script attaches to `window`. Nullable and
/// re-read on every call rather than cached at import time, because the
/// script tag loads `async` — it may genuinely not exist yet the instant
/// this file's top level runs, only by the time a page actually tries to
/// use it (see [isReady]).
@JS('google')
external JSObject? get _googleGlobal;

extension type _GoogleNamespace._(JSObject _) implements JSObject {
  external _AccountsNamespace get accounts;
}

extension type _AccountsNamespace._(JSObject _) implements JSObject {
  external _AccountsId get id;
}

extension type _AccountsId._(JSObject _) implements JSObject {
  external void initialize(_IdConfiguration config);
  external void renderButton(web.HTMLElement parent, _GsiButtonConfiguration options);
}

/// Object-literal config for `google.accounts.id.initialize(...)`. Field
/// names are GIS's own (snake_case, not camelCase) — see
/// https://developers.google.com/identity/gsi/web/reference/js-reference#IdConfiguration
extension type _IdConfiguration._(JSObject _) implements JSObject {
  external factory _IdConfiguration({
    required String client_id,
    required JSFunction callback,
    String? nonce,
    bool? use_fedcm_for_prompt,
    bool? auto_select,
  });
}

/// https://developers.google.com/identity/gsi/web/reference/js-reference#GsiButtonConfiguration
extension type _GsiButtonConfiguration._(JSObject _) implements JSObject {
  external factory _GsiButtonConfiguration({
    String? type,
    String? shape,
    String? theme,
    String? text,
    String? size,
    String? logo_alignment,
    String? width,
  });
}

/// What GIS passes to the configured `callback` — see
/// https://developers.google.com/identity/gsi/web/reference/js-reference#CredentialResponse
/// `credential` is the ID token JWT string, exactly what
/// AuthService.signInWithGoogleIdToken needs to hand to Supabase.
extension type CredentialResponse._(JSObject _) implements JSObject {
  external String get credential;
}

abstract class GoogleIdentity {
  /// False until the async `gsi/client` script tag has actually attached
  /// `window.google`. [renderSignInButton] silently does nothing if
  /// called too early — checking this first (or just retrying briefly)
  /// avoids that.
  static bool get isReady => _googleGlobal != null;

  /// Configures GIS once with this app's OAuth client + nonce + callback,
  /// then renders Google's OWN button into [container] — deliberately
  /// Google's rendered button, not a custom-styled one, both because
  /// Google's brand guidelines expect it and because a self-drawn button
  /// would still trigger the exact same consent flow with none of the
  /// visual trust signals (the "G" logo, the exact wording) Google's own
  /// rendering provides.
  ///
  /// [nonce] must be the RAW (unhashed) nonce — AuthService generates
  /// both the raw and SHA-256-hashed versions together (see
  /// generateNonce) and this needs the raw one; [onCredential] is handed
  /// the same raw nonce back so it can pass it to Supabase alongside the
  /// token, matching Supabase's own documented requirement that the nonce
  /// sent to signInWithIdToken be the unhashed string while the one given
  /// to Google here is its hash.
  static void renderSignInButton({
    required web.HTMLElement container,
    required String clientId,
    required String hashedNonce,
    required void Function(String credential) onCredential,
  }) {
    final google = _googleGlobal;
    if (google == null) return;

    final callback = ((CredentialResponse response) {
      onCredential(response.credential);
    }).toJS;

    (google as _GoogleNamespace).accounts.id.initialize(
      _IdConfiguration(
        client_id: clientId,
        callback: callback,
        nonce: hashedNonce,
        use_fedcm_for_prompt: true,
      ),
    );

    google.accounts.id.renderButton(
      container,
      _GsiButtonConfiguration(
        type: 'standard',
        shape: 'pill',
        // 'outline' renders Google's LIGHT button (white fill, dark
        // text) — correct on a light page, wrong here: this dashboard's
        // login card is dark, and 'outline' sat as a bright white pill
        // against it. 'filled_black' is Google's own dark-surface
        // variant (dark fill, white text) — this app has no light mode
        // to also account for (theme.dart's KolaDashboardColors are the
        // dark palette unconditionally on this still-unmigrated login
        // page — see its file header), so a fixed choice is correct
        // here rather than something that needs to react to a mode.
        theme: 'filled_black',
        text: 'continue_with',
        size: 'large',
        logo_alignment: 'left',
        width: '332',
      ),
    );
  }
}
