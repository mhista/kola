// meta_oauth_service.dart — fix-properly pass. Shared by BOTH
// instagram_shop and facebook_catalog (connector_catalog.dart's own
// featureKey comment: "can this business connect [a Meta commerce
// surface]" is one integration, not two — same "one client, many
// connectors" shape as GoogleOAuthService being shared across
// google_sheets/google_drive/google_calendar).
//
// VERIFIED LIVE against developers.facebook.com/docs/facebook-login/
// guides/advanced/manual-flow/ (fetched in full during this pass):
//   authorize: https://www.facebook.com/v25.0/dialog/oauth
//   token:     GET https://graph.facebook.com/v25.0/oauth/access_token
//              (a GET with query params — the one real shape
//              difference from every other provider in this file's
//              family, which all POST a form body)
//
// NO REFRESH TOKEN — Meta's classic OAuth does not hand out one the
// way Google/Dropbox/HubSpot do. Instead a short-lived user access
// token (from the code exchange above) is traded for a LONG-LIVED
// token (~60 days) via the same endpoint with grant_type=
// fb_exchange_token — this is Meta's own documented mechanism (Access
// Tokens for Meta Technologies), stable across API versions for a
// decade. ConnectorSyncSweepService stores and uses that long-lived
// token directly; there is nothing to "refresh" it into on this
// classic-OAuth path — a workspace whose long-lived token finally
// expires (~60 days of total inactivity) simply needs to reconnect,
// same failure mode connector_service.dart's `error` status already
// exists to surface.

import 'dart:convert';
import 'package:http/http.dart' as http;

class MetaOAuthService {
  const MetaOAuthService({
    required this.appId,
    required this.appSecret,
    required this.redirectUri,
  });

  final String appId;
  final String appSecret;
  final String redirectUri;

  static const _authBaseUrl = 'https://www.facebook.com/v25.0/dialog/oauth';
  static const _tokenUrl = 'https://graph.facebook.com/v25.0/oauth/access_token';

  /// instagram_shop's scope — enough to read the shoppable product tags
  /// on a connected Instagram professional account's catalog.
  static const scopeInstagramBasic = 'instagram_basic';
  static const scopeCatalogManagement = 'catalog_management';

  /// facebook_catalog additionally needs to see which Pages/Business
  /// Manager assets the token can act on, not just the catalog itself.
  static const scopePagesShowList = 'pages_show_list';
  static const scopeBusinessManagement = 'business_management';

  String authorizationUrl({required String state, required List<String> scopes}) {
    final uri = Uri.parse(_authBaseUrl).replace(queryParameters: {
      'client_id': appId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes.join(','),
      'state': state,
    });
    return uri.toString();
  }

  /// Step 1 — trades the authorization code for a SHORT-lived user
  /// access token. Deliberately not the last step of the flow; see
  /// [exchangeForLongLivedToken] and this file's header.
  Future<Map<String, dynamic>> exchangeCode(String code) async {
    final uri = Uri.parse(_tokenUrl).replace(queryParameters: {
      'client_id': appId,
      'redirect_uri': redirectUri,
      'client_secret': appSecret,
      'code': code,
    });
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Meta token exchange failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Step 2 — trades the short-lived token from [exchangeCode] for a
  /// long-lived one (~60 days). Called immediately after step 1 in the
  /// callback route, never deferred — see this file's header on why
  /// there is no separate "refresh" call later the way Google/Dropbox
  /// have one.
  Future<Map<String, dynamic>> exchangeForLongLivedToken(
    String shortLivedToken,
  ) async {
    final uri = Uri.parse(_tokenUrl).replace(queryParameters: {
      'grant_type': 'fb_exchange_token',
      'client_id': appId,
      'client_secret': appSecret,
      'fb_exchange_token': shortLivedToken,
    });
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Meta long-lived token exchange failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
