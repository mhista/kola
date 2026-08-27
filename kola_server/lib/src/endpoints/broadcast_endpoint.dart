// broadcast_endpoint.dart — Gate 9. Dashboard-session-authenticated
// surface over the core queue engine (broadcast_sweep_service.dart).
// No dashboard UI consumes this yet — v1 scope, per the "core queue
// engine" decision for this gate — but the endpoint exists so the
// engine is drivable and testable without a UI, same as every other
// gate in this codebase shipped its endpoint before its screen.
//
// recipientsJson IS A JSON STRING, NOT List<String> — same reason
// sale_endpoint.dart's ringUpSale and invoice_endpoint.dart's
// createInvoice already take linesJson as a String: this Serverpod
// install drops the deserializer for List<CustomType> parameters on the
// generated client (see sale_endpoint.dart's own header for the full
// trace). recipientsJson is `["2348012345678", "2348098765432", ...]` —
// a JSON array of plain address strings, decoded here.

import 'package:serverpod/serverpod.dart';
import 'dart:convert';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/broadcast_repository.dart';
import 'package:kola_server/src/services/repository/broadcast_recipient_repository.dart';
import 'package:kola_server/src/services/repository/message_suppression_repository.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/messaging/broadcast_sweep_service.dart';
import 'package:kola_server/kola_logger.dart';

class BroadcastEndpoint extends Endpoint {
  BroadcastRepository get _broadcasts => getIt<BroadcastRepository>();
  BroadcastRecipientRepository get _recipients => getIt<BroadcastRecipientRepository>();
  MessageSuppressionRepository get _suppressions => getIt<MessageSuppressionRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();

  static const _supportedPlatforms = ['whatsapp', 'telegram'];

  /// Default pace when the caller doesn't specify one — deliberately
  /// conservative (spec: "the limit is a ceiling to stay beneath, not a
  /// target to hit"). Neither WhatsApp's nor Telegram's exact per-number
  /// throughput ceiling is read programmatically anywhere in this
  /// codebase yet (spec calls the WhatsApp quality-tier check out as a
  /// real, unbuilt gap) — this is a fixed, cautious placeholder, not a
  /// value derived from either platform's actual current limits.
  static const _defaultThroughputPerMinute = 20;
  static const _maxThroughputPerMinute = 120;

  /// Creates a broadcast in 'draft' status with every recipient row
  /// pre-loaded — nothing sends until [startBroadcast] flips it to
  /// 'running'. Recipients already suppressed for this workspace/
  /// platform are dropped here rather than being loaded and skipped
  /// later, so totalRecipients reflects who could actually be reached —
  /// live suppression added AFTER this call is still re-checked at send
  /// time by broadcast_sweep_service.dart, per spec.
  Future<Broadcast> createBroadcast(
    Session session,
    String accessToken,
    int workspaceId,
    String platform,
    String text,
    String recipientsJson,
    int? throughputPerMinute,
  ) async {
    await _require(accessToken, workspaceId);

    if (!_supportedPlatforms.contains(platform)) {
      throw KolaException(message: 'Unsupported platform "$platform" — must be one of $_supportedPlatforms.');
    }
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw KolaException(message: 'A broadcast needs a message body.');
    }

    final decoded = jsonDecode(recipientsJson);
    if (decoded is! List || decoded.isEmpty) {
      throw KolaException(message: 'recipientsJson must be a non-empty JSON array of recipient addresses.');
    }

    // Dedupe within this call (migration 049's unique index on
    // (broadcastId, to) would otherwise reject the second occurrence as
    // a plain insert failure) and drop anything already suppressed —
    // see method header.
    final seen = <String>{};
    final toSend = <String>[];
    for (final raw in decoded) {
      if (raw is! String) continue;
      final address = raw.trim();
      if (address.isEmpty || !seen.add(address)) continue;

      final normalized = _normalizeAddress(platform, address);
      final suppressed = await _suppressions.isSuppressed(
        workspaceId: workspaceId,
        platform: platform,
        addressNormalized: normalized,
      );
      if (!suppressed) toSend.add(address);
    }

    if (toSend.isEmpty) {
      throw KolaException(message: 'Every recipient in this list is suppressed (opted out) or invalid.');
    }

    // `int.clamp` returns `num`, not `int` — .toInt() keeps this an int
    // without a second helper just for a one-line bound check.
    final throughput =
        (throughputPerMinute ?? _defaultThroughputPerMinute).clamp(1, _maxThroughputPerMinute).toInt();

    final broadcast = await _broadcasts.create(
      workspaceId: workspaceId,
      platform: platform,
      text: trimmedText,
      throughputPerMinute: throughput,
      totalRecipients: toSend.length,
    );
    final broadcastId = broadcast.id;
    if (broadcastId == null) {
      throw KolaException(message: 'Failed to create broadcast.');
    }

    await _recipients.createMany(broadcastId: broadcastId, workspaceId: workspaceId, recipients: toSend);

