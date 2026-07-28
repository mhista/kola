// workspace_member_dto.dart
//
// Translates between:
//   Serverpod model  → WorkspaceMember  (generated/workspace_member.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: workspace_members
// Schema: docs/migrations/001_initial_schema.sql (source of truth — not
// duplicated here to avoid the two drifting apart over time).
//
// NOTE: user_id is a Supabase Auth UUID (string), not our own bigserial
//       scheme — see workspace_member.spy.yaml's header comment.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class WorkspaceMemberDto extends BaseDto<WorkspaceMember> {
  const WorkspaceMemberDto();

  @override
  WorkspaceMember fromRow(Map<String, dynamic> row) {
    return WorkspaceMember(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      userId: row['user_id'] as String,
      role: row['role'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(WorkspaceMember model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'user_id': model.userId,
      'role': model.role,
      // created_at is set by Supabase default — this row is never updated,
      // only inserted or deleted (role changes go through a dedicated
      // repository method rather than a generic update, see below).
    };
  }
}
