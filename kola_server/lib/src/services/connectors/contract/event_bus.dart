// event_bus.dart — Gate 2. The single entry point every emission call
// site in this codebase goes through — PART V: "Every ingestion, every
// webhook, every action becomes a timestamped event against a graph
// entity." No caller writes to the `events` table directly; they all
// call [EventBus.emit].
//
// WHY emit() NEVER THROWS: this is deliberately the same discipline
// ConnectorSyncLogRepository.record() and OwnerNotificationDispatcher's
// call sites already use in this codebase — an event-bus write failing
// must never be the reason a real business action (an errand executing,
// a conversation starting, a payment confirming) fails or rolls back.
// The event bus observes the business; it is not load-bearing for it.
// Every failure is logged loudly instead (PART IX's "prefer loud
// failure to a clean-looking screen").

import 'dart:convert';

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/services/repository/event_repository.dart';
import 'webhook_delivery_service.dart';

class EventBus {
  EventBus({
    required EventRepository events,
    required WebhookDeliveryService webhookDelivery,
  }) : _events = events,
       _webhookDelivery = webhookDelivery;

  final EventRepository _events;
  final WebhookDeliveryService _webhookDelivery;

  /// Records one occurrence and, if it is genuinely new (not a
  /// dedup'd replay of something already ingested — see
  /// event_repository.dart's `wasNew`), fans it out to every workspace
  /// webhook subscriber for [eventType].
  ///
  /// [fingerprint] is the idempotency key — 'kind:subject', e.g.
  /// 'errand_executed:412'. Two calls with the same [workspaceId] +
  /// [fingerprint] converge to one stored event and at most one webhook
  /// delivery round, regardless of how many times a caller (a retried
  /// webhook handler, a replayed sync) actually calls emit.
  ///
  /// [payload] is a plain Map — this method owns the jsonEncode, so
  /// every call site passes real Dart values rather than pre-encoding a
  /// string itself.
  Future<void> emit({
    required int workspaceId,
    required String eventType,
    required String fingerprint,
    required Map<String, dynamic> payload,
    DateTime? occurredAt,
  }) async {
    try {
      final (event, wasNew) = await _events.emit(
        workspaceId: workspaceId,
        eventType: eventType,
        fingerprint: fingerprint,
        payloadJson: _encode(payload),
        occurredAt: occurredAt,
      );

      if (!wasNew) {
        Log.info('EventBus: $fingerprint already existed for workspace $workspaceId — skipping delivery');
        return;
      }

      await _webhookDelivery.deliverToSubscribers(
        workspaceId: workspaceId,
        eventType: eventType,
        payloadJson: event.payloadJson,
      );
    } catch (e, stackTrace) {
      Log.error(
        'EventBus.emit failed for workspace $workspaceId, type $eventType, '
        'fingerprint $fingerprint — the triggering action itself still '
        'succeeded; only the event record/webhook fan-out was lost',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// PART V: "Events are stored permanently and are replayable." Re-runs
  /// webhook delivery for every already-stored event matching the
  /// filter — the case this exists for is an owner who fixed a broken
  /// endpoint and wants what they missed while it was down, without
  /// kola re-doing (or re-charging for) whatever originally produced
  /// each event. Does NOT re-insert anything into `events` — replay
  /// only ever reads what emit() already wrote, matching PART V's
  /// "ingestion must be idempotent" applied to redelivery as well as to
  /// first delivery.
  Future<int> replay({
    required int workspaceId,
    String? eventType,
    DateTime? since,
  }) async {
    final events = await _events.listByWorkspace(
      workspaceId: workspaceId,
      eventType: eventType,
      since: since,
    );

    var delivered = 0;
    for (final event in events) {
      try {
        await _webhookDelivery.deliverToSubscribers(
          workspaceId: workspaceId,
          eventType: event.eventType,
          payloadJson: event.payloadJson,
        );
        delivered++;
      } catch (e) {
        Log.error('EventBus.replay: delivery failed for event ${event.id}', error: e);
      }
    }
    return delivered;
  }

  static String _encode(Map<String, dynamic> payload) => jsonEncode(payload);
}
