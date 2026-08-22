// google_oauth_service.dart — Gate 4. The FIRST real OAuth-redirect flow
// in this codebase — see docs/DESIGN_DELTA.md's "owed, with a name on
// it: Google OAuth (one provider, one consent flow, one refresh path,
// three scopes) restores Sheets / Drive / Calendar." Written generic
// over [scopes] specifically so Drive and Calendar are a new scope
// constant and a new adapter later, not a second OAuth implementation —
// the same "one connector as proof, then pour more through the same
// engine" instinct as the payment-gateway sweep.
//
// PLAIN HTTPS, NOT A GOOGLE SDK PACKAGE: same convention as every other
// provider wrapper in this codebase (PaystackService, FlutterwaveService,
// WhatsAppService) — one dependency-free HTTP call shape kolaa's own
// retry/logging conventions already know how to wrap, rather than a
// third-party SDK with its own error types and its own opinions about
// token storage.
//
// WHY "offline" ACCESS TYPE + "consent" PROMPT: this codebase's own
// sync engine (ConnectorSyncSweepService) runs unattended, on a Timer,
// with nobody present to re-authenticate — it needs a REFRESH token,
// which Google only issues on the FIRST consent, and only when
// access_type=offline is explicitly requested. prompt=consent forces
// that first-consent behavior even for an account that connected
// before and would otherwise silently get no refresh token on a
// reconnect.

import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleOAuthService {
  const GoogleOAuthService({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  final String clientId;
  final String clientSecret;
  final String redirectUri;

  static const _authBaseUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenUrl = 'https://oauth2.googleapis.com/token';

  /// Read-only Sheets scope — the only one Gate 4 actually requests today.
  /// Drive/Calendar add their own constants here when their adapters are
  /// built, not a speculative combined scope requested before either
  /// exists (asking for access nothing uses yet is exactly the kind of
  /// consent-screen overreach that makes an owner distrust the connect
  /// flow).
  static const scopeSheetsReadonly =
      'https://www.googleapis.com/auth/spreadsheets.readonly';

  /// The URL to redirect the owner's browser to. [state] must be an
  /// opaque, server-signed value the callback route can verify — see
  /// ConnectorEndpoint.startGoogleOAuth for how it's built. Google
  /// returns this exact value on the callback unmodified; it is this
  /// flow's ONLY defence against a forged callback claiming to connect
  /// a workspace the requester doesn't own.
  String authorizationUrl({required String state, required List<String> scopes}) {
    final uri = Uri.parse(_authBaseUrl).replace(queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes.join(' '),
      'access_type': 'offline',
      'prompt': 'consent',
      'state': state,
    });
    return uri.toString();
  }

  /// Exchanges an authorization [code] (from the callback's `code` query
  /// param) for an access token + refresh token. Returns the raw decoded
  /// response — `refresh_token` is only present on a first-consent
  /// exchange (see this file's header on access_type/prompt), so a
  /// caller must check for its presence rather than assume it.
  Future<Map<String, dynamic>> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google token exchange failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Trades a stored refresh token for a fresh, short-lived access
  /// token. Called at the START of every sync run (GoogleSheetsAdapter
  /// never caches an access token across runs) — access tokens are
  /// ~1 hour, and the sweep runs every 30 minutes but per-workspace, not
  /// continuously, so caching would save at most one call while adding a
  /// second place a token's freshness could be wrong.
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'refresh_token',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google token refresh failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
