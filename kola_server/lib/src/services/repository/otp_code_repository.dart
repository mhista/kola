// otp_code_repository.dart
//
// All database read/write operations for OtpCode records (Phase 8b:
// OTP delivery via email).
//
// MULTI-TENANCY: [findLatestForConversation] filters by workspaceId, same
// convention as every other per-conversation repository in this project.
//
// "LATEST" IS THE ACTIVE ONE, NOT A SEPARATE FLAG: since 'sendOtp'
// inserts a new row every time (see the model's own header on why),
// there's no dedicated "isActive" column — the most recently created
// row for a conversation is simply the one 'verifyOtp' and the resend-
// cooldown check both care about. Ordering by created_at descending and
// taking the first row is enough; a partial unique index enforcing
// "only one row per conversation with verified_at is null" was
// considered and skipped as unnecessary ceremony for what's already a
// low-write-volume table.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/otp_code_dto.dart';
import 'supabase_client.dart';

final _log = Logger('OtpCodeRepository');

const _dto = OtpCodeDto();

class OtpCodeRepository {
  const OtpCodeRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  /// The most recently issued code for [conversationId], regardless of
  /// whether it's still valid, already verified, or expired — callers
  /// (OtpService) are what decide which of those states it's in and
  /// what to do about it. Null if 'sendOtp' has never been called for
  /// this conversation.
  Future<OtpCode?> findLatestForConversation(int conversationId, int workspaceId) async {
    _log.fine('findLatestForConversation($conversationId, workspaceId=$workspaceId)');
    final response = await supabase
        .from('otp_codes')
        .select()
        .eq('conversation_id', conversationId)
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Issues a new code row — see the model's header on why this is
  /// always an insert, never an update-in-place.
  Future<OtpCode> create({
    required int workspaceId,
    required int conversationId,
    required String recipientEmail,
    required String code,
    required DateTime expiresAt,
  }) async {
    final now = DateTime.now().toUtc();
    _log.info('Creating OTP code workspaceId=$workspaceId conversationId=$conversationId');

    final otp = OtpCode(
      workspaceId: workspaceId,
      conversationId: conversationId,
      recipientEmail: recipientEmail,
      code: code,
      expiresAt: expiresAt,
      attempts: 0,
      createdAt: now,
      updatedAt: now,
    );

    final row = _dto.toRow(otp, includeId: false);
    row['created_at'] = now.toIso8601String();

    final response = await supabase.from('otp_codes').insert(row).select().single();
    return _dto.fromRow(response);
  }

  /// One more wrong guess against [id] — see the model's header on the
  /// 5-attempt cap OtpService enforces using this count.
  Future<void> incrementAttempts(int id, int currentAttempts) async {
    _log.info('incrementAttempts id=$id (was $currentAttempts)');
    await supabase
        .from('otp_codes')
        .update({
          'attempts': currentAttempts + 1,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Marks [id] as successfully verified, right now.
  Future<void> markVerified(int id) async {
    _log.info('markVerified id=$id');
    final now = DateTime.now().toUtc();
    await supabase
        .from('otp_codes')
        .update({
          'verified_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', id);
  }
}
