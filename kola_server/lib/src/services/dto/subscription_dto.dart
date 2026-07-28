// subscription_dto.dart
//
// Translates between:
//   Serverpod model  → Subscription  (kola_server/lib/src/generated/subscription.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: subscriptions
// Schema: docs/migrations/008_subscriptions_and_usage_records.sql
//
// NOTE: Supabase uses snake_case column names.
//       Serverpod models use camelCase field names.
//       The DTO handles this mapping explicitly — no magic, no reflection.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class SubscriptionDto extends BaseDto<Subscription> {
  const SubscriptionDto();

  @override
  Subscription fromRow(Map<String, dynamic> row) {
    return Subscription(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      plan: row['plan'] as String,
      gatewayProvider: row['gateway_provider'] as String?,
      gatewayCustomerId: row['gateway_customer_id'] as String?,
      gatewaySubscriptionId: row['gateway_subscription_id'] as String?,
      currentPeriodStart: row['current_period_start'] != null
          ? DateTime.parse(row['current_period_start'] as String)
          : null,
      currentPeriodEnd: row['current_period_end'] != null
          ? DateTime.parse(row['current_period_end'] as String)
          : null,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Subscription model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'plan': model.plan,
      'gateway_provider': model.gatewayProvider,
      'gateway_customer_id': model.gatewayCustomerId,
      'gateway_subscription_id': model.gatewaySubscriptionId,
      'current_period_start': model.currentPeriodStart?.toIso8601String(),
      'current_period_end': model.currentPeriodEnd?.toIso8601String(),
      'status': model.status,
      'updated_at': model.updatedAt.toIso8601String(),
      // created_at is set by Supabase default — we never write it on updates
    };
  }
}
