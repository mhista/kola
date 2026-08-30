// payment_reconciliation_service.dart — Gate 13. Payment-to-order
// matching, demonstrable across every gateway this codebase syncs
// (Paystack, Flutterwave, Stripe, Monnify, Fincra) and the manual/
// bank-transfer path, against till Sales — the "₦180,000 from six
// customers has not been matched to any order" sentence Rev 5's own
// Part V used to justify the whole business-graph build.
//
// NOT THE SAME "RECONCILIATION" ALREADY IN THIS CODEBASE — worth being
// explicit, because the word is already used nearby for something
// different: PaymentTransactionRepository.listForReconciliation and
// ManualPaymentService's reminder sweep reconcile a CLAIMED bank
// transfer against a gateway's own confirmation — payment-transaction-
// to-payment-transaction, single table, `gateway == 'bank_transfer'`
// only. This service reconciles a payment (any gateway, already
// confirmed) against a till Sale — two different tables, the actual
// Gate 13 scope: "money the business has and does not know what to do
// with... Paystack cannot see this; it sees payments, not
// conversations [or orders]."
//
// WHY AUTO-LINK RATHER THAN A REVIEW QUEUE, UNLIKE CUSTOMER MERGES:
// Rev 5 Part V's identity-resolution rule — "merges are proposals, not
// facts" — exists because a wrong customer merge silently combines two
// people's order histories, and there is no error message for that.
// Linking a payment to a sale carries a much smaller failure cost: a
// wrong link means one sale shows the wrong payment reference, an
// owner who looks would notice a mismatched amount or customer
// immediately, and clearing [PaymentTransaction.saleId] undoes it
// completely — no destructive rewrite, no combined history. So this
// service links automatically ONLY when a match is deterministic and
// UNAMBIGUOUS (see [_match]), same "no fuzzy matching" discipline Rev 5
// demands of identity resolution, but without the extra owner-approval
// step that risk level doesn't need here.
//
// THE MATCHING WINDOW IS DELIBERATELY SHORT, NOT "ALL HISTORY" — a real,
// named scope cut: this runs inside WorkspaceSweepService, which itself
// runs on every dashboard Overview load (see finding_endpoint.dart's
// header — "a sweep is a handful of indexed reads over one workspace").
// A query and an in-memory match over unbounded history would break
// that cost model. [_window] bounds both the SQL query and the
// candidate set. Money that goes unmatched for longer than the window
// still shows up in the unmatched TOTAL (each sweep re-queries the same
// window from "now"), but stops being actively re-attempted once a
// payment or sale falls out of it — worth widening if a real workspace
// shows this mattering, not designed away speculatively.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/repository/sale_repository.dart';

final _log = Logger('PaymentReconciliationService');

/// One currency's worth of still-unmatched money, after this run's
/// matching pass. [WorkspaceSweepService]'s detector turns this into
/// the owner-facing finding.
class UnmatchedMoney {
  const UnmatchedMoney({
    required this.currency,
    required this.totalMinor,
    required this.transactionCount,
    required this.distinctCustomerCount,
  });

  final String currency;
  final int totalMinor;
  final int transactionCount;

  /// Counts distinct known customers PLUS one for "unidentified" if any
  /// unmatched transaction has no customerId — matches the spirit of
  /// Rev 5's own example sentence ("from six customers"), while staying
  /// honest that some of the money may not be attributable to a named
  /// customer at all.
  final int distinctCustomerCount;
}

class PaymentReconciliationResult {
  const PaymentReconciliationResult({
    required this.matchedThisRun,
    required this.unmatched,
  });

  final int matchedThisRun;
  final List<UnmatchedMoney> unmatched;
}

class PaymentReconciliationService {
  PaymentReconciliationService({
    required PaymentTransactionRepository transactions,
    required SaleRepository sales,
  })  : _transactions = transactions,
        _sales = sales;

  final PaymentTransactionRepository _transactions;
  final SaleRepository _sales;

  /// See this file's header. 14 days is generous against real till/bank
  /// lag (a transfer can land hours after a sale is rung up, or vice
  /// versa if the sale is entered after the owner sees the alert) while
  /// keeping the per-sweep query and in-memory match small.
  static const _window = Duration(days: 14);

  /// A sale and a payment matching on amount+currency+time is only
  /// trusted as identity-bearing when NEITHER side contradicts the
  /// other's customer — see [_match].
  static const _timeTolerance = Duration(hours: 48);

