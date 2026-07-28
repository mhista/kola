// session_verifier.dart
//
// Verifies a Supabase Auth access token (JWT) sent by the dashboard on
// every workspace-scoped request, and extracts the identity claims we
// actually need.
//
// WHY WE DON'T ISSUE OUR OWN AUTH TOKENS:
//   Supabase Auth already handles signup, login, password reset, and
//   session refresh — reimplementing any of that here would be exactly
//   the kind of "rebuild something that already exists" the working
//   conventions warn against. The dashboard authenticates directly
//   against Supabase Auth and gets back a signed JWT; this server's only
//   job is to check that JWT's signature is genuine before trusting the
//   `sub` claim (the Supabase Auth user UUID) as the caller's identity.
//
// TASK #106 — WHY THIS FILE CHANGED FROM A STATIC-SECRET CHECK TO JWKS:
//   The original version of this file only ever did one thing: verify
//   the token's HS256 signature against Env.supabaseJwtSecret, the
//   project's legacy shared JWT secret. That's Supabase's "Legacy"
//   system (see supabase.com/docs/guides/auth/signing-keys) — it works,
//   but it means every JWT secret rotation on the Supabase side requires
//   someone to manually copy the new secret into this server's own env
//   vars and redeploy, with a real (if narrow) window where the two are
//   out of sync. That's the "workaround, not the correct long-term fix"
//   this task refers to.
//
//   Supabase's newer Signing Keys system solves this by publishing the
//   CURRENT signing key's public half at a discovery endpoint
//   (GET <supabaseUrl>/auth/v1/.well-known/jwks.json) — once a project
//   has moved to an asymmetric key (ES256 P-256 is what Supabase
//   recommends; RS256 is also supported), this server can verify tokens
//   using ONLY that public key, fetched live, with no shared secret
//   living in this server's env at all. Key rotation on Supabase's side
//   then requires zero changes here — the next fetch just sees the new
//   key.
//
//   THE CATCH — WHY THE LEGACY PATH IS STILL HERE, NOT DELETED: a shared
//   secret (whether the legacy JWT secret, or the "shared secret" key
//   TYPE the new system also offers) is NEVER published via JWKS — doing
//   so would let anyone forge tokens. JWKS only ever exposes asymmetric
//   (EC/RSA) public keys. So JWKS-based verification only works once a
//   Supabase project has actually completed the dashboard-side migration
//   ("Migrate JWT secret" then "Rotate keys" to an asymmetric key,
//   Settings > JWT Signing Keys) — a one-time action on Supabase's own
//   dashboard, not something this server can trigger. Until that's done
//   (or if it's simply not done yet on this project), tokens are still
//   HS256-signed with the legacy secret and have no JWKS entry — [verify]
//   below falls back to the exact same Env.supabaseJwtSecret check this
//   file always did, so nothing breaks for a project that hasn't
//   migrated. The moment a project DOES migrate, this file starts
//   verifying via JWKS automatically, with no code change needed here.
//
// UNVERIFIED IN THIS SANDBOX: no Dart toolchain and no live Supabase
// project on the Signing Keys system were available to actually run this
// against a real ES256/RS256 token — see jwk_to_pem.dart's header for the
// same caveat on the DER encoding it does. Test this against a real
// migrated project before relying on it in production; the legacy path
// below is what keeps auth working in the meantime either way.
//
// WHAT THIS FILE DELIBERATELY DOES NOT DO:
//   It does not check *workspace* access — only *identity*. "Is this a
//   genuine, non-expired Supabase session, and whose?" is answered here.
//   "Does this user have access to workspace 42?" is answered one layer
//   up, in workspace_access.dart, which calls this file first and then
//   checks WorkspaceMemberRepository.

import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/kola_logger.dart';
import 'jwk_to_pem.dart';

/// Thrown when an access token fails verification (bad signature, expired,
/// malformed, or missing the claims we need). Endpoints should catch this
/// and translate it into whatever "unauthorized" response shape they use.
class InvalidSessionException implements Exception {
  final String message;
  const InvalidSessionException(this.message);

  @override
  String toString() => 'InvalidSessionException: $message';
}

/// The identity claims we trust once a token has been verified.
class VerifiedSession {
  const VerifiedSession({required this.userId, required this.email});

  /// Supabase Auth user id (UUID string) — matches WorkspaceMember.userId.
  final String userId;

  /// May be null for phone-auth-only users; not relied on for access
  /// control, only shown in the dashboard UI.
  final String? email;
}

/// In-memory cache of the JWKS document, shared across every
/// SessionVerifier instance (there's normally exactly one, but this is a
/// `static` cache rather than an instance field so that holds even if
/// something someday constructs more than one). Mirrors Supabase's own
/// edge-cache TTL (10 minutes) for the discovery endpoint — see
/// supabase.com/docs/guides/auth/signing-keys's "Public key discovery and
/// caching" section — rather than inventing an unrelated number.
class _JwksCache {
  static Map<String, dynamic>? _keysByKid;
  static DateTime? _fetchedAt;
  static DateTime? _lastForcedRefetch;

