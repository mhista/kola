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

  /// Phase 13f — the Customers page's list, with lifetime value and
  /// order count already computed per customer, so the page doesn't
  /// have to call getCustomerDetail once per row (an N+1 this endpoint
  /// avoids by fetching Sales/Payments/Conversations ONCE for the whole
  /// workspace and grouping in memory — same shape as
  /// AnalyticsEndpoint.getSummary, Phase 13e).
  ///
  /// De-duplicated the same way: a completed PaymentTransaction already
  /// matched to a Sale via saleId is not counted twice. `from`/`to` span
  /// effectively "all time" — there's no natural period boundary for a
  /// customer's own lifetime value the way Analytics has one for a
  /// revenue trend.
  Future<List<CustomerSummary>> listCustomersWithSummary(
    Session session,
    String accessToken,
    int workspaceId, {
    int limit = 500,
  }) async {
    await _require(accessToken, workspaceId);

    final from = DateTime.utc(2000);
    final to = DateTime.now().toUtc().add(const Duration(days: 1));

    final results = await Future.wait([
      _customers.listByWorkspace(workspaceId: workspaceId, limit: limit),
      _sales.listByWorkspaceAndRange(workspaceId: workspaceId, from: from, to: to),
      _payments.listCompletedByWorkspaceAndRange(workspaceId: workspaceId, from: from, to: to),
      _conversations.listByWorkspace(workspaceId),
    ]);
    final customers = results[0] as List<Customer>;
    final sales = (results[1] as List<Sale>).where((s) => s.status == 'completed');
    final payments = results[2] as List<PaymentTransaction>;
    final conversations = results[3] as List<Conversation>;

    // saleId -> the reconciled payment's own customerId (which may be
    // null if that payment arrived unresolved). PaymentReconciliationService
    // guarantees a match never CONTRADICTS a resolved customerId on
    // either side (see payment_transaction.spy.yaml's saleId field doc)
    // — so when this is non-null it is always the same customer the
    // Sale itself points at, and the payment loop below will credit
    // them. Only skip the Sale in that case; if the payment side never
    // resolved a customerId, the Sale is this customer's only record of
    // that revenue and must still be counted.
    final reconciledPaymentCustomerBySaleId = <int, int?>{
      for (final p in payments)
        if (p.saleId != null) p.saleId!: p.customerId,
    };

    final ltvByCustomer = <int, int>{};
    final ordersByCustomer = <int, int>{};
    final lastActivityByCustomer = <int, DateTime>{};
    var currency = 'NGN';

    void touch(int? customerId, DateTime at) {
      if (customerId == null) return;
      final current = lastActivityByCustomer[customerId];
      if (current == null || at.isAfter(current)) {
        lastActivityByCustomer[customerId] = at;
      }
    }

    for (final s in sales) {
      if (s.customerId == null) continue;
      if (s.id != null &&
          reconciledPaymentCustomerBySaleId.containsKey(s.id) &&
          reconciledPaymentCustomerBySaleId[s.id] != null) {
        // Counted via its matching payment below instead — see the map
        // comment above on why this is only safe when that payment
        // itself resolved a customerId.
        touch(s.customerId, s.soldAt);
        continue;
      }
      ltvByCustomer.update(s.customerId!, (v) => v + s.totalMinor, ifAbsent: () => s.totalMinor);
      ordersByCustomer.update(s.customerId!, (v) => v + 1, ifAbsent: () => 1);
      touch(s.customerId, s.soldAt);
      currency = s.currency;
    }
    for (final p in payments) {
      if (p.customerId == null) continue;
      ltvByCustomer.update(p.customerId!, (v) => v + p.amountKobo, ifAbsent: () => p.amountKobo);
      ordersByCustomer.update(p.customerId!, (v) => v + 1, ifAbsent: () => 1);
      touch(p.customerId, p.createdAt);
      currency = p.currency;
    }
    for (final c in conversations) {
      touch(c.customerId, c.lastMessageAt);
    }

    final summaries = [
      for (final c in customers)
        CustomerSummary(
          customer: c,
          ltvMinor: c.id == null ? 0 : (ltvByCustomer[c.id] ?? 0),
          orderCount: c.id == null ? 0 : (ordersByCustomer[c.id] ?? 0),
          currency: currency,
          lastActivityAt: c.id == null ? null : lastActivityByCustomer[c.id],
        ),
    ];

    // Most-recent-activity first — the export's default sort, and a
    // sensible one when nothing else has been chosen.
    summaries.sort((a, b) {
      final at = a.lastActivityAt, bt = b.lastActivityAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return summaries;
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
