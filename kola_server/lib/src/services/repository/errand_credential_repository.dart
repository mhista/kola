// errand_credential_repository.dart
//
// All database read/write operations for ErrandCredential records — one
// row per webhook/dbCredential/mcp-backed Errand (1:1, enforced by the
// unique index on errand_id — see errand_credential.spy.yaml). A
// 'builtin' Errand never has a row here.
//
// CREDENTIAL HANDLING: this repository stores and returns whatever
// ciphertext it's given in encryptedCredential — it never encrypts or
// decrypts itself, same separation of concerns as ChannelRepository.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/errand_credential_dto.dart';
import 'supabase_client.dart';

final _log = Logger('ErrandCredentialRepository');

const _dto = ErrandCredentialDto();

class ErrandCredentialRepository {
  const ErrandCredentialRepository();

  /// The one credential row for an Errand, if it has one — null for a
  /// 'builtin' Errand, or a webhook/dbCredential/mcp Errand that hasn't
  /// had its credential collected yet.
  Future<ErrandCredential?> findByErrandId(int errandId) async {
    _log.fine('findByErrandId($errandId)');
    final response = await supabase
        .from('errand_credentials')
        .select()
        .eq('errand_id', errandId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Create the (only) credential row for an Errand. Callers must have
  /// already confirmed no row exists yet (findByErrandId returned null)
  /// — the unique index on errand_id makes a second insert fail loudly
  /// rather than silently, but [upsert] below is the right call for a
  /// "create or replace" flow (e.g. rotating a webhook's auth header).
  Future<ErrandCredential> create({
    required int errandId,
    required String encryptedCredential,
  }) async {
    final now = DateTime.now().toUtc();
    _log.info('Creating errand credential errandId=$errandId');

    final credential = ErrandCredential(
      errandId: errandId,
      encryptedCredential: encryptedCredential,
      createdAt: now,
      updatedAt: now,
    );

    final row = _dto.toRow(credential, includeId: false);
    row['created_at'] = now.toIso8601String();

    final response =
        await supabase.from('errand_credentials').insert(row).select().single();
    return _dto.fromRow(response);
  }

  /// Create-or-replace — the usual call for "reconnect this Errand's
  /// credential" flows, since a business rotating a webhook's auth
  /// header or a database's connection string should never need to know
  /// whether a row already exists.
  Future<ErrandCredential> upsert({
    required int errandId,
    required String encryptedCredential,
  }) async {
    _log.info('Upserting errand credential errandId=$errandId');
    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('errand_credentials')
        .upsert({
          'errand_id': errandId,
          'encrypted_credential': encryptedCredential,
          'updated_at': now.toIso8601String(),
        }, onConflict: 'errand_id')
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Deletes the credential row for an errand, if one exists — a no-op
  /// (not an error) if there isn't one, since a 'builtin' Errand never
  /// had one to begin with. Called by ErrandEndpoint.deleteErrand before
  /// it deletes the Errand row itself, so a webhook/dbCredential
  /// Errand's now-orphaned secret never lingers in the database.
  Future<void> deleteForErrand(int errandId) async {
    _log.info('deleteForErrand errandId=$errandId');
    await supabase.from('errand_credentials').delete().eq('errand_id', errandId);
  }
}
