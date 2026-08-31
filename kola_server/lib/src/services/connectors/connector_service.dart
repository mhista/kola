// connector_service.dart — Layer 3. The merge behind the Integrations
// marketplace.
//
// Produces one ConnectorStatus per catalog entry by combining four
// sources that each answer a different question:
//
//   ConnectorCatalog      what this connector IS         (code)
//   FeatureFlagService    is it released to you          (feature_flags)
//   channels              is WhatsApp/Telegram connected
//   payment_gateway_...   is Paystack/Flutterwave/Stripe connected
//   workspace_connectors  is everything else connected
//
// ── WHY THE MERGE IS HERE AND NOT IN THE DASHBOARD ───────────────────
//
// The previous integrations page hardcoded its own connector list, so
// the server and the UI could disagree about what exists — and the UI
// always won, because it was the one drawing the screen. Doing it here
// also means the browser is never sent the catalog, the flag set and
// three storage shapes to recombine, which it would have to get right
// identically on every page.
//
// ── NO SECRET LEAVES THIS FILE ───────────────────────────────────────
//
// ConnectorStatus.displayDetail is a masked tail or an account name.
// Ciphertext, plaintext credentials and ConnectorField.secret values
// never appear in a response. The one place this file decrypts is to
// compute a masked tail for a payment gateway, matching the design's
// "Secret key: sk_live_••••••••3f2a" — and only the last four characters
// survive the function.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/connectors/connector_catalog.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/payment_gateway_credential_repository.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/repository/owner_notification_settings_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';

final _log = Logger('ConnectorService');

/// The four states the design renders. Strings rather than an enum
/// because they cross the wire — see connector_status.spy.yaml.
abstract class ConnectorStatusValue {
  static const soon = 'soon';
  static const available = 'available';
  static const connected = 'connected';
  static const error = 'error';
}

class ConnectorService {
  ConnectorService({
    required FeatureFlagService features,
    required BotRepository bots,
    required ChannelRepository channels,
    required PaymentGatewayCredentialRepository gateways,
    required WorkspaceConnectorRepository generic,
    required OwnerNotificationSettingsRepository ownerNotifications,
  })  : _features = features,
        _bots = bots,
        _channels = channels,
        _gateways = gateways,
        _generic = generic,
        _ownerNotifications = ownerNotifications;

  final FeatureFlagService _features;
  final BotRepository _bots;
  final ChannelRepository _channels;
  final PaymentGatewayCredentialRepository _gateways;
  final WorkspaceConnectorRepository _generic;
  // Fix-properly pass — slack's catalog entry is `manage`, not
  // `generic`-store-backed, but _resolve still needs SOME source of
  // truth for its status tile. This is that source: the same repository
  // the Settings page's Slack webhook form already reads and writes.
  final OwnerNotificationSettingsRepository _ownerNotifications;

  /// Every connector in the catalog, with this workspace's state
  /// resolved onto it. Always returns all 15 — a connector the
  /// workspace cannot use yet is `soon`, not absent, because the
  /// marketplace draws it either way.
  ///
  /// Sorted by how much the owner needs to care: error, connected,
  /// available, soon. Category grouping and filtering happen in the UI,
  /// which already has the category on every row.
  Future<List<ConnectorStatus>> listForWorkspace(Workspace workspace) async {
    final workspaceId = workspace.id;
    if (workspaceId == null) {
      throw ArgumentError('Workspace has no id — cannot list connectors.');
    }

    final enabled = await _features.enabledFeatures(workspace);

    // All three stores in parallel. Sequential reads here would be three
    // round trips before the page can draw anything, on connections
    // where one can be 400ms.
    final results = await Future.wait([
      _channelsForWorkspace(workspaceId),
      _gateways.listByWorkspace(workspaceId),
      _generic.listByWorkspace(workspaceId),
      _ownerNotifications.findByWorkspaceId(workspaceId),
    ]);

    final channels = results[0] as List<Channel>;
    final gateways = results[1] as List<PaymentGatewayCredential>;
    final stored = results[2] as List<WorkspaceConnector>;
    final ownerNotificationSettings =
        results[3] as OwnerNotificationSettings?;

    final byGateway = {for (final g in gateways) g.gateway: g};
    final byKey = {for (final s in stored) s.connectorKey: s};
    final byPlatform = <String, Channel>{};
    for (final c in channels) {
      // A workspace can have the same platform on several bots. The
      // connected one wins — the marketplace answers "is WhatsApp
      // working for this business", not "for this bot".
      final existing = byPlatform[c.platformType];
      if (existing == null || c.status == 'connected') {
        byPlatform[c.platformType] = c;
      }
    }

    final out = <ConnectorStatus>[];
    for (final def in ConnectorCatalog.all) {
      out.add(_resolve(
        def: def,
        enabled: enabled.contains(def.featureKey),
        channel: byPlatform[def.key],
        gateway: byGateway[def.key],
        stored: byKey[def.key],
        ownerNotificationSettings: ownerNotificationSettings,
      ));
    }

    out.sort((a, b) =>
        _sortRank(a.status).compareTo(_sortRank(b.status)));
    return out;
  }

