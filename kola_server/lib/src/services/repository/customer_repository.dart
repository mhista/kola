// customer_repository.dart — Gate 3. Storage for the identity anchor
// (migration 039). See customer_identity_resolver.dart for the service
// that actually decides when to create vs. reuse a customer — this file
// only owns persistence and the merge-redirect resolution.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/customer_dto.dart';
import 'supabase_client.dart';

final _log = Logger('CustomerRepository');

const _dto = CustomerDto();

class CustomerRepository {
  const CustomerRepository();

  Future<Customer> create({
    required int workspaceId,
    String? displayName,
    required String firstSeenSource,
    DateTime? firstSeenAt,
  }) async {
    final now = DateTime.now().toUtc();
    final inserted = await supabase
        .from('customers')
        .insert({
          'workspace_id': workspaceId,
          'display_name': displayName,
          'first_seen_source': firstSeenSource,
          'first_seen_at': (firstSeenAt ?? now).toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select()
        .single();
    return _dto.fromRow(inserted);
  }

  Future<Customer?> findById(int id) async {
    final row = await supabase.from('customers').select().eq('id', id).maybeSingle();
    return row == null ? null : _dto.fromRow(row);
  }

  /// Follows [Customer.mergedIntoId] to its root. A merge never rewrites
  /// any other table's customer_id (see migration 039's header) — every
  /// caller that resolves "the customer for this record" must go
  /// through this instead of trusting a stored id directly. Bounded to
  /// guard against a cycle that should never exist but must never hang
  /// a request if it somehow does.
  Future<Customer?> resolveCanonical(int id) async {
    var current = await findById(id);
    var hops = 0;
    while (current != null && current.mergedIntoId != null && hops < 10) {
      current = await findById(current.mergedIntoId!);
      hops++;
    }
    return current;
  }

  Future<void> setDisplayName(int id, String displayName) async {
    await supabase
        .from('customers')
        .update({
          'display_name': displayName,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Confirming a merge proposal only ever sets this — never touches
  /// conversations/payment_transactions/sales. See migration 039's
  /// header on why.
  Future<void> setMergedInto({required int loserId, required int survivorId}) async {
    _log.info('merge: customer $loserId -> $survivorId');
    await supabase
        .from('customers')
        .update({
          'merged_into_id': survivorId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', loserId);
  }

  /// Reversing a merge — see migration 039's header on why this is a
  /// single-column clear and nothing else needs undoing.
  Future<void> clearMergedInto(int id) async {
    await supabase
        .from('customers')
        .update({
          'merged_into_id': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<List<Customer>> listByWorkspace({
    required int workspaceId,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await supabase
        .from('customers')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('merged_into_id', null)
        .order('updated_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((r) => _dto.fromRow(r as Map<String, dynamic>)).toList();
  }
}
