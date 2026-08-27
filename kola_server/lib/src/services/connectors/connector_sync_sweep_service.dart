// connector_sync_sweep_service.dart — Gate 4. The loop that actually
// calls ConnectorAdapter.sync on a schedule, for every pull-based
// connector this contract has. Two adapters today (Paystack,
// Flutterwave) sharing one loop via [_sweepGateway] — written to add a
// call per connector rather than one service per connector, same "the
// framework does the looping, the adapter does the provider-specific
// work" split as ChannelHealthCheckService already draws for the
// channel store.
//
// WHY A PLAIN TIMER, NOT A SERVERPOD FUTURECALL: same reasoning as
// trial_sweep_service.dart's header — Serverpod Mini has no Postgres of
// its own (Supabase is the only persistence layer), and FutureCall's own
// scheduling state is normally persisted in Serverpod's database. A
// Timer.periodic inside the same long-running process needs no
// infrastructure this project doesn't already have.
//
// WHY EVERY WORKSPACE'S PAYSTACK CREDENTIAL, EVERY RUN, RATHER THAN A
// QUEUE: at this stage the number of workspaces with a payment gateway
// connected is small, and ConnectorRetry + per-credential try/catch
// already isolate one workspace's failure from every other's — the same
// "loop everyone, isolate failures" shape ChannelHealthCheckService and
// TrialSweepService both already use. Revisit with a real queue once
// connected-workspace count makes a single sweep pass too slow to finish
// inside its own interval — not before, per this codebase's own
// no-speculative-infrastructure discipline.

import 'dart:convert';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/billing/paystack_service.dart';
import 'package:kola_server/src/services/billing/flutterwave_service.dart';
import 'package:kola_server/src/services/repository/payment_gateway_credential_repository.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/repository/connector_sync_log_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/connector_retry.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';
import 'package:kola_server/src/services/connectors/paystack_adapter.dart';
import 'package:kola_server/src/services/connectors/flutterwave_adapter.dart';
import 'package:kola_server/src/services/connectors/google/google_oauth_service.dart';
import 'package:kola_server/src/services/connectors/google/google_sheets_adapter.dart';
import 'package:kola_server/src/services/connectors/google/google_sheets_config.dart';
import 'package:kola_server/src/services/connectors/google/google_drive_adapter.dart';
import 'package:kola_server/src/services/connectors/microsoft/microsoft_oauth_service.dart';
import 'package:kola_server/src/services/connectors/microsoft/onedrive_excel_adapter.dart';
import 'package:kola_server/src/services/connectors/bumpa/bumpa_service.dart';
import 'package:kola_server/src/services/connectors/bumpa/bumpa_adapter.dart';

class ConnectorSyncSweepService {
  ConnectorSyncSweepService({
    required PaymentGatewayCredentialRepository gatewayCredentials,
    required WorkspaceConnectorRepository genericConnectors,
    required ConnectorSyncLogRepository syncLog,
  })  : _gatewayCredentials = gatewayCredentials,
        _genericConnectors = genericConnectors,
        _syncLog = syncLog;

  final PaymentGatewayCredentialRepository _gatewayCredentials;
  final WorkspaceConnectorRepository _genericConnectors;
  final ConnectorSyncLogRepository _syncLog;

  /// Runs every registered pull-based adapter for every workspace
  /// connected to it. Returns how many workspace-connector pairs synced
  /// without error, for server.dart's own startup/interval log line —
  /// same "make an empty or failing sweep visible, not silently fine"
  /// discipline as TrialSweepService.sweepOnce.
  Future<int> sweepOnce() async {
    var succeeded = 0;
    succeeded += await _sweepGateway(
      gateway: 'paystack',
      buildAdapter: (workspaceId, secretKey) => PaystackAdapter(
        workspaceId: workspaceId,
        service: PaystackService(secretKey: secretKey),
      ),
    );
    succeeded += await _sweepGateway(
      gateway: 'flutterwave',
      buildAdapter: (workspaceId, secretKey) => FlutterwaveAdapter(
        workspaceId: workspaceId,
        service: FlutterwaveService(secretKey: secretKey),
      ),
    );
    succeeded += await _sweepGoogleSheets();
    succeeded += await _sweepGoogleDrive();
    succeeded += await _sweepOneDriveExcel();
    succeeded += await _sweepBumpa();
    return succeeded;
  }

