// task_endpoint.dart
//
// Phase 13b — the backend behind the previously-404ing `/tasks` sidebar
// route. Mirrors SupportTicketEndpoint's shape: requireWorkspaceAccess on
// every method, findByIdScoped before any mutation, Log.success on
// writes. Unlike SupportTicket (bot-created only), a Task can also be
// created by hand from the dashboard — the export itself has no visible
// "add task" affordance, but a kanban board with no way to add a card
// defeats its own purpose, so `create` is a deliberate, small addition
// on top of the design, not a subtraction from it (same "adding what's
// needed is fine, cutting what's shown is not" rule this codebase has
// already applied elsewhere — see the Bots list precedent noted in
// docs/PHASE_13_HANDOFF.pdf).

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/task_repository.dart';
import 'package:kola_server/kola_logger.dart';

class TaskEndpoint extends Endpoint {
  TaskRepository get _tasks => getIt<TaskRepository>();

  /// Every task for a workspace — tasks_page.dart buckets these into
  /// the three kanban columns client-side by status.
  Future<List<Task>> list(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _tasks.listByWorkspace(workspaceId);
  }

  /// Creates a task by hand — see file header on why this exists even
  /// though the design export itself only shows pre-populated cards.
  Future<Task> create(
    Session session,
    String accessToken,
    int workspaceId,
    String title, {
    String priority = 'medium',
    String? sourceType,
    int? sourceFindingId,
    String? assignee,
    DateTime? dueAt,
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    const validPriorities = {'high', 'medium', 'low'};
    if (!validPriorities.contains(priority)) {
      throw KolaException(
        message: 'Unknown priority "$priority" — must be one of: ${validPriorities.join(", ")}',
      );
    }
    const validSourceTypes = {'recommendation', 'observation', 'operation'};
    if (sourceType != null && !validSourceTypes.contains(sourceType)) {
      throw KolaException(
        message: 'Unknown sourceType "$sourceType" — must be one of: ${validSourceTypes.join(", ")}',
      );
    }

    final created = await _tasks.create(
      workspaceId: workspaceId,
      title: title,
      priority: priority,
      sourceType: sourceType,
      sourceFindingId: sourceFindingId,
      assignee: assignee,
      dueAt: dueAt,
    );

    Log.success(
      'Task created',
      data: {'workspaceId': workspaceId, 'taskId': created.id, 'title': title},
      session: session,
    );

    return created;
  }

  /// Moves a task between columns — 'todo' | 'in_progress' | 'done'.
  Future<Task> setStatus(
    Session session,
    String accessToken,
    int workspaceId,
    int taskId,
    String status,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    await _requireTaskInWorkspace(taskId, workspaceId);

    const validStatuses = {'todo', 'in_progress', 'done'};
    if (!validStatuses.contains(status)) {
      throw KolaException(message: 'Unknown status "$status" — must be one of: ${validStatuses.join(", ")}');
    }

    final updated = await _tasks.setStatus(taskId, status);

    Log.success(
      'Task status updated',
      data: {'workspaceId': workspaceId, 'taskId': taskId, 'status': status},
      session: session,
    );

    return updated;
  }

  Future<void> delete(
    Session session,
    String accessToken,
    int workspaceId,
    int taskId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    await _requireTaskInWorkspace(taskId, workspaceId);
    await _tasks.delete(taskId);

    Log.success(
      'Task deleted',
      data: {'workspaceId': workspaceId, 'taskId': taskId},
      session: session,
    );
  }

  Future<Task> _requireTaskInWorkspace(int taskId, int workspaceId) async {
    final task = await _tasks.findByIdScoped(taskId, workspaceId);
    if (task == null) {
      throw KolaException(message: 'Task $taskId not found in workspace $workspaceId');
    }
    return task;
  }
}
