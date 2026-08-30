// dropbox_oauth_callback_route.dart — fix-properly pass. The Dropbox
// twin of google_oauth_callback_route.dart. Same state-verification
// contract (see that file's header — it is the whole security model
// here too), same GET-not-POST reasoning, same one-route-for-every-
// workspace shape.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'dropbox_oauth_service.dart';

final _log = Logger('DropboxOAuthCallbackRoute');

class DropboxOAuthCallbackRoute extends Route {
  DropboxOAuthCallbackRoute() : super(methods: {Method.get});

  static const _dashboardIntegrationsPath = '/integrations';

  WorkspaceConnectorRepository get _stored => const WorkspaceConnectorRepository();
  DropboxOAuthService get _oauth => DropboxOAuthService(
        clientId: Env.dropboxClientId,
        clientSecret: Env.dropboxClientSecret,
        redirectUri: Env.dropboxRedirectUri,
      );

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final uri = request.url;
    final error = uri.queryParameters['error'];
    final code = uri.queryParameters['code'];
    final stateRaw = uri.queryParameters['state'];

    if (error != null) {
      return _redirectToDashboard(connected: false, reason: 'declined');
    }
    if (code == null || stateRaw == null) {
      _log.warning('Dropbox OAuth callback missing code or state');
      return _redirectToDashboard(connected: false, reason: 'invalid_callback');
    }

    Map<String, dynamic> state;
    try {
      state = jsonDecode(ChannelCredentialEncryptionService.decrypt(stateRaw))
          as Map<String, dynamic>;
    } catch (e) {
      _log.warning('Dropbox OAuth callback state failed to decrypt: $e');
      return _redirectToDashboard(connected: false, reason: 'invalid_state');
    }

    final expiresAt = DateTime.tryParse(state['expiresAt'] as String? ?? '');
    if (expiresAt == null || DateTime.now().toUtc().isAfter(expiresAt)) {
      _log.warning('Dropbox OAuth callback used an expired state');
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
        _log.warning(
          'Dropbox OAuth exchange returned no refresh_token for workspace $workspaceId',
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
        displayDetail: 'Connected',
      );

      _log.info('Dropbox OAuth connected: workspace=$workspaceId connector=$connectorKey');
      return _redirectToDashboard(connected: true, connectorKey: connectorKey);
    } catch (e, stackTrace) {
      _log.severe('Dropbox OAuth token exchange failed', e, stackTrace);
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
    return Response(302, headers: Headers.build((h) {
      h['location'] = [url.toString()];
    }));
  }
}