  /// The generic store's shape is different enough from a payment
  /// gateway's single-secret credential (a JSON config carrying BOTH a
  /// refresh token AND a chosen spreadsheet id — see
  /// ConnectorEndpoint.setGoogleSheetTarget) that this stays its own
  /// method rather than being forced through [_sweepGateway]'s
  /// single-string abstraction. A second generic-store adapter (Drive,
  /// Calendar) gets its own method here too, for the same reason.
  Future<int> _sweepGoogleSheets() async {
    final connectors = await _genericConnectors.listAllByKey('google_sheets');
    if (connectors.isEmpty) return 0;

    Log.info('ConnectorSyncSweepService: syncing ${connectors.length} Google Sheets connection(s)...');
    var succeeded = 0;
    final oauth = GoogleOAuthService(
      clientId: Env.googleOAuthClientId,
      clientSecret: Env.googleOAuthClientSecret,
      redirectUri: Env.googleOAuthRedirectUri,
    );

    for (final connector in connectors) {
      final workspaceId = connector.workspaceId;
      if (connector.encryptedConfig == null) continue;

      try {
        final config = jsonDecode(
          ChannelCredentialEncryptionService.decrypt(connector.encryptedConfig!),
        ) as Map<String, dynamic>;
        final refreshToken = config['refreshToken'] as String?;
        // Connect Gate, subphase 4d — a workspace can have MORE THAN ONE
        // sheet connected now; GoogleSheetsConfig reads the new plural
        // key and falls back to the old singular one transparently, so
        // a workspace that never touched the picker keeps syncing
        // exactly as before. See that file's header.
        final spreadsheetIds = GoogleSheetsConfig.spreadsheetIdsFrom(config);
        if (refreshToken == null || spreadsheetIds.isEmpty) {
          // Connected via OAuth but no sheet chosen yet — see
          // ConnectorEndpoint.setGoogleSheetTargets. Not an error; just
          // nothing to sync until the owner picks one.
          continue;
        }

        // One SyncResult per sheet, summed into a single sync-run record
        // for this connector row — the dashboard's connector card shows
        // one row per CONNECTOR, not one per sheet, so its totals need
        // to already be the sum, not the last sheet's numbers.
        var recordsSeen = 0;
        var recordsChanged = 0;
        final errors = <String>[];
        String? lastCursor;
        var anySucceeded = false;

        for (final spreadsheetId in spreadsheetIds) {
          try {
            final adapter = GoogleSheetsAdapter(
              workspaceId: workspaceId,
              refreshToken: refreshToken,
              spreadsheetId: spreadsheetId,
              oauth: oauth,
            );

            final result = await ConnectorRetry.run<SyncResult>(
              () => adapter.sync(),
              deadLetter: _syncLog,
              workspaceId: workspaceId,
              connectorKey: 'google_sheets',
              store: 'generic',
              kind: 'sync',
            );

            recordsSeen += result.recordsSeen;
            recordsChanged += result.recordsChanged;
            if (result.errors.isNotEmpty) {
              errors.addAll(result.errors.map((e) => '[$spreadsheetId] $e'));
            }
            if (!result.nextCursor.isEmpty) {
              lastCursor = result.nextCursor.value as String?;
            }
            anySucceeded = true;
          } catch (e) {
            // One bad sheet (deleted, made private, malformed) must not
            // stop the rest of this workspace's sheets from syncing —
            // same "isolate failures" posture ConnectorRetry already
            // applies across WORKSPACES, extended here across SHEETS
            // within one workspace.
            errors.add('[$spreadsheetId] $e');
            Log.warning('ConnectorSyncSweepService: Google Sheets $spreadsheetId failed for workspace $workspaceId: $e');
          }
        }

        await _genericConnectors.recordSyncRun(
          workspaceId: workspaceId,
          connectorKey: 'google_sheets',
          cursor: lastCursor ?? connector.syncCursor,
          syncedAt: DateTime.now(),
          recordsSeen: recordsSeen,
          recordsChanged: recordsChanged,
          errorCount: errors.length,
        );

        await _syncLog.record(
          workspaceId: workspaceId,
          connectorKey: 'google_sheets',
          store: 'generic',
          kind: 'sync',
          success: errors.isEmpty,
          recordsSeen: recordsSeen,
          recordsChanged: recordsChanged,
          errorMessage: errors.isEmpty ? null : errors.join('; '),
        );

        if (recordsChanged > 0) {
          Log.info(
            'ConnectorSyncSweepService: workspace $workspaceId Google Sheets '
            '(${spreadsheetIds.length} sheet(s)) — $recordsSeen seen, $recordsChanged changed',
          );
        }
        if (anySucceeded) succeeded++;
      } catch (e) {
        Log.error('ConnectorSyncSweepService: Google Sheets sync failed for workspace $workspaceId', error: e);
      }
    }

    return succeeded;
  }

