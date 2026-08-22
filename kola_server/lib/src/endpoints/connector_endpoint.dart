// connector_endpoint.dart — Layer 3. The Integrations marketplace's
// only server surface.
//
// READ + CONNECT for the generic store. Deliberately NOT a second way to
// connect WhatsApp, Telegram, Paystack or Flutterwave: those already
// have endpoints with real domain behaviour attached — probe-before-
// persist, webhook registration, bot-registry bootstrap — and a parallel
// path into the same tables that skipped any of it would produce rows
// that look connected and do not work.
//
// So the marketplace ROUTES rather than duplicates:
//   store == channel         → ChannelEndpoint
//   store == paymentGateway  → PaymentEndpoint (design's authType
//                              'manage', linking to /billing)
//   store == generic         → here
//
// listConnectors covers all three, because reading is safe to unify and
// the page needs one list.

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/connectors/connector_catalog.dart';
import 'package:kola_server/src/services/connectors/connector_service.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/connectors/google/google_oauth_service.dart';
import 'package:kola_server/src/services/connectors/microsoft/microsoft_oauth_service.dart';
import 'package:kola_server/src/services/connectors/microsoft/microsoft_graph_excel_service.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/kola_logger.dart';

class ConnectorEndpoint extends Endpoint {
  ConnectorService get _connectors => getIt<ConnectorService>();
  WorkspaceConnectorRepository get _stored =>
      getIt<WorkspaceConnectorRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();
  GoogleOAuthService get _googleOAuth => GoogleOAuthService(
        clientId: Env.googleOAuthClientId,
        clientSecret: Env.googleOAuthClientSecret,
        redirectUri: Env.googleOAuthRedirectUri,
      );
  MicrosoftOAuthService get _microsoftOAuth => MicrosoftOAuthService(
        clientId: Env.microsoftOAuthClientId,
        clientSecret: Env.microsoftOAuthClientSecret,
        redirectUri: Env.microsoftOAuthRedirectUri,
        tenant: Env.microsoftOAuthTenant,
      );
  MicrosoftGraphExcelService get _microsoftExcel => const MicrosoftGraphExcelService();

  /// Every connector in the catalog with this workspace's state resolved
  /// onto it — all 16, always. A connector the workspace cannot use yet
  /// comes back as `soon` rather than being omitted, because the
  /// marketplace draws it either way.
  ///
  /// Unlike FeatureEndpoint.listEnabledFeatures, this DOES disclose the
  /// existence of unreleased capabilities — that is the design's
  /// coming-soon tile, and it is a deliberate exception to the
  /// absence-not-false rule rather than an oversight. The exception is
  /// narrow: connector names only. No flag key, no state, nothing about
  /// the rest of the roadmap.
  Future<List<ConnectorStatus>> listConnectors(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final workspace = await _requireWorkspace(workspaceId);
    return _connectors.listForWorkspace(workspace);
  }

