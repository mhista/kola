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
import 'package:kola_server/src/services/connectors/google/google_calendar_service.dart';
import 'package:kola_server/src/services/connectors/google/google_drive_service.dart';
import 'package:kola_server/src/services/connectors/google/google_sheets_config.dart';
import 'package:kola_server/src/services/connectors/microsoft/microsoft_oauth_service.dart';
import 'package:kola_server/src/services/connectors/microsoft/microsoft_graph_excel_service.dart';
import 'package:kola_server/src/services/connectors/dropbox/dropbox_oauth_service.dart';
import 'package:kola_server/src/services/connectors/hubspot/hubspot_oauth_service.dart';
import 'package:kola_server/src/services/connectors/meta/meta_oauth_service.dart';
import 'package:kola_server/src/services/repository/calendar_booking_repository.dart';
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
  GoogleCalendarService get _googleCalendar => const GoogleCalendarService();
  GoogleDriveService get _googleDrive => const GoogleDriveService();
  CalendarBookingRepository get _bookings => getIt<CalendarBookingRepository>();
  DropboxOAuthService get _dropboxOAuth => DropboxOAuthService(
        clientId: Env.dropboxClientId,
        clientSecret: Env.dropboxClientSecret,
        redirectUri: Env.dropboxRedirectUri,
      );
  HubSpotOAuthService get _hubspotOAuth => HubSpotOAuthService(
        clientId: Env.hubspotClientId,
        clientSecret: Env.hubspotClientSecret,
        redirectUri: Env.hubspotRedirectUri,
      );
  MetaOAuthService get _metaOAuth => MetaOAuthService(
        appId: Env.metaAppId,
        appSecret: Env.metaAppSecret,
        redirectUri: Env.metaOAuthRedirectUri,
      );

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

  /// Connect Gate, subphase 4d — every Google Sheets spreadsheet the
  /// CONNECTED account can see, for the dashboard's picker. This is what
  /// [setGoogleSheetTarget]'s old doc comment said didn't exist yet ("the
  /// heavier Picker API, deliberately not built for this pass") — it's
  /// simpler than Google's own Picker widget: a plain Drive files.list
  /// call under drive.metadata.readonly (see google_drive_service.dart),
  /// requested alongside the Sheets scope specifically so this becomes
  /// possible. [alreadyConnected] is computed against this workspace's
  /// current selection so the dashboard can pre-check rows without a
  /// second round trip.
  ///
  /// Throws [GoogleSheetsReconnectRequiredException]-shaped KolaException
  /// for a workspace that connected BEFORE this scope existed — their
  /// stored refresh token has no Drive grant, so Google will 403 this
  /// call until they reconnect. See this file's header on why that's
  /// surfaced as a clear "reconnect" message, not a raw API error.
  Future<List<GoogleDriveSpreadsheet>> listGoogleSheets(
    Session session,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final existing = await _stored.findByWorkspaceAndKey(workspaceId, connectorKey);
    if (existing == null || existing.status != 'connected' || existing.encryptedConfig == null) {
      throw KolaException(message: 'Connect with Google before choosing sheets.');
    }

    final config = jsonDecode(
      ChannelCredentialEncryptionService.decrypt(existing.encryptedConfig!),
    ) as Map<String, dynamic>;
    final refreshToken = config['refreshToken'] as String?;
    if (refreshToken == null) {
      throw KolaException(message: 'This connection is missing its sign-in — reconnect Google Sheets.');
    }

    final tokens = await _googleOAuth.refreshAccessToken(refreshToken);
    final oauthAccessToken = tokens['access_token'] as String?;
    if (oauthAccessToken == null) {
      throw KolaException(message: 'Google did not return a valid access token — try reconnecting.');
    }

    final currentIds = GoogleSheetsConfig.spreadsheetIdsFrom(config).toSet();

    try {
      final files = await _googleDrive.listSpreadsheets(accessToken: oauthAccessToken);
      return files
          .map((f) => GoogleDriveSpreadsheet(
                id: f.id,
                name: f.name,
                webViewLink: f.webViewLink,
                alreadyConnected: currentIds.contains(f.id),
              ))
          .toList();
    } catch (e) {
      // A connection made before drive.metadata.readonly existed has no
      // Drive grant on its stored refresh token — Google 403s this call
      // specifically, not the Sheets read itself. See this file's header.
      Log.warning('ConnectorEndpoint.listGoogleSheets: Drive list failed for workspace $workspaceId: $e');
      throw KolaException(
        message: 'Kolaa can\'t list your spreadsheets yet — reconnect Google Sheets to grant access '
            'to your Drive file list (your existing sheets keep syncing either way).',
      );
    }
  }

  /// Connect Gate, subphase 4d — REPLACES the full set of spreadsheets a
  /// CONNECTED Google Sheets integration reads, in one call — what the
  /// picker's "Save" button calls after an owner checks/unchecks rows
  /// from [listGoogleSheets]. An empty list is valid: it means "sync
  /// nothing", not an error — same as never having picked a sheet at all
  /// under the old single-target flow.
  Future<ConnectorStatus> setGoogleSheetTargets(
    Session session,
    String accessToken,
    int workspaceId,
    String connectorKey,
    List<String> spreadsheetIds,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _requireWorkspace(workspaceId);
    final existing = await _stored.findByWorkspaceAndKey(workspaceId, connectorKey);
    if (existing == null || existing.status != 'connected' || existing.encryptedConfig == null) {
      throw KolaException(message: 'Connect with Google before choosing sheets.');
    }

    final config = jsonDecode(
      ChannelCredentialEncryptionService.decrypt(existing.encryptedConfig!),
    ) as Map<String, dynamic>;
    final nextConfig = GoogleSheetsConfig.withSpreadsheetIds(config, spreadsheetIds);
    final reencrypted = ChannelCredentialEncryptionService.encrypt(jsonEncode(nextConfig));

    await _stored.upsert(
      workspaceId: workspaceId,
      connectorKey: connectorKey,
      status: 'connected',
      encryptedConfig: reencrypted,
      displayDetail: _sheetsDisplayDetail(spreadsheetIds),
      lastSyncedAt: existing.lastSyncedAt,
    );

    Log.info('Google Sheets targets set for workspace $workspaceId: ${spreadsheetIds.length} sheet(s)');
    return _one(workspace, connectorKey);
  }

  /// Kept for any caller still on the old single-sheet flow (a paste box
  /// as a fallback next to the picker, or an older dashboard build) —
  /// ADDS [sheetUrl] to whatever's already selected rather than
  /// replacing it, since a paste box has no way to express "and keep the
  /// others too" the way the picker's checkbox list does.
  Future<ConnectorStatus> setGoogleSheetTarget(
    Session session,
    String accessToken,
    int workspaceId,
    String connectorKey,
    String sheetUrl,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final existing = await _stored.findByWorkspaceAndKey(workspaceId, connectorKey);
    if (existing == null || existing.status != 'connected' || existing.encryptedConfig == null) {
      throw KolaException(message: 'Connect with Google before choosing a sheet.');
    }

    final spreadsheetId = _extractSpreadsheetId(sheetUrl);
    if (spreadsheetId == null) {
      throw KolaException(
        message:         'That does not look like a Google Sheets URL. Paste the link from '
        'your browser\'s address bar while the sheet is open.',
      );
    }

    final config = jsonDecode(
      ChannelCredentialEncryptionService.decrypt(existing.encryptedConfig!),
    ) as Map<String, dynamic>;
    final current = GoogleSheetsConfig.spreadsheetIdsFrom(config);
    final next = {...current, spreadsheetId}.toList();

    return setGoogleSheetTargets(session, accessToken, workspaceId, connectorKey, next);
  }

  static String _sheetsDisplayDetail(List<String> spreadsheetIds) {
    if (spreadsheetIds.isEmpty) return 'Connected — no sheet chosen yet';
    if (spreadsheetIds.length == 1) {
      final id = spreadsheetIds.first;
      return 'Sheet: ${id.substring(0, id.length.clamp(0, 8))}…';
    }
    return '${spreadsheetIds.length} sheets connected';
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

  /// Fix-properly pass — the Dropbox twin of [startGoogleOAuth]. Same
  /// state-signing contract, no scope list: Dropbox's OAuth app
  /// permissions are configured once on the App Console (a fixed
  /// "scope" per app, not requested per-authorize-call the way Google/
  /// Meta scopes are), so there is no per-connector scope lookup to
  /// fail on the way [_googleScopesFor]/[_microsoftScopesFor] can.
  Future<String> startDropboxOAuth(
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
      throw KolaException(message: '${def.name} is not available on this workspace yet.');
    }
    if (def.auth != ConnectorAuth.oauth || connectorKey != 'dropbox') {
      throw KolaException(message: '${def.name} does not use Dropbox sign-in.');
    }

    final state = ChannelCredentialEncryptionService.encrypt(jsonEncode({
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String(),
    }));

    return _dropboxOAuth.authorizationUrl(state: state);
  }

  /// Fix-properly pass — the HubSpot twin of [startGoogleOAuth].
  Future<String> startHubSpotOAuth(
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
      throw KolaException(message: '${def.name} is not available on this workspace yet.');
    }
    if (def.auth != ConnectorAuth.oauth || connectorKey != 'hubspot') {
      throw KolaException(message: '${def.name} does not use HubSpot sign-in.');
    }

    final state = ChannelCredentialEncryptionService.encrypt(jsonEncode({
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String(),
    }));

    return _hubspotOAuth.authorizationUrl(
      state: state,
      scopes: const [HubSpotOAuthService.scopeContactsRead],
    );
  }

  /// Fix-properly pass — the Meta twin of [startGoogleOAuth], shared by
  /// BOTH instagram_shop and facebook_catalog (one Meta App — see
  /// meta_oauth_service.dart's header). [_metaScopesFor] is what tells
  /// the two connectors apart.
  Future<String> startMetaOAuth(
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
      throw KolaException(message: '${def.name} is not available on this workspace yet.');
    }
    if (def.auth != ConnectorAuth.oauth) {
      throw KolaException(message: '${def.name} does not use Meta sign-in.');
    }

    final scopes = _metaScopesFor(connectorKey);
    if (scopes == null) {
      throw KolaException(message: 'No Meta scope is defined for "$connectorKey" yet.');
    }

    final state = ChannelCredentialEncryptionService.encrypt(jsonEncode({
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String(),
    }));

    return _metaOAuth.authorizationUrl(state: state, scopes: scopes);
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

  /// Gate 4 — sets whether a bot-proposed calendar booking is created on
  /// Google immediately, or held as a pending row an owner must approve
  /// first. See calendar_booking.spy.yaml's header on why this exists:
  /// Calendar is the first write-capable connector, and this is the
  /// owner's own guardrail on it, not a fixed platform decision.
  /// [bookingMode] must be 'draft' or 'immediate'. Read back by
  /// bookCalendarEvent (builtin_errand_executor.dart), which treats an
  /// UNSET value (a connection made before this setting existed, or one
  /// never touched) as 'draft' — the safer default, never 'immediate'
  /// by omission.
  Future<ConnectorStatus> setCalendarBookingMode(
    Session session,
    String accessToken,
    int workspaceId,
    String bookingMode,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    if (bookingMode != 'draft' && bookingMode != 'immediate') {
      throw KolaException(message: 'bookingMode must be "draft" or "immediate".');
    }

    final workspace = await _requireWorkspace(workspaceId);
    final existing = await _stored.findByWorkspaceAndKey(workspaceId, 'google_calendar');
    if (existing == null || existing.status != 'connected' || existing.encryptedConfig == null) {
      throw KolaException(message: 'Connect Google Calendar before setting this.');
    }

    final config = jsonDecode(
      ChannelCredentialEncryptionService.decrypt(existing.encryptedConfig!),
    ) as Map<String, dynamic>;
    config['bookingMode'] = bookingMode;
    final reencrypted = ChannelCredentialEncryptionService.encrypt(jsonEncode(config));

    await _stored.upsert(
      workspaceId: workspaceId,
      connectorKey: 'google_calendar',
      status: 'connected',
      encryptedConfig: reencrypted,
      displayDetail: 'Connected — $bookingMode bookings',
      lastSyncedAt: existing.lastSyncedAt,
    );

    Log.info('Calendar booking mode set for workspace $workspaceId: $bookingMode');
    return _one(workspace, 'google_calendar');
  }

  /// Gate 4 — every booking this workspace's bot(s) have proposed that
  /// still needs an owner's yes/no. Draft-mode bookings only — a
  /// workspace running in immediate mode never accumulates any of these,
  /// since bookCalendarEvent skips straight to Google for them.
  Future<List<CalendarBooking>> listPendingBookings(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _bookings.listPending(workspaceId);
  }

  /// Approves a pending booking: marks it 'approved', creates the real
  /// Google Calendar event, then marks it 'booked' with the real event
  /// id. If the Google call itself fails (token revoked, etc.), the
  /// booking is left sitting at 'approved' rather than silently reverted
  /// — visibly stuck, matching migration 042's own reasoning for why
  /// 'approved' and 'booked' are distinct states, not one.
  Future<CalendarBooking> approveBooking(
    Session session,
    String accessToken,
    int workspaceId,
    int bookingId,
  ) async {
    final member = await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final booking = await _bookings.findById(workspaceId, bookingId);
    if (booking == null) {
      throw KolaException(message: 'Booking not found.');
    }
    if (booking.status != 'pending') {
      throw KolaException(message: 'This booking has already been resolved.');
    }

    final connector = await _stored.findByWorkspaceAndKey(workspaceId, 'google_calendar');
    if (connector == null || connector.encryptedConfig == null) {
      throw KolaException(message: 'Google Calendar is not connected for this workspace.');
    }
    final config = jsonDecode(
      ChannelCredentialEncryptionService.decrypt(connector.encryptedConfig!),
    ) as Map<String, dynamic>;
    final refreshToken = config['refreshToken'] as String?;
    if (refreshToken == null) {
      throw KolaException(message: 'This Google Calendar connection is missing its sign-in — reconnect and try again.');
    }

    await _bookings.markApproved(bookingId, resolvedByEmail: member.userId);

    final tokens = await _googleOAuth.refreshAccessToken(refreshToken);
    final googleAccessToken = tokens['access_token'] as String?;
    if (googleAccessToken == null) {
      throw KolaException(message: 'Google did not return a valid access token. The booking is approved but not yet on the calendar — try again shortly.');
    }

    final eventId = await _googleCalendar.createEvent(
      accessToken: googleAccessToken,
      title: booking.title,
      description: booking.description,
      startsAt: booking.startsAt,
      endsAt: booking.endsAt,
      attendeeEmail: booking.attendeeEmail,
    );

    Log.info('Calendar booking $bookingId approved and booked (workspace $workspaceId, event $eventId)');
    return _bookings.markBooked(bookingId, googleEventId: eventId);
  }

  Future<CalendarBooking> rejectBooking(
    Session session,
    String accessToken,
    int workspaceId,
    int bookingId,
  ) async {
    final member = await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final booking = await _bookings.findById(workspaceId, bookingId);
    if (booking == null) {
      throw KolaException(message: 'Booking not found.');
    }
    if (booking.status != 'pending') {
      throw KolaException(message: 'This booking has already been resolved.');
    }

    Log.info('Calendar booking $bookingId rejected (workspace $workspaceId)');
    return _bookings.markRejected(bookingId, resolvedByEmail: member.userId);
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
        // Connect Gate, subphase 4d — drive.metadata.readonly rides
        // along with the Sheets grant so the dashboard can list the
        // account's spreadsheets for a picker, instead of requiring a
        // pasted link. See google_drive_service.dart's header.
        'google_sheets' => const [
            GoogleOAuthService.scopeSheetsReadonly,
            GoogleOAuthService.scopeDriveMetadataReadonly,
          ],
        'google_calendar' => const [GoogleOAuthService.scopeCalendarEvents],
        // Gate 11 — see google_oauth_service.dart's scopeDriveReadonly
        // doc comment on why this is a broader, SEPARATE grant from
        // google_sheets' own drive.metadata.readonly, not a reuse of it.
        'google_drive' => const [GoogleOAuthService.scopeDriveReadonly],
        _ => null,
      };

  /// Which Microsoft Graph scope a connector's OAuth grant should
  /// request — the Microsoft-provider twin of [_googleScopesFor], same
  /// reasoning.
  static List<String>? _microsoftScopesFor(String connectorKey) => switch (connectorKey) {
        'onedrive_excel' => const [MicrosoftOAuthService.scopeFilesReadWrite],
        _ => null,
      };

  /// Fix-properly pass — which Meta permission(s) a connector's OAuth
  /// grant should request. Both instagram_shop and facebook_catalog
  /// share ONE Meta App (one client_id/secret — see meta_oauth_service
  /// .dart's header) but request DIFFERENT scopes, because they read
  /// different data: instagram_shop only ever needs the Instagram-side
  /// catalog tags, facebook_catalog needs the Business Manager/Pages
  /// surface a Facebook catalog actually lives under.
  static List<String>? _metaScopesFor(String connectorKey) => switch (connectorKey) {
        'instagram_shop' => const [
            MetaOAuthService.scopeInstagramBasic,
            MetaOAuthService.scopeCatalogManagement,
          ],
        'facebook_catalog' => const [
            MetaOAuthService.scopeCatalogManagement,
            MetaOAuthService.scopePagesShowList,
            MetaOAuthService.scopeBusinessManagement,
          ],
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
