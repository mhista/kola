// report_endpoint.dart — Documents' End-of-day report tab. Task #30:
// "no aggregation endpoint behind this tab yet" (documents_page.dart's
// own header, and the _comingSoon placeholder it pointed the report
// tab at). This is that endpoint.
//
// Computed fresh from Sale rows on every call — see
// end_of_day_report.spy.yaml's header for why nothing here is
// persisted as its own table.
//
// Gated on the same commerce.core + commerce.pos flags SaleEndpoint
// and InvoiceEndpoint already use — a report on the till's own output
// is not a separate capability a workspace opts into.

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/sale_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';

class ReportEndpoint extends Endpoint {
  SaleRepository get _sales => getIt<SaleRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();

  /// [date] is any moment inside the day to report on — only its
  /// UTC calendar date is used (start-of-day to start-of-next-day).
  /// Defaults to today (server UTC) when omitted, which is the only
  /// case documents_page.dart currently calls with — a date picker for
  /// past days is a natural follow-up, not built here.
  Future<EndOfDayReport> getEndOfDayReport(
    Session session,
    String accessToken,
    int workspaceId, {
    DateTime? date,
  }) async {
    await _require(accessToken, workspaceId);

    final target = (date ?? DateTime.now().toUtc()).toUtc();
    final dayStart = DateTime.utc(target.year, target.month, target.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final todaySales = await _sales.listByWorkspaceAndRange(
      workspaceId: workspaceId,
      from: dayStart,
      to: dayEnd,
    );

    final report = _aggregate(workspaceId, dayStart, todaySales);

    // "What kola noticed" — the one trend callout the export's mockup
    // showed. Only computed when yesterday actually had completed
    // sales to compare against; a shop's first day, or any day with no
    // prior activity, gets no insight rather than a fabricated one —
    // same rule as everywhere else in this codebase that a missing
    // fact is omitted, not invented.
    final yesterdayStart = dayStart.subtract(const Duration(days: 1));
    final yesterdaySales = await _sales.listByWorkspaceAndRange(
      workspaceId: workspaceId,
      from: yesterdayStart,
      to: dayStart,
    );
    final yesterdayGross = yesterdaySales
        .where((s) => s.status == 'completed')
        .fold<int>(0, (sum, s) => sum + s.totalMinor);

    String? insight;
    if (yesterdayGross > 0) {
      final diff = report.grossMinor - yesterdayGross;
      final pct = (diff / yesterdayGross * 100).round();
      if (pct == 0) {
        insight = "Today's takings are level with yesterday's — ${_naira(report.grossMinor)}.";
      } else if (pct > 0) {
        insight = "Takings are ${pct.abs()}% higher than yesterday (${_naira(report.grossMinor)} vs ${_naira(yesterdayGross)}).";
      } else {
        insight = "Takings are ${pct.abs()}% lower than yesterday (${_naira(report.grossMinor)} vs ${_naira(yesterdayGross)}).";
      }
    }

    return EndOfDayReport(
      workspaceId: report.workspaceId,
      reportDate: report.reportDate,
      grossMinor: report.grossMinor,
      transactionCount: report.transactionCount,
      refundsMinor: report.refundsMinor,
      refundCount: report.refundCount,
      byPaymentMethodJson: report.byPaymentMethodJson,
      insightText: insight,
    );
  }

  EndOfDayReport _aggregate(int workspaceId, DateTime dayStart, List<Sale> sales) {
    final completed = sales.where((s) => s.status == 'completed').toList();
    final refunded = sales.where((s) => s.status == 'refunded').toList();

    final byMethod = <String, int>{};
    for (final s in completed) {
      byMethod.update(s.paymentMethod, (v) => v + s.totalMinor, ifAbsent: () => s.totalMinor);
    }

    return EndOfDayReport(
      workspaceId: workspaceId,
      reportDate: dayStart,
      grossMinor: completed.fold<int>(0, (sum, s) => sum + s.totalMinor),
      transactionCount: completed.length,
      refundsMinor: refunded.fold<int>(0, (sum, s) => sum + s.totalMinor),
      refundCount: refunded.length,
      byPaymentMethodJson: jsonEncode(byMethod),
      insightText: null,
    );
  }

  /// Plain-English naira formatting for insightText only — the
  /// dashboard formats every other amount itself via money_format.dart;
  /// this is the one place server-generated text needs its own number
  /// formatting baked in, since it's a full sentence, not a field.
  String _naira(int minor) {
    final major = minor ~/ 100;
    final s = major.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '₦$buf';
  }

  Future<void> _require(String accessToken, int workspaceId) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
    }
    if (!await _features.isEnabled(FeatureKeys.commerceCore, workspace) ||
        !await _features.isEnabled(FeatureKeys.commercePos, workspace)) {
      throw KolaException(message: 'Reports are not available on this workspace yet.');
    }
  }
}