  static const _ttl = Duration(minutes: 10);
  // A kid that isn't in the current cache triggers one immediate refetch
  // (handles "key was just rotated, cache is merely stale") — but only
  // once per this cooldown, so a stream of tokens carrying a bogus/
  // malicious kid can't force-refetch on every single request.
  static const _forcedRefetchCooldown = Duration(seconds: 30);

  /// Returns the JWK matching [kid], fetching (or refetching) the JWKS
  /// document as needed. Returns null if [kid] genuinely isn't published
  /// — the caller's job to then fall back to the legacy secret path, not
  /// this cache's.
  static Future<Map<String, dynamic>?> find(String kid) async {
    if (_keysByKid == null || _isStale()) {
      await _fetch();
    }
    if (_keysByKid?[kid] == null) {
      final now = DateTime.now();
      final canForceRefetch =
          _lastForcedRefetch == null || now.difference(_lastForcedRefetch!) > _forcedRefetchCooldown;
      if (canForceRefetch) {
        _lastForcedRefetch = now;
        await _fetch();
      }
    }
    return _keysByKid?[kid] as Map<String, dynamic>?;
  }

  static bool _isStale() =>
      _fetchedAt == null || DateTime.now().difference(_fetchedAt!) > _ttl;

  static Future<void> _fetch() async {
    if (Env.supabaseUrl.isEmpty) return;
    try {
      final uri = Uri.parse(
        '${Env.supabaseUrl}/auth/v1/.well-known/jwks.json',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        Log.warning('JWKS fetch returned HTTP ${response.statusCode} — falling back to legacy secret');
        return;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rawKeys = (body['keys'] as List?) ?? const [];
      final byKid = <String, dynamic>{};
      for (final rawKey in rawKeys) {
        final keyMap = rawKey as Map<String, dynamic>;
        final kid = keyMap['kid'] as String?;
        if (kid != null) byKid[kid] = keyMap;
      }
      _keysByKid = byKid;
      _fetchedAt = DateTime.now();
    } catch (e) {
      Log.warning('JWKS fetch failed — falling back to legacy secret: $e');
      // Deliberately don't clear an existing cache on a transient network
      // failure — stale-but-valid beats "every request now fails" until
      // the next successful fetch.
    }
  }
}

class SessionVerifier {
  const SessionVerifier();

  /// Verifies [accessToken] and returns the caller's identity.
  ///
  /// Throws [InvalidSessionException] if the token is missing, malformed,
  /// expired, or signed with a key/secret this server doesn't trust.
  Future<VerifiedSession> verify(String accessToken) async {
    if (accessToken.isEmpty) {
      throw const InvalidSessionException('No access token provided');
    }

    final header = _decodeHeaderUnverified(accessToken);
    final kid = header?['kid'] as String?;
    final alg = header?['alg'] as String?;

    JWTKey? key;
    if (kid != null && (alg == 'ES256' || alg == 'RS256')) {
      final jwk = await _JwksCache.find(kid);
      if (jwk != null) {
        key = _keyFromJwk(jwk);
      }
    }

    // No usable JWKS entry (project hasn't migrated off the legacy JWT
    // secret yet, or this token predates a recent rotation) — fall back
    // to the exact check this file always did. See this file's header
    // for why that's a legitimate fallback, not a hack.
    key ??= Env.supabaseJwtSecret.isNotEmpty ? SecretKey(Env.supabaseJwtSecret) : null;

    if (key == null) {
      throw const InvalidSessionException(
        'No verification key available — SUPABASE_JWT_SECRET is not configured '
        'and no matching JWKS key was found for this token',
      );
    }

    try {
      final jwt = JWT.verify(accessToken, key);
      final payload = jwt.payload as Map<String, dynamic>;

      final userId = payload['sub'] as String?;
      if (userId == null || userId.isEmpty) {
        throw const InvalidSessionException('Token missing sub claim');
      }

      return VerifiedSession(
        userId: userId,
        email: payload['email'] as String?,
      );
    } on JWTExpiredException {
      throw const InvalidSessionException('Session expired');
    } on JWTException catch (e) {
      Log.warning('Session verification failed: ${e.message}');
      throw InvalidSessionException('Invalid session: ${e.message}');
    }
  }

  /// Reads the JWT header (the first of the three base64url segments)
  /// WITHOUT verifying anything — this only tells us which key to try,
  /// it is never treated as a trust decision by itself. The actual
  /// cryptographic check happens afterward via JWT.verify(), same as
  /// before this file's JWKS support existed.
  Map<String, dynamic>? _decodeHeaderUnverified(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  JWTKey? _keyFromJwk(Map<String, dynamic> jwk) {
    final kty = jwk['kty'] as String?;
    try {
      if (kty == 'EC' && jwk['crv'] == 'P-256') {
        return ECPublicKey(
          ecP256JwkToPem(x: jwk['x'] as String, y: jwk['y'] as String),
        );
      }
      if (kty == 'RSA') {
        return RSAPublicKey(
          rsaJwkToPem(n: jwk['n'] as String, e: jwk['e'] as String),
        );
      }
    } catch (e) {
      Log.warning('Failed to build verification key from JWKS entry: $e');
    }
    // Unsupported kty/crv (e.g. a future EdDSA/Ed25519 key — see this
    // file's header) — fall back to the legacy secret rather than fail
    // outright, since [verify] treats a null key as "try the fallback."
    return null;
  }
}
