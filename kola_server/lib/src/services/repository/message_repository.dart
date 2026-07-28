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

  Future<Message> create({
    required int conversationId,
    required String direction,
    required String senderType,
    required String body,
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
        })
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
