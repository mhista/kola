// broadcast_sweep_service.dart — Gate 9's core queue engine. Same
// "sweep + act, wired into server.dart on a plain Timer" shape as
// trial_sweep_service.dart / customer_campaign_sweep_service.dart —
// this is that same pattern applied to
// docs/Kolaa_Connections_Backbone_Direction_v5.pdf Part VI's broadcast
// spec: "a broadcast is a job, not a loop... paced against provider
// limits... resumable and idempotent... cancellable mid-flight...
// suppression checked at send time."
//
// TICK INTERVAL, NOT DAILY/HOURLY LIKE THIS CODEBASE'S OTHER SWEEPS: a
// broadcast's pacing (messages per minute) needs sub-minute granularity
// to mean anything, so server.dart runs this one on a short Timer
// (every 15s) rather than the 1h/24h cadence every other sweep here
// uses — see this file's own batch-size math.
//
// WHY THIS IS RESUMABLE: every recipient's progress lives in
// broadcast_recipients (state = queued/sending/sent/failed/skipped), not
// in any variable this service holds. A crash between ticks loses
// nothing — the next tick just queries for state = 'queued' again,
// exactly like before the crash. The only in-flight risk is a crash
// between markSending() and the send attempt actually landing, which
// would leave a row stuck in 'sending' forever; that's a known, narrow
// gap (a stuck-in-'sending' sweeper/reaper is not built) rather than a
// silently accepted one.
//
// WHY TRANSACTIONAL SENDS NEVER QUEUE BEHIND A BROADCAST ("priority
// lanes are essential" — spec): not because this service arbitrates
// between them at runtime, but because they never share a queue in the
// first place. Gate 8's POST /v1/messages (outbound_message_service.dart
// called directly, synchronously, per HTTP request) never touches
// broadcast_recipients at all — it sends immediately. This service only
// ever works through THIS table, on its own throttled schedule. Two
// separate code paths to the same channel adapter is what makes
// "broadcast can never block a transactional send" true structurally,
// without needing a shared token-bucket/priority-queue implementation.
//
// RETRY POLICY, AND ITS REAL LIMIT: MessagingResult.errorMessage (see
// messaging_result.dart) is a free-text string, not a machine-readable
// error code — none of this codebase's adapters classify a failure as
// "rate limited, retry" vs. "invalid number, don't bother" today. So
// this service applies ONE policy to every failure: retry up to
// [_maxAttempts] times, then mark 'failed'. That is the honest version
// of the spec's "per-failure retry policy" given what's actually
// available to inspect — a real, named simplification, not the full
// classify-by-failure-type behavior the spec describes.

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/broadcast_repository.dart';
import 'package:kola_server/src/services/repository/broadcast_recipient_repository.dart';
import 'package:kola_server/src/services/repository/message_suppression_repository.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/messaging/outbound_message_service.dart';
import 'package:kola_server/kola_logger.dart';

class BroadcastSweepService {
  BroadcastSweepService({
    required BroadcastRepository broadcasts,
    required BroadcastRecipientRepository recipients,
    required MessageSuppressionRepository suppressions,
    required OutboundMessageService outbound,
  }) : _broadcasts = broadcasts,
       _recipients = recipients,
       _suppressions = suppressions,
       _outbound = outbound;

  final BroadcastRepository _broadcasts;
  final BroadcastRecipientRepository _recipients;
  final MessageSuppressionRepository _suppressions;
  final OutboundMessageService _outbound;

  static const int _maxAttempts = 3;

  /// How often server.dart's Timer calls [sweepOnce] — every downstream
  /// batch-size calculation assumes this exact interval.
  static const Duration tickInterval = Duration(seconds: 15);

  /// Works one tick's worth of every currently-'running' broadcast.
  /// Per-broadcast try/catch, same discipline as every other sweep in
  /// this codebase: one broadcast's bug (a bad row, a transient
  /// exception) must never stall every other workspace's broadcast.
  Future<void> sweepOnce() async {
    final running = await _broadcasts.listRunning();
    for (final broadcast in running) {
      try {
        await _tick(broadcast);
      } catch (e, stackTrace) {
        Log.error('BroadcastSweepService: tick failed for broadcast ${broadcast.id}', error: e, stackTrace: stackTrace);
      }
    }
  }

