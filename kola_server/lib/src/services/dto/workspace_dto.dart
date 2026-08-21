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
      ownerName: row['owner_name'] as String?,
      plan: row['plan'] as String,
      status: row['status'] as String,
      trialStartedAt: DateTime.parse(row['trial_started_at'] as String),
      trialFullAccessEndsAt: DateTime.parse(
        row['trial_full_access_ends_at'] as String,
      ),
      trialEndsAt: DateTime.parse(row['trial_ends_at'] as String),
      // PHASE 10 — defaults false when the column is absent, so a read
      // against a database where migration 018 hasn't run yet degrades
      // to "not internal" rather than throwing.
      isInternal: (row['is_internal'] as bool?) ?? false,
      // Defaults to the launch market when the column is absent, so a
      // read against a database where migration 021 has not run keeps
      // the current pricing rather than falling to the international
      // tier and silently re-pricing someone.
      region: (row['region'] as String?) ?? 'NG',
      // Migration 035. Defaults 0 when absent (a pre-till row, or a read
      // against a database where 035 hasn't run) — matching that
      // migration's own DEFAULT 0, never charging VAT nobody opted into.
      taxRateBps: (row['tax_rate_bps'] as int?) ?? 0,
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
      'owner_name': model.ownerName,
      'plan': model.plan,
      'status': model.status,
      'trial_started_at': model.trialStartedAt.toIso8601String(),
      'trial_full_access_ends_at': model.trialFullAccessEndsAt
          .toIso8601String(),
      'trial_ends_at': model.trialEndsAt.toIso8601String(),
      'is_internal': model.isInternal,
      'region': model.region,
      'tax_rate_bps': model.taxRateBps,
      'updated_at': model.updatedAt.toIso8601String(),
      // created_at is set by Supabase default — we never write it on updates
    };
  }
}