    Log.success(
      'Broadcast created',
      data: {'workspaceId': workspaceId, 'broadcastId': broadcastId, 'recipients': toSend.length},
      session: session,
    );

    return broadcast;
  }

  /// draft -> running. broadcast_sweep_service.dart's next tick (every
  /// [BroadcastSweepService.tickInterval]) picks it up from here — this
  /// method does not send anything itself.
  Future<Broadcast> startBroadcast(
    Session session,
    String accessToken,
    int workspaceId,
    int broadcastId,
  ) async {
    await _require(accessToken, workspaceId);
    final broadcast = await _requireBroadcast(broadcastId, workspaceId);

    if (broadcast.status != 'draft') {
      throw KolaException(message: 'Only a draft broadcast can be started (this one is "${broadcast.status}").');
    }

    final updated = await _broadcasts.setStatus(broadcastId, 'running', startedAt: DateTime.now().toUtc());
    Log.success('Broadcast started', data: {'workspaceId': workspaceId, 'broadcastId': broadcastId}, session: session);
    return updated;
  }

  /// Stops future sends. "There is no recall" — whatever already sent,
  /// sent; only 'queued' rows are affected, and they simply never get
  /// attempted (broadcast_sweep_service.dart only ever works
  /// 'running' broadcasts).
  Future<Broadcast> cancelBroadcast(
    Session session,
    String accessToken,
    int workspaceId,
    int broadcastId,
  ) async {
    await _require(accessToken, workspaceId);
    final broadcast = await _requireBroadcast(broadcastId, workspaceId);

    if (broadcast.status == 'completed' || broadcast.status == 'cancelled') {
      throw KolaException(message: 'This broadcast is already "${broadcast.status}" — nothing to cancel.');
    }

    final updated = await _broadcasts.setStatus(broadcastId, 'cancelled');
    Log.success('Broadcast cancelled', data: {'workspaceId': workspaceId, 'broadcastId': broadcastId}, session: session);
    return updated;
  }

  Future<List<Broadcast>> listBroadcasts(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await _require(accessToken, workspaceId);
    return _broadcasts.listByWorkspace(workspaceId);
  }

  /// "Live progress — sent, delivered, failed, remaining" (spec, minus
  /// delivered/read — see broadcast.spy.yaml's header on why those
  /// aren't tracked yet).
  Future<BroadcastProgress> getBroadcastProgress(
    Session session,
    String accessToken,
    int workspaceId,
    int broadcastId,
  ) async {
    await _require(accessToken, workspaceId);
    final broadcast = await _requireBroadcast(broadcastId, workspaceId);
    final counts = await _recipients.countsByState(broadcastId);

    return BroadcastProgress(
      broadcastId: broadcastId,
      status: broadcast.status,
      totalRecipients: broadcast.totalRecipients,
      queued: counts['queued'] ?? 0,
      sending: counts['sending'] ?? 0,
      sent: counts['sent'] ?? 0,
      failed: counts['failed'] ?? 0,
      skipped: counts['skipped'] ?? 0,
    );
  }

  // ── Suppression list ─────────────────────────────────────────────────

  Future<List<MessageSuppression>> listSuppressions(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await _require(accessToken, workspaceId);
    return _suppressions.listByWorkspace(workspaceId);
  }

  Future<MessageSuppression> addSuppression(
    Session session,
    String accessToken,
    int workspaceId,
    String platform,
    String address,
  ) async {
    await _require(accessToken, workspaceId);
    if (!_supportedPlatforms.contains(platform)) {
      throw KolaException(message: 'Unsupported platform "$platform" — must be one of $_supportedPlatforms.');
    }
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      throw KolaException(message: 'An address is required.');
    }
    return _suppressions.add(
      workspaceId: workspaceId,
      platform: platform,
      addressNormalized: _normalizeAddress(platform, trimmed),
      reason: 'manual',
    );
  }

  Future<void> removeSuppression(
    Session session,
    String accessToken,
    int workspaceId,
    String platform,
    String address,
  ) async {
    await _require(accessToken, workspaceId);
    await _suppressions.remove(
      workspaceId: workspaceId,
      platform: platform,
      addressNormalized: _normalizeAddress(platform, address.trim()),
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────

  static String _normalizeAddress(String platform, String raw) =>
      platform == 'whatsapp' ? CustomerIdentityResolver.normalizePhone(raw) : raw;

  Future<Broadcast> _requireBroadcast(int broadcastId, int workspaceId) async {
    final broadcast = await _broadcasts.findByIdScoped(broadcastId, workspaceId);
    if (broadcast == null) {
      throw KolaException(message: 'Broadcast $broadcastId not found.');
    }
    return broadcast;
  }

  Future<void> _require(String accessToken, int workspaceId) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
    }
    if (!await _features.isEnabled(FeatureKeys.broadcast, workspace)) {
      throw KolaException(message: 'Broadcast messaging is not available on this workspace yet.');
    }
  }
}