  /// Gate 11 — google_drive's own sweep. Simpler than
  /// [_sweepGoogleSheets]: no per-target loop (GoogleDriveAdapter syncs
  /// every eligible file it can see in one call — see that adapter's own
  /// header on why there's no picker step to loop over), so this is
  /// closer in shape to [_sweepOneDriveExcel] with a config that's just
  /// {refreshToken}, no target ids at all.
  Future<int> _sweepGoogleDrive() async {
    final connectors = await _genericConnectors.listAllByKey('google_drive');
    if (connectors.isEmpty) return 0;

    Log.info('ConnectorSyncSweepService: syncing ${connectors.length} Google Drive connection(s)...');
    var succeeded = 0;
    final oauth = GoogleOAuthService(
      clientId: Env.googleOAuthClientId,
      clientSecret: Env.googleOAuthClientSecret,
      redirectUri: Env.googleOAuthRedirectUri,
    );

    for (final connector in connectors) {
      final workspaceId = connector.workspaceId;
      if (connector.encryptedConfig == null) continue;

      try {
        final config = jsonDecode(
          ChannelCredentialEncryptionService.decrypt(connector.encryptedConfig!),
        ) as Map<String, dynamic>;
        final refreshToken = config['refreshToken'] as String?;
        if (refreshToken == null) continue; // shouldn't happen — set at connect time

        final adapter = GoogleDriveAdapter(
          workspaceId: workspaceId,
          refreshToken: refreshToken,
          oauth: oauth,
        );

        final result = await ConnectorRetry.run<SyncResult>(
          () => adapter.sync(),
          deadLetter: _syncLog,
          workspaceId: workspaceId,
          connectorKey: 'google_drive',
          store: 'generic',
          kind: 'sync',
        );

        await _genericConnectors.recordSyncRun(
          workspaceId: workspaceId,
          connectorKey: 'google_drive',
          cursor: result.nextCursor.isEmpty ? connector.syncCursor : result.nextCursor.value as String?,
          syncedAt: DateTime.now(),
          recordsSeen: result.recordsSeen,
          recordsChanged: result.recordsChanged,
          errorCount: result.errors.length,
        );

        await _syncLog.record(
          workspaceId: workspaceId,
          connectorKey: 'google_drive',
          store: 'generic',
          kind: 'sync',
          success: !result.hadErrors,
          recordsSeen: result.recordsSeen,
          recordsChanged: result.recordsChanged,
          errorMessage: result.hadErrors ? result.errors.join('; ') : null,
        );

        if (result.recordsChanged > 0) {
          Log.info(
            'ConnectorSyncSweepService: workspace $workspaceId Google Drive — '
            '${result.recordsSeen} seen, ${result.recordsChanged} changed',
          );
        }
        succeeded++;
      } catch (e) {
        Log.error('ConnectorSyncSweepService: Google Drive sync failed for workspace $workspaceId', error: e);
      }
    }

    return succeeded;
  }

