// channel_dto.dart
//
// Translates between:
//   Serverpod model  → Channel  (generated/channel.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: channels
// Schema: docs/migrations/001_initial_schema.sql (source of truth — not
// duplicated here to avoid the two drifting apart over time).
//
// NOTE: encrypted_credential is ciphertext only — see channel.spy.yaml's
//       header comment. This DTO never decrypts; decryption happens one
//       layer up, only at the moment a credential is actually needed to
//       make an outbound call (Phase 2).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ChannelDto extends BaseDto<Channel> {
  const ChannelDto();

  @override
  Channel fromRow(Map<String, dynamic> row) {
    return Channel(
      id: row['id'] as int?,
      botId: row['bot_id'] as int,
      platformType: row['platform_type'] as String,
      displayName: row['display_name'] as String?,
      encryptedCredential: row['encrypted_credential'] as String?,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Channel model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'bot_id': model.botId,
      'platform_type': model.platformType,
      'display_name': model.displayName,
      'encrypted_credential': model.encryptedCredential,
      'status': model.status,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
