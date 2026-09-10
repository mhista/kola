// intelligence_endpoint.dart — Phase 14g. Backs `/intelligence`,
// confirmed unbuilt this pass (no route in kola_dashboard's app.dart, no
// page file) even though nav_model.dart has pointed at it since Phase
// 13e, gated on `businessIntelligence` — a locked destination with no
// page behind the lock. See PHASE_14_HANDOFF.pdf's 14g section for the
// grep that confirmed the gap, and analytics_endpoint.dart's own header
// for why Phase 13e deliberately scoped this page out: "it needs an
// AI-reasoning layer ... that does not exist anywhere in this
// codebase." IntelligenceNarrativeService is that layer, built for this
// pass.
//
// ── WHAT THIS ADDS THAT ANALYTICS DOESN'T ALREADY HAVE ─────────────────
//
// 1. TOP PRODUCTS BY REVENUE/VELOCITY/MARGIN — genuinely new
//    aggregation over SaleLine (bulk-fetched via the new
//    SaleRepository.listLinesForSales, not one request per sale),
//    joined in memory to Product for costMinor. Margin is null whenever
//    a product's cost was never set — never a fabricated number, same
//    rule this codebase applies everywhere a real input is missing.
//
// 2. THE NARRATIVE — a real plain-English paragraph over the computed
//    numbers, via IntelligenceNarrativeService (real AiOrchestrator
//    call, honest template fallback if every provider fails).
//
// ── WHAT THIS DELIBERATELY REUSES RATHER THAN DUPLICATES ──────────────
//
// Revenue trend (the day-by-day chart) and customer-segment bars are
// NOT recomputed here. The dashboard's own Intelligence page calls the
// EXISTING AnalyticsEndpoint.getSummary and CustomerEndpoint.
// listCustomersWithSummary directly for those — both already real,
// already-generated client methods, and duplicating their dedup logic
// here (Sale vs. reconciled PaymentTransaction double-counting,
// specifically) would risk a second implementation quietly drifting
// from the first. This endpoint is additive: only what neither of those
// already provides.
//
// ── PHASE 14/174 UPDATE: THE "CORRELATION SPOTTED" CUT IS UN-DEFERRED ──
//
// The gap this header used to name — "there is no Timeline page in this
// codebase yet, so there is nothing real to link to" — is closed:
// event_endpoint.dart/timeline_page.dart now exist. [correlationCallout]
// below is the real (deliberately simple, not statistical) check the
// export's callout needed: did revenue fall THIS period vs. the prior
// one, AND did escalated conversations (this codebase's one real
// complaint/escalation signal — Conversation.status == 'escalated',
// same field ConversationRepository.listEscalatedByWorkspace already
// reads) rise over the same two windows. Both real, both already
// computed elsewhere in this file/endpoint family — no new revenue or
// escalation pipeline was built for this, per the brief's own
// instruction to reuse rather than duplicate. Null whenever either
// condition doesn't hold, same "absence over a fabricated finding"
// rule as [revenueDeltaPct] itself.
//
// ── TWO NAMED GAPS THAT REMAIN ──────────────────────────────────────────
//
// 1. RESPONSE TIME. The design shows a "Response time" card (a big
//    number + "-N% vs last period"). Grepped for any existing average-
//    response-time computation anywhere in this codebase
//    (responseTime/response_time/avgResponse/firstResponse) — zero
//    matches. No real number exists to show. Rather than compute a
//    first-response-time metric under this pass's scope (a genuinely
//    separate aggregation over Message.createdAt pairs, not a small
//    addition), this card is SKIPPED entirely — not shipped with a
//    fabricated figure, not shipped as a fake "coming soon" card either.
//
// 2. CUSTOMER SATISFACTION. Also grepped (rating/csat/satisfaction) —
//    no rating/CSAT field exists on Conversation or SupportTicket
//    anywhere in this codebase. intelligence_page.dart renders this
//    card as an honest "not enough data yet" state using workspace age
//    (a real signal, passed in from app.dart) — see that file's own
//    comment. Nothing added here server-side for it: there is no real
//    number to compute.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/sale_repository.dart';
import 'package:kola_server/src/services/repository/product_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/ai/intelligence_narrative_service.dart';

const _validPeriods = {7, 30, 90};

class IntelligenceEndpoint extends Endpoint {
  SaleRepository get _sales => getIt<SaleRepository>();
  ProductRepository get _products => getIt<ProductRepository>();
  ConversationRepository get _conversations => getIt<ConversationRepository>();
  IntelligenceNarrativeService get _narratives =>
      getIt<IntelligenceNarrativeService>();

