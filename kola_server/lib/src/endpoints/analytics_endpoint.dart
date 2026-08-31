// analytics_endpoint.dart — Phase 13e. Backs `/analytics`, one of the
// five previously-404ing sidebar routes (see observations_page.dart's
// header for the shared audit). Built against the buildable half of
// `Kola Analytics.dc.html`.
//
// ── WHAT SHIPS: DAILY REVENUE + CHANNEL SEGMENTS, BOTH REAL ────────────
//
// Revenue by day, and a segment table broken down by channel (WhatsApp,
// Telegram, ..., and "In-person" for till sales with no channel at
// all) — every number here is a direct aggregation over Sale /
// PaymentTransaction / Conversation, computed fresh on every call, same
// "no second table to keep in sync" posture as ReportEndpoint's own
// EndOfDayReport.
//
// DE-DUPLICATED THE SAME WAY OPERATIONS' CUSTOMER CHIPS ARE (Phase
// 13c): a completed PaymentTransaction with a non-null saleId is money
// Gate 13's reconciliation already attached to a till Sale — counting
// both the channel payment AND the Sale would double it. Channel
// segments sum every completed payment for that channel regardless of
// saleId (the money genuinely came in through that channel); the
// "In-person" segment sums only Sales that have NO matching payment,
// so the same naira is never counted twice.
//
// ── WHAT DOES NOT SHIP: TWO NAMED CUTS FROM THE EXPORT ─────────────────
//
// 1. Geography ('WhatsApp — Lagos' / 'WhatsApp — Abuja'). Customer has
//    no location field anywhere in this codebase. Inventing a city
//    would be exactly the false-fact mistake DESIGN_DELTA.md forbids —
//    segments here are channel-only.
//
// 2. Customer tenure ('Repeat customers' / 'First-time customers').
//    Buildable in principle (classify each transaction's customerId by
//    whether it had any completed money before the period started) but
//    genuinely separate scope from what this pass covers — real,
//    deferred work, named here rather than shipped half-built.
//
// `Kola Business Intelligence.dc.html` (the curated, narrative sibling
// page) is not attempted at all this pass — it needs an AI-reasoning
// layer (revenue narratives, cross-metric correlation) that does not
// exist anywhere in this codebase, the same deliberately-unfilled seam
// Phase 12 already names for Observations/Recommendations.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/sale_repository.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';

const _validPeriods = {7, 30, 90};

class AnalyticsEndpoint extends Endpoint {
  SaleRepository get _sales => getIt<SaleRepository>();
  PaymentTransactionRepository get _payments => getIt<PaymentTransactionRepository>();
  ConversationRepository get _conversations => getIt<ConversationRepository>();
  ChannelRepository get _channels => getIt<ChannelRepository>();

