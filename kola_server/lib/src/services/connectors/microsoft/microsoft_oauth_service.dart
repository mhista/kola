// microsoft_oauth_service.dart — Gate 4. Second OAuth provider in this
// codebase, same generic-over-[scopes] shape as GoogleOAuthService (see
// that file's header) — one flow, more scopes/adapters later, not a
// third implementation of the same plumbing.
//
// FETCHED AND READ BEFORE WRITING, NOT RECONSTRUCTED FROM MEMORY — see
// this codebase's own "read real docs before connecting" rule. Sources:
//   https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow
//   https://learn.microsoft.com/en-us/graph/api/shares-get
//   https://learn.microsoft.com/en-us/graph/api/worksheet-usedrange
//
// WHY TENANT 'organizations', NOT 'common': the Excel workbook API this
// connector depends on (worksheet usedRange, see
// microsoft_graph_excel_service.dart) is DOCUMENTED as "Not supported"
// for delegated personal Microsoft accounts — it only works for work/
// school (Microsoft 365) accounts. 'common' would let a business owner
// sign in with a personal @outlook.com account, complete the whole
// consent flow, and then have every sync fail with a confusing Graph
// error. 'organizations' has Microsoft itself refuse a personal account
// at the sign-in screen instead — a clearer failure, earlier.
//
// WHY offline_access IS A REQUESTED SCOPE HERE, UNLIKE GOOGLE: Google
// issues a refresh token via a URL PARAMETER (access_type=offline).
// Microsoft's v2.0 endpoint issues one only if the app explicitly asks
// for the offline_access SCOPE — there is no equivalent query parameter.
// Both achieve the same thing (this connector's unattended sweep needs a
// refresh token, not just a short-lived access token) via each
// provider's own real mechanism.
//
// PLAIN HTTPS, NOT MSAL: same convention as GoogleOAuthService and every
// other provider wrapper in this codebase — no third-party SDK with its
// own token cache and its own opinions about storage.

import 'dart:convert';
import 'package:http/http.dart' as http;

class MicrosoftOAuthService {
  const MicrosoftOAuthService({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    this.tenant = 'organizations',
  });

  final String clientId;
  final String clientSecret;
  final String redirectUri;

  /// 'organizations' (work/school accounts only) by default — see this
  /// file's header on why 'common' would let a personal account sign in
  /// only to fail later. Configurable per instance rather than a bare
  /// constant so a future single-tenant deployment can pin its own GUID
  /// without a code change.
  final String tenant;

  String get _authBaseUrl =>
      'https://login.microsoftonline.com/$tenant/oauth2/v2.0/authorize';
  String get _tokenUrl =>
      'https://login.microsoftonline.com/$tenant/oauth2/v2.0/token';

  /// Least-privileged permission actually documented to work for both
  /// Graph calls this connector makes — /shares/{..}/driveItem and
  /// /workbook/worksheets/{..}/usedRange. Both endpoints' own permission
  /// tables list Files.ReadWrite with no Files.Read alternative, so
  /// asking for less would fail at Graph, not just at the consent
  /// screen — see this file's header for the fetched sources.
  static const scopeFilesReadWrite = 'Files.ReadWrite';

  /// Must be requested on every authorize AND refresh call for Microsoft
  /// to keep issuing/honouring a refresh token — see this file's header.
  static const _scopeOfflineAccess = 'offline_access';

  /// The URL to redirect the owner's browser to. [state] must be an
  /// opaque, server-signed value the callback route can verify — same
  /// contract as GoogleOAuthService.authorizationUrl, see
  /// ConnectorEndpoint.startMicrosoftOAuth for how it's built.
  String authorizationUrl({required String state, required List<String> scopes}) {
    final uri = Uri.parse(_authBaseUrl).replace(queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'response_mode': 'query',
      'scope': [...scopes, _scopeOfflineAccess].join(' '),
      // Forces re-consent even for an account that connected before, so
      // a reconnect after a revoked grant still yields a fresh refresh
      // token rather than silently getting none — same reasoning as
      // Google's prompt=consent.
      'prompt': 'consent',
      'state': state,
    });
    return uri.toString();
  }

  /// Exchanges an authorization [code] for an access token + refresh
  /// token. [scopes] must match what [authorizationUrl] requested —
  /// Microsoft's token endpoint wants the scope restated here too,
  /// unlike Google's.
  Future<Map<String, dynamic>> exchangeCode(String code, {required List<String> scopes}) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'scope': [...scopes, _scopeOfflineAccess].join(' '),
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Microsoft token exchange failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Trades a stored refresh token for a fresh, short-lived access
  /// token. Same "never cache an access token across sync runs"
  /// discipline as GoogleOAuthService.refreshAccessToken.
  Future<Map<String, dynamic>> refreshAccessToken(
    String refreshToken, {
    required List<String> scopes,
  }) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'refresh_token',
        'scope': [...scopes, _scopeOfflineAccess].join(' '),
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Microsoft token refresh failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
