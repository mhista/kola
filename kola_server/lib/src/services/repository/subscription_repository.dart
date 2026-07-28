// subscription_repository.dart
//
// All database read/write operations for Subscription records — a
// workspace's billing-gateway relationship (see subscription.spy.yaml's
// header for why this is separate from Workspace.plan/.status).
//
// PATTERN: same as every other repository in this project — speaks only
// in Serverpod model types, SubscriptionDto handles the Supabase JSON
// translation, callers never see raw Maps.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/subscription_dto.dart';
import 'supabase_client.dart';

final _log = Logger('SubscriptionRepository');

const _dto = SubscriptionDto();

class SubscriptionRepository {
  const SubscriptionRepository();

  /// A workspace has at most one Subscription row (see
  /// subscription_workspace_idx) — null means no gateway relationship
  /// exists yet, which is the normal state for every trialing workspace.
  Future<Subscription?> findByWorkspace(int workspaceId) async {
    _log.fine('findByWorkspace($workspaceId)');
    final response = await supabase
        .from('subscriptions')
        .select()
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Creates the FIRST Subscription row for a workspace — called the
  /// moment Phase 5c's gateway integration actually establishes a
  /// billing relationship (a successful checkout), never at workspace
  /// creation (see subscription.spy.yaml's header).
  Future<Subscription> create({
    required int workspaceId,
    required String plan,
    String? gatewayProvider,
    String? gatewayCustomerId,
    String? gatewaySubscriptionId,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    String status = 'none',
    DateTime? now,
  }) async {
    final createdAt = now ?? DateTime.now().toUtc();
    _log.info('Creating subscription workspaceId=$workspaceId plan=$plan');

    final subscription = Subscription(
      workspaceId: workspaceId,
      plan: plan,
      gatewayProvider: gatewayProvider,
      gatewayCustomerId: gatewayCustomerId,
      gatewaySubscriptionId: gatewaySubscriptionId,
      currentPeriodStart: currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd,
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final row = _dto.toRow(subscription, includeId: false);
    row['created_at'] = createdAt.toIso8601String();

    final response = await supabase
        .from('subscriptions')
        .insert(row)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Updates an existing Subscription's mutable fields (plan change,
  /// gateway webhook syncing period dates/status, etc). Matches on id.
  Future<Subscription> update(Subscription subscription) async {
    _log.info('Updating subscription id=${subscription.id}');
    final row = _dto.toRow(subscription, includeId: false);
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await supabase
        .from('subscriptions')
        .update(row)
        .eq('id', subscription.id!)
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
