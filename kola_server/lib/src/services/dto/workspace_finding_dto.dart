// workspace_finding_dto.dart
//
// Serverpod model ↔ Supabase row for `workspace_findings` (migration 034).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class WorkspaceFindingDto extends BaseDto<WorkspaceFinding> {
  const WorkspaceFindingDto();

  @override
  WorkspaceFinding fromRow(Map<String, dynamic> row) {
    return WorkspaceFinding(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      kind: row['kind'] as String,
      fingerprint: row['fingerprint'] as String,
      severity: row['severity'] as int,
      title: row['title'] as String,
      detail: row['detail'] as String?,
      subjectType: row['subject_type'] as String?,
      subjectId: row['subject_id'] as int?,
      // Postgres double precision arrives as num, and as an INT when the
      // stored value is exactly 1.0 — which it is for every deterministic
      // detector, i.e. all of them today. `as double` would throw on the
      // common case; toDouble() handles both.
      confidence: (row['confidence'] as num).toDouble(),
      firstSeenAt: DateTime.parse(row['first_seen_at'] as String),
      lastSeenAt: DateTime.parse(row['last_seen_at'] as String),
      resolvedAt: row['resolved_at'] == null
          ? null
          : DateTime.parse(row['resolved_at'] as String),
      dismissedAt: row['dismissed_at'] == null
          ? null
          : DateTime.parse(row['dismissed_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(WorkspaceFinding model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'kind': model.kind,
      'fingerprint': model.fingerprint,
      'severity': model.severity,
      'title': model.title,
      'detail': model.detail,
      'subject_type': model.subjectType,
      'subject_id': model.subjectId,
      'confidence': model.confidence,
      'first_seen_at': model.firstSeenAt.toIso8601String(),
      'last_seen_at': model.lastSeenAt.toIso8601String(),
      'resolved_at': model.resolvedAt?.toIso8601String(),
      'dismissed_at': model.dismissedAt?.toIso8601String(),
      // created_at / updated_at are left to the column defaults on
      // insert. Sending them would let a clock-skewed app server write a
      // creation time the database disagrees with.
    };
  }
}
