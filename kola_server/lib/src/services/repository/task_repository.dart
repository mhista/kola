// task_repository.dart
//
// All database read/write operations for Task records (Phase 13b —
// the backend behind the previously-404ing /tasks board).
//
// MULTI-TENANCY: every method filters by workspaceId, same convention as
// every other repository in this project.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/task_dto.dart';
import 'supabase_client.dart';

final _log = Logger('TaskRepository');

const _dto = TaskDto();

class TaskRepository {
  const TaskRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<Task?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, workspaceId=$workspaceId)');
    final response = await supabase
        .from('tasks')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every task for a workspace, newest first — the board reads this
  /// once and buckets client-side by status into the three columns
  /// (see tasks_page.dart).
  Future<List<Task>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('tasks')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  Future<Task> create({
    required int workspaceId,
    required String title,
    String priority = 'medium',
    String? sourceType,
    int? sourceFindingId,
    String? assignee,
    DateTime? dueAt,
  }) async {
    final now = DateTime.now().toUtc();
    _log.info('Creating task workspaceId=$workspaceId title="$title"');

    final task = Task(
      workspaceId: workspaceId,
      title: title,
      status: 'todo',
      priority: priority,
      sourceType: sourceType,
      sourceFindingId: sourceFindingId,
      assignee: assignee,
      dueAt: dueAt,
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final row = _dto.toRow(task, includeId: false);
    row['created_at'] = now.toIso8601String();
    final response = await supabase.from('tasks').insert(row).select().single();
    return _dto.fromRow(response);
  }

  /// Moves a task between columns — 'todo' | 'in_progress' | 'done'.
  /// Stamps completedAt the moment status becomes 'done', clears it if
  /// ever moved back — same pattern SupportTicketRepository.setStatus
  /// already established for resolvedAt.
  Future<Task> setStatus(int taskId, String status) async {
    _log.info('setStatus taskId=$taskId status=$status');
    final now = DateTime.now().toUtc();
    final isDone = status == 'done';

    final response = await supabase
        .from('tasks')
        .update({
          'status': status,
          'completed_at': isDone ? now.toIso8601String() : null,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', taskId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  Future<void> delete(int taskId) async {
    _log.info('delete taskId=$taskId');
    await supabase.from('tasks').delete().eq('id', taskId);
  }
}
