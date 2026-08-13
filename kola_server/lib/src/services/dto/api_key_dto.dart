// api_key_dto.dart
//
// Serverpod model ↔ Supabase row for `api_keys` (migration 026).
//
// NOTE: there is no plaintext column and no plaintext field. The key is
// hashed at creation and never stored — see api_key.spy.yaml's header.
// This DTO could not leak one if it tried.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ApiKeyDto extends BaseDto<ApiKey> {
  const ApiKeyDto();

  @override
  ApiKey fromRow(Map<String, dynamic> row) {
    return ApiKey(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      name: row['name'] as String,
      keyPrefix: row['key_prefix'] as String,
      keyHash: row['key_hash'] as String,
      lastFour: row['last_four'] as String,
      scope: row['scope'] as String,
      lastUsedAt: row['last_used_at'] == null
          ? null
          : DateTime.parse(row['last_used_at'] as String),
      revokedAt: row['revoked_at'] == null
          ? null
          : DateTime.parse(row['revoked_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(ApiKey model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'name': model.name,
      'key_prefix': model.keyPrefix,
      'key_hash': model.keyHash,
      'last_four': model.lastFour,
      'scope': model.scope,
      'last_used_at': model.lastUsedAt?.toIso8601String(),
      'revoked_at': model.revokedAt?.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
