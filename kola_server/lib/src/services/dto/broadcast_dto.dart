// broadcast_dto.dart
//
// Translates between:
//   Serverpod model  → Broadcast  (generated/broadcast.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: broadcasts
// Schema: docs/migrations/049_broadcasts.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class BroadcastDto extends BaseDto<Broadcast> {
  const BroadcastDto();

  @override
  Broadcast fromRow(Map<String, dynamic> row) {
    return Broadcast(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      platform: row['platform'] as String,
      text: row['text'] as String,
      status: row['status'] as String,
      throughputPerMinute: row['throughput_per_minute'] as int,
      totalRecipients: row['total_recipients'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      startedAt: row['started_at'] == null ? null : DateTime.parse(row['started_at'] as String),
      completedAt: row['completed_at'] == null ? null : DateTime.parse(row['completed_at'] as String),
      // Gate 10 (migration 050). Defaults to 0 at the DB level, but a
      // row inserted before this migration ran would read back null
      // from a plain `select()` only if the ALTER TABLE's own DEFAULT
      // hadn't backfilled it — Postgres backfills existing rows for an
      // ADD COLUMN ... DEFAULT, so this `?? 0` is defensive, not load-
      // bearing.
      escalatedReplyCount: (row['escalated_reply_count'] as int?) ?? 0,
      lastDigestSentAt:
          row['last_digest_sent_at'] == null ? null : DateTime.parse(row['last_digest_sent_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Broadcast model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'platform': model.platform,
      'text': model.text,
      'status': model.status,
      'throughput_per_minute': model.throughputPerMinute,
      'total_recipients': model.totalRecipients,
      'updated_at': model.updatedAt.toIso8601String(),
      'started_at': model.startedAt?.toIso8601String(),
      'completed_at': model.completedAt?.toIso8601String(),
      'escalated_reply_count': model.escalatedReplyCount,
      'last_digest_sent_at': model.lastDigestSentAt?.toIso8601String(),
    };
  }
}
