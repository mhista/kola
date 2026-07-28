// errand_dto.dart
//
// Translates between:
//   Serverpod model  → Errand  (generated/errand.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: errands
// Schema: docs/migrations/005_errands_and_knowledge_seed.sql (source of
// truth — not duplicated here to avoid the two drifting apart over time).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ErrandDto extends BaseDto<Errand> {
  const ErrandDto();

  @override
  Errand fromRow(Map<String, dynamic> row) {
    return Errand(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      name: row['name'] as String,
      descriptionForAi: row['description_for_ai'] as String,
      source: row['source'] as String,
      builtinHandlerKey: row['builtin_handler_key'] as String?,
      createdVia: row['created_via'] as String,
      permissionScope: row['permission_scope'] as String,
      inputSchemaJson: row['input_schema_json'] as String,
      sensitiveInputKeysJson: row['sensitive_input_keys_json'] as String,
      status: row['status'] as String,
      queryTemplateSql: row['query_template_sql'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Errand model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'name': model.name,
      'description_for_ai': model.descriptionForAi,
      'source': model.source,
      'builtin_handler_key': model.builtinHandlerKey,
      'created_via': model.createdVia,
      'permission_scope': model.permissionScope,
      'input_schema_json': model.inputSchemaJson,
      'sensitive_input_keys_json': model.sensitiveInputKeysJson,
      'status': model.status,
      'query_template_sql': model.queryTemplateSql,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
