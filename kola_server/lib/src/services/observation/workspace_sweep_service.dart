// workspace_sweep_service.dart — kola noticing things without being asked.
//
// ── WHAT THIS REPLACES ───────────────────────────────────────────────
//
// The Overview's "Needs your attention" was computed inline from
// whatever the page had already fetched, so it could only ever mention
// escalated conversations and open tickets. Products out of stock,
// documents that failed to index, a workspace with no channel connected
// — none of it was noticed, because nothing was looking.
//
// The design also shows a "Top recommendation" card. Neither section had
// a source.
//
// ── DETERMINISTIC, ON PURPOSE ────────────────────────────────────────
//
// Every detector below is a rule over rows the workspace already has.
// No model is consulted, no wording is generated. See finding_kinds.dart
// for the argument; the short version is that "this product has 0 stock"
// is a fact, and the Overview is the worst screen in the product for a
// plausible-sounding mistake.
//
// The AI hook belongs one layer up — a single line reasoning ACROSS
// findings ("three of your six low-stock items are Ankara; your supplier
// trip is overdue"). That is a different job from detection, it runs once
// per sweep rather than once per finding, and it is deliberately NOT
// wired yet. Designing the seam without filling it is the point:
// `confidence` exists on the row so a model-authored line can be visibly
// less certain than a counted one, instead of sitting beside it looking
// equally solid.
//
// ── THE SWEEP IS A RECONCILIATION, NOT AN INSERT ─────────────────────
//
// Each run computes the finding set that SHOULD exist, then:
//
//   present now, stored     → touch last_seen_at, keep first_seen_at
//   present now, not stored → insert
//   stored, absent now      → mark resolved
//
// That third case is what makes the list trustworthy. Without it,
// restocking a product leaves the alert on screen until someone deletes
// it by hand, and an owner who sees one stale item stops believing the
// rest.
//
// Idempotent by construction: identity is (workspace_id, fingerprint),
// so running the sweep twice, or twice concurrently, converges.

import 'package:logging/logging.dart';

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/observation/finding_kinds.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/knowledge_document_repository.dart';
import 'package:kola_server/src/services/repository/product_repository.dart';
import 'package:kola_server/src/services/repository/support_ticket_repository.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/repository/workspace_finding_repository.dart';
import 'package:kola_server/src/services/billing/payment_reconciliation_service.dart';

final _log = Logger('WorkspaceSweepService');

/// A finding before it has an id — what a detector returns.
class DetectedFinding {
  const DetectedFinding({
    required this.kind,
    required this.fingerprint,
    required this.title,
    this.detail,
    this.subjectType,
    this.subjectId,
    this.confidence = 1.0,
  });

  final String kind;
  final String fingerprint;
  final String title;
  final String? detail;
  final String? subjectType;
  final int? subjectId;
  final double confidence;

  int get severity => FindingKinds.severityFor(kind);
}

class WorkspaceSweepService {
  WorkspaceSweepService({
    required WorkspaceFindingRepository findings,
    required ProductRepository products,
    required ConversationRepository conversations,
    required KnowledgeDocumentRepository documents,
    required WorkspaceConnectorRepository connectors,
    required SupportTicketRepository tickets,
    required PaymentReconciliationService reconciliation,
  })  : _findings = findings,
        _products = products,
        _conversations = conversations,
        _documents = documents,
        _connectors = connectors,
        _tickets = tickets,
        _reconciliation = reconciliation;

  final WorkspaceFindingRepository _findings;
  final ProductRepository _products;
  final ConversationRepository _conversations;
  final KnowledgeDocumentRepository _documents;
  final WorkspaceConnectorRepository _connectors;
  final SupportTicketRepository _tickets;
  final PaymentReconciliationService _reconciliation;

  /// Above this, individual product findings collapse into one counted
  /// finding.
  ///
  /// An owner with 40 items out of stock does not need 40 rows telling
  /// them so — that is not attention, it is noise, and it buries the one
  /// escalated conversation underneath it. Below the threshold the
  /// individual rows are more useful, because each one names something
  /// they can act on directly.
  static const _collapseAbove = 5;

