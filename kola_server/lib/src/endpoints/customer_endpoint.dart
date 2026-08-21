// customer_endpoint.dart — Gate 3 / Gate 3b. The graph's read surface:
// backs kola_dashboard's Customers page (design brief §8.11) and the
// merge-review queue. Gated on customers.core, matching the existing
// /customers nav item in nav_model.dart.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/customer_repository.dart';
import 'package:kola_server/src/services/repository/customer_identity_signal_repository.dart';
import 'package:kola_server/src/services/repository/customer_merge_proposal_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/repository/sale_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';

class CustomerEndpoint extends Endpoint {
  CustomerRepository get _customers => getIt<CustomerRepository>();
  CustomerIdentitySignalRepository get _signals => getIt<CustomerIdentitySignalRepository>();
  CustomerMergeProposalRepository get _mergeProposals => getIt<CustomerMergeProposalRepository>();
  ConversationRepository get _conversations => getIt<ConversationRepository>();
  PaymentTransactionRepository get _payments => getIt<PaymentTransactionRepository>();
  SaleRepository get _sales => getIt<SaleRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();

  Future<List<Customer>> listCustomers(
    Session session,
    String accessToken,
    int workspaceId, {
    int limit = 100,
    int offset = 0,
  }) async {
    await _require(accessToken, workspaceId);
    return _customers.listByWorkspace(workspaceId: workspaceId, limit: limit, offset: offset);
  }

  /// The Gate 3b proof surface: everything this customer has ever done,
  /// across every source, in one place — see CustomerDetail's header.
  Future<CustomerDetail> getCustomerDetail(
    Session session,
    String accessToken,
    int workspaceId,
    int customerId,
  ) async {
    await _require(accessToken, workspaceId);

    // Always resolve through any merge — a stale link (a browser tab
    // open on a customer that has since been merged into another)
    // should land on the survivor, not 404 or show half a history.
    final resolved = await _customers.resolveCanonical(customerId);
    if (resolved == null) {
      throw KolaException(message: 'Customer $customerId not found.');
    }
    final resolvedId = resolved.id!;

    final results = await Future.wait([
      _signals.listForCustomer(resolvedId),
      _conversations.listByCustomer(resolvedId),
      _payments.listByCustomer(resolvedId),
      _sales.listByCustomer(resolvedId),
    ]);

    return CustomerDetail(
      customer: resolved,
      signals: results[0] as List<CustomerIdentitySignal>,
      conversations: results[1] as List<Conversation>,
      payments: results[2] as List<PaymentTransaction>,
      sales: results[3] as List<Sale>,
    );
  }

  /// The merge-review queue — PART V: "Merges are proposals, not
  /// facts... the owner confirms."
  Future<List<CustomerMergeProposal>> listMergeProposals(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await _require(accessToken, workspaceId);
    return _mergeProposals.listPending(workspaceId);
  }

  /// [approve] true confirms the merge (loser folds into survivor via
  /// mergedIntoId — see customer_repository.dart's header on why
  /// nothing else is ever rewritten); false rejects it outright, and
  /// the two customers stay independent. The LOWER-id customer
  /// (customerAId) is always treated as the survivor — arbitrary but
  /// consistent, and it means "the older record wins" in practice,
  /// since ids are assigned in creation order.
  Future<void> resolveMergeProposal(
    Session session,
    String accessToken,
    int workspaceId,
    int proposalId,
    bool approve,
  ) async {
    final member = await _require(accessToken, workspaceId);

    final proposal = await _mergeProposals.findById(proposalId);
    if (proposal == null || proposal.workspaceId != workspaceId) {
      throw KolaException(message: 'Merge proposal $proposalId not found.');
    }
    if (proposal.status != 'pending') {
      throw KolaException(message: 'This proposal has already been resolved.');
    }

    if (approve) {
      await _customers.setMergedInto(
        loserId: proposal.customerBId,
        survivorId: proposal.customerAId,
      );
    }

    await _mergeProposals.resolve(
      id: proposalId,
      status: approve ? 'confirmed' : 'rejected',
      // No email lookup available at this layer (WorkspaceMember only
      // carries the Supabase Auth user id, not an email) — the acting
      // user's id is still real audit evidence of who decided this.
      resolvedByEmail: member.userId,
    );
  }

  Future<WorkspaceMember> _require(String accessToken, int workspaceId) async {
    final member = await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
    }
    if (!await _features.isEnabled(FeatureKeys.customers, workspace)) {
      throw KolaException(message: 'Customers is not available on this workspace yet.');
    }
    return member;
  }
}
