// event_repository.dart — Gate 2. Storage for the permanent, replayable
// event log (migration 037). See event_bus.dart for the service that
// actually decides WHEN to call [emit] and what happens after a genuine
// new event lands (webhook fan-out) — this file only owns persistence
// and the fingerprint-dedup guarantee itself.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/event_dto.dart';
import 'supabase_client.dart';

final _log = Logger('EventRepository');

const _dto = EventDto();

class EventRepository {
  const EventRepository();

  /// Inserts one event, or does nothing if [fingerprint] already exists
  /// for this workspace — migration 037's unique index on
  /// (workspace_id, fingerprint) is what makes this atomic rather than a
  /// racy check-then-insert. Returns the row (existing or newly
  /// inserted) alongside whether it was ACTUALLY new, because
  /// EventBus.emit only fans out to webhook delivery on a genuine first
  /// occurrence — a replayed/duplicate emission must not re-notify every
  /// subscriber.
  ///
  /// `ignoreDuplicates: true` is Supabase's client-level spelling of
  /// `ON CONFLICT (workspace_id, fingerprint) DO NOTHING`. NOT an
  /// existing pattern anywhere else in this codebase — every other
  /// upsert call site (workspace_connector_repository.dart,
  /// webhook_endpoint_repository.dart, workspace_finding_repository
  /// .dart) wants a MERGE on conflict, not a skip, so none of them pass
  /// this parameter. Verified directly against supabase.com/docs/
  /// reference/dart/upsert (fetched, not recalled) rather than assumed
  /// from the merge-on-conflict shape those other call sites use:
  /// `ignoreDuplicates` (bool, default false) is real and does exactly
  /// this — "if true, duplicate rows are ignored" — on the same
  /// `.upsert(data, {onConflict, ignoreDuplicates})` method every other
  /// call site already uses, just with this one flag flipped.
  Future<(Event event, bool wasNew)> emit({
    required int workspaceId,
    required String eventType,
    required String fingerprint,
    required String payloadJson,
    DateTime? occurredAt,
  }) async {
    _log.fine('emit($workspaceId, $eventType, $fingerprint)');
    final now = DateTime.now().toUtc();

    final inserted = await supabase
        .from('events')
        .upsert(
          {
            'workspace_id': workspaceId,
            'event_type': eventType,
            'fingerprint': fingerprint,
            'payload': _decodeForInsert(payloadJson),
            'occurred_at': (occurredAt ?? now).toIso8601String(),
            'ingested_at': now.toIso8601String(),
          },
          onConflict: 'workspace_id,fingerprint',
          ignoreDuplicates: true,
        )
        .select();

    // ignoreDuplicates means a conflicting row returns an EMPTY select,
    // not the existing row — Supabase does not hand back what it
    // skipped. So an empty result means "this fingerprint already
    // existed", and the existing row has to be fetched separately to
    // return something to the caller at all.
    if ((inserted as List).isEmpty) {
      final existing = await supabase
          .from('events')
          .select()
          .eq('workspace_id', workspaceId)
          .eq('fingerprint', fingerprint)
          .single();
      return (_dto.fromRow(existing), false);
    }

    return (_dto.fromRow(inserted.first as Map<String, dynamic>), true);
  }

  /// Every event for a workspace, oldest first, optionally narrowed by
  /// type and/or a starting point — the query PART V's "replay" and the
  /// future Timeline both need: "everything that happened, in order,
  /// optionally since some point."
  Future<List<Event>> listByWorkspace({
    required int workspaceId,
    String? eventType,
    DateTime? since,
    int limit = 200,
  }) async {
    _log.fine('listByWorkspace($workspaceId, type=$eventType, since=$since)');
    var query = supabase.from('events').select().eq('workspace_id', workspaceId);
    if (eventType != null) query = query.eq('event_type', eventType);
    if (since != null) query = query.gte('occurred_at', since.toIso8601String());

    final response = await query.order('occurred_at', ascending: true).limit(limit);
    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// See event_dto.dart's header — payload travels as a jsonEncode'd
  /// String on the Dart side and jsonb in Postgres; this is the one
  /// write path event_dto.dart's toRow doesn't cover (emit() builds its
  /// own row map rather than going through an Event model first, same
  /// pattern workspace_connector_repository.dart's upsert() already
  /// uses for the same reason: the caller has field values, not a
  /// fully-built model to encode). Fails safe to an empty object rather
  /// than throwing mid-emit and losing an otherwise-valid event — every
  /// real caller builds payloadJson via jsonEncode, so a decode failure
  /// here means a bug upstream, not a case worth crashing the emit over.
  static Object _decodeForInsert(String payloadJson) {
    try {
      return jsonDecode(payloadJson);
    } catch (e) {
      _log.warning('emit(): payloadJson did not decode ($e) — storing {}');
      return <String, dynamic>{};
    }
  }
}
