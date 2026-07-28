// support_ticket_dto.dart
//
// Translates between:
//   Serverpod model  → SupportTicket  (generated/support_ticket.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: support_tickets
// Schema: docs/migrations/011_support_tickets.sql (task #130 / Phase 8b).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class SupportTicketDto extends BaseDto<SupportTicket> {
  const SupportTicketDto();

  @override
  SupportTicket fromRow(Map<String, dynamic> row) {
    return SupportTicket(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      conversationId: row['conversation_id'] as int,
      subject: row['subject'] as String,
      description: row['description'] as String,
      priority: row['priority'] as String,
      status: row['status'] as String,
      slaDeadline: DateTime.parse(row['sla_deadline'] as String),
      resolvedAt: row['resolved_at'] == null
          ? null
          : DateTime.parse(row['resolved_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(SupportTicket model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'conversation_id': model.conversationId,
      'subject': model.subject,
      'description': model.description,
      'priority': model.priority,
      'status': model.status,
      'sla_deadline': model.slaDeadline.toIso8601String(),
      'resolved_at': model.resolvedAt?.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