  /// The Microsoft-provider twin of [_sweepGoogleSheets] — same generic-
  /// store reasoning, same reason it stays its own method rather than
  /// going through [_sweepGateway]: config here is {refreshToken,
  /// driveId, itemId}, not one secret string.
  Future<int> _sweepOneDriveExcel() async {
    final connectors = await _genericConnectors.listAllByKey('onedrive_excel');
    if (connectors.isEmpty) return 0;

    Log.info('ConnectorSyncSweepService: syncing ${connectors.length} OneDrive Excel connection(s)...');
    var succeeded = 0;
    final oauth = MicrosoftOAuthService(
      clientId: Env.microsoftOAuthClientId,
      clientSecret: Env.microsoftOAuthClientSecret,
      redirectUri: Env.microsoftOAuthRedirectUri,
      tenant: Env.microsoftOAuthTenant,
    );

    for (final connector in connectors) {
      final workspaceId = connector.workspaceId;
      if (connector.encryptedConfig == null) continue;

      try {
        final config = jsonDecode(
          ChannelCredentialEncryptionService.decrypt(connector.encryptedConfig!),
        ) as Map<String, dynamic>;
        final refreshToken = config['refreshToken'] as String?;
        final driveId = config['driveId'] as String?;
        final itemId = config['itemId'] as String?;
        if (refreshToken == null || driveId == null || itemId == null) {
          // Connected via OAuth but no file chosen yet — see
          // ConnectorEndpoint.setExcelFileTarget. Not an error; just
          // nothing to sync until the owner picks one.
          continue;
        }

        final adapter = OneDriveExcelAdapter(
          workspaceId: workspaceId,
          refreshToken: refreshToken,
          driveId: driveId,
          itemId: itemId,
          oauth: oauth,
        );

        final result = await ConnectorRetry.run<SyncResult>(
          () => adapter.sync(),
          deadLetter: _syncLog,
          workspaceId: workspaceId,
          connectorKey: 'onedrive_excel',
          store: 'generic',
          kind: 'sync',
        );

        await _genericConnectors.recordSyncRun(
          workspaceId: workspaceId,
          connectorKey: 'onedrive_excel',
          cursor: result.nextCursor.isEmpty ? connector.syncCursor : result.nextCursor.value as String?,
          syncedAt: DateTime.now(),
          recordsSeen: result.recordsSeen,
          recordsChanged: result.recordsChanged,
          errorCount: result.errors.length,
        );

        await _syncLog.record(
          workspaceId: workspaceId,
          connectorKey: 'onedrive_excel',
          store: 'generic',
          kind: 'sync',
          success: !result.hadErrors,
          recordsSeen: result.recordsSeen,
          recordsChanged: result.recordsChanged,
          errorMessage: result.hadErrors ? result.errors.join('; ') : null,
        );

        if (result.recordsChanged > 0) {
          Log.info(
            'ConnectorSyncSweepService: workspace $workspaceId OneDrive Excel — '
            '${result.recordsSeen} seen, ${result.recordsChanged} changed',
          );
        }
        succeeded++;
      } catch (e) {
        Log.error('ConnectorSyncSweepService: OneDrive Excel sync failed for workspace $workspaceId', error: e);
      }
    }

    return succeeded;
  }

