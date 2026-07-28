// whatsapp_message_template_dto.dart
//
// Translates between:
//   Serverpod model  → WhatsAppMessageTemplate  (generated/whatsapp_message_template.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: whatsapp_message_templates
// Schema: docs/migrations/014_whatsapp_message_templates.sql (task #150).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class WhatsAppMessageTemplateDto extends BaseDto<WhatsAppMessageTemplate> {
  const WhatsAppMessageTemplateDto();

  @override
  WhatsAppMessageTemplate fromRow(Map<String, dynamic> row) {
    return WhatsAppMessageTemplate(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      channelId: row['channel_id'] as int,
      metaTemplateName: row['meta_template_name'] as String,
      requestedCategory: row['requested_category'] as String,
      metaCategory: row['meta_category'] as String?,
      language: row['language'] as String,
      bodyText: row['body_text'] as String,
      metaTemplateId: row['meta_template_id'] as String?,
      status: row['status'] as String,
      rejectionReason: row['rejection_reason'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(WhatsAppMessageTemplate model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'channel_id': model.channelId,
      'meta_template_name': model.metaTemplateName,
      'requested_category': model.requestedCategory,
      'meta_category': model.metaCategory,
      'language': model.language,
      'body_text': model.bodyText,
      'meta_template_id': model.metaTemplateId,
      'status': model.status,
      'rejection_reason': model.rejectionReason,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
