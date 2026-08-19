// auth_service.dart — talks directly to Supabase Auth's own REST API
// (NOT the `supabase` package — see pubspec.yaml's header for why: we
// only need signIn/signUp/refresh/signOut, and raw `http` calls avoid
// pulling in the realtime/storage/postgrest/functions surface that
// package brings along). Same "raw HTTP over a heavy client library"
// choice kola_landing already made for its waitlist form
// (lib/services/waitlist_api_service.dart) — this is that same pattern
// applied to Auth.
//
// Session persistence: the resulting AuthSession is cached in
// LocalStorage (see services/local_storage.dart) so a page reload
// doesn't force a fresh login — restoreSession() reads it back and
// refreshes proactively if it's already expired or about to be.
//
// Endpoint reference (Supabase Auth REST API, GoTrue):
//   POST {SUPABASE_URL}/auth/v1/signup        { email, password }
//   POST {SUPABASE_URL}/auth/v1/token?grant_type=password
//                                              { email, password }
//   POST {SUPABASE_URL}/auth/v1/token?grant_type=refresh_token
//                                              { refresh_token }
// All three take the anon key as both the `apikey` header and (for
// signup/password grant) the `Authorization: Bearer` header — the anon
// key identifies the calling PROJECT, not the user; the response body
// is what actually proves who the user is.
//
// GOOGLE OAUTH (Gate 0) — a fourth endpoint, structurally different from
// the three above because it's a browser REDIRECT dance, not a single
// request/response:
//   GET {SUPABASE_URL}/auth/v1/authorize?provider=google&redirect_to={url}
// sends the browser to Google's consent screen; Google returns it to
// GoTrue, which then 302s to {url} with the session appended as a URL
// FRAGMENT (#access_token=...&refresh_token=...&expires_in=...) rather
// than a query string or response body — GoTrue's default "implicit"
// flow, chosen deliberately here because this codebase has no PKCE
// code_verifier storage anywhere and adding one for a single provider
// would be new state-management machinery, not a delta. If the
// Supabase project's Auth settings force PKCE-only, this flow needs a
// code_verifier/code_challenge pair added — NOT verified either way,
// since the Google provider isn't enabled in Supabase yet to test
// against.
//
// [beginGoogleSignIn] therefore does not return an AuthSession — it
// never gets a response at all, it hands the tab to Google. The result
// comes back on a *different* page load, at /auth/callback, which reads
// the fragment via [consumeOAuthCallback]. See pages/auth_callback_page.dart.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import '../config/env.dart';
import '../models/auth_session.dart';
import 'local_storage.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  AuthService()
    : _baseUrl = Env.supabaseUrl,
      _anonKey = Env.supabaseAnonKey;

  final String _baseUrl;
  final String _anonKey;

  static const _storageKey = 'kola_auth_session';

  Map<String, String> get _headers => {
    'apikey': _anonKey,
    'Content-Type': 'application/json',
  };

  Future<AuthSession> signUp({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/v1/signup'),
      headers: _headers,
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    return _handleTokenResponse(response, context: 'Sign up');
  }

  Future<AuthSession> signInWithPassword({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/v1/token?grant_type=password'),
      headers: _headers,
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    return _handleTokenResponse(response, context: 'Sign in');
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/v1/token?grant_type=refresh_token'),
      headers: _headers,
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    return _handleTokenResponse(response, context: 'Session refresh');
  }

  AuthSession _handleTokenResponse(http.Response response, {required String context}) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['error_description'] as String? ??
          decoded['msg'] as String? ??
          decoded['error'] as String? ??
          'Unknown error';
      throw AuthException('$context failed: $message');
    }
    final session = AuthSession.fromJson(decoded);
    _persist(session);
    return session;
  }

  /// Reads a persisted session back from LocalStorage, refreshing it
  /// first if it's already expired. Returns null if there's nothing
  /// stored, storage is corrupt, or the refresh itself fails (e.g. the
  /// refresh token was revoked) — any of those cases just means "the
  /// user needs to log in again," not a crash.
  Future<AuthSession?> restoreSession() async {
    final raw = LocalStorage.getItem(_storageKey);
    if (raw == null) return null;

    try {
      final stored = AuthSession.fromStorageJson(jsonDecode(raw) as Map<String, dynamic>);
      if (!stored.isExpired) return stored;
      return await refresh(stored.refreshToken);
    } catch (_) {
      LocalStorage.removeItem(_storageKey);
      return null;
    }
  }

  void signOut() {
    LocalStorage.removeItem(_storageKey);
  }

  /// Navigates the whole tab to GoTrue's Google consent redirect. Does
  /// not return an AuthSession — see the file header. `redirectTo` is
  /// built from the CURRENT origin (window.location.origin), not a
  /// baked-in config value, so this works unmodified on localhost, a
  /// preview deploy, and production alike — each origin must still be
  /// added to the Google OAuth client's "Authorized redirect URIs" and
  /// to Supabase's own allow-list, or Google/GoTrue will reject the
  /// redirect before this dashboard ever sees it again.
  void beginGoogleSignIn() {
    final redirectTo = '${web.window.location.origin}/auth/callback';
    final uri = Uri.parse('$_baseUrl/auth/v1/authorize').replace(
      queryParameters: {'provider': 'google', 'redirect_to': redirectTo},
    );
    web.window.location.assign(uri.toString());
  }

  /// Parses the URL fragment GoTrue appends after a successful Google
  /// redirect (`#access_token=...&refresh_token=...&expires_in=...`) and
  /// persists it exactly like [_handleTokenResponse] does for password
  /// auth, so downstream code (restoreSession, refresh) cannot tell the
  /// difference between a Google session and a password one — by design,
  /// AuthSession carries no `provider` field because nothing today reads
  /// one.
  ///
  /// Returns null (rather than throwing) for a fragment that failed
  /// on Google/GoTrue's side (`#error=...&error_description=...`) or is
  /// simply missing tokens — the caller (AuthCallbackPage) treats both as
  /// "show an error, offer to try again," never as a crash.
  AuthSession? consumeOAuthCallback(String hash) {
    final raw = hash.startsWith('#') ? hash.substring(1) : hash;
    final params = Uri.splitQueryString(raw);

    if (params.containsKey('error')) return null;

    final accessToken = params['access_token'];
    final refreshToken = params['refresh_token'];
    if (accessToken == null || refreshToken == null) return null;

    final expiresIn = int.tryParse(params['expires_in'] ?? '') ?? 3600;
    final session = _sessionFromAccessToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
    _persist(session);
    return session;
  }

  /// The implicit-flow fragment carries the tokens but not a decoded
  /// user object (unlike the /token JSON responses _handleTokenResponse
  /// parses) — id/email live inside the JWT's own claims instead. This
  /// decodes just enough of the JWT (base64url payload, no signature
  /// check — verifying it is kola_server's job via SessionVerifier, the
  /// same division of responsibility the file header describes for the
  /// password flow) to fill AuthSession.userId/email from `sub`/`email`.
  AuthSession _sessionFromAccessToken({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) {
    final parts = accessToken.split('.');
    var userId = '';
    String? email;
    if (parts.length == 3) {
      try {
        final normalized = base64Url.normalize(parts[1]);
        final payload = jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
        userId = payload['sub'] as String? ?? '';
        email = payload['email'] as String?;
      } catch (_) {
        // Malformed/unexpected JWT shape — leave userId/email empty
        // rather than throw. kola_server still verifies the token
        // itself on every real request; a blank display name here is
        // cosmetic, not a security gap.
      }
    }
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      userId: userId,
      email: email,
    );
  }

  void _persist(AuthSession session) {
    LocalStorage.setItem(_storageKey, jsonEncode(session.toJson()));
  }
}
