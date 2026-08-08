// manual_payment_service.dart
//
// Bank-transfer payments: the path a very large share of SME commerce
// actually settles on. A customer asks to pay by transfer, kola shares
// the business's account details, a named person watches for the money
// and confirms it arrived.
//
// ── THE ONE RULE THIS FILE EXISTS TO ENFORCE ─────────────────────────
//
// A gateway payment is VERIFIED — the provider is re-queried and
// confirms the money moved. A transfer marked paid is a HUMAN CLAIM —
// one person tapped a button.
//
// Every transaction this service completes is written with
// confirmationMethod = 'human_marked', ALWAYS, with no parameter to
// override it. There is deliberately no code path here that can produce
// a 'gateway_verified' row, because the only thing that should ever
// write that value is a real gateway verification.
//
// This is not primarily about fraud. A rep marking the wrong order paid
// is an ordinary Tuesday mistake, and without this distinction it is
// invisible in the timeline, in reports, and in revenue totals.
//
// ── WHY THE REMINDERS BACK OFF ───────────────────────────────────────
//
// The original design reminded the assigned person every 2 minutes and
// the owner every 5, indefinitely, until someone confirmed. A customer
// saying "I'll send it this evening" would generate roughly thirty
// notifications an hour to two people — who would mute the channel, and
// the mechanism would then be dead for the case where it mattered.
//
// So: a stated expectation, intervals that widen, a hard cap, and an
// automatic expiry. Chasing harder does not make money arrive faster;
// it only makes the chasing ignorable.
//
// ── WHY 'unconfirmed' IS NOT 'failed' ────────────────────────────────
//
// When the window closes, the transfer becomes `unconfirmed` — a real
// end state, not a failure. The money may well have arrived; nobody
// confirmed it in time. Marking it failed would understate revenue and
// hide exactly the rows a reconciliation pass needs to surface.

import 'package:logging/logging.dart';

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';

final _log = Logger('ManualPaymentService');

