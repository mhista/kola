// feature_flag_dto.dart
//
// Serverpod FeatureFlag ↔ Supabase `feature_flags` row.
// Schema: docs/migrations/018_feature_flags.sql (Phase 10).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class FeatureFlagDto extends BaseDto<FeatureFlag> {
  const FeatureFlagDto();

  @override
  FeatureFlag fromRow(Map<String, dynamic> row) {
    return FeatureFlag(
      id: row['id'] as int?,
      key: row['key'] as String,
      name: row['name'] as String,
      description: row['description'] as String,
      state: row['state'] as String,
      minimumPlan: row['minimum_plan'] as String?,
      releasePhase: row['release_phase'] as String,
      externallyGated: (row['externally_gated'] as bool?) ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(FeatureFlag model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'key': model.key,
      'name': model.name,
      'description': model.description,
      'state': model.state,
      'minimum_plan': model.minimumPlan,
      'release_phase': model.releasePhase,
      'externally_gated': model.externallyGated,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
