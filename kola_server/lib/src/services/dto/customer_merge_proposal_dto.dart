// customer_merge_proposal_dto.dart — Gate 3.
//
// Supabase table: customer_merge_proposals
// Schema: docs/migrations/039_customer_graph.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class CustomerMergeProposalDto extends BaseDto<CustomerMergeProposal> {
  const CustomerMergeProposalDto();

  @override
  CustomerMergeProposal fromRow(Map<String, dynamic> row) {
    return CustomerMergeProposal(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      customerAId: row['customer_a_id'] as int,
      customerBId: row['customer_b_id'] as int,
      matchedOn: row['matched_on'] as String,
      evidenceJson: row['evidence_json'] as String? ?? '{}',
      status: row['status'] as String,
      resolvedByEmail: row['resolved_by_email'] as String?,
      resolvedAt: row['resolved_at'] == null
          ? null
          : DateTime.parse(row['resolved_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(CustomerMergeProposal model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'customer_a_id': model.customerAId,
      'customer_b_id': model.customerBId,
      'matched_on': model.matchedOn,
      'evidence_json': model.evidenceJson,
      'status': model.status,
      'resolved_by_email': model.resolvedByEmail,
      'resolved_at': model.resolvedAt?.toIso8601String(),
    };
  }
}
