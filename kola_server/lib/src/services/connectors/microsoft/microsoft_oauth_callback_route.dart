// microsoft_oauth_callback_route.dart — Gate 4. Where Microsoft's
// redirect lands after an owner grants (or denies) consent. Same shape,
// same reasoning, as google_oauth_callback_route.dart — read that file's
// header first; this one only calls out where Microsoft's flow differs.
//
// STATE VERIFICATION IS THE WHOLE SECURITY MODEL HERE, IDENTICALLY TO
// GOOGLE'S ROUTE: [ConnectorEndpoint.startMicrosoftOAuth] encrypts
// {workspaceId, connectorKey, expiresAt} into `state`, Microsoft returns
// it unmodified, and decrypting it here (same AES service) is what
// proves the callback belongs to a flow kolaa itself started.
//
// ONE ROUTE FOR EVERY WORKSPACE AND EVERY MICROSOFT-BACKED CONNECTOR —
// today only OneDrive/SharePoint Excel, but a second Microsoft Graph
// connector (Outlook Calendar, say) would land here too, disambiguated
// by `state`'s own connectorKey, exactly like the Google route already
// is future-proofed for Drive/Calendar.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'microsoft_oauth_service.dart';

final _log = Logger('MicrosoftOAuthCallbackRoute');

class MicrosoftOAuthCallbackRoute extends Route {
  MicrosoftOAuthCallbackRoute() : super(methods: {Method.get});

  static const _dashboardIntegrationsPath = '/integrations';

  WorkspaceConnectorRepository get _stored => const WorkspaceConnectorRepository();
  MicrosoftOAuthService get _oauth => MicrosoftOAuthService(
        clientId: Env.microsoftOAuthClientId,
        clientSecret: Env.microsoftOAuthClientSecret,
        redirectUri: Env.microsoftOAuthRedirectUri,
        tenant: Env.microsoftOAuthTenant,
      );

  @override
  Future<Result> handleCall(Session session, Request request) async {
    // VERIFIED AGAINST RELIC'S REAL SOURCE — same fix as
    // GoogleOAuthCallbackRoute: no `requestedUri` getter exists on
    // Relic's Request; the query-string-bearing property is `request.url`.
    final uri = request.url;
    // Microsoft's own error param is 'error' + 'error_description', same
    // query-param name Google uses for the "owner declined" case — one
    // check covers both providers' cancel path.
    final error = uri.queryParameters['error'];
    final code = uri.queryParameters['code'];
    final stateRaw = uri.queryParameters['state'];

    if (error != null) {
      return _redirectToDashboard(connected: false, reason: 'declined');
    }
    if (code == null || stateRaw == null) {
      _log.warning('Microsoft OAuth callback missing code or state');
      return _redirectToDashboard(connected: false, reason: 'invalid_callback');
    }

    Map<String, dynamic> state;
    try {
      state = jsonDecode(ChannelCredentialEncryptionService.decrypt(stateRaw))
          as Map<String, dynamic>;
    } catch (e) {
      _log.warning('Microsoft OAuth callback state failed to decrypt: $e');
      return _redirectToDashboard(connected: false, reason: 'invalid_state');
    }

    final expiresAt = DateTime.tryParse(state['expiresAt'] as String? ?? '');
    if (expiresAt == null || DateTime.now().toUtc().isAfter(expiresAt)) {
      _log.warning('Microsoft OAuth callback used an expired state');
      return _redirectToDashboard(connected: false, reason: 'expired');
    }

    final workspaceId = state['workspaceId'] as int?;
    final connectorKey = state['connectorKey'] as String?;
    final scopes = (state['scopes'] as List<dynamic>?)?.cast<String>();
    if (workspaceId == null || connectorKey == null || scopes == null) {
      return _redirectToDashboard(connected: false, reason: 'invalid_state');
    }

    try {
      final tokens = await _oauth.exchangeCode(code, scopes: scopes);
      final refreshToken = tokens['refresh_token'] as String?;
      if (refreshToken == null) {
        _log.warning(
          'Microsoft OAuth exchange returned no refresh_token for workspace $workspaceId',
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
        // No driveId/itemId yet — ConnectorEndpoint.setExcelFileTarget is
        // the next step. Unlike Google Sheets' equivalent step (a pure
        // regex against the pasted URL), resolving a OneDrive/SharePoint
        // sharing link needs a real Graph call — see
        // MicrosoftGraphExcelService.resolveShareUrl's header — which is
        // why it happens in that endpoint, not here.
        displayDetail: 'Signed in — choose a file',
      );

      _log.info('Microsoft OAuth connected: workspace=$workspaceId connector=$connectorKey');
      return _redirectToDashboard(connected: true, connectorKey: connectorKey);
    } catch (e, stackTrace) {
      _log.severe('Microsoft OAuth token exchange failed', e, stackTrace);
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
    // VERIFIED AGAINST RELIC'S REAL SOURCE — same fix as
    // GoogleOAuthCallbackRoute._redirectToDashboard: `headers` takes a
    // `Headers?`, built via Headers.build(...), not a bare Map.
    return Response(302, headers: Headers.build((h) {
      h['location'] = [url.toString()];
    }));
  }
}