  // ── Private ──────────────────────────────────────────────────────────

  ConnectorStatus _resolve({
    required ConnectorDefinition def,
    required bool enabled,
    Channel? channel,
    PaymentGatewayCredential? gateway,
    WorkspaceConnector? stored,
    OwnerNotificationSettings? ownerNotificationSettings,
  }) {
    final base = _describe(def);

    // NOT RELEASED → 'soon', and no stored detail is disclosed.
    //
    // This deliberately wins over stored state. `locked` is also the
    // kill-switch destination (RELEASE_PHASES.md §0), so a connector
    // whose capability has been pulled is NOT operating — reporting it
    // as 'connected' would be the false-fact failure. The cost is that a
    // previously-connected connector reads as 'soon' rather than
    // something more precise like 'paused'; the design has no fifth
    // state, and inventing one here would be inventing UI.
    if (!enabled) {
      return base..status = ConnectorStatusValue.soon;
    }

    // Slack is `store: generic` for catalog-grouping purposes (it isn't
    // a channel or a payment gateway) but its real state lives in
    // OwnerNotificationSettings, not workspace_connectors — see this
    // file's header and connector_catalog.dart's slack entry. Resolved
    // here, before the generic-store switch below, so a workspace that
    // has never touched Settings-Slack doesn't wrongly show "connected"
    // (or vice versa) by consulting the wrong table.
    if (def.key == 'slack') {
      final ready = ownerNotificationSettings != null &&
          ownerNotificationSettings.slackEnabled &&
          (ownerNotificationSettings.encryptedSlackWebhookUrl ?? '')
              .trim()
              .isNotEmpty;
      if (!ready) {
        return base..status = ConnectorStatusValue.available;
      }
      return base
        ..status = ConnectorStatusValue.connected
        ..displayDetail = 'Incoming webhook configured'
        ..lastSyncedAt = ownerNotificationSettings.updatedAt;
    }

    switch (def.store) {
      case ConnectorStore.channel:
        if (channel == null || channel.encryptedCredential == null) {
          return base..status = ConnectorStatusValue.available;
        }
        // channelId set on every remaining branch below — a business can
        // reconnect an 'error'/'disconnected' row (setCredential upserts
        // in place) or disconnect a live one, and both actions need the
        // real row id regardless of which of these three states it's in.
        base.channelId = channel.id;
        if (channel.status == 'disconnected') {
          return base
            ..status = ConnectorStatusValue.error
            ..lastError =
                'kola can no longer reach this channel. Reconnect to resume.'
            ..displayDetail = channel.displayName;
        }
        if (channel.status != 'connected') {
          // 'pending' — the row exists but the connect flow never
          // finished. Offerable, not broken.
          return base..status = ConnectorStatusValue.available;
        }
        return base
          ..status = ConnectorStatusValue.connected
          ..displayDetail = channel.displayName
          ..lastSyncedAt = channel.updatedAt;

      case ConnectorStore.paymentGateway:
        if (gateway == null) {
          return base..status = ConnectorStatusValue.available;
        }
        return base
          ..status = ConnectorStatusValue.connected
          ..displayDetail = _maskedSecret(gateway.encryptedSecretKey)
          ..lastSyncedAt = gateway.updatedAt;

      case ConnectorStore.generic:
        if (stored == null || stored.status == 'disconnected') {
          return base..status = ConnectorStatusValue.available;
        }
        if (stored.status == 'error') {
          return base
            ..status = ConnectorStatusValue.error
            ..lastError = stored.lastError
            ..displayDetail = stored.displayDetail
            ..lastSyncedAt = stored.lastSyncedAt;
        }
        return base
          ..status = ConnectorStatusValue.connected
          ..displayDetail = stored.displayDetail
          ..lastSyncedAt = stored.lastSyncedAt;
    }
  }

