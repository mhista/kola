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

import 'dart:convert';
import 'package:http/http.dart' as http;
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

  void _persist(AuthSession session) {
    LocalStorage.setItem(_storageKey, jsonEncode(session.toJson()));
  }
}
