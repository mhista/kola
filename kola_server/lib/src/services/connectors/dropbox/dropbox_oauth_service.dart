// dropbox_oauth_service.dart — fix-properly pass. The Dropbox twin of
// google_oauth_service.dart, same shape deliberately: plain HTTPS, no
// SDK, one class that knows the authorize URL and the token endpoint
// and nothing else about what Dropbox is used for.
//
// VERIFIED LIVE against developers.dropbox.com/oauth-guide (fetched in
// full during this pass, cross-checked against dropbox.tech's own
// "Using OAuth 2.0 with offline access" writeup) — not guessed from
// training data alone, per this project's connector-building
// discipline:
//   authorize: https://www.dropbox.com/oauth2/authorize
//   token:     https://api.dropboxapi.com/oauth2/token   (NOT
//              api.dropbox.com — the OAuth token endpoint lives on the
//              api-prefixed host, unlike the authorize redirect, which
//              is the easy mistake to make here)
//
// token_access_type=offline IS DROPBOX'S OWN NAME for exactly what
// Google spells access_type=offline + prompt=consent: request a
// refresh token on top of the short-lived access token, because
// ConnectorSyncSweepService runs unattended and cannot re-prompt an
// owner for consent every time an access token expires.

import 'dart:convert';
import 'package:http/http.dart' as http;

class DropboxOAuthService {
  const DropboxOAuthService({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  final String clientId;
  final String clientSecret;
  final String redirectUri;

  static const _authBaseUrl = 'https://www.dropbox.com/oauth2/authorize';
  static const _tokenUrl = 'https://api.dropboxapi.com/oauth2/token';

  /// The URL to redirect the owner's browser to. [state] must be an
  /// opaque, server-signed value the callback route can verify — same
  /// contract as GoogleOAuthService.authorizationUrl, same reason: it's
  /// this flow's only defence against a forged callback.
  String authorizationUrl({required String state}) {
    final uri = Uri.parse(_authBaseUrl).replace(queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'token_access_type': 'offline',
      'state': state,
    });
    return uri.toString();
  }

  /// Exchanges an authorization [code] for an access token + refresh
  /// token. Dropbox authenticates the token endpoint with HTTP Basic
  /// auth (client_id:client_secret) OR client credentials in the body —
  /// the body form is used here to match every other provider wrapper
  /// in this codebase (Google, Microsoft) rather than mixing auth
  /// styles across otherwise-identical service classes.
  Future<Map<String, dynamic>> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Dropbox token exchange failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Trades a stored refresh token for a fresh, short-lived access
  /// token — same "never cache across sync runs" reasoning as
  /// GoogleOAuthService.refreshAccessToken.
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Dropbox token refresh failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