  Future<IntelligenceSummary> getIntelligence(
    Session session,
    String accessToken,
    int workspaceId, {
    int periodDays = 30,
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    if (!_validPeriods.contains(periodDays)) {
      throw KolaException(
        message: 'Unknown periodDays $periodDays — must be one of: ${_validPeriods.join(", ")}',
      );
    }

    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final periodEnd = today.add(const Duration(days: 1));
    final periodStart = periodEnd.subtract(Duration(days: periodDays));
    final priorStart = periodStart.subtract(Duration(days: periodDays));

    final results = await Future.wait([
      _sales.listByWorkspaceAndRange(workspaceId: workspaceId, from: priorStart, to: periodEnd),
      _products.listByWorkspace(workspaceId, includeArchived: true),
      // Phase 14/174 — the correlation check's escalation signal. All
      // conversations regardless of window, filtered in memory below by
      // the same current/prior split everything else here uses (same
      // shape as AnalyticsEndpoint's own allConvos read).
      _conversations.listByWorkspace(workspaceId),
    ]);
    final allSales = (results[0] as List<Sale>).where((s) => s.status == 'completed').toList();
    final allProducts = results[1] as List<Product>;
    final allConversations = results[2] as List<Conversation>;
    final productById = {
      for (final p in allProducts)
        if (p.id != null) p.id!: p,
    };

    bool inCurrent(DateTime d) => !d.isBefore(periodStart) && d.isBefore(periodEnd);
    bool inPrior(DateTime d) => !d.isBefore(priorStart) && d.isBefore(periodStart);

    final currentSales = allSales.where((s) => inCurrent(s.soldAt)).toList();
    final priorSales = allSales.where((s) => inPrior(s.soldAt)).toList();

    var currency = 'NGN';
    if (currentSales.isNotEmpty) currency = currentSales.first.currency;

    final revenueMinor = currentSales.fold<int>(0, (sum, s) => sum + s.totalMinor);
    final priorRevenueMinor = priorSales.fold<int>(0, (sum, s) => sum + s.totalMinor);
    final revenueDeltaPct = priorRevenueMinor > 0
        ? (revenueMinor - priorRevenueMinor) / priorRevenueMinor * 100
        : null;

    // ── Top products: bulk-fetch lines for this period's sales only ────
    final currentSaleIds = [
      for (final s in currentSales)
        if (s.id != null) s.id!,
    ];
    final lines = await _sales.listLinesForSales(currentSaleIds);

    final unitsByProduct = <int, int>{};
    final revenueByProduct = <int, int>{};
    final nameByProduct = <int, String>{};
    for (final line in lines) {
      final pid = line.productId;
      if (pid == null) {
        // A line with no productId (the product was later deleted —
        // see sale_line.spy.yaml's ON DELETE SET NULL note) still
        // happened, but there is no catalog row left to attach a margin
        // or a "top products" ranking to. Excluded from this table
        // rather than shown as an unlinked ghost row.
        continue;
      }
      unitsByProduct.update(pid, (v) => v + line.quantity, ifAbsent: () => line.quantity);
      revenueByProduct.update(pid, (v) => v + line.lineTotalMinor, ifAbsent: () => line.lineTotalMinor);
      nameByProduct[pid] = line.name; // the snapshot name at sale time
    }

    final topProducts = unitsByProduct.keys.map((pid) {
      final units = unitsByProduct[pid]!;
      final revenue = revenueByProduct[pid]!;
      final costMinor = productById[pid]?.costMinor;
      final marginMinor = costMinor == null ? null : revenue - (costMinor * units);
      final marginPct = (marginMinor == null || revenue == 0)
          ? null
          : marginMinor / revenue * 100;
      return IntelligenceProduct(
        productId: pid,
        name: nameByProduct[pid] ?? 'Unknown product',
        unitsSold: units,
        revenueMinor: revenue,
        marginMinor: marginMinor,
        marginPct: marginPct,
      );
    }).toList()
      ..sort((a, b) => b.revenueMinor.compareTo(a.revenueMinor));

    // Top 8 — enough for a real table without sending the whole catalog
    // on every load.
    final cappedTopProducts = topProducts.take(8).toList();

    // ── Orders by day — real weekday distribution, current period only ─
    //
    // Dart's DateTime.weekday is 1 (Monday) .. 7 (Sunday); index 0..6
    // here so the dashboard can zip it straight against a fixed
    // Mon..Sun label list without re-deriving the same offset twice.
    final ordersByWeekday = List<int>.filled(7, 0);
    for (final s in currentSales) {
      ordersByWeekday[s.soldAt.toUtc().weekday - 1]++;
    }

    // ── Correlation spotted — Phase 14/174, see this file's own header
    // for what this is and is not (a simple two-condition check, not
    // statistics). Escalated conversations are this codebase's one
    // real complaint/escalation signal; Conversation carries no
    // dedicated "escalatedAt" column, so updatedAt (stamped whenever
    // status transitions — see conversation_repository.dart's own
    // setStatus) stands in as "when this became a complaint", same
    // honest-approximation posture as WorkspaceFinding's firstSeenAt.
    final escalated = allConversations.where((c) => c.status == 'escalated').toList();
    final currentEscalations = escalated.where((c) => inCurrent(c.updatedAt)).length;
    final priorEscalations = escalated.where((c) => inPrior(c.updatedAt)).length;

    String? correlationCallout;
    if (revenueDeltaPct != null &&
        revenueDeltaPct < 0 &&
        currentEscalations > priorEscalations &&
        currentEscalations > 0) {
      correlationCallout = 'Revenue is down ${revenueDeltaPct.abs().toStringAsFixed(1)}% '
          'this period, alongside a rise in escalated conversations '
          '($priorEscalations → $currentEscalations) — worth checking whether '
          'the two are related.';
    }

    final narrative = await _narratives.narrate(
      periodDays: periodDays,
      currency: currency,
      revenueMinor: revenueMinor,
      revenueDeltaPct: revenueDeltaPct,
      topProducts: cappedTopProducts,
    );

    return IntelligenceSummary(
      workspaceId: workspaceId,
      periodDays: periodDays,
      currency: currency,
      revenueMinor: revenueMinor,
      revenueDeltaPct: revenueDeltaPct,
      topProducts: cappedTopProducts,
      narrative: narrative.text,
      narrativeIsTemplate: narrative.isTemplate,
      correlationCallout: correlationCallout,
      ordersByWeekday: ordersByWeekday,
    );
  }
}