  /// Connects a generic-store connector by storing the values from its
  /// catalog-defined form.
  ///
  /// [values] is keyed by ConnectorField.key. Anything not declared on
  /// the connector's own definition is DROPPED rather than stored —
  /// a caller cannot invent fields, so the encrypted blob's shape stays
  /// the one the catalog describes.
  Future<ConnectorStatus> connectConnector(
    Session session,
    String accessToken,
    int workspaceId,
    String connectorKey,
    Map<String, String> values,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final workspace = await _requireWorkspace(workspaceId);
    final def = ConnectorCatalog.byKey(connectorKey);
    if (def == null) {
      throw KolaException(message: 'Unknown connector "$connectorKey".');
    }

    // GATE ON THE FLAG. Without this, a caller who knows a connector key
    // could connect a capability that has not been released to them —
    // which would make the coming-soon tile the only thing standing
    // between a workspace and an unreleased feature. That is UI, not a
    // control.
    //
    // This is also the gap PaymentEndpoint.connectGateway still has: it
    // checks workspace access and nothing else, so payments.collect
    // being locked does not actually stop a gateway being connected.
    // Recorded in DESIGN_DELTA.md — fix it there too.
    if (!await _features.isEnabled(def.featureKey, workspace)) {
      throw KolaException(
        message:         '${def.name} is not available on this workspace yet.',
      );
    }

    if (def.store != ConnectorStore.generic) {
      throw KolaException(
        message:         '${def.name} is connected through its own flow, not here. '
        'See connector_endpoint.dart\'s header on why this does not '
        'duplicate ChannelEndpoint or PaymentEndpoint.',
      );
    }

    if (def.auth != ConnectorAuth.fields) {
      throw KolaException(
        message:         '${def.name} uses ${_authLabel(def.auth)} and cannot be connected '
        'by submitting fields.',
      );
    }

    // Only declared fields, and every required one present.
    final accepted = <String, String>{};
    for (final field in def.fields) {
      final value = values[field.key]?.trim();
      if (value == null || value.isEmpty) {
        throw KolaException(message: '${field.label} is required.');
      }
      accepted[field.key] = value;
    }

    // Encrypted as one blob with the SAME service used for channel
    // tokens and gateway keys — AES-256-GCM, 24 existing call sites. Do
    // not add a second encryption service; one already exists.
    final encrypted = ChannelCredentialEncryptionService.encrypt(
      _encodeConfig(accepted),
    );

    // The safe-to-show half: the first NON-SECRET field the owner will
    // recognise — a store URL, an account id. Never a secret, since this
    // is read straight onto the connector card.
    //
    // Written as a loop rather than .firstOrNull because that extension
    // comes from package:collection, which kola_server does not declare
    // as a dependency.
    String? detail;
    for (final field in def.fields) {
      if (field.secret) continue;
      final value = accepted[field.key];
      if (value != null && value.isNotEmpty) {
        detail = value;
        break;
      }
    }

    await _stored.upsert(
      workspaceId: workspaceId,
      connectorKey: connectorKey,
      status: 'connected',
      encryptedConfig: encrypted,
      displayDetail: detail,
      lastSyncedAt: DateTime.now().toUtc(),
    );

    Log.info('Connector $connectorKey connected for workspace $workspaceId');
    return _one(workspace, connectorKey);
  }

  /// Gate 4 — the URL to redirect the owner's browser to, for a
  /// connector whose auth type is 'oauth'. The dashboard opens this
  /// directly (a real browser redirect, not an API call the client can
  /// inspect); GoogleOAuthCallbackRoute is where the flow lands back.
  Future<String> startGoogleOAuth(
    Session session,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _requireWorkspace(workspaceId);
    final def = ConnectorCatalog.byKey(connectorKey);
    if (def == null) {
      throw KolaException(message: 'Unknown connector "$connectorKey".');
    }
    if (!await _features.isEnabled(def.featureKey, workspace)) {
      throw KolaException(
        message:         '${def.name} is not available on this workspace yet.',
      );
    }
    if (def.auth != ConnectorAuth.oauth) {
      throw KolaException(
        message:         '${def.name} does not use Google sign-in.',
      );
    }

    final scopes = _googleScopesFor(connectorKey);
    if (scopes == null) {
      throw KolaException(
        message:         'No Google scope is defined for "$connectorKey" yet.',
      );
    }

    // The state parameter is this flow's ONLY defence against a forged
    // callback — Google returns it unmodified, so it must carry enough
    // to prove WHICH workspace asked, and enough to prove IT was the
    // one that asked (not a value guessed or replayed). Encrypting a
    // JSON payload with the same AES service every other credential in
    // this codebase already uses gets both: opaque to read, and
    // impossible to forge without the master key.
    final state = ChannelCredentialEncryptionService.encrypt(jsonEncode({
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      // Bounds how long an issued-but-unused consent URL stays valid —
      // an owner who opens the link, gets distracted, and clicks it a
      // week later should re-start rather than complete a stale flow.
      'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String(),
    }));

    return _googleOAuth.authorizationUrl(state: state, scopes: scopes);
  }

