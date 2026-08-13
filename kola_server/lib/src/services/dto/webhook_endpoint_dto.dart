// webhook_endpoint_dto.dart
//
// Serverpod model ↔ Supabase row for `webhook_endpoints` (migration 026).
//
// NOTE on `events`: the column is a Postgres text[], which the Supabase
// client hands back as a List<dynamic>. Cast element-wise rather than
// with `as List<String>` — that cast succeeds on an empty list and
// throws on a populated one, which is the worst possible place to find
// out.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class WebhookEndpointDto extends BaseDto<WebhookEndpoint> {
  const WebhookEndpointDto();

  @override
  WebhookEndpoint fromRow(Map<String, dynamic> row) {
    return WebhookEndpoint(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      url: row['url'] as String,
      events: [
        for (final e in (row['events'] as List? ?? const [])) e.toString(),
      ],
      status: row['status'] as String,
      encryptedSecret: row['encrypted_secret'] as String?,
      lastDeliveryAt: row['last_delivery_at'] == null
          ? null
          : DateTime.parse(row['last_delivery_at'] as String),
      lastError: row['last_error'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(WebhookEndpoint model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'url': model.url,
      'events': model.events,
      'status': model.status,
      'encrypted_secret': model.encryptedSecret,
      'last_delivery_at': model.lastDeliveryAt?.toIso8601String(),
      'last_error': model.lastError,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
