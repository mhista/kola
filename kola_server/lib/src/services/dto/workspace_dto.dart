// workspace_dto.dart
//
// Translates between:
//   Serverpod model  → Workspace  (kola_server/lib/src/generated/workspace.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: workspaces
// Schema: docs/migrations/001_initial_schema.sql (source of truth — not
// duplicated here to avoid the two drifting apart over time).
//
// NOTE: Supabase uses snake_case column names.
//       Serverpod models use camelCase field names.
//       The DTO handles this mapping explicitly — no magic, no reflection.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class WorkspaceDto extends BaseDto<Workspace> {
  const WorkspaceDto();

  @override
  Workspace fromRow(Map<String, dynamic> row) {
    return Workspace(
      id: row['id'] as int?,
      name: row['name'] as String,
      industryTag: row['industry_tag'] as String?,
      plan: row['plan'] as String,
      status: row['status'] as String,
      trialStartedAt: DateTime.parse(row['trial_started_at'] as String),
      trialFullAccessEndsAt: DateTime.parse(
        row['trial_full_access_ends_at'] as String,
      ),
      trialEndsAt: DateTime.parse(row['trial_ends_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Workspace model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'name': model.name,
      'industry_tag': model.industryTag,
      'plan': model.plan,
      'status': model.status,
      'trial_started_at': model.trialStartedAt.toIso8601String(),
      'trial_full_access_ends_at': model.trialFullAccessEndsAt
          .toIso8601String(),
      'trial_ends_at': model.trialEndsAt.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String(),
      // created_at is set by Supabase default — we never write it on updates
    };
  }
}
