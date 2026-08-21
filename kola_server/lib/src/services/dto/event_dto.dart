// event_dto.dart
//
// Translates between:
//   Serverpod model  → Event  (generated/event.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: events
// Schema: docs/migrations/037_event_bus.sql
//
// payload_json in Postgres is jsonb; this DTO reads/writes it as a
// jsonEncode'd String on the Dart side (see event.spy.yaml's header on
// why) — jsonDecode/jsonEncode happen one layer up, in event_bus.dart,
// which is the only place that actually knows a given event_type's
// payload shape.

import 'dart:convert';

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class EventDto extends BaseDto<Event> {
  const EventDto();

  @override
  Event fromRow(Map<String, dynamic> row) {
    // Supabase's postgrest client already decodes a jsonb column into a
    // Dart Map/List — re-encoding it back to a String here is what keeps
    // Event.payloadJson a String on the Dart side, matching every other
    // *Json field in this codebase (ErrandExecutionLog.inputJson, etc.),
    // rather than introducing the one model whose field type depends on
    // which layer last touched it.
    final payload = row['payload'];
    return Event(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      eventType: row['event_type'] as String,
      fingerprint: row['fingerprint'] as String,
      payloadJson: payload == null ? '{}' : jsonEncode(payload),
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      ingestedAt: DateTime.parse(row['ingested_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Event model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'event_type': model.eventType,
      'fingerprint': model.fingerprint,
      'payload': jsonDecode(model.payloadJson),
      'occurred_at': model.occurredAt.toIso8601String(),
      'ingested_at': model.ingestedAt.toIso8601String(),
    };
  }
}