  /// Gate 4 — sets which spreadsheet a CONNECTED Google Sheets integration
  /// actually reads. Separate from the OAuth connect step because OAuth
  /// authorizes an ACCOUNT, not a specific file — Google has no "pick one
  /// sheet" step in the redirect flow itself (that needs the heavier
  /// Picker API, deliberately not built for this pass), so the owner
  /// pastes the sheet's URL after connecting instead.
  Future<ConnectorStatus> setGoogleSheetTarget(
    Session session,
    String accessToken,
    int workspaceId,
    String connectorKey,
    String sheetUrl,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _requireWorkspace(workspaceId);
    final existing = await _stored.findByWorkspaceAndKey(workspaceId, connectorKey);
    if (existing == null || existing.status != 'connected' || existing.encryptedConfig == null) {
      throw KolaException(
        message:         'Connect with Google before choosing a sheet.',
      );
    }

    final spreadsheetId = _extractSpreadsheetId(sheetUrl);
    if (spreadsheetId == null) {
      throw KolaException(
        message:         'That does not look like a Google Sheets URL. Paste the link from '
        'your browser\'s address bar while the sheet is open.',
      );
    }

    // The stored config already holds the refresh token, under a JSON
    // key set by GoogleOAuthCallbackRoute — decrypt, add spreadsheetId
    // alongside it, re-encrypt as one blob. Never touches the refresh
    // token itself.
    final config = jsonDecode(
      ChannelCredentialEncryptionService.decrypt(existing.encryptedConfig!),
    ) as Map<String, dynamic>;
    config['spreadsheetId'] = spreadsheetId;
    final reencrypted = ChannelCredentialEncryptionService.encrypt(jsonEncode(config));

    await _stored.upsert(
      workspaceId: workspaceId,
      connectorKey: connectorKey,
      status: 'connected',
      encryptedConfig: reencrypted,
      displayDetail: 'Sheet: ${spreadsheetId.substring(0, spreadsheetId.length.clamp(0, 8))}…',
      lastSyncedAt: existing.lastSyncedAt,
    );

    Log.info('Google Sheets target set for workspace $workspaceId: $spreadsheetId');
    return _one(workspace, connectorKey);
  }

  /// Gate 4 — the Microsoft-provider twin of [startGoogleOAuth]. Same
  /// state-signing contract, one real difference: [scopes] is embedded
  /// in the encrypted state too, because
  /// MicrosoftOAuthCallbackRoute.handleCall needs to restate the exact
  /// same scope string on the token exchange (Microsoft's token endpoint
  /// requires it; Google's does not — see microsoft_oauth_service.dart's
  /// header).
  Future<String> startMicrosoftOAuth(
    Session session,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _requireWorkspace(workspaceId);
    final def = ConnectorCatalog.byKey(connectorKey);
    if (def == null) {
      throw KolaException(message: 'Unknown connector "$connectorKey".');
    }
    if (!await _features.isEnabled(def.featureKey, workspace)) {
      throw KolaException(
        message:         '${def.name} is not available on this workspace yet.',
      );
    }
    if (def.auth != ConnectorAuth.oauth) {
      throw KolaException(
        message:         '${def.name} does not use Microsoft sign-in.',
      );
    }

    final scopes = _microsoftScopesFor(connectorKey);
    if (scopes == null) {
      throw KolaException(
        message:         'No Microsoft scope is defined for "$connectorKey" yet.',
      );
    }

    final state = ChannelCredentialEncryptionService.encrypt(jsonEncode({
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'scopes': scopes,
      'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String(),
    }));

    return _microsoftOAuth.authorizationUrl(state: state, scopes: scopes);
  }

  /// Gate 4 — the OneDrive/SharePoint twin of [setGoogleSheetTarget].
  /// UNLIKE that method, this one makes a real Graph call: a sharing URL
  /// carries no stable id the way a Google Sheets URL does, so the
  /// pasted link has to be resolved into a (driveId, itemId) pair via
  /// MicrosoftGraphExcelService.resolveShareUrl BEFORE anything is
  /// stored — see that method's header. Doing this here rather than at
  /// sync time means a bad link fails LOUD, in front of the owner who
  /// just pasted it, not silently on the next unattended sweep run.
  Future<ConnectorStatus> setExcelFileTarget(
    Session session,
    String accessToken,
    int workspaceId,
    String connectorKey,
    String fileUrl,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _requireWorkspace(workspaceId);
    final existing = await _stored.findByWorkspaceAndKey(workspaceId, connectorKey);
    if (existing == null || existing.status != 'connected' || existing.encryptedConfig == null) {
      throw KolaException(
        message:         'Connect with Microsoft before choosing a file.',
      );
    }

    final config = jsonDecode(
      ChannelCredentialEncryptionService.decrypt(existing.encryptedConfig!),
    ) as Map<String, dynamic>;
    final refreshToken = config['refreshToken'] as String?;
    if (refreshToken == null) {
      throw KolaException(
        message:         'This connection is missing its Microsoft sign-in — reconnect and try again.',
      );
    }

    final tokens = await _microsoftOAuth.refreshAccessToken(
      refreshToken,
      scopes: const [MicrosoftOAuthService.scopeFilesReadWrite],
    );
    final graphAccessToken = tokens['access_token'] as String?;
    if (graphAccessToken == null) {
      throw KolaException(
        message:         'Microsoft did not return a valid access token. Reconnect and try again.',
      );
    }

    final resolved = await _microsoftExcel.resolveShareUrl(
      shareUrl: fileUrl.trim(),
      accessToken: graphAccessToken,
    );

    config['driveId'] = resolved.driveId;
    config['itemId'] = resolved.itemId;
    final reencrypted = ChannelCredentialEncryptionService.encrypt(jsonEncode(config));

    await _stored.upsert(
      workspaceId: workspaceId,
      connectorKey: connectorKey,
      status: 'connected',
      encryptedConfig: reencrypted,
      displayDetail: 'File: ${resolved.name}',
      lastSyncedAt: existing.lastSyncedAt,
    );

    Log.info('OneDrive Excel target set for workspace $workspaceId: ${resolved.name}');
    return _one(workspace, connectorKey);
  }

