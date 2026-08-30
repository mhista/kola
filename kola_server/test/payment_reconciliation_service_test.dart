// payment_reconciliation_service_test.dart
//
// GATE 14. Real, runnable tests for the matching rule Gate 13's own
// header calls out as the thing this codebase most needs to get right:
// "money the business has and does not know what to do with." The rule
// itself (isMatch, distinctCustomerCount) was made public specifically
// for this file — see payment_reconciliation_service.dart's doc comment
// on isMatch — following the same "make the thing you most need to
// trust the thing you can actually test" reasoning text_chunker_test.dart
// established as this codebase's first automated test.
//
// WHAT IS NOT TESTED HERE, AND WHY IT'S HONEST TO SAY SO:
//   reconcileWorkspace() itself — the method that queries, links, and
//   writes — is NOT exercised here. It's constructed from
//   PaymentTransactionRepository and SaleRepository, both concrete
//   classes that talk to Supabase directly with no interface to fake
//   against. Testing it for real means either introducing repository
//   interfaces (a real refactor, not attempted speculatively here) or a
//   live/staging database, neither of which this pass invents unasked.
//   What's tested instead is the part that decides whether two records
//   describe the same transaction — isMatch — which is where a bug
//   would actually cost a business money (a false match silently marks
//   real money as accounted for; a false non-match hides money that is).
//   See GATE_14_STATUS.md for the full list of what this gate covers and
//   what it names as a real, unclosed gap.
//
// Run with: dart test test/

import 'package:test/test.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/billing/payment_reconciliation_service.dart';

PaymentTransaction _payment({
  int? id,
  int? customerId,
  int amountKobo = 500000,
  String currency = 'NGN',
  DateTime? paidAt,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 8, 1, 12);
  return PaymentTransaction(
    id: id,
    workspaceId: 1,
    gateway: 'paystack',
    reference: 'ref-${id ?? 0}',
    amountKobo: amountKobo,
    currency: currency,
    customerEmail: 'buyer@example.com',
    customerId: customerId,
    status: 'completed',
    holdStatus: 'released',
    confirmationMethod: 'gateway',
    reminderCount: 0,
    createdAt: created,
    updatedAt: created,
    paidAt: paidAt ?? created,
  );
}

Sale _sale({
  int? id,
  int? customerId,
  int totalMinor = 500000,
  String currency = 'NGN',
  String paymentMethod = 'transfer',
  String status = 'completed',
  DateTime? soldAt,
}) {
  final sold = soldAt ?? DateTime.utc(2026, 8, 1, 12);
  return Sale(
    id: id,
    workspaceId: 1,
    customerId: customerId,
    reference: 'sale-${id ?? 0}',
    subtotalMinor: totalMinor,
    taxRateBps: 0,
    taxMinor: 0,
    totalMinor: totalMinor,
    currency: currency,
    paymentMethod: paymentMethod,
    status: status,
    soldAt: sold,
    createdAt: sold,
    updatedAt: sold,
  );
}

