// errand_entity_mapping_repository.dart
//
// Gate 5's second half (migration 044): "someone else's system, mapped
// to entities." All database read/write operations for the optional
// column-role mapping a dbCredential Errand can be given — one row per
// Errand, 1:1 via the unique index on errand_id, same shape as
// ErrandCredentialRepository.
//
// DELIBERATELY NOT A SERVERPOD MODEL, UNLIKE EVERY OTHER REPOSITORY IN
// THIS DIRECTORY: see migration 044's own header on why. ErrandEndpoint
// exposes this mapping to the dashboard as a JSON string
// (getEntityMapping/setEntityMapping), never as a typed protocol class,
// so this repository is free to return a plain Dart value object that
// never has to cross the Serverpod client boundary — no
// `serverpod generate` run required to add it. If this ever needs to be
// a real column on the generated Errand model instead, that's a
// straightforward follow-up once a Dart/Serverpod toolchain is
// available; this table is designed to fold into that cleanly (see the
// migration file).

import 'package:logging/logging.dart';
import 'supabase_client.dart';

final _log = Logger('ErrandEntityMappingRepository');

/// One Errand's saved row-to-Customer mapping. [mappingJson] is the raw
/// JSON string ErrandEndpoint hands to and from the dashboard — this
/// repository never parses it; that's ErrandEndpoint's (validation) and
/// ErrandRowCustomerMapper's (application) job respectively, same
/// "repository stores what it's given" separation of concerns
/// ErrandCredentialRepository already follows for encryptedCredential.
class ErrandEntityMapping {
  const ErrandEntityMapping({
    required this.errandId,
    required this.mappingJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final int errandId;
  final String mappingJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ErrandEntityMapping.fromRow(Map<String, dynamic> row) => ErrandEntityMapping(
    errandId: row['errand_id'] as int,
    mappingJson: row['mapping_json'] as String? ?? '{}',
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );
}

class ErrandEntityMappingRepository {
  const ErrandEntityMappingRepository();

  /// The one mapping row for an Errand, if it has one — null for an
  /// Errand that has never had a mapping saved (or had it saved and
  /// deleted).
  Future<ErrandEntityMapping?> findByErrandId(int errandId) async {
    _log.fine('findByErrandId($errandId)');
    final response = await supabase
        .from('errand_entity_mappings')
        .select()
        .eq('errand_id', errandId)
        .maybeSingle();

    if (response == null) return null;
    return ErrandEntityMapping.fromRow(response);
  }

  /// Create-or-replace, same reasoning as ErrandCredentialRepository.upsert
  /// — an owner editing an existing mapping ("actually it's `cust_email`,
  /// not `email`") should never need to know whether a row already
  /// exists.
  Future<ErrandEntityMapping> upsert({
    required int errandId,
    required String mappingJson,
  }) async {
    _log.info('Upserting errand entity mapping errandId=$errandId');
    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('errand_entity_mappings')
        .upsert({
          'errand_id': errandId,
          'mapping_json': mappingJson,
          'updated_at': now.toIso8601String(),
        }, onConflict: 'errand_id')
        .select()
        .single();

    return ErrandEntityMapping.fromRow(response);
  }

  /// Deletes the mapping row for an Errand, if one exists — a no-op if
  /// there isn't one. Not called from ErrandEndpoint.deleteErrand: unlike
  /// errand_credentials (deleted explicitly there), migration 044 gave
  /// errand_id an `on delete cascade` foreign key, so a deleted Errand's
  /// mapping row is already removed by Postgres itself. This method
  /// exists for the "clear the mapping without deleting the Errand"
  /// case — setEntityMapping's disable path.
  Future<void> deleteForErrand(int errandId) async {
    _log.info('deleteForErrand errandId=$errandId');
    await supabase.from('errand_entity_mappings').delete().eq('errand_id', errandId);
  }
}
