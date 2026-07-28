// errand_credential_dto.dart
//
// Translates between:
//   Serverpod model  → ErrandCredential  (generated/errand_credential.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: errand_credentials
// Schema: docs/migrations/005_errands_and_knowledge_seed.sql (source of
// truth — not duplicated here to avoid the two drifting apart over time).
//
// NOTE: encrypted_credential is ciphertext only — see
//       errand_credential.spy.yaml's header comment. This DTO never
//       decrypts; decryption happens one layer up, only at the moment a
//       credential is actually needed to make an outbound call.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class ErrandCredentialDto extends BaseDto<ErrandCredential> {
  const ErrandCredentialDto();

  @override
  ErrandCredential fromRow(Map<String, dynamic> row) {
    return ErrandCredential(
      id: row['id'] as int?,
      errandId: row['errand_id'] as int,
      encryptedCredential: row['encrypted_credential'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(ErrandCredential model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'errand_id': model.errandId,
      'encrypted_credential': model.encryptedCredential,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