  /// The catalog half — everything true of a connector regardless of who
  /// is asking. [status] is overwritten by the caller.
  ConnectorStatus _describe(ConnectorDefinition def) {
    return ConnectorStatus(
      key: def.key,
      name: def.name,
      category: def.category,
      // Phase C of the agent architecture correction — see
      // connector_status.spy.yaml's header on why this is now on the
      // wire instead of only living in the catalog's own ConnectorStore.
      isChannel: def.store == ConnectorStore.channel,
      // Gate 4 — see connector_status.spy.yaml's own field comment.
      isPaymentGateway: def.store == ConnectorStore.paymentGateway,
      description: def.description,
      status: ConnectorStatusValue.soon,
      authType: _authName(def.auth),
      manageRoute: def.manageRoute,
      helpText: def.helpText,
      fields: [
        for (final f in def.fields)
          ConnectorFieldSpec(
            key: f.key,
            label: f.label,
            placeholder: f.placeholder,
            secret: f.secret,
          ),
      ],
    );
  }

  Future<List<Channel>> _channelsForWorkspace(int workspaceId) async {
    final bots = await _bots.listByWorkspace(workspaceId);
    final ids = [for (final b in bots) if (b.id != null) b.id!];
    if (ids.isEmpty) return const [];

    // Parallel rather than one query with an IN filter: listByBot is the
    // verified repository API, and a workspace has a handful of bots,
    // not thousands. Revisit if that stops being true.
    final perBot = await Future.wait(ids.map(_channels.listByBot));
    return [for (final list in perBot) ...list];
  }

  /// '••••••••3f2a' — the design's masked tail for a connected gateway.
  ///
  /// Decrypts to read the last four characters and keeps nothing else.
  /// Returns null rather than throwing if decryption fails: a wrong or
  /// missing CHANNEL_CREDENTIAL_MASTER_KEY must not take down the whole
  /// marketplace over a cosmetic string.
  String? _maskedSecret(String ciphertext) {
    try {
      final plain = ChannelCredentialEncryptionService.decrypt(ciphertext);
      if (plain.length < 4) return null;
      return 'Secret key: ••••••••${plain.substring(plain.length - 4)}';
    } catch (e) {
      _log.warning('Could not decrypt gateway key for masking: $e');
      return null;
    }
  }

  /// Wire values, matching the design export's own `authType` strings so
  /// the page can branch on them without a translation table. Note
  /// `keydisplay` is lowercase in the export — kept identical rather
  /// than tidied, because the only thing that matters is that both sides
  /// agree.
  static String _authName(ConnectorAuth auth) => switch (auth) {
        ConnectorAuth.fields => 'fields',
        ConnectorAuth.oauth => 'oauth',
        ConnectorAuth.manage => 'manage',
        ConnectorAuth.keyDisplay => 'keydisplay',
        ConnectorAuth.whatsapp => 'whatsapp',
      };

  static int _sortRank(String status) => switch (status) {
        ConnectorStatusValue.error => 0,
        ConnectorStatusValue.connected => 1,
        ConnectorStatusValue.available => 2,
        _ => 3,
      };
}