/// Thrown when the workspace has no verified account to share.
///
/// A distinct type because the fix is specific and the caller should say
/// so: add and verify an account, rather than "something went wrong".
class NoVerifiedBankAccountException implements Exception {
  const NoVerifiedBankAccountException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ManualPaymentService {
  ManualPaymentService({
    required PaymentTransactionRepository transactions,
  }) : _transactions = transactions;

  final PaymentTransactionRepository _transactions;

  /// How long after creation each reminder fires, measured from when the
  /// transfer was requested.
  ///
  /// WIDENING, not repeating: 15m → 45m → 2h → 6h → 24h. Five reminders
  /// over a day, front-loaded while the customer is still likely at
  /// their phone, then spacing out. Compare the original design's ~720
  /// notifications in the same period.
  ///
  /// After the last one the transfer expires to `unconfirmed` rather
  /// than continuing — see [shouldExpire].
  static const reminderSchedule = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 45),
    Duration(hours: 2),
    Duration(hours: 6),
    Duration(hours: 24),
  ];

  static int get maxReminders => reminderSchedule.length;

  /// Default window when the customer gives no indication of timing.
  /// Long enough to cover "I'll do it when I get home", short enough
  /// that an abandoned request does not sit open for a week.
  static const defaultExpectedWindow = Duration(hours: 24);

  /// Whether a reminder is due now.
  ///
  /// Pure and takes [now] so it is testable without waiting real hours —
  /// the same reason TrialStateMachine takes one.
  static bool isReminderDue({
    required DateTime createdAt,
    required int remindersSent,
    required DateTime now,
  }) {
    if (remindersSent >= reminderSchedule.length) return false;
    final dueAt = createdAt.add(reminderSchedule[remindersSent]);
    return !now.isBefore(dueAt);
  }

  /// Whether a still-pending transfer has run out of window.
  ///
  /// Expiry is driven by the reminder schedule rather than by
  /// `expectedBy`: the customer's stated time is a hint, not a deadline,
  /// and someone who says "tomorrow" should not have their request
  /// closed at midnight.
  static bool shouldExpire({
    required DateTime createdAt,
    required int remindersSent,
    required DateTime now,
  }) {
    if (remindersSent < reminderSchedule.length) return false;
    final lastDue = createdAt.add(reminderSchedule.last);
    return now.isAfter(lastDue);
  }

  /// Opens a transfer request and returns the transaction to track it.
  ///
  /// [account] MUST be verified. An unverified account is refused rather
  /// than sent — a bot broadcasting bank details is precisely the
  /// pattern payment scammers impersonate, and the one protection that
  /// actually helps is that the details came from a deliberate,
  /// checked, workspace-level record rather than a text box someone
  /// typed into while building an errand.
  Future<PaymentTransaction> requestTransfer({
    required int workspaceId,
    required PaymentBankAccount account,
    required int amountMinor,
    required String currency,
    required String customerEmail,
    String? customerPhone,
    required String assignedTo,
    DateTime? expectedBy,
    int? conversationId,
    DateTime? now,
  }) async {
    if (!account.isVerified) {
      throw const NoVerifiedBankAccountException(
        'This account has not been verified yet, so it cannot be shared '
        'with a customer. Confirm the details are correct first.',
      );
    }
    if (!account.isActive) {
      throw const NoVerifiedBankAccountException(
        'This account is no longer in use. Choose the active one.',
      );
    }
    if (amountMinor <= 0) {
      throw ArgumentError('amountMinor must be positive');
    }

    final createdAt = now ?? DateTime.now().toUtc();
    final due = expectedBy ?? createdAt.add(defaultExpectedWindow);

    final transaction = await _transactions.create(
      workspaceId: workspaceId,
      gateway: 'bank_transfer',
      reference: _generateReference(createdAt),
      amountKobo: amountMinor,
      currency: currency,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      conversationId: conversationId,
      status: 'pending',
      // Not verified, and never will be by this path.
      confirmationMethod: 'human_marked',
      assignedTo: assignedTo,
      expectedBy: due,
    );

    _log.info('Transfer requested: workspace=$workspaceId '
        'amount=$amountMinor $currency assignedTo=$assignedTo '
        'expectedBy=$due');

    return transaction;
  }

  /// Records that a person confirms the money arrived.
  ///
  /// [confirmedBy] and at least one of [proofReference] / [proofUrl] are
  /// required TOGETHER, on purpose. Proof asked for later almost never
  /// materialises — the transfer receipt is in front of the person at
  /// this exact moment and nowhere else. Without it a dispute three
  /// weeks from now is one person's memory against another's.
  ///
  /// The resulting row is `completed` but `human_marked`. Every surface
  /// that shows money must render that differently from a verified
  /// payment.
  Future<PaymentTransaction> markPaid({
    required int transactionId,
    required int workspaceId,
    required String confirmedBy,
    String? proofReference,
    String? proofUrl,
    DateTime? now,
  }) async {
    final hasProof = (proofReference != null && proofReference.trim().isNotEmpty) ||
        (proofUrl != null && proofUrl.trim().isNotEmpty);
    if (!hasProof) {
      throw ArgumentError(
        'A transfer reference or a screenshot is required to mark this '
        'paid. Without one there is nothing to check against later.',
      );
    }
    if (confirmedBy.trim().isEmpty) {
      throw ArgumentError('confirmedBy is required — someone owns this claim.');
    }

    final existing = await _transactions.findByIdScoped(transactionId, workspaceId);
    if (existing == null) {
      throw Exception('Transaction $transactionId not found in this workspace.');
    }
    if (existing.gateway != 'bank_transfer') {
      // A gateway transaction must never be human-marked — that would
      // overwrite a verified fact with a claim.
      throw ArgumentError(
        'Transaction $transactionId is a ${existing.gateway} payment and is '
        'confirmed by the provider, not by hand.',
      );
    }
    if (existing.status == 'completed') {
      _log.info('Transaction $transactionId already completed — no-op.');
      return existing;
    }

    final confirmedAt = now ?? DateTime.now().toUtc();
    _log.warning('Transfer HUMAN-MARKED paid: txn=$transactionId '
        'workspace=$workspaceId by=$confirmedBy');

    return _transactions.markHumanConfirmed(
      transactionId: transactionId,
      confirmedBy: confirmedBy.trim(),
      confirmedAt: confirmedAt,
      proofReference: proofReference?.trim(),
      proofUrl: proofUrl?.trim(),
    );
  }

  /// Closes a transfer nobody confirmed within the window.
  ///
  /// `unconfirmed`, NOT `failed` — see this file's header. These are
  /// exactly the rows an end-of-day reconciliation should surface:
  /// "these were requested and never confirmed; did the money arrive?"
  Future<void> expire(int transactionId) async {
    _log.info('Transfer expired to unconfirmed: txn=$transactionId');
    await _transactions.setStatus(transactionId, 'unconfirmed');
  }

  static String _generateReference(DateTime at) =>
      'KOLA-TR-${at.microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';
}
