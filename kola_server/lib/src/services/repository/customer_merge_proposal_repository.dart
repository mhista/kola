// customer_merge_proposal_repository.dart — Gate 3. The owner-
// confirmation queue's storage. See migration 039's header on why a
// proposal is raised only from a genuine signal conflict, never from
// similarity — and customer_merge_proposal.spy.yaml for the shape.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/customer_merge_proposal_dto.dart';
import 'supabase_client.dart';

final _log = Logger('CustomerMergeProposalRepository');

const _dto = CustomerMergeProposalDto();

class CustomerMergeProposalRepository {
  const CustomerMergeProposalRepository();

  /// Raises a proposal for the (lower id, higher id) pair, or does
  /// nothing if a pending one already exists for that exact pair —
  /// migration 039's partial unique index (status = 'pending') is what
  /// makes this a no-op on conflict rather than a second card for the
  /// same suspicion.
  Future<void> raise({
    required int workspaceId,
    required int customerIdA,
    required int customerIdB,
    required String matchedOn,
    required Map<String, dynamic> evidence,
  }) async {
    final lower = customerIdA < customerIdB ? customerIdA : customerIdB;
    final higher = customerIdA < customerIdB ? customerIdB : customerIdA;

    try {
      await supabase.from('customer_merge_proposals').insert({
        'workspace_id': workspaceId,
        'customer_a_id': lower,
        'customer_b_id': higher,
        'matched_on': matchedOn,
        'evidence_json': jsonEncode(evidence),
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      _log.info(
        'raise($workspaceId, $lower, $higher): a pending proposal for this '
        'pair already exists — $e',
      );
    }
  }

  Future<List<CustomerMergeProposal>> listPending(int workspaceId) async {
    final response = await supabase
        .from('customer_merge_proposals')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List).map((r) => _dto.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<CustomerMergeProposal?> findById(int id) async {
    final row = await supabase
        .from('customer_merge_proposals')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _dto.fromRow(row);
  }

  Future<void> resolve({
    required int id,
    required String status, // 'confirmed' | 'rejected'
    required String resolvedByEmail,
  }) async {
    await supabase
        .from('customer_merge_proposals')
        .update({
          'status': status,
          'resolved_by_email': resolvedByEmail,
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}
