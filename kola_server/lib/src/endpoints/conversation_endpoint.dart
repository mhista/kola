// conversation_endpoint.dart
//
// The bare-bones inbox surface (task #96) — enough for a human to see
// which conversations are escalated, read the thread, and reply,
// WITHOUT building the full Phase 4 dashboard. Matches
// "Kola Conversations.dc.html"'s eventual UI conceptually (left rail =
// listEscalated, center thread = getMessages, reply box =
// sendHumanReply) but this endpoint doesn't know or care what renders
// it — could be curled directly today.
//
// Mirrors ErrandEndpoint's shape: requireWorkspaceAccess on every
// method, findByIdScoped before any mutation, Log.success on writes.

import 'package:serverpod/serverpod.dart' hide Message;
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/message_repository.dart';
import 'package:kola_server/src/services/messaging/telegram/telegram_bot_registry.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_bot_registry.dart';
import 'package:kola_server/kola_logger.dart';

class ConversationEndpoint extends Endpoint {
  ConversationRepository get _conversations => getIt<ConversationRepository>();
  MessageRepository get _messages => getIt<MessageRepository>();

  /// Every escalated conversation for a workspace, most recently active
  /// first — the inbox's main queue.
  Future<List<Conversation>> listEscalated(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _conversations.listEscalatedByWorkspace(workspaceId);
  }

  /// Every conversation for a workspace regardless of status — for a
  /// future "all conversations" view beyond just the escalated queue.
  Future<List<Conversation>> listAll(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _conversations.listByWorkspace(workspaceId);
  }

  /// The full message thread for one conversation, oldest first.
  Future<List<Message>> getMessages(
    Session session,
    String accessToken,
    int workspaceId,
    int conversationId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    await _requireConversationInWorkspace(conversationId, workspaceId);
    return _messages.listByConversation(conversationId);
  }

  /// The human's reply — persisted as a Message (senderType 'human')
  /// and actually sent back to the customer over whichever platform
  /// (Telegram/WhatsApp) the conversation is on, via that platform's
  /// registry (same messagingFor(channelId) adapters the bot itself
  /// uses to send). Does NOT change the conversation's status — it
  /// stays 'escalated' until the human explicitly closes it (see
  /// [closeConversation]), since one reply doesn't necessarily resolve
  /// things.
  Future<Message> sendHumanReply(
    Session session,
    String accessToken,
    int workspaceId,
    int conversationId,
    String body,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    final conversation = await _requireConversationInWorkspace(conversationId, workspaceId);

    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw KolaException(message: 'Reply body cannot be empty.');
    }

    final adapter = conversation.platformType == 'telegram'
        ? TelegramBotRegistry.instance.messagingFor(conversation.channelId)
        : WhatsAppBotRegistry.instance.messagingFor(conversation.channelId);

    if (adapter == null) {
      throw KolaException(
        message:         'Channel ${conversation.channelId} (${conversation.platformType}) is not '
        'currently connected — cannot send this reply.',
      );
    }

    final result = await adapter.sendText(recipient: conversation.externalUserId, text: trimmed);
    if (!result.success) {
      throw KolaException(message: 'Failed to send reply: ${result.errorMessage ?? "unknown error"}');
    }

    final message = await _messages.create(
      conversationId: conversationId,
      direction: 'outbound',
      senderType: 'human',
      body: trimmed,
    );
    await _conversations.touchLastMessageAt(conversationId);

    Log.success(
      'Human reply sent',
      data: {'workspaceId': workspaceId, 'conversationId': conversationId},
      session: session,
    );

    return message;
  }

  /// Marks a conversation resolved — status flips to 'closed', so the
  /// bot resumes auto-replying if the customer messages again (see
  /// ConversationRepository.findOrCreate's reopen-on-new-message logic).
  Future<Conversation> closeConversation(
    Session session,
    String accessToken,
    int workspaceId,
    int conversationId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    await _requireConversationInWorkspace(conversationId, workspaceId);

    final updated = await _conversations.setStatus(conversationId, 'closed');

    Log.success(
      'Conversation closed',
      data: {'workspaceId': workspaceId, 'conversationId': conversationId},
      session: session,
    );

    return updated;
  }

  Future<Conversation> _requireConversationInWorkspace(int conversationId, int workspaceId) async {
    final conversation = await _conversations.findByIdScoped(conversationId, workspaceId);
    if (conversation == null) {
      throw KolaException(message: 'Conversation $conversationId not found in workspace $workspaceId');
    }
    return conversation;
  }
}