  Future<PaymentReconciliationResult> reconcileWorkspace(int workspaceId) async {
    final now = DateTime.now().toUtc();
    final from = now.subtract(_window);

    final payments = await _transactions.listCompletedByWorkspaceAndRange(
      workspaceId: workspaceId,
      from: from,
      to: now,
    );
    final sales = await _sales.listByWorkspaceAndRange(
      workspaceId: workspaceId,
      from: from,
      to: now,
    );

    final linkedSaleIds = {
      for (final p in payments)
        if (p.saleId != null) p.saleId!,
    };
    final unmatchedPayments = payments.where((p) => p.saleId == null).toList();
    // Cash needs no reconciliation — there is no external record to
    // match it against, and a cash sale linked to a gateway payment
    // would be a contradiction, not a match.
    final candidateSales = sales
        .where((s) => s.status == 'completed')
        .where((s) => s.paymentMethod != 'cash')
        .where((s) => s.id != null && !linkedSaleIds.contains(s.id))
        .toList();

    var matched = 0;
    final stillUnmatched = <PaymentTransaction>[];

    for (final payment in unmatchedPayments) {
      final matches = candidateSales.where((s) => isMatch(payment, s)).toList();
      // UNAMBIGUOUS ONLY — more than one candidate sale fits just as
      // well means this pass genuinely cannot tell which one, and
      // guessing is exactly the "confident nonsense" Rev 5's identity
      // rules warn against for name-only matches. Left for a human (or
      // a later, richer pass) rather than picked arbitrarily.
      if (matches.length == 1) {
        final sale = matches.single;
        // Mutual uniqueness: the chosen sale must not ALSO fit another
        // still-unmatched payment equally well, or this payment could
        // be "stealing" a sale a different payment matches just as
        // validly. Cheap to check against the small in-memory set this
        // sweep already holds.
        final rivalPayments = unmatchedPayments.where((p) => p != payment && isMatch(p, sale)).toList();
        if (rivalPayments.isEmpty && sale.id != null && payment.id != null) {
          try {
            await _transactions.setSaleId(payment.id!, sale.id!);
            candidateSales.remove(sale); // consumed — no other payment may claim it this run
            matched++;
            continue;
          } catch (e) {
            _log.warning('failed to link payment ${payment.id} to sale ${sale.id}: $e');
          }
        }
      }
      stillUnmatched.add(payment);
    }

    // Group what remains by currency — almost always one currency per
    // workspace in practice, but Stripe makes multi-currency real, and
    // silently summing across currencies would produce a false total.
    final byCurrency = <String, List<PaymentTransaction>>{};
    for (final p in stillUnmatched) {
      byCurrency.putIfAbsent(p.currency, () => []).add(p);
    }

    final unmatched = [
      for (final entry in byCurrency.entries)
        UnmatchedMoney(
          currency: entry.key,
          totalMinor: entry.value.fold(0, (sum, p) => sum + p.amountKobo),
          transactionCount: entry.value.length,
          distinctCustomerCount: distinctCustomerCount(entry.value),
        ),
    ];

    return PaymentReconciliationResult(matchedThisRun: matched, unmatched: unmatched);
  }

  /// Deterministic candidate test — NOT identity resolution, just
  /// "could this payment be what paid for this sale":
  ///   • same currency, exact amount (no tolerance — a partial or
  ///     over-payment is a real discrepancy worth surfacing, not
  ///     something to paper over with a fuzzy amount match)
  ///   • sold within [_timeTolerance] of when the payment actually
  ///     landed (paidAt, falling back to createdAt for the human-marked
  ///     edge case — see listCompletedByWorkspaceAndRange's own doc)
  ///   • customer identity never CONTRADICTS: if both sides have a
  ///     resolved customerId, they must be the same one. Either side
  ///     being null (a walk-in sale, a payment whose identity resolver
  ///     had nothing to go on) does not block a match — Rev 5's "never
  ///     merge on name alone" is about MERGING two identities, not
  ///     about refusing to link a walk-in cash-register entry to the
  ///     one payment that landed at the right amount and moment.
  ///
  /// Gate 14 — public (not `_match`) specifically so
  /// `test/payment_reconciliation_service_test.dart` can exercise the
  /// real matching rule directly, with plain `PaymentTransaction`/`Sale`
  /// instances and no database — same reasoning TextChunker's own header
  /// gives for being pure: this is the piece of Gate 13 whose correctness
  /// matters most, so it's the piece worth making testable for real.
  static bool isMatch(PaymentTransaction payment, Sale sale) {
    if (payment.currency != sale.currency) return false;
    if (payment.amountKobo != sale.totalMinor) return false;
    if (payment.customerId != null && sale.customerId != null && payment.customerId != sale.customerId) {
      return false;
    }
    final paymentTime = payment.paidAt ?? payment.createdAt;
    final delta = sale.soldAt.difference(paymentTime).abs();
    return delta <= _timeTolerance;
  }

  /// Gate 14 — public for the same testability reason as [isMatch].
  static int distinctCustomerCount(List<PaymentTransaction> payments) {
    final known = <int>{};
    var hasUnknown = false;
    for (final p in payments) {
      if (p.customerId != null) {
        known.add(p.customerId!);
      } else {
        hasUnknown = true;
      }
    }
    return known.length + (hasUnknown ? 1 : 0);
  }
}
