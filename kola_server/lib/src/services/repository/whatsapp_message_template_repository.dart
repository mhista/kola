// whatsapp_message_template_repository.dart
//
// All database read/write operations for WhatsAppMessageTemplate records
// (task #150). See whatsapp_message_template.spy.yaml's header for why
// these exist at all — only out-of-window business-initiated sends need
// a Meta-approved template; a bot replying inside an open service window
// never touches this.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/whatsapp_message_template_dto.dart';
import 'supabase_client.dart';

final _log = Logger('WhatsAppMessageTemplateRepository');

const _dto = WhatsAppMessageTemplateDto();

class WhatsAppMessageTemplateRepository {
  const WhatsAppMessageTemplateRepository();

  Future<WhatsAppMessageTemplate?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, workspaceId=$workspaceId)');
    final response = await supabase
        .from('whatsapp_message_templates')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every template submitted for a workspace, newest first — the
  /// dashboard's template list/status view.
  Future<List<WhatsAppMessageTemplate>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('whatsapp_message_templates')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<WhatsAppMessageTemplate>> listByChannel(int channelId) async {
    _log.fine('listByChannel($channelId)');
    final response = await supabase
        .from('whatsapp_message_templates')
        .select()
        .eq('channel_id', channelId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<WhatsAppMessageTemplate> create({
    required int workspaceId,
    required int channelId,
    required String metaTemplateName,
    required String requestedCategory,
    required String language,
    required String bodyText,
    String? metaTemplateId,
    String status = 'pending',
  }) async {
    final now = DateTime.now().toUtc();
    _log.info(
      'Creating WhatsApp template workspaceId=$workspaceId channelId=$channelId name=$metaTemplateName',
    );

    final template = WhatsAppMessageTemplate(
      workspaceId: workspaceId,
      channelId: channelId,
      metaTemplateName: metaTemplateName,
      requestedCategory: requestedCategory,
      metaCategory: null,
      language: language,
      bodyText: bodyText,
      metaTemplateId: metaTemplateId,
      status: status,
      rejectionReason: null,
      createdAt: now,
      updatedAt: now,
    );

    final row = _dto.toRow(template, includeId: false);
    row['created_at'] = now.toIso8601String();
    final response =
        await supabase.from('whatsapp_message_templates').insert(row).select().single();
    return _dto.fromRow(response);
  }

  /// Updates a template's status/category/rejection reason after checking
  /// Meta's own review outcome — see WhatsAppTemplateEndpoint.
  /// refreshTemplateStatus, the one caller.
  Future<WhatsAppMessageTemplate> updateStatus({
    required int templateId,
    required String status,
    String? metaCategory,
    String? rejectionReason,
  }) async {
    _log.info('updateStatus templateId=$templateId status=$status');
    final response = await supabase
        .from('whatsapp_message_templates')
        .update({
          'status': status,
          'meta_category': metaCategory,
          'rejection_reason': rejectionReason,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', templateId)
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