  Future<List<WorkspaceFinding>> sweep(int workspaceId) async {
    final now = DateTime.now().toUtc();
    final detected = <DetectedFinding>[];

    // Each detector is independently guarded. A sweep that cannot read
    // conversations should still report on stock — a partial list is
    // useful, and an exception here would take down the whole Overview
    // for one failing table.
    for (final detector in <Future<List<DetectedFinding>> Function(int)>[
      _detectCommerce,
      _detectConversations,
      _detectTickets,
      _detectKnowledge,
      _detectSetup,
      _detectPaymentReconciliation,
    ]) {
      try {
        detected.addAll(await detector(workspaceId));
      } catch (e) {
        _log.warning('detector failed for workspace $workspaceId: $e');
      }
    }

    try {
      return await _findings.reconcile(
        workspaceId: workspaceId,
        detected: detected,
        now: now,
      );
    } catch (e) {
      _log.warning('reconcile failed for workspace $workspaceId: $e');
      // Returning what is already stored beats returning nothing: the
      // previous sweep's findings are stale by minutes, not wrong.
      return _findings.listOpen(workspaceId);
    }
  }

  // ── Commerce ────────────────────────────────────────────────────────

  Future<List<DetectedFinding>> _detectCommerce(int workspaceId) async {
    final products =
        await _products.listByWorkspace(workspaceId, includeArchived: false);
    final out = <DetectedFinding>[];

    // NULL STOCK IS NOT ZERO STOCK.
    //
    // A tailoring service has null stock and is perfectly sellable. This
    // is the same distinction the catalog badges make, and getting it
    // wrong here would tell an owner six of their services are out of
    // stock every single morning.
    final outOfStock = [
      for (final p in products)
        if (p.stock != null && p.stock == 0) p,
    ];
    final lowStock = [
      for (final p in products)
        if (p.stock != null && p.stock! > 0 && p.stock! <= p.lowStockThreshold)
          p,
    ];

    if (outOfStock.length > _collapseAbove) {
      out.add(DetectedFinding(
        kind: FindingKinds.productOutOfStock,
        // No subject id, so the fingerprint is workspace-wide. Crossing
        // the threshold in either direction resolves the other form and
        // creates this one, which is correct: they are different
        // statements, not the same one reworded.
        fingerprint: '${FindingKinds.productOutOfStock}:all',
        title: '${FindingKinds.count(outOfStock.length, 'product')} '
            'out of stock',
        detail: 'Customers asking for these will be told they cannot buy '
            'them. Restock or archive the ones you no longer sell.',
      ));
    } else {
      for (final p in outOfStock) {
        if (p.id == null) continue;
        out.add(DetectedFinding(
          kind: FindingKinds.productOutOfStock,
          fingerprint: '${FindingKinds.productOutOfStock}:${p.id}',
          title: '${p.name} is out of stock',
          detail: 'kola will tell customers this one is unavailable.',
          subjectType: 'product',
          subjectId: p.id,
        ));
      }
    }

    if (lowStock.isNotEmpty) {
      out.add(DetectedFinding(
        kind: FindingKinds.productLowStock,
        fingerprint: '${FindingKinds.productLowStock}:all',
        title: '${FindingKinds.count(lowStock.length, 'product')} running low',
        detail: lowStock.length <= 3
            ? lowStock.map((p) => '${p.name} (${p.stock} left)').join(', ')
            : '${lowStock.take(3).map((p) => p.name).join(', ')} '
                'and ${lowStock.length - 3} more.',
      ));
    }

    // Quality gaps. Counted, never listed one by one — a new catalog has
    // dozens and the point is the total, not the names.
    final noPrice = products.where((p) => p.priceMinor == null).length;
    // Deliberately excludes services: "by quote" is a legitimate,
    // deliberate state for one, and flagging it would be telling an owner
    // to fix something that is already right.
    final noPriceGoods = products
        .where((p) => p.priceMinor == null && p.archetype != 'services')
        .length;
    if (noPriceGoods > 0) {
      out.add(DetectedFinding(
        kind: FindingKinds.productMissingPrice,
        fingerprint: '${FindingKinds.productMissingPrice}:all',
        title: '${FindingKinds.count(noPriceGoods, 'product')} '
            'with no price',
        detail: 'kola cannot quote these, so it has to pass the question '
            'to you. ${noPrice > noPriceGoods ? 'Services priced by quote '
            'are not counted here.' : ''}'
            .trim(),
      ));
    }

