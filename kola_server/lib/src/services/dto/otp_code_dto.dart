// otp_code_dto.dart
//
// Translates between:
//   Serverpod model  → OtpCode  (generated/otp_code.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: otp_codes
// Schema: docs/migrations/013_otp_codes.sql (Phase 8b: OTP delivery via email).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class OtpCodeDto extends BaseDto<OtpCode> {
  const OtpCodeDto();

  @override
  OtpCode fromRow(Map<String, dynamic> row) {
    return OtpCode(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      conversationId: row['conversation_id'] as int,
      recipientEmail: row['recipient_email'] as String,
      code: row['code'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
      attempts: row['attempts'] as int,
      verifiedAt: row['verified_at'] == null ? null : DateTime.parse(row['verified_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(OtpCode model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'conversation_id': model.conversationId,
      'recipient_email': model.recipientEmail,
      'code': model.code,
      'expires_at': model.expiresAt.toIso8601String(),
      'attempts': model.attempts,
      'verified_at': model.verifiedAt?.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
