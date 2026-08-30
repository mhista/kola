// hubspot_oauth_service.dart — fix-properly pass. The HubSpot twin of
// google_oauth_service.dart / dropbox_oauth_service.dart — same shape,
// plain HTTPS, no SDK.
//
// VERIFIED LIVE against developers.hubspot.com/docs/guides/api/
// app-management/oauth-tokens (fetched in full during this pass):
//   install/authorize: https://app.hubspot.com/oauth/authorize
//   token:             https://api.hubapi.com/oauth/v1/token
//
// HubSpot's token endpoint takes grant_type=authorization_code (initial)
// or grant_type=refresh_token (refresh), both against the SAME url —
// unlike Google/Dropbox's shared endpoint this isn't a coincidence to
// note, it's just how HubSpot designed it; kept as two methods anyway
// to match every other provider wrapper's shape in this codebase.
//
// HubSpot access tokens are short-lived (expires_in ~1800s in the
// docs' own example) — same "never cache across sync runs, refresh at
// the start of every run" reasoning as Google/Dropbox.

import 'dart:convert';
import 'package:http/http.dart' as http;

class HubSpotOAuthService {
  const HubSpotOAuthService({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  final String clientId;
  final String clientSecret;
  final String redirectUri;

  static const _authBaseUrl = 'https://app.hubspot.com/oauth/authorize';
  static const _tokenUrl = 'https://api.hubapi.com/oauth/v1/token';

  /// Read-only CRM scope — the only thing connector_endpoint.dart's
  /// hubspot flow needs: bringing existing customer records into kola's
  /// own customer graph (see connector_catalog.dart's hubspot entry),
  /// never writing back to HubSpot.
  static const scopeContactsRead = 'crm.objects.contacts.read';

  String authorizationUrl({required String state, required List<String> scopes}) {
    final uri = Uri.parse(_authBaseUrl).replace(queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scopes.join(' '),
      'state': state,
    });
    return uri.toString();
  }

  Future<Map<String, dynamic>> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'HubSpot token exchange failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'HubSpot token refresh failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