  Future<void> _tick(Broadcast broadcast) async {
    final broadcastId = broadcast.id;
    if (broadcastId == null) return;

    final batchSize = _batchSizeFor(broadcast.throughputPerMinute);
    final batch = await _recipients.nextQueuedBatch(broadcastId: broadcastId, limit: batchSize);

    if (batch.isEmpty) {
      await _maybeComplete(broadcastId);
      return;
    }

    // Claim the whole batch before sending any of it — see file header
    // on why this is what makes a second overlapping tick safe (it
    // won't happen with a single server instance, but costs nothing to
    // guard against).
    final ids = [for (final r in batch) if (r.id != null) r.id!];
    await _recipients.markSending(ids);

    for (final recipient in batch) {
      await _sendOne(broadcast, recipient);
    }
  }

  Future<void> _maybeComplete(int broadcastId) async {
    final counts = await _recipients.countsByState(broadcastId);
    final remaining = (counts['queued'] ?? 0) + (counts['sending'] ?? 0);
    if (remaining == 0) {
      await _broadcasts.setStatus(broadcastId, 'completed', completedAt: DateTime.now().toUtc());
      Log.success('Broadcast $broadcastId completed', data: counts);
    }
  }

  Future<void> _sendOne(Broadcast broadcast, BroadcastRecipient recipient) async {
    final id = recipient.id;
    if (id == null) return;

    final normalizedAddress = _normalizeAddress(broadcast.platform, recipient.to);

    final suppressed = await _suppressions.isSuppressed(
      workspaceId: recipient.workspaceId,
      platform: broadcast.platform,
      addressNormalized: normalizedAddress,
    );
    if (suppressed) {
      await _recipients.markSkipped(id: id, reason: 'Suppressed (opted out) — checked at send time.');
      return;
    }

    final result = await _outbound.send(
      workspaceId: recipient.workspaceId,
      platform: broadcast.platform,
      to: recipient.to,
      text: broadcast.text,
      // Namespaced per broadcast+recipient row — a retried attempt on
      // the SAME row (this service marking it 'queued' again after a
      // retryable failure) reuses this exact key every time, so
      // OutboundMessageService's own idempotency check
      // (message_repository.dart's findByConversationAndExternalId)
      // means a crash right after a successful send but before
      // markSent() runs still can't produce a second real message —
      // the next attempt finds the already-sent Message and returns it
      // instead of sending again.
      idempotencyKey: 'broadcast:${broadcast.id}:$id',
      // Gate 10 — tags the recipient's conversation so a later reply
      // carries this broadcast's context into inbound_message_handler
      // .dart. See outbound_message_service.dart's [broadcastId] param
      // doc.
      broadcastId: broadcast.id,
    );

    final attemptCount = recipient.attemptCount + 1;

    if (result.success) {
      final messageId = result.message?.id;
      if (messageId == null) {
        // Defensive only — OutboundSendResult.ok always carries a
        // Message. Treat as a failed attempt rather than crash the
        // sweep on a state that should be unreachable.
        await _recipients.markFailedAttempt(
          id: id,
          error: 'Send reported success with no message id.',
          attemptCount: attemptCount,
          terminal: attemptCount >= _maxAttempts,
        );
        return;
      }
      await _recipients.markSent(id: id, messageId: messageId, attemptCount: attemptCount);
    } else {
      final terminal = attemptCount >= _maxAttempts;
      await _recipients.markFailedAttempt(
        id: id,
        error: result.error ?? 'Unknown error',
        attemptCount: attemptCount,
        terminal: terminal,
      );
    }
  }

  static String _normalizeAddress(String platform, String raw) {
    final trimmed = raw.trim();
    return platform == 'whatsapp' ? CustomerIdentityResolver.normalizePhone(trimmed) : trimmed;
  }

  /// throughputPerMinute converted to a per-[tickInterval] batch size —
  /// "batches with a configured throughput, well under whatever the
  /// channel permits" (spec). Always at least 1 once a broadcast is
  /// running, so a throughput below one message per tick still makes
  /// forward progress rather than stalling.
  static int _batchSizeFor(int throughputPerMinute) {
    final perTick = throughputPerMinute * tickInterval.inSeconds / 60;
    return perTick < 1 ? 1 : perTick.round();
  }
}
