// task_dto.dart
//
// Translates between:
//   Serverpod model  → Task  (generated/task.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: tasks
// Schema: docs/migrations/059_tasks.sql (Phase 13b).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class TaskDto extends BaseDto<Task> {
  const TaskDto();

  @override
  Task fromRow(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      title: row['title'] as String,
      status: row['status'] as String,
      priority: row['priority'] as String,
      sourceType: row['source_type'] as String?,
      sourceFindingId: row['source_finding_id'] as int?,
      assignee: row['assignee'] as String?,
      dueAt: row['due_at'] == null ? null : DateTime.parse(row['due_at'] as String),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Task model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'title': model.title,
      'status': model.status,
      'priority': model.priority,
      'source_type': model.sourceType,
      'source_finding_id': model.sourceFindingId,
      'assignee': model.assignee,
      'due_at': model.dueAt?.toIso8601String(),
      'completed_at': model.completedAt?.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