void main() {
  group('PaymentReconciliationService.isMatch', () {
    test('matches on exact amount, currency, and close time', () {
      final payment = _payment();
      final sale = _sale();
      expect(PaymentReconciliationService.isMatch(payment, sale), isTrue);
    });

    test('does not match a different currency, same amount', () {
      final payment = _payment(currency: 'NGN');
      final sale = _sale(currency: 'USD');
      expect(PaymentReconciliationService.isMatch(payment, sale), isFalse);
    });

    test('does not match a different amount — no tolerance for partial/over payment', () {
      final payment = _payment(amountKobo: 500000);
      final sale = _sale(totalMinor: 499900);
      expect(PaymentReconciliationService.isMatch(payment, sale), isFalse,
          reason: 'a ₦1 short payment is a real discrepancy, not something '
              'a fuzzy match should paper over');
    });

    test('does not match outside the 48-hour tolerance', () {
      final paidAt = DateTime.utc(2026, 8, 1, 0);
      final payment = _payment(paidAt: paidAt);
      final sale = _sale(soldAt: paidAt.add(const Duration(hours: 49)));
      expect(PaymentReconciliationService.isMatch(payment, sale), isFalse);
    });

    test('matches right at the edge of the 48-hour tolerance', () {
      final paidAt = DateTime.utc(2026, 8, 1, 0);
      final payment = _payment(paidAt: paidAt);
      final sale = _sale(soldAt: paidAt.add(const Duration(hours: 48)));
      expect(PaymentReconciliationService.isMatch(payment, sale), isTrue);
    });

    test('time tolerance is symmetric — a sale rung up before the payment lands still matches', () {
      final paidAt = DateTime.utc(2026, 8, 1, 12);
      final payment = _payment(paidAt: paidAt);
      final sale = _sale(soldAt: paidAt.subtract(const Duration(hours: 10)));
      expect(PaymentReconciliationService.isMatch(payment, sale), isTrue);
    });

    test('a walk-in sale with no customerId still matches an identified payment', () {
      final payment = _payment(customerId: 42);
      final sale = _sale(customerId: null);
      expect(PaymentReconciliationService.isMatch(payment, sale), isTrue,
          reason: 'either side being null must not block a match — see '
              'isMatch\'s own doc on why this differs from identity merging');
    });

    test('an unidentified payment still matches a sale with a known customer', () {
      final payment = _payment(customerId: null);
      final sale = _sale(customerId: 42);
      expect(PaymentReconciliationService.isMatch(payment, sale), isTrue);
    });

    test('does not match when both sides know a customer and they disagree', () {
      final payment = _payment(customerId: 42);
      final sale = _sale(customerId: 99);
      expect(PaymentReconciliationService.isMatch(payment, sale), isFalse);
    });

    test('matches when both sides know a customer and they agree', () {
      final payment = _payment(customerId: 42);
      final sale = _sale(customerId: 42);
      expect(PaymentReconciliationService.isMatch(payment, sale), isTrue);
    });

    test('falls back to createdAt when paidAt is null', () {
      // PaymentTransaction.paidAt is nullable in the schema for the
      // manually-confirmed-bank-transfer path; the service falls back
      // to createdAt so those payments are still reconcilable.
      final created = DateTime.utc(2026, 8, 1, 12);
      final payment = PaymentTransaction(
        workspaceId: 1,
        gateway: 'bank_transfer',
        reference: 'ref-manual',
        amountKobo: 500000,
        currency: 'NGN',
        customerEmail: 'buyer@example.com',
        status: 'completed',
        holdStatus: 'released',
        confirmationMethod: 'manual',
        reminderCount: 0,
        createdAt: created,
        updatedAt: created,
        paidAt: null,
      );
      final sale = _sale(soldAt: created.add(const Duration(hours: 1)));
      expect(PaymentReconciliationService.isMatch(payment, sale), isTrue);
    });
  });

  group('PaymentReconciliationService.distinctCustomerCount', () {
    test('is zero for an empty list', () {
      expect(PaymentReconciliationService.distinctCustomerCount([]), 0);
    });

    test('counts each distinct known customer once', () {
      final payments = [
        _payment(id: 1, customerId: 1),
        _payment(id: 2, customerId: 1),
        _payment(id: 3, customerId: 2),
      ];
      expect(PaymentReconciliationService.distinctCustomerCount(payments), 2);
    });

    test('adds exactly one for any number of unidentified payments', () {
      final payments = [
        _payment(id: 1, customerId: null),
        _payment(id: 2, customerId: null),
        _payment(id: 3, customerId: 2),
      ];
      // 1 known customer + 1 bucket for "unidentified", not 2 + 1 —
      // matches the "from six customers" style sentence this feeds,
      // where every anonymous payment isn't its own customer.
      expect(PaymentReconciliationService.distinctCustomerCount(payments), 2);
    });

    test('does not add an unidentified bucket when every payment is identified', () {
      final payments = [
        _payment(id: 1, customerId: 1),
        _payment(id: 2, customerId: 2),
      ];
      expect(PaymentReconciliationService.distinctCustomerCount(payments), 2);
    });
  });
}