    return out;
  }

  // ── Conversations ───────────────────────────────────────────────────

  Future<List<DetectedFinding>> _detectConversations(int workspaceId) async {
    final escalated = await _conversations.listEscalatedByWorkspace(workspaceId);
    if (escalated.isEmpty) return const [];

    final now = DateTime.now().toUtc();

    // Individually, always — never collapsed. Each one is a person
    // waiting, and "4 conversations escalated" is a number where
    // "Adaeze has been waiting 3 hours" is a prompt to act.
    return [
      for (final c in escalated)
        if (c.id != null)
          DetectedFinding(
            kind: FindingKinds.conversationEscalated,
            fingerprint: '${FindingKinds.conversationEscalated}:${c.id}',
            title: '${c.displayName ?? 'A customer'} is waiting for you',
            detail: c.lastMessageAt == null
                ? 'kola could not answer this one confidently.'
                : 'Waiting ${FindingKinds.since(c.lastMessageAt!, now)}. '
                    'kola could not answer this one confidently.',
            subjectType: 'conversation',
            subjectId: c.id,
          ),
    ];
  }

  // ── Support tickets ─────────────────────────────────────────────────
  //
  // PORTED FROM THE OVERVIEW, NOT INVENTED HERE.
  //
  // overview_page.dart already computed these inline — overdue tickets
  // and tickets within two hours of their SLA — and it was the only
  // attention logic that existed. Replacing that page's list with
  // findings WITHOUT this detector would have silently dropped the one
  // alert the product already had.
  //
  // Worth naming, because "rebuild it properly" is exactly the change
  // that loses a working feature by omission.

  Future<List<DetectedFinding>> _detectTickets(int workspaceId) async {
    final tickets = await _tickets.listByWorkspace(workspaceId);
    final now = DateTime.now().toUtc();

    final open = tickets
        .where((t) => t.status != 'resolved' && t.status != 'closed')
        .toList();

    final overdue = open.where((t) => t.slaDeadline.isBefore(now)).toList();
    // Past deadline is a SEPARATE, worse case than approaching one.
    // Collapsing them would let the most urgent thing on the page read as
    // the least — the original code made this distinction and it was
    // right to.
    final dueSoon = open
        .where((t) => t.slaDeadline.isAfter(now))
        .where((t) => t.slaDeadline.difference(now) < const Duration(hours: 2))
        .toList();

    return [
      // Individually, because a ticket has a SUBJECT — a sentence the
      // owner wrote or a customer sent — and naming it is the difference
      // between a number and a thing to go and do.
      for (final t in overdue)
        if (t.id != null)
          DetectedFinding(
            kind: FindingKinds.ticketOverdue,
            fingerprint: '${FindingKinds.ticketOverdue}:${t.id}',
            title: '"${t.subject}" is past its deadline',
            detail: 'Was due ${FindingKinds.since(t.slaDeadline, now)} ago.',
            subjectType: 'ticket',
            subjectId: t.id,
          ),
      if (dueSoon.isNotEmpty)
        DetectedFinding(
          kind: FindingKinds.ticketDueSoon,
          fingerprint: '${FindingKinds.ticketDueSoon}:all',
          title: '${FindingKinds.count(dueSoon.length, 'support ticket')} '
              'due within two hours',
          detail: dueSoon.length == 1
              ? '"${dueSoon.first.subject}"'
              : dueSoon.take(2).map((t) => '"${t.subject}"').join(', '),
        ),
    ];
  }

  // ── Knowledge ───────────────────────────────────────────────────────

  Future<List<DetectedFinding>> _detectKnowledge(int workspaceId) async {
    final docs = await _documents.listByWorkspace(workspaceId);
    final out = <DetectedFinding>[];

    for (final d in docs.where((d) => d.status == 'failed')) {
      if (d.id == null) continue;
      out.add(DetectedFinding(
        kind: FindingKinds.documentFailed,
        fingerprint: '${FindingKinds.documentFailed}:${d.id}',
        title: 'kola could not read "${d.title}"',
        // The stored reason, not a generic apology. It is already
        // owner-facing — see DocumentIngestionService._ownerFacingReason.
        detail: d.errorMessage ??
            'Something went wrong while processing it. Try adding it again.',
        subjectType: 'document',
        subjectId: d.id,
      ));
    }

    if (docs.isEmpty) {
      out.add(const DetectedFinding(
        kind: FindingKinds.knowledgeEmpty,
        fingerprint: '${FindingKinds.knowledgeEmpty}:workspace',
        title: 'kola has not been taught anything yet',
        detail: 'Until it has your policies — delivery, returns, sizing — '
            'it has to pass those questions to you.',
      ));
    }

    return out;
  }

  // ── Money (Gate 13 — reconciliation) ───────────────────────────────
  //
  // THE ONE DETECTOR IN THIS FILE THAT WRITES, NOT JUST READS. Every
  // other detector here computes a finding set from rows that already
  // exist; this one first asks PaymentReconciliationService to attempt
  // real, deterministic payment-to-sale links (see that service's own
  // header for why doing this on every sweep — rather than a separate
  // scheduled job — is safe: same bounded, indexed-per-workspace cost
  // every other detector already pays), and only THEN reports whatever
  // money is still left over. Matching before reporting means a payment
  // that WAS matched a moment ago by this same call never shows up as
  // "unmatched" in the very call that matched it.

  Future<List<DetectedFinding>> _detectPaymentReconciliation(int workspaceId) async {
    final result = await _reconciliation.reconcileWorkspace(workspaceId);
    if (result.unmatched.isEmpty) return const [];

    return [
      for (final group in result.unmatched)
        DetectedFinding(
          kind: FindingKinds.paymentUnmatched,
          // Fingerprinted by currency, not by the individual
          // transactions it currently covers — the same "kind:subject,
          // never counts" discipline this file's own header (borrowed
          // from workspace_findings' migration 034) already applies
          // elsewhere. The total changing from run to run must not read
          // as a new finding each time; it is the same ongoing
          // condition with an updated number.
          fingerprint: '${FindingKinds.paymentUnmatched}:${group.currency}',
          title: '${_money(group.totalMinor, group.currency)} from '
              '${FindingKinds.count(group.distinctCustomerCount, 'customer')} '
              'has not been matched to any order',
          detail: '${FindingKinds.count(group.transactionCount, 'payment')} came in '
              "that don't line up with a sale in the till — a partial payment, "
              'an order rung up under the wrong amount, or one still on its way. '
              'Check Sales for the ones missing a payment.',
        ),
    ];
  }

  /// Matches ReportEndpoint's own minor-units formatter for NGN — same
  /// "₦" + two-decimal convention used everywhere else money is shown
  /// to an owner in this codebase. Falls back to a plain "<amount>
  /// <CODE>" for anything else, since Stripe (Gate 13's own "across
  /// providers" requirement) makes a non-NGN workspace real, and
  /// prefixing a foreign amount with ₦ would be a false fact about the
  /// business's own money.
  static String _money(int minor, String currency) {
    final amount = (minor / 100).toStringAsFixed(2);
    return currency == 'NGN' ? '₦$amount' : '$amount $currency';
  }

  // ── Setup ───────────────────────────────────────────────────────────

  Future<List<DetectedFinding>> _detectSetup(int workspaceId) async {
    final connectors = await _connectors.listByWorkspace(workspaceId);
    if (connectors.isNotEmpty) return const [];

    return const [
      DetectedFinding(
        kind: FindingKinds.noChannelConnected,
        fingerprint: '${FindingKinds.noChannelConnected}:workspace',
        title: 'No channel connected yet',
        detail: 'kola is ready, but customers have no way to reach it. '
            'Connecting WhatsApp or Telegram takes a few minutes.',
      ),
    ];
  }
}
