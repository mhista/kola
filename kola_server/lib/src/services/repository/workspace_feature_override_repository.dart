// workspace_feature_override_repository.dart
//
// PHASE 10. Database access for per-workspace feature overrides.
//
// Workspace-scoped in the normal way (SRS.md §5), with one deliberate
// exception: [listByFeature] is global, so kola_admin can answer "who
// is currently in the beta for this feature?" — a question that cannot
// be answered workspace-by-workspace. Same precedent as
// SupportTicketRepository.listOpenPastDeadline.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/workspace_feature_override_dto.dart';
import 'supabase_client.dart';

final _log = Logger('WorkspaceFeatureOverrideRepository');

const _dto = WorkspaceFeatureOverrideDto();

class WorkspaceFeatureOverrideRepository {
  const WorkspaceFeatureOverrideRepository();

  /// Every override for one workspace. Loaded whole and cached by
  /// FeatureFlagService rather than queried per feature — a workspace
  /// has at most a handful of these.
  Future<List<WorkspaceFeatureOverride>> listByWorkspace(int workspaceId) async {
    final response = await supabase
        .from('workspace_feature_overrides')
        .select()
        .eq('workspace_id', workspaceId);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every workspace with an override for one feature — "who is in this
  /// beta?". Global by design; see file header.
  Future<List<WorkspaceFeatureOverride>> listByFeature(String featureKey) async {
    final response = await supabase
        .from('workspace_feature_overrides')
        .select()
        .eq('feature_key', featureKey);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Creates or replaces one workspace's override for one feature.
  /// Upsert on (workspace_id, feature_key) so granting a workspace beta
  /// access twice is idempotent rather than creating a second row that
  /// would make resolution ambiguous.
  Future<void> upsert(WorkspaceFeatureOverride override) async {
    _log.info('Override: workspace=${override.workspaceId} '
        'feature=${override.featureKey} enabled=${override.enabled} '
        '(${override.note})');

    await supabase.from('workspace_feature_overrides').upsert(
      _dto.toRow(override),
      onConflict: 'workspace_id,feature_key',
      ignoreDuplicates: false,
    );
  }

  /// Removes an override, returning the workspace to whatever the
  /// platform-wide state says. Distinct from setting enabled=false,
  /// which is an active decision to keep the feature off for this
  /// workspace even after general release.
  Future<void> remove(int workspaceId, String featureKey) async {
    _log.info('Override removed: workspace=$workspaceId feature=$featureKey');
    await supabase
        .from('workspace_feature_overrides')
        .delete()
        .eq('workspace_id', workspaceId)
        .eq('feature_key', featureKey);
  }
}