  /// Bumpa's twin of [_sweepGoogleSheets]/[_sweepOneDriveExcel] — same
  /// reason it stays its own method rather than [_sweepGateway]'s
  /// single-secret-string shape: config here is {secretKey, publicKey},
  /// both required, neither one a substitute for the other — see
  /// bumpa_service.dart's header on why mixing them up fails loud
  /// rather than silently.
  Future<int> _sweepBumpa() async {
    final connectors = await _genericConnectors.listAllByKey('bumpa');
    if (connectors.isEmpty) return 0;

    Log.info('ConnectorSyncSweepService: syncing ${connectors.length} Bumpa connection(s)...');
    var succeeded = 0;

    for (final connector in connectors) {
      final workspaceId = connector.workspaceId;
      if (connector.encryptedConfig == null) continue;

      try {
        final config = jsonDecode(
          ChannelCredentialEncryptionService.decrypt(connector.encryptedConfig!),
        ) as Map<String, dynamic>;
        final secretKey = config['secretKey'] as String?;
        final publicKey = config['publicKey'] as String?;
        if (secretKey == null || publicKey == null) continue; // shouldn't happen — both are required fields at connect time

        final adapter = BumpaAdapter(
          workspaceId: workspaceId,
          service: BumpaService(secretKey: secretKey, publicKey: publicKey),
        );

        final result = await ConnectorRetry.run<SyncResult>(
          () => adapter.sync(),
          deadLetter: _syncLog,
          workspaceId: workspaceId,
          connectorKey: 'bumpa',
          store: 'generic',
          kind: 'sync',
        );

        await _genericConnectors.recordSyncRun(
          workspaceId: workspaceId,
          connectorKey: 'bumpa',
          cursor: result.nextCursor.isEmpty ? connector.syncCursor : result.nextCursor.value as String?,
          syncedAt: DateTime.now(),
          recordsSeen: result.recordsSeen,
          recordsChanged: result.recordsChanged,
          errorCount: result.errors.length,
        );

        await _syncLog.record(
          workspaceId: workspaceId,
          connectorKey: 'bumpa',
          store: 'generic',
          kind: 'sync',
          success: !result.hadErrors,
          recordsSeen: result.recordsSeen,
          recordsChanged: result.recordsChanged,
          errorMessage: result.hadErrors ? result.errors.join('; ') : null,
        );

        if (result.recordsChanged > 0) {
          Log.info(
            'ConnectorSyncSweepService: workspace $workspaceId Bumpa — '
            '${result.recordsSeen} seen, ${result.recordsChanged} changed',
          );
        }
        succeeded++;
      } catch (e) {
        Log.error('ConnectorSyncSweepService: Bumpa sync failed for workspace $workspaceId', error: e);
      }
    }

    return succeeded;
  }

  /// One credential store, one loop, any adapter — [buildAdapter] is the
  /// only thing that varies per gateway. Extracted after Flutterwave
  /// became the second implementation; a third pull-based payment
  /// gateway adapter needs only a new [_sweepGateway] call in
  /// [sweepOnce], not a third copy of this loop.
  Future<int> _sweepGateway({
    required String gateway,
    required ConnectorAdapter Function(int workspaceId, String secretKey) buildAdapter,
  }) async {
    final credentials = await _gatewayCredentials.listAllByGateway(gateway);
    if (credentials.isEmpty) return 0;

    Log.info('ConnectorSyncSweepService: syncing ${credentials.length} $gateway credential(s)...');
    var succeeded = 0;

    for (final credential in credentials) {
      final workspaceId = credential.workspaceId;
      try {
        final secretKey = ChannelCredentialEncryptionService.decrypt(credential.encryptedSecretKey);
        final adapter = buildAdapter(workspaceId, secretKey);

        final cursor = credential.syncCursor == null
            ? SyncCursor.none
            : SyncCursor(credential.syncCursor);

        final result = await ConnectorRetry.run<SyncResult>(
          () => adapter.sync(cursor: cursor),
          deadLetter: _syncLog,
          workspaceId: workspaceId,
          connectorKey: gateway,
          store: 'payment_gateway',
          kind: 'sync',
        );

        await _gatewayCredentials.updateSyncState(
          workspaceId: workspaceId,
          gateway: gateway,
          cursor: result.nextCursor.isEmpty ? credential.syncCursor : result.nextCursor.value as String?,
          syncedAt: DateTime.now(),
        );

        await _syncLog.record(
          workspaceId: workspaceId,
          connectorKey: gateway,
          store: 'payment_gateway',
          kind: 'sync',
          success: !result.hadErrors,
          recordsSeen: result.recordsSeen,
          recordsChanged: result.recordsChanged,
          errorMessage: result.hadErrors ? result.errors.join('; ') : null,
        );

        if (result.recordsChanged > 0) {
          Log.info(
            'ConnectorSyncSweepService: workspace $workspaceId $gateway — '
            '${result.recordsSeen} seen, ${result.recordsChanged} changed',
          );
        }
        succeeded++;
      } catch (e) {
        // ConnectorRetry.run already wrote the dead-letter row and
        // rethrew — this catch exists only so ONE workspace's exhausted
        // retries can't stop the rest of the sweep, same isolation
        // ChannelHealthCheckService's per-channel try/catch gives.
        Log.error('ConnectorSyncSweepService: $gateway sync failed for workspace $workspaceId', error: e);
      }
    }

    return succeeded;
  }
}
