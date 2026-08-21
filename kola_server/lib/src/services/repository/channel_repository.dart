// channel_repository.dart
//
// All database read/write operations for Channel records — one row per
// messaging platform a Bot is connected to.
//
// CREDENTIAL HANDLING: this repository stores and returns whatever
// ciphertext it's given in encryptedCredential — it never encrypts or
// decrypts itself. That responsibility belongs to a dedicated encryption
// service (Phase 2, mirroring wallet_encryption_service.dart's pattern),
// kept separate so this file's job stays exactly "talk to the channels
// table" and nothing more.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/channel_dto.dart';
import 'supabase_client.dart';

final _log = Logger('ChannelRepository');

const _dto = ChannelDto();

class ChannelRepository {
  const ChannelRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<Channel?> findById(int id) async {
    _log.fine('findById($id)');
    final response = await supabase
        .from('channels')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every channel connected to a bot (a bot may have both Telegram and
  /// WhatsApp channels simultaneously).
  Future<List<Channel>> listByBot(int botId) async {
    _log.fine('listByBot($botId)');
    final response = await supabase
        .from('channels')
        .select()
        .eq('bot_id', botId);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Find a specific platform's channel for a bot (e.g. "does this bot
  /// already have a Telegram channel?") — used to prevent duplicate
  /// channel rows for the same (bot, platform) pair during onboarding.
  Future<Channel?> findByBotAndPlatform(int botId, String platformType) async {
    _log.fine('findByBotAndPlatform($botId, $platformType)');
    final response = await supabase
        .from('channels')
        .select()
        .eq('bot_id', botId)
        .eq('platform_type', platformType)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every channel currently in 'connected' status — used by the nightly
  /// credential health check (SRS.md §13) to know what to re-verify.
  Future<List<Channel>> listConnected() async {
    _log.fine('listConnected()');
    final response = await supabase
        .from('channels')
        .select()
        .eq('status', 'connected');

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every connected channel for one platform — used by
  /// TelegramBotRegistry.bootstrapFromDb() at server startup to spin up
  /// exactly the Telegram bots that should be running, without touching
  /// any (future) connected WhatsApp channels in the same query.
  Future<List<Channel>> listConnectedByPlatform(String platformType) async {
    _log.fine('listConnectedByPlatform($platformType)');
    final response = await supabase
        .from('channels')
        .select()
        .eq('status', 'connected')
        .eq('platform_type', platformType);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Create a channel row in 'pending' status — before the owner has
  /// actually completed the connect flow. encryptedCredential is filled
  /// in later via [setCredential] once the flow succeeds.
  Future<Channel> create({
    required int botId,
    required String platformType,
    String? displayName,
  }) async {
    final now = DateTime.now().toUtc();
    _log.info('Creating channel botId=$botId platformType=$platformType');

    final channel = Channel(
      botId: botId,
      platformType: platformType,
      displayName: displayName,
      encryptedCredential: null,
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    );

    final row = _dto.toRow(channel, includeId: false);
    row['created_at'] = now.toIso8601String();

    final response = await supabase
        .from('channels')
        .insert(row)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Store an already-encrypted credential and flip status to 'connected'.
  /// Takes ciphertext, not a plaintext token — see class-level note.
  Future<Channel> setCredential({
    required int channelId,
    required String encryptedCredential,
    String? displayName,
  }) async {
    _log.info('setCredential channelId=$channelId');
    final response = await supabase
        .from('channels')
        .update({
          'encrypted_credential': encryptedCredential,
          if (displayName != null) 'display_name': displayName,
          'status': 'connected',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', channelId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Mark a channel disconnected (expired/revoked token) without deleting
  /// its history — set by the nightly health check when re-verification
  /// fails.
  Future<Channel> markDisconnected(int channelId) async {
    _log.warning('markDisconnected channelId=$channelId');
    final response = await supabase
        .from('channels')
        .update({
          'status': 'disconnected',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', channelId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Gate 1 — records that ChannelHealthCheckService actually attempted
  /// this channel just now, regardless of outcome. Deliberately separate
  /// from [markDisconnected]: a channel that passed its check still
  /// needs lastHealthCheckAt updated, and a channel that failed gets
  /// BOTH calls (see channel_health_check_service.dart's _flagUnhealthy).
  Future<void> touchHealthCheck(int channelId) async {
    _log.fine('touchHealthCheck channelId=$channelId');
    await supabase
        .from('channels')
        .update({'last_health_check_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', channelId);
  }
}
