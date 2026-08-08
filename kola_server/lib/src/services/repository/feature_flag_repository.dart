// feature_flag_repository.dart
//
// PHASE 10. Database access for FeatureFlag rows.
//
// DELIBERATELY NOT WORKSPACE-SCOPED — the only repository in this
// project that isn't, and worth stating explicitly so it doesn't look
// like an oversight against SRS.md §5's isolation rule. Feature flags
// are PLATFORM state, not tenant state: there is exactly one row per
// feature for the whole system. Per-workspace variation lives in
// workspace_feature_overrides, which IS workspace-scoped.
//
// Writes here are made only by kola_admin. Nothing in the customer-
// facing server calls setState/upsert — the customer server reads.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/feature_flag_dto.dart';
import 'supabase_client.dart';

final _log = Logger('FeatureFlagRepository');

const _dto = FeatureFlagDto();

class FeatureFlagRepository {
  const FeatureFlagRepository();

  /// Every flag. FeatureFlagService caches the result — see its header
  /// on why this is loaded whole rather than queried per key (the table
  /// is ~45 bounded rows, and per-key lookups on the message path would
  /// be a round trip per check).
  Future<List<FeatureFlag>> listAll() async {
    final response = await supabase
        .from('feature_flags')
        .select()
        .order('release_phase')
        .order('key');

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<FeatureFlag?> findByKey(String key) async {
    final response = await supabase
        .from('feature_flags')
        .select()
        .eq('key', key)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Flips one feature's platform-wide state. THE unlock operation, and
  /// also the kill switch (any state → 'locked').
  ///
  /// The caller is responsible for calling FeatureFlagService.invalidate
  /// afterwards — without it the change waits out the cache TTL, which
  /// is the difference between a kill switch and a kill request.
  Future<void> setState(String key, String state) async {
    _log.warning('Feature "$key" state → $state');
    await supabase.from('feature_flags').update({
      'state': state,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('key', key);
  }

  /// Creates or updates a flag definition. Used by the seed/reconcile
  /// path so a newly-declared feature key gets a row without a manual
  /// migration for every feature added.
  ///
  /// NOTE it deliberately does NOT overwrite `state` on conflict — see
  /// the SQL in migration 018. Re-running a seed must never silently
  /// re-lock a feature that has already been released to customers.
  Future<void> upsertDefinition(FeatureFlag flag) async {
    await supabase.from('feature_flags').upsert(
      _dto.toRow(flag),
      onConflict: 'key',
      ignoreDuplicates: false,
    );
  }
}
