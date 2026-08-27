// workspace_finding_repository.dart
//
// Storage for what the sweep noticed. See migration 034 for the schema
// and workspace_sweep_service.dart for what produces these.
//
// MULTI-TENANCY: every method takes workspaceId and filters on it. Same
// rule as every other repository here — RLS is enabled with no policies,
// so this layer IS the isolation boundary, not a second line of defence
// behind one.

import 'package:logging/logging.dart';

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/workspace_finding_dto.dart';
import 'package:kola_server/src/services/observation/workspace_sweep_service.dart';
import 'supabase_client.dart';

final _log = Logger('WorkspaceFindingRepository');

const _dto = WorkspaceFindingDto();

class WorkspaceFindingRepository {
  const WorkspaceFindingRepository();

  /// A dismissal used to be permanent — see git history's original
  /// comment here: "A previously DISMISSED one stays dismissed." That
  /// was a real design choice, and it produced a real bug: an owner
  /// dismisses "8 products running low" once, the exact same products
  /// are STILL low three weeks later, and the Overview keeps saying
  /// "Nothing needs you right now" forever — the section reads as
  /// broken/disappeared, because from the owner's side it effectively
  /// is. Reported directly by a real user: "recommendations stopped
  /// showing up entirely... that's not supposed to be the case."
  ///
  /// [dismissCooldown] is the fix: "I saw this, stop telling me" is
  /// honoured for a bounded window, not forever. After the cooldown
  /// elapses, a finding whose underlying condition is STILL being
  /// actively detected (last_seen_at recent — see reconcile) is treated
  /// as open again, the same way a resolved-then-recurring finding
  /// already was. Dismissing it again (WorkspaceFindingRepository
  /// .dismiss) restarts the window from that moment.
  static const dismissCooldown = Duration(days: 7);

