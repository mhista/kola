// platform_endpoint.dart — API keys and outbound webhooks.
//
// Backs Kola API Webhooks.dc.html.
//
// ── GATED ON platform.public_api, AND THAT MATTERS ───────────────────
//
// Every method here checks the capability flag, not just workspace
// access. PaymentEndpoint.connectGateway does NOT — it checks access and
// nothing else, which means `payments.collect` being locked does not
// actually stop a gateway being connected. That gap is recorded in
// DESIGN_DELTA.md and is not repeated here.
//
// An unreleased capability whose endpoints still work is not released
// software with a hidden UI. It is released software.
//
// ── THE KEY IS RETURNED ONCE ─────────────────────────────────────────
//
// createApiKey returns CreatedApiKey, which carries the plaintext. No
// other method can produce one, and no read path returns it, because the
// server only stores a SHA-256 hash. See api_key_service.dart.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/platform/api_key_service.dart';
import 'package:kola_server/src/services/repository/api_key_repository.dart';
import 'package:kola_server/src/services/repository/webhook_endpoint_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/kola_logger.dart';

class PlatformEndpoint extends Endpoint {
  ApiKeyService get _keyService => getIt<ApiKeyService>();
  ApiKeyRepository get _keys => getIt<ApiKeyRepository>();
  WebhookEndpointRepository get _hooks => getIt<WebhookEndpointRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();

  /// The design's EVENT_TYPES, in storage form.
  static const eventTypes = <String>[
    'new_conversation',
    'errand_executed',
    'bot_published',
    'payment_confirmed',
  ];

  // ── Keys ─────────────────────────────────────────────────────────────

  /// Every key for the workspace, revoked ones included — the design
  /// shows them so an owner can see what they turned off.
  Future<List<ApiKey>> listApiKeys(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await _require(accessToken, workspaceId);
    return _keys.listByWorkspace(workspaceId);
  }

  /// Creates a key. The response carries the ONLY copy of the plaintext.
  Future<CreatedApiKey> createApiKey(
    Session session,
    String accessToken,
    int workspaceId,
    String name,
    String scope,
  ) async {
    await _require(accessToken, workspaceId);

    final created = await _keyService.create(
      workspaceId: workspaceId,
      name: name,
      scope: scope,
    );

    // Deliberately logs the NAME and never the key or its hash. A secret
    // in a log file is a secret in every backup of that log file.
    Log.info(
      'API key created',
      data: {'workspaceId': workspaceId, 'name': name, 'scope': scope},
      session: session,
    );
    return created;
  }

  /// Revokes immediately. Idempotent — revoking twice keeps the original
  /// timestamp, because when it stopped working is the fact that matters.
  Future<void> revokeApiKey(
    Session session,
    String accessToken,
    int workspaceId,
    int keyId,
  ) async {
    await _require(accessToken, workspaceId);
    await _keys.revoke(workspaceId, keyId);
    Log.info(
      'API key revoked',
      data: {'workspaceId': workspaceId, 'keyId': keyId},
      session: session,
    );
  }

  // ── Webhooks ─────────────────────────────────────────────────────────

  Future<List<WebhookEndpoint>> listWebhookEndpoints(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await _require(accessToken, workspaceId);
    return _hooks.listByWorkspace(workspaceId);
  }

  /// Registers an endpoint, or updates the one already on this URL.
  ///
  /// The signing secret is generated here and encrypted before storage —
  /// unlike an API key, kola must recover this one to sign each delivery.
  Future<WebhookEndpoint> saveWebhookEndpoint(
    Session session,
    String accessToken,
    int workspaceId,
    String url,
    List<String> events,
  ) async {
    await _require(accessToken, workspaceId);

    final trimmed = url.trim();
    // https only. A webhook carries conversation and payment data, and
    // posting it over plaintext http would leak it to every hop in
    // between — worth refusing rather than warning about.
    if (!trimmed.startsWith('https://')) {
      throw Exception('Webhook URLs must start with https://');
    }
    final unknown = events.where((e) => !eventTypes.contains(e)).toList();
    if (unknown.isNotEmpty) {
      throw Exception('Unknown event: ${unknown.first}');
    }
    if (events.isEmpty) {
      throw Exception('Choose at least one event to send.');
    }

    final secret = ApiKeyService.hashOf(
      '${DateTime.now().microsecondsSinceEpoch}:$trimmed:$workspaceId',
    );

    return _hooks.upsert(
      workspaceId: workspaceId,
      url: trimmed,
      events: events,
      encryptedSecret: ChannelCredentialEncryptionService.encrypt(secret),
    );
  }

  Future<void> deleteWebhookEndpoint(
    Session session,
    String accessToken,
    int workspaceId,
    int endpointId,
  ) async {
    await _require(accessToken, workspaceId);
    await _hooks.delete(workspaceId, endpointId);
  }

  // ── Private ──────────────────────────────────────────────────────────

  /// Workspace access AND the capability flag.
  ///
  /// Both, every time. See this file's header on why the flag check is
  /// not optional.
  Future<void> _require(String accessToken, int workspaceId) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw Exception('Workspace $workspaceId not found.');
    }
    if (!await _features.isEnabled(FeatureKeys.publicApi, workspace)) {
      throw Exception(
        'The kola API is not available on this workspace yet.',
      );
    }
  }
}
