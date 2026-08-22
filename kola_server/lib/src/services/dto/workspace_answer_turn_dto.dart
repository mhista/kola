// workspace_answer_turn_dto.dart — Connect Gate, subphase 4g.
//
// Supabase table: workspace_answer_turns
// Schema: docs/migrations/043_workspace_answer_turns.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class WorkspaceAnswerTurnDto extends BaseDto<WorkspaceAnswerTurn> {
  const WorkspaceAnswerTurnDto();

  @override
  WorkspaceAnswerTurn fromRow(Map<String, dynamic> row) {
    return WorkspaceAnswerTurn(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      role: row['role'] as String,
      content: row['content'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(WorkspaceAnswerTurn model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'role': model.role,
      'content': model.content,
    };
  }
}
