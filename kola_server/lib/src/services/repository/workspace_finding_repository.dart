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

  /// Open findings: neither resolved nor dismissed.
  ///
  /// Ordered worst-first, then OLDEST-first within a severity. The
  /// oldest tie-break is deliberate — among equally urgent things, the
  /// one that has been wrong longest is the one most likely to have been
  /// forgotten.
  Future<List<WorkspaceFinding>> listOpen(int workspaceId) async {
    _log.fine('listOpen($workspaceId)');
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
        .filter('dismissed_at', 'is', null)
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
    // Scoped to rows that are currently OPEN and not dismissed: touching
    // a dismissed row would revive it as "resolved", which is a different
    // and misleading state — the owner did not fix it, they chose to
    // ignore it.
    final fingerprints = [for (final d in detected) d.fingerprint];
    var stale = supabase
        .from('workspace_findings')
        .update({'resolved_at': iso, 'updated_at': iso})
        .eq('workspace_id', workspaceId)
        .filter('resolved_at', 'is', null)
        .filter('dismissed_at', 'is', null);
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