  /// Open findings: not resolved, and either never dismissed or
  /// dismissed longer ago than [dismissCooldown] — see that field's
  /// header for why this is no longer a hard permanent exclusion.
  ///
  /// Ordered worst-first, then OLDEST-first within a severity. The
  /// oldest tie-break is deliberate — among equally urgent things, the
  /// one that has been wrong longest is the one most likely to have been
  /// forgotten.
  Future<List<WorkspaceFinding>> listOpen(int workspaceId) async {
    _log.fine('listOpen($workspaceId)');
    final cutoff = DateTime.now().toUtc().subtract(dismissCooldown).toIso8601String();
    final response = await supabase
        .from('workspace_findings')
        .select()
        .eq('workspace_id', workspaceId)
        // `.filter(col, 'is', null)` and NOT the dedicated null helper.
        //
        // postgrest-dart renamed that helper across major versions, and
        // api_key_repository.dart already settled this: `filter` is the
        // generic escape hatch and has been stable throughout. Following
        // the existing precedent rather than rediscovering the rename at
        // runtime.
        .filter('resolved_at', 'is', null)
        // Raw PostgREST `or` filter string, not two chained calls — a
        // second `.filter`/`.eq` call ANDs with everything before it,
        // and this needs OR: "never dismissed" OR "dismissed a while
        // ago". `.is.null` and `.lt.<iso8601>` are the same operator
        // spellings used elsewhere in this file via `.filter`.
        .or('dismissed_at.is.null,dismissed_at.lt.$cutoff')
        .order('severity', ascending: true)
        .order('first_seen_at', ascending: true);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Makes stored findings match [detected], and returns what is open.
  ///
  /// ── THREE CASES, AND THE THIRD IS THE IMPORTANT ONE ───────────────
  ///
  ///   detected + stored     touch last_seen_at. first_seen_at is NOT
  ///                         written, which is what lets the dashboard
  ///                         say "for six days".
  ///   detected + new        insert.
  ///   stored + not detected resolve.
  ///
  /// Without the third, restocking a product leaves its alert on screen
  /// until someone clears it by hand — and an owner who sees one stale
  /// item stops trusting the whole section.
  ///
  /// A detected finding that was previously RESOLVED comes back: the
  /// condition is true again, and that is a new occurrence of the same
  /// thing rather than a new thing. A previously DISMISSED one stays
  /// dismissed — see below.
  Future<List<WorkspaceFinding>> reconcile({
    required int workspaceId,
    required List<DetectedFinding> detected,
    required DateTime now,
  }) async {
    _log.fine('reconcile($workspaceId, ${detected.length} detected)');

    final iso = now.toIso8601String();

    if (detected.isNotEmpty) {
      final rows = [
        for (final d in detected)
          {
            'workspace_id': workspaceId,
            'kind': d.kind,
            'fingerprint': d.fingerprint,
            'severity': d.severity,
            'title': d.title,
            'detail': d.detail,
            'subject_type': d.subjectType,
            'subject_id': d.subjectId,
            'confidence': d.confidence,
            // Only meaningful on INSERT. On conflict the stored value is
            // kept, because upsert's excluded row is not applied to
            // columns left out of the update — see the note below.
            'first_seen_at': iso,
            'last_seen_at': iso,
            // Clears a previous resolution. The condition is true again.
            'resolved_at': null,
            'updated_at': iso,
          },
      ];

      // onConflict names the unique index from migration 034.
      //
      // NOTE ON WHAT UPSERT OVERWRITES: postgrest's upsert updates every
      // column present in the payload. first_seen_at IS in the payload,
      // so this would reset it on every sweep — which would silently
      // destroy the one thing the table exists for.
      //
      // Handled by writing first_seen_at back to its stored value below
      // rather than by omitting it here, because omitting it would leave
      // the column unset on genuine inserts and violate NOT NULL.
      final existing = await _fingerprintFirstSeen(workspaceId);
      for (final row in rows) {
        final prior = existing[row['fingerprint']];
        if (prior != null) row['first_seen_at'] = prior;
      }

      await supabase.from('workspace_findings').upsert(
            rows,
            onConflict: 'workspace_id,fingerprint',
          );
    }

    // Resolve anything no longer detected.
    //
    // Scoped to rows that are currently OPEN and either never dismissed
    // or dismissed past [WorkspaceFindingRepository.dismissCooldown] —
    // touching a STILL-suppressed dismissed row would revive it as
    // "resolved", which is a different and misleading state (the owner
    // did not fix it, they chose to ignore it). But once the cooldown
    // has elapsed, [listOpen] already treats the row as open again — if
    // the sweep also finds the underlying condition is genuinely gone,
    // marking it resolved here is what stops a fixed problem from
    // sitting in "Needs your attention" forever just because it was
    // dismissed once, weeks ago, before it was actually fixed.
    final dismissCutoff =
        now.subtract(WorkspaceFindingRepository.dismissCooldown).toIso8601String();
    final fingerprints = [for (final d in detected) d.fingerprint];
    var stale = supabase
        .from('workspace_findings')
        .update({'resolved_at': iso, 'updated_at': iso})
        .eq('workspace_id', workspaceId)
        .filter('resolved_at', 'is', null)
        .or('dismissed_at.is.null,dismissed_at.lt.$dismissCutoff');
    if (fingerprints.isNotEmpty) {
      // Everything the sweep did NOT just report.
      //
      // The value is a PostgREST list LITERAL - `("a","b")` - not a Dart
      // List. `not` passes its value straight into the query string, so
      // a List would stringify as `[a, b]`, match nothing, and quietly
      // resolve every open finding on every sweep.
      //
      // Each fingerprint is quoted because they contain a colon
      // ('product_out_of_stock:41'), which PostgREST would otherwise
      // read as a value separator.
      final list = fingerprints.map((f) => '"$f"').join(',');
      stale = stale.not('fingerprint', 'in', '($list)');
    }
    await stale;

    return listOpen(workspaceId);
  }

  /// fingerprint → stored first_seen_at, for the upsert above.
  Future<Map<String, String>> _fingerprintFirstSeen(int workspaceId) async {
    final response = await supabase
        .from('workspace_findings')
        .select('fingerprint, first_seen_at')
        .eq('workspace_id', workspaceId);

    return {
      for (final row in response as List)
        (row as Map<String, dynamic>)['fingerprint'] as String:
            row['first_seen_at'] as String,
    };
  }

  /// "I know about this one."
  ///
  /// Scoped by workspace as well as id: without it, a crafted id would
  /// let one workspace dismiss another's finding. The id alone is not an
  /// authorization.
  Future<void> dismiss(int workspaceId, int findingId) async {
    _log.info('dismiss($workspaceId, $findingId)');
    await supabase
        .from('workspace_findings')
        .update({
          'dismissed_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', findingId)
        .eq('workspace_id', workspaceId);
  }
}
