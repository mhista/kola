// workspace_feature_override_dto.dart
//
// Serverpod WorkspaceFeatureOverride ↔ Supabase
// `workspace_feature_overrides` row.
// Schema: docs/migrations/018_feature_flags.sql (Phase 10).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class WorkspaceFeatureOverrideDto extends BaseDto<WorkspaceFeatureOverride> {
  const WorkspaceFeatureOverrideDto();

  @override
  WorkspaceFeatureOverride fromRow(Map<String, dynamic> row) {
    return WorkspaceFeatureOverride(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      featureKey: row['feature_key'] as String,
      enabled: row['enabled'] as bool,
      note: row['note'] as String,
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(
    WorkspaceFeatureOverride model, {
    bool includeId = false,
  }) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'feature_key': model.featureKey,
      'enabled': model.enabled,
      'note': model.note,
      'created_by': model.createdBy,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
