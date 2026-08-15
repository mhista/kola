// message_repository.dart
//
// All database read/write operations for Message records. No workspace-
// scoping on reads here directly (unlike most repositories) — every
// caller reaches Message through a Conversation it has already fetched
// with findByIdScoped (which IS workspace-scoped), so isolation is
// enforced one level up, same as ErrandCredential is reached only
// through an already-scoped Errand.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/message_dto.dart';
import 'supabase_client.dart';

final _log = Logger('MessageRepository');

const _dto = MessageDto();

class MessageRepository {
  const MessageRepository();

  /// Every message in a conversation, oldest first — the message thread
  /// (Kola Conversations.dc.html's center panel).
  Future<List<Message>> listByConversation(int conversationId) async {
    _log.fine('listByConversation($conversationId)');
    final response = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// [mediaKind] set with [mediaUrl] null is a DELIBERATE, MEANINGFUL
  /// state, not an error: the customer sent a photo and it could not be
  /// stored. Migration 032's header says so, and the dashboard renders
  /// it as "sent a photo (couldn't be saved)". Collapsing it to a plain
  /// text message would lose the fact that a picture was ever sent.
  Future<Message> create({
    required int conversationId,
    required String direction,
    required String senderType,
    required String body,
    String? mediaKind,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    String? mediaImagekitFileId,
    String? mediaMimeType,
  }) async {
    _log.info('Creating message conversationId=$conversationId direction=$direction senderType=$senderType');
    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'direction': direction,
          'sender_type': senderType,
          'body': body,
          'created_at': now.toIso8601String(),
          // Omitted entirely when there is no media, so a text message's
          // row is byte-for-byte what it was before this change.
          if (mediaKind != null) 'media_kind': mediaKind,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (mediaThumbnailUrl != null)
            'media_thumbnail_url': mediaThumbnailUrl,
          if (mediaImagekitFileId != null)
            'media_imagekit_file_id': mediaImagekitFileId,
          if (mediaMimeType != null) 'media_mime_type': mediaMimeType,
        })
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
