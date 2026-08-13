// api_key_repository.dart
//
// Storage for `api_keys` (migration 026).
//
// This repository never sees a plaintext key. It stores the hash it is
// given and looks rows up BY hash — the same discipline as
// PaymentGatewayCredentialRepository, which never encrypts, only stores
// ciphertext handed to it. One place to audit, and it is not here.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/api_key_dto.dart';
import 'supabase_client.dart';

final _log = Logger('ApiKeyRepository');

const _dto = ApiKeyDto();

class ApiKeyRepository {
  const ApiKeyRepository();

  /// Every key for a workspace, revoked ones included.
  ///
  /// Revoked keys are RETURNED, not filtered: the design shows them so an
  /// owner can see what they turned off and when. Hiding them would make
  /// "why did my integration stop working" unanswerable from the screen.
  Future<List<ApiKey>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('api_keys')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// The authentication path: find a LIVE key by hash.
  ///
  /// Filters `revoked_at is null` in the query rather than in Dart. A
  /// revoked key must never authenticate, and a filter applied after the
  /// fetch is one early `return` away from being skipped.
  Future<ApiKey?> findLiveByHash(String keyHash) async {
    _log.fine('findLiveByHash(…)');
    final response = await supabase
        .from('api_keys')
        .select()
        .eq('key_hash', keyHash)
        // `.filter(col, 'is', null)` rather than `.isFilter(...)`:
        // postgrest-dart renamed the dedicated helper across major
        // versions (`is_` → `isFilter`), and this repository has no
        // precedent to copy. `filter` is the generic escape hatch and
        // has been stable throughout.
        .filter('revoked_at', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  Future<ApiKey> create({
    required int workspaceId,
    required String name,
    required String keyPrefix,
    required String keyHash,
    required String lastFour,
    required String scope,
  }) async {
    _log.fine('create($workspaceId, $name, $scope)');
    final response = await supabase
        .from('api_keys')
        .insert({
          'workspace_id': workspaceId,
          'name': name,
          'key_prefix': keyPrefix,
          'key_hash': keyHash,
          'last_four': lastFour,
          'scope': scope,
        })
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Revokes by stamping a time, never by deleting.
  ///
  /// Idempotent on purpose: revoking an already-revoked key keeps the
  /// ORIGINAL timestamp, because the moment it stopped working is the
  /// fact worth preserving.
  Future<void> revoke(int workspaceId, int keyId) async {
    _log.fine('revoke($workspaceId, $keyId)');
    await supabase
        .from('api_keys')
        .update({
          'revoked_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', keyId)
        .eq('workspace_id', workspaceId)
        .filter('revoked_at', 'is', null);
  }

  /// Stamps last-used. Called on every authenticated request, so it is
  /// deliberately a blind update with no read-back.
  Future<void> touch(int keyId) async {
    await supabase
        .from('api_keys')
        .update({'last_used_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', keyId);
  }
}
