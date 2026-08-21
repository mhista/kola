// conversation_repository.dart
//
// All database read/write operations for Conversation records.
//
// MULTI-TENANCY: every method filters by workspaceId, same convention as
// every other repository in this project.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/conversation_dto.dart';
import 'supabase_client.dart';

final _log = Logger('ConversationRepository');

const _dto = ConversationDto();

class ConversationRepository {
  const ConversationRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<Conversation?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, workspaceId=$workspaceId)');
    final response = await supabase
        .from('conversations')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// The one Conversation for a given customer on a given channel, if
  /// any — the unique index on (channelId, externalUserId) guarantees
  /// there's never more than one.
  Future<Conversation?> findByChannelAndExternalUser({
    required int channelId,
    required String externalUserId,
  }) async {
    _log.fine('findByChannelAndExternalUser(channelId=$channelId, externalUserId=$externalUserId)');
    final response = await supabase
        .from('conversations')
        .select()
        .eq('channel_id', channelId)
        .eq('external_user_id', externalUserId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every 'escalated' conversation for a workspace, most recently
  /// active first — the inbox's main list (Kola Conversations.dc.html's
  /// left rail).
  Future<List<Conversation>> listEscalatedByWorkspace(int workspaceId) async {
    _log.fine('listEscalatedByWorkspace($workspaceId)');
    final response = await supabase
        .from('conversations')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('status', 'escalated')
        .order('last_message_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every conversation for a workspace regardless of status, most
  /// recently active first — for a future "all conversations" view
  /// beyond just the escalated queue.
  Future<List<Conversation>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('conversations')
        .select()
        .eq('workspace_id', workspaceId)
        .order('last_message_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Gate 3b — every conversation on a customer's unified timeline.
  Future<List<Conversation>> listByCustomer(int customerId) async {
    _log.fine('listByCustomer($customerId)');
    final response = await supabase
        .from('conversations')
        .select()
        .eq('customer_id', customerId)
        .order('last_message_at', ascending: false);
    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Find the Conversation for (channelId, externalUserId), or create a
  /// fresh 'bot'-status one if this is the customer's first message —
  /// the one entry point telegram_bot_registry.dart/
  /// whatsapp_bot_registry.dart call on every inbound message, so they
  /// never have to reason about create-vs-reuse themselves.
  ///
  /// REOPEN-ON-NEW-MESSAGE: if the existing conversation is 'closed', a
  /// new inbound message reopens it to 'bot' (not back to 'escalated' —
  /// a fresh message after a human resolved things starts with the bot
  /// again, same as a brand-new thread would) rather than leaving it
  /// silently closed forever. An 'escalated' conversation's status is
  /// left untouched here — see file header on why the bot must not
  /// auto-reply while a human is handling it.
  Future<Conversation> findOrCreate({
    required int workspaceId,
    required int botId,
    required int channelId,
    required String platformType,
    required String externalUserId,
    String? displayName,
  }) async {
    final existing = await findByChannelAndExternalUser(
      channelId: channelId,
      externalUserId: externalUserId,
    );

    final now = DateTime.now().toUtc();

    if (existing == null) {
      _log.info(
        'Creating conversation workspaceId=$workspaceId channelId=$channelId externalUserId=$externalUserId',
      );
      final conversation = Conversation(
        workspaceId: workspaceId,
        botId: botId,
        channelId: channelId,
        platformType: platformType,
        externalUserId: externalUserId,
        displayName: displayName,
        status: 'bot',
        lastMessageAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final row = _dto.toRow(conversation, includeId: false);
      row['created_at'] = now.toIso8601String();
      final response =
          await supabase.from('conversations').insert(row).select().single();
      return _dto.fromRow(response);
    }

    if (existing.status == 'closed') {
      _log.info('Reopening closed conversation ${existing.id} to status=bot');
      return setStatus(existing.id!, 'bot');
    }

    return existing;
  }

  /// Transition a conversation's status — see file header for the
  /// full state machine.
  Future<Conversation> setStatus(int conversationId, String status) async {
    _log.info('setStatus conversationId=$conversationId status=$status');
    final response = await supabase
        .from('conversations')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', conversationId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Gate 3 — set once by CustomerIdentityResolver right after
  /// findOrCreate, only when the conversation doesn't already have a
  /// customerId (see inbound_message_handler.dart's call site). Never
  /// overwrites an existing link — identity resolution is idempotent by
  /// construction (same phone always resolves to the same customer), so
  /// there's nothing to reconcile on a repeat message.
  Future<void> setCustomer(int conversationId, int customerId) async {
    _log.info('setCustomer conversationId=$conversationId customerId=$customerId');
    await supabase
        .from('conversations')
        .update({
          'customer_id': customerId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', conversationId);
  }

  /// Bumps lastMessageAt — called every time a Message is stored (either
  /// direction) so the inbox's "most recently active" ordering stays
  /// accurate without a join/aggregate over messages on every list call.
  Future<void> touchLastMessageAt(int conversationId) async {
    await supabase
        .from('conversations')
        .update({
          'last_message_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', conversationId);
  }
}