  /// Disconnects, clearing the stored credential but keeping the row —
  /// 'disconnected' and "never connected" are different states, and the
  /// row is the only record that this business ever had it working.
  Future<ConnectorStatus> disconnectConnector(
    Session session,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final workspace = await _requireWorkspace(workspaceId);
    final def = ConnectorCatalog.byKey(connectorKey);
    if (def == null) {
      throw KolaException(message: 'Unknown connector "$connectorKey".');
    }
    if (def.store != ConnectorStore.generic) {
      throw KolaException(
        message:         '${def.name} is disconnected through its own flow, not here.',
      );
    }

    await _stored.disconnect(workspaceId, connectorKey);
    Log.info('Connector $connectorKey disconnected for workspace $workspaceId');
    return _one(workspace, connectorKey);
  }

  // ── Private ──────────────────────────────────────────────────────────

  Future<Workspace> _requireWorkspace(int workspaceId) async {
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
    }
    return workspace;
  }

  /// Re-reads through the same merge the list uses, so a connect
  /// response and a subsequent refresh can never disagree about the
  /// state of the thing just connected.
  Future<ConnectorStatus> _one(Workspace workspace, String connectorKey) async {
    final all = await _connectors.listForWorkspace(workspace);
    return all.firstWhere((c) => c.key == connectorKey);
  }

  /// JSON encoding of the accepted field map, for the encrypted blob.
  ///
  /// Uses dart:convert. An earlier version of this file hand-rolled the
  /// escaping and got it wrong on the very first line — a credential
  /// containing a quote or a backslash would have produced a blob that
  /// decrypted successfully and then failed to parse, which is the worst
  /// shape of bug: the data is intact and unreadable.
  static String _encodeConfig(Map<String, String> values) =>
      jsonEncode(values);

  /// Which Google scope a connector's OAuth grant should request. A
  /// lookup table, not a field on ConnectorDefinition — scopes are an
  /// OAuth-flow detail, not part of the marketplace's own catalog shape,
  /// and this is the ONLY place in the codebase that needs to know one.
  static List<String>? _googleScopesFor(String connectorKey) => switch (connectorKey) {
        'google_sheets' => const [GoogleOAuthService.scopeSheetsReadonly],
        _ => null, // google_drive/google_calendar join this once their adapters exist
      };

  /// Which Microsoft Graph scope a connector's OAuth grant should
  /// request — the Microsoft-provider twin of [_googleScopesFor], same
  /// reasoning.
  static List<String>? _microsoftScopesFor(String connectorKey) => switch (connectorKey) {
        'onedrive_excel' => const [MicrosoftOAuthService.scopeFilesReadWrite],
        _ => null,
      };

  /// Pulls the spreadsheet id out of any of Google's own URL shapes —
  /// `.../spreadsheets/d/<id>/edit#gid=0`, with or without a trailing
  /// path, with or without query params. A raw id pasted with no URL at
  /// all also matches (Sheets ids are exactly this shape: letters,
  /// digits, `-`, `_`), which is a deliberate mercy for an owner who
  /// copied the id instead of the whole address bar.
  static String? _extractSpreadsheetId(String input) {
    final trimmed = input.trim();
    final urlMatch = RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (urlMatch != null) return urlMatch.group(1);
    if (RegExp(r'^[a-zA-Z0-9_-]{20,}$').hasMatch(trimmed)) return trimmed;
    return null;
  }

  static String _authLabel(ConnectorAuth auth) => switch (auth) {
        ConnectorAuth.fields => 'a form',
        ConnectorAuth.oauth => 'sign-in with the provider',
        ConnectorAuth.manage => 'settings elsewhere in kola',
        ConnectorAuth.keyDisplay => 'a key you paste into the other product',
        ConnectorAuth.whatsapp => 'the WhatsApp setup flow',
      };
}
