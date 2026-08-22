// google_oauth_callback_route.dart — Gate 4. Where Google's redirect
// lands after an owner grants (or denies) consent. GET, not POST — this
// is the browser navigating back, not a server-to-server webhook, which
// is why this route (unlike every payment webhook route in this
// codebase) ends by REDIRECTING the browser rather than returning JSON.
//
// STATE VERIFICATION IS THE WHOLE SECURITY MODEL HERE: Google's
// authorization code alone proves nothing about which kolaa workspace
// should receive it — [ConnectorEndpoint.startGoogleOAuth] encrypted
// {workspaceId, connectorKey, expiresAt} into `state` before handing the
// consent URL to the browser, and Google returns that exact value
// unmodified. Decrypting it here (same AES service every other
// credential in this codebase already uses) is what proves the
// callback corresponds to a flow kolaa itself started, for the
// workspace it started it for, within the window it was valid for.
//
// ONE ROUTE FOR EVERY WORKSPACE AND EVERY GOOGLE-BACKED CONNECTOR — same
// shape as the payment webhook routes: Google's OAuth redirect URI is
// registered ONCE per OAuth client, not per workspace, so `state` (not
// the URL) is what disambiguates.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'google_oauth_service.dart';

final _log = Logger('GoogleOAuthCallbackRoute');

class GoogleOAuthCallbackRoute extends Route {
  GoogleOAuthCallbackRoute() : super(methods: {Method.get});

  static const _dashboardIntegrationsPath = '/integrations';

  WorkspaceConnectorRepository get _stored => const WorkspaceConnectorRepository();
  GoogleOAuthService get _oauth => GoogleOAuthService(
        clientId: Env.googleOAuthClientId,
        clientSecret: Env.googleOAuthClientSecret,
        redirectUri: Env.googleOAuthRedirectUri,
      );

  @override
  Future<Result> handleCall(Session session, Request request) async {
    // VERIFIED AGAINST RELIC'S REAL SOURCE (same fix already documented in
    // whatsapp_webhook_route.dart's header): there is no `requestedUri`
    // getter on Relic's Request — the query-string-bearing property is
    // `request.url` ("full original URI").
    final uri = request.url;
    final error = uri.queryParameters['error'];
    final code = uri.queryParameters['code'];
    final stateRaw = uri.queryParameters['state'];

    if (error != null) {
      // The owner clicked "Cancel" on Google's own consent screen —
      // not a bug, not worth logging as one.
      return _redirectToDashboard(connected: false, reason: 'declined');
    }
    if (code == null || stateRaw == null) {
      _log.warning('Google OAuth callback missing code or state');
      return _redirectToDashboard(connected: false, reason: 'invalid_callback');
    }

    Map<String, dynamic> state;
    try {
      state = jsonDecode(ChannelCredentialEncryptionService.decrypt(stateRaw))
          as Map<String, dynamic>;
    } catch (e) {
      _log.warning('Google OAuth callback state failed to decrypt: $e');
      return _redirectToDashboard(connected: false, reason: 'invalid_state');
    }

    final expiresAt = DateTime.tryParse(state['expiresAt'] as String? ?? '');
    if (expiresAt == null || DateTime.now().toUtc().isAfter(expiresAt)) {
      _log.warning('Google OAuth callback used an expired state');
      return _redirectToDashboard(connected: false, reason: 'expired');
    }

    final workspaceId = state['workspaceId'] as int?;
    final connectorKey = state['connectorKey'] as String?;
    if (workspaceId == null || connectorKey == null) {
      return _redirectToDashboard(connected: false, reason: 'invalid_state');
    }

    try {
      final tokens = await _oauth.exchangeCode(code);
      final refreshToken = tokens['refresh_token'] as String?;
      if (refreshToken == null) {
        // Happens if the owner had already granted consent before and
        // Google didn't consider this a first-consent exchange despite
        // prompt=consent — extremely rare, but a reconnect must fail
        // loud rather than silently store nothing to refresh with.
        _log.warning(
          'Google OAuth exchange returned no refresh_token for workspace $workspaceId',
        );
        return _redirectToDashboard(connected: false, reason: 'no_refresh_token');
      }

      final config = jsonEncode({'refreshToken': refreshToken});
      final encrypted = ChannelCredentialEncryptionService.encrypt(config);

      await _stored.upsert(
        workspaceId: workspaceId,
        connectorKey: connectorKey,
        status: 'connected',
        encryptedConfig: encrypted,
        // No spreadsheetId yet — ConnectorEndpoint.setGoogleSheetTarget
        // is the next step, prompted by the dashboard once it sees this
        // connector come back 'connected' with no sheet chosen.
        displayDetail: 'Signed in — choose a sheet',
      );

      _log.info('Google OAuth connected: workspace=$workspaceId connector=$connectorKey');
      return _redirectToDashboard(connected: true, connectorKey: connectorKey);
    } catch (e, stackTrace) {
      _log.severe('Google OAuth token exchange failed', e, stackTrace);
      return _redirectToDashboard(connected: false, reason: 'exchange_failed');
    }
  }

  Result _redirectToDashboard({
    required bool connected,
    String? connectorKey,
    String? reason,
  }) {
    final params = {
      if (connected) 'connected': connectorKey ?? 'true' else 'error': reason ?? 'unknown',
    };
    final url = Uri.parse('${Env.dashboardBaseUrl}$_dashboardIntegrationsPath')
        .replace(queryParameters: params.isEmpty ? null : params);
    // VERIFIED AGAINST RELIC'S REAL SOURCE: Response's `headers` parameter
    // takes a `Headers?`, not a bare `Map<String, String>` — same
    // Headers.build(...) constructor already proven in
    // lib/web/api_routes.dart's `_corsHeaders`. Header VALUES are
    // `List<String>`, even for a single value like this one.
    return Response(302, headers: Headers.build((h) {
      h['location'] = [url.toString()];
    }));
  }
}