  Future<AnalyticsSummary> getSummary(
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
    final periodEnd = today.add(const Duration(days: 1)); // includes all of today
    final periodStart = periodEnd.subtract(Duration(days: periodDays));
    final priorStart = periodStart.subtract(Duration(days: periodDays));

    // One fetch spanning both windows — half the round trips of fetching
    // current and prior separately, split in memory below.
    final results = await Future.wait([
      _sales.listByWorkspaceAndRange(workspaceId: workspaceId, from: priorStart, to: periodEnd),
      _payments.listCompletedByWorkspaceAndRange(workspaceId: workspaceId, from: priorStart, to: periodEnd),
      _conversations.listByWorkspace(workspaceId),
    ]);
    final allSales = (results[0] as List<Sale>).where((s) => s.status == 'completed').toList();
    final allPayments = results[1] as List<PaymentTransaction>;
    final allConvos = results[2] as List<Conversation>;

    final reconciledSaleIds = {
      for (final p in allPayments)
        if (p.saleId != null) p.saleId!,
    };

    bool inCurrent(DateTime d) => !d.isBefore(periodStart) && d.isBefore(periodEnd);
    bool inPrior(DateTime d) => !d.isBefore(priorStart) && d.isBefore(periodStart);

    final currentSales = allSales.where((s) => inCurrent(s.soldAt)).toList();
    final priorSales = allSales.where((s) => inPrior(s.soldAt)).toList();
    final currentPayments = allPayments.where((p) => inCurrent(p.createdAt)).toList();
    final priorPayments = allPayments.where((p) => inPrior(p.createdAt)).toList();

    var currency = 'NGN';
    if (currentSales.isNotEmpty) currency = currentSales.first.currency;
    if (currentPayments.isNotEmpty) currency = currentPayments.first.currency;

    // ── Daily revenue: unmatched Sales + unmatched-to-a-sale payments ──
    final dailyMinor = <DateTime, int>{};
    for (var i = 0; i < periodDays; i++) {
      dailyMinor[periodStart.add(Duration(days: i))] = 0;
    }
    for (final s in currentSales) {
      final day = DateTime.utc(s.soldAt.year, s.soldAt.month, s.soldAt.day);
      dailyMinor.update(day, (v) => v + s.totalMinor, ifAbsent: () => s.totalMinor);
    }
    for (final p in currentPayments) {
      if (p.saleId != null) continue; // already counted via its Sale
      final day = DateTime.utc(p.createdAt.year, p.createdAt.month, p.createdAt.day);
      dailyMinor.update(day, (v) => v + p.amountKobo, ifAbsent: () => p.amountKobo);
    }
    final dailyRevenue = (dailyMinor.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => AnalyticsDailyPoint(date: e.key, grossMinor: e.value))
        .toList();

    // ── Channel labels: resolve each distinct channelId once ───────────
    final channelIds = {
      for (final p in [...currentPayments, ...priorPayments])
        if (p.channelId != null) p.channelId!,
    };
    final channelLabelById = <int, String>{};
    for (final id in channelIds) {
      final channel = await _channels.findById(id);
      if (channel != null) channelLabelById[id] = _channelLabel(channel.platformType);
    }

    final segments = <AnalyticsSegment>[];
    final labelsSeen = {...channelLabelById.values};
    for (final label in labelsSeen) {
      final platformKeys = channelLabelById.entries.where((e) => e.value == label).map((e) => e.key).toSet();
      final curr = currentPayments.where((p) => p.channelId != null && platformKeys.contains(p.channelId));
      final prior = priorPayments.where((p) => p.channelId != null && platformKeys.contains(p.channelId));
      final currRevenue = curr.fold<int>(0, (sum, p) => sum + p.amountKobo);
      final priorRevenue = prior.fold<int>(0, (sum, p) => sum + p.amountKobo);
      // Conversation.platformType is a channel-family string ('whatsapp',
      // 'telegram', ...) — matched against the same label mapping so a
      // segment's conversation count and its revenue describe the same
      // channel family.
      final convoCount = allConvos
          .where((c) => _channelLabel(c.platformType) == label && inCurrent(c.lastMessageAt))
          .length;
      segments.add(AnalyticsSegment(
        label: label,
        conversations: convoCount,
        orders: curr.length,
        revenueMinor: currRevenue,
        deltaPct: priorRevenue > 0 ? (currRevenue - priorRevenue) / priorRevenue * 100 : null,
      ));
    }

    // ── In-person: Sales with no reconciled payment at all ──────────────
    final inPersonCurrent = currentSales.where((s) => s.id == null || !reconciledSaleIds.contains(s.id));
    final inPersonPrior = priorSales.where((s) => s.id == null || !reconciledSaleIds.contains(s.id));
    final inPersonCurrRevenue = inPersonCurrent.fold<int>(0, (sum, s) => sum + s.totalMinor);
    final inPersonPriorRevenue = inPersonPrior.fold<int>(0, (sum, s) => sum + s.totalMinor);
    if (inPersonCurrent.isNotEmpty || inPersonPrior.isNotEmpty) {
      segments.add(AnalyticsSegment(
        label: 'In-person',
        conversations: 0,
        orders: inPersonCurrent.length,
        revenueMinor: inPersonCurrRevenue,
        deltaPct: inPersonPriorRevenue > 0
            ? (inPersonCurrRevenue - inPersonPriorRevenue) / inPersonPriorRevenue * 100
            : null,
      ));
    }

    // Worst-to-best-known ordering isn't meaningful here; highest
    // revenue first reads most naturally as "what matters most."
    segments.sort((a, b) => b.revenueMinor.compareTo(a.revenueMinor));

    return AnalyticsSummary(
      workspaceId: workspaceId,
      periodDays: periodDays,
      currency: currency,
      dailyRevenue: dailyRevenue,
      segments: segments,
    );
  }

  /// 'whatsapp' → 'WhatsApp', 'telegram' → 'Telegram', etc. — the small
  /// set of platformType values this codebase's channel connectors
  /// actually use (see channel catalog in integrations_page.dart);
  /// anything unrecognized falls back to a capitalized version of the
  /// raw value rather than a hidden channel.
  static String _channelLabel(String platformType) {
    const known = {
      'whatsapp': 'WhatsApp',
      'telegram': 'Telegram',
      'instagram': 'Instagram',
      'instagram_shop': 'Instagram',
      'facebook_catalog': 'Facebook',
      'messenger': 'Messenger',
    };
    final hit = known[platformType];
    if (hit != null) return hit;
    if (platformType.isEmpty) return platformType;
    return platformType[0].toUpperCase() + platformType.substring(1);
  }
}
