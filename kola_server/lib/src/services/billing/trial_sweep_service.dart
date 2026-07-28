// trial_sweep_service.dart — Phase 5b's other half: actually persisting
// the one real status transition trial_state_machine.dart identifies
// (trialing → paused once trialEndsAt passes). Wired to run on an
// interval from server.dart — see this file's header there for why a
// plain Dart Timer, not a Serverpod FutureCall: Serverpod Mini has no
// Postgres of its own (Supabase is the only persistence layer, per
// server.dart's own header comment), and FutureCall's scheduling state
// is itself normally persisted in Serverpod's own database — relying on
// it here would be assuming infrastructure this project deliberately
// doesn't have. A Timer.periodic inside the same long-running process
// costs nothing extra and needs no new infrastructure.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'trial_state_machine.dart';

class TrialSweepService {
  TrialSweepService({required WorkspaceRepository workspaces, TrialStateMachine? stateMachine})
    : _workspaces = workspaces,
      _stateMachine = stateMachine ?? const TrialStateMachine();

  final WorkspaceRepository _workspaces;
  final TrialStateMachine _stateMachine;

  /// Finds every 'trialing' workspace whose 14-day window has passed and
  /// persists the transition to 'paused', one workspace at a time so a
  /// single bad row can't stop the rest of the sweep. Returns how many
  /// were actually transitioned this run — server.dart logs this so a
  /// silently-empty sweep (e.g. nothing ever pauses because a query is
  /// wrong) is visible, not hidden inside a "ran fine" log line.
  Future<int> sweepOnce({DateTime? now}) async {
    final n = (now ?? DateTime.now()).toUtc();
    final trialing = await _workspaces.listByStatus('trialing');

    var transitioned = 0;
    for (final workspace in trialing) {
      if (!_stateMachine.needsTransition(workspace, now: n)) continue;
      try {
        await _workspaces.setStatus(workspace.id!, 'paused');
        transitioned++;
        Log.info('Trial window ended — workspace ${workspace.id} paused (trialEndsAt was ${workspace.trialEndsAt})');
      } catch (e) {
        Log.error('TrialSweepService: failed to pause workspace ${workspace.id}', error: e);
      }
    }
    return transitioned;
  }
}
