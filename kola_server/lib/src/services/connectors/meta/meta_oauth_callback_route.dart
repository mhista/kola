// meta_oauth_callback_route.dart — fix-properly pass. ONE route for
// BOTH instagram_shop and facebook_catalog — `connectorKey` (carried
// through `state`, same as every other provider) is what tells this
// route which catalog entry to store the result against, same as
// GoogleOAuthCallbackRoute serving google_sheets/drive/calendar through
// one route.
//
// Stores an ACCESS token, not a refresh token — see meta_oauth_
// service.dart's header on why Meta's classic OAuth has no refresh
// token to store here.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'meta_oauth_service.dart';

final _log = Logger('MetaOAuthCallbackRoute');

class MetaOAuthCallbackRoute extends Route {
  MetaOAuthCallbackRoute() : super(methods: {Method.get});

  static const _dashboardIntegrationsPath = '/integrations';

  WorkspaceConnectorRepository get _stored => const WorkspaceConnectorRepository();
  MetaOAuthService get _oauth => MetaOAuthService(
        appId: Env.metaAppId,
        appSecret: Env.metaAppSecret,
        redirectUri: Env.metaOAuthRedirectUri,
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
      _log.warning('Meta OAuth callback missing code or state');
      return _redirectToDashboard(connected: false, reason: 'invalid_callback');
    }

    Map<String, dynamic> state;
    try {
      state = jsonDecode(ChannelCredentialEncryptionService.decrypt(stateRaw))
          as Map<String, dynamic>;
    } catch (e) {
      _log.warning('Meta OAuth callback state failed to decrypt: $e');
      return _redirectToDashboard(connected: false, reason: 'invalid_state');
    }

    final expiresAt = DateTime.tryParse(state['expiresAt'] as String? ?? '');
    if (expiresAt == null || DateTime.now().toUtc().isAfter(expiresAt)) {
      _log.warning('Meta OAuth callback used an expired state');
      return _redirectToDashboard(connected: false, reason: 'expired');
    }

    final workspaceId = state['workspaceId'] as int?;
    final connectorKey = state['connectorKey'] as String?;
    if (workspaceId == null || connectorKey == null) {
      return _redirectToDashboard(connected: false, reason: 'invalid_state');
    }

    try {
      final shortLived = await _oauth.exchangeCode(code);
      final shortLivedToken = shortLived['access_token'] as String?;
      if (shortLivedToken == null) {
        _log.warning(
          'Meta OAuth exchange returned no access_token for workspace $workspaceId',
        );
        return _redirectToDashboard(connected: false, reason: 'exchange_failed');
      }

      final longLived = await _oauth.exchangeForLongLivedToken(shortLivedToken);
      final accessToken = longLived['access_token'] as String?;
      if (accessToken == null) {
        _log.warning(
          'Meta long-lived token exchange returned nothing for workspace $workspaceId',
        );
        return _redirectToDashboard(connected: false, reason: 'exchange_failed');
      }

      final config = jsonEncode({'accessToken': accessToken});
      final encrypted = ChannelCredentialEncryptionService.encrypt(config);

      await _stored.upsert(
        workspaceId: workspaceId,
        connectorKey: connectorKey,
        status: 'connected',
        encryptedConfig: encrypted,
        displayDetail: 'Connected',
      );

      _log.info('Meta OAuth connected: workspace=$workspaceId connector=$connectorKey');
      return _redirectToDashboard(connected: true, connectorKey: connectorKey);
    } catch (e, stackTrace) {
      _log.severe('Meta OAuth token exchange failed', e, stackTrace);
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
