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
import 'package:kola_server/kola_logger.dart';

class ConnectorEndpoint extends Endpoint {
  ConnectorService get _connectors => getIt<ConnectorService>();
  WorkspaceConnectorRepository get _stored =>
      getIt<WorkspaceConnectorRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();

  /// Every connector in the catalog with this workspace's state resolved
  /// onto it — all 15, always. A connector the workspace cannot use yet
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
      throw Exception('Unknown connector "$connectorKey".');
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
      throw Exception(
        '${def.name} is not available on this workspace yet.',
      );
    }

    if (def.store != ConnectorStore.generic) {
      throw Exception(
        '${def.name} is connected through its own flow, not here. '
        'See connector_endpoint.dart\'s header on why this does not '
        'duplicate ChannelEndpoint or PaymentEndpoint.',
      );
    }

    if (def.auth != ConnectorAuth.fields) {
      throw Exception(
        '${def.name} uses ${_authLabel(def.auth)} and cannot be connected '
        'by submitting fields.',
      );
    }

    // Only declared fields, and every required one present.
    final accepted = <String, String>{};
    for (final field in def.fields) {
      final value = values[field.key]?.trim();
      if (value == null || value.isEmpty) {
        throw Exception('${field.label} is required.');
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
      throw Exception('Unknown connector "$connectorKey".');
    }
    if (def.store != ConnectorStore.generic) {
      throw Exception(
        '${def.name} is disconnected through its own flow, not here.',
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
      throw Exception('Workspace $workspaceId not found.');
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

  static String _authLabel(ConnectorAuth auth) => switch (auth) {
        ConnectorAuth.fields => 'a form',
        ConnectorAuth.oauth => 'sign-in with the provider',
        ConnectorAuth.manage => 'settings elsewhere in kola',
        ConnectorAuth.keyDisplay => 'a key you paste into the other product',
        ConnectorAuth.whatsapp => 'the WhatsApp setup flow',
      };
}
