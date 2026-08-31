// offline_sale_queue.dart — Phase 11g-b. The local outbox a sale is
// written to when it cannot reach the server, so it is queued rather
// than lost. Built and testable on its own, before 11g-c wires
// till_page.dart to actually use it.
//
// ── WHY window.localStorage AND NOT INDEXEDDB ────────────────────────
//
// The obvious "real" choice for offline queuing is IndexedDB, and it
// was considered first. Rejected for this pass, for a concrete reason
// rather than convenience: IndexedDB's raw browser API is
// callback/event-based (onsuccess/onerror/onupgradeneeded handlers on
// IDBRequest), which is exactly the kind of dynamic, loosely-typed JS
// interop `dom_files.dart`'s own header warns this codebase has gotten
// wrong before, silently, in a way that only shows up at runtime with
// no Dart toolchain here to catch it before a real user hits it. A
// till's offline queue holds, realistically, a handful to a few dozen
// unsynced sales at once — not a dataset IndexedDB's extra complexity
// buys anything for. `local_storage.dart` already has a PROVEN, simple,
// synchronous wrapper over `window.localStorage` (Storage.getItem/
// setItem — plain, non-overloaded DOM methods, not an interop trap),
// already shipping in production for the auth session and workspace
// selection. This reuses that exact mechanism instead of introducing a
// second, riskier one. If the queue's real-world size ever outgrows
// localStorage's ~5-10MB-per-origin ceiling, THAT is the trigger to
// revisit IndexedDB — not a preference stated up front.
//
// ── WHAT clientReference IS AND WHY IT'S GENERATED HERE ──────────────
//
// `SaleEndpoint.ringUpSale` already has a live idempotency guard: pass
// the same `clientReference` twice and the second call returns the
// FIRST call's Sale unchanged rather than double-selling (see
// `sale_repository.dart`'s `findByClientReference`). This queue is what
// finally puts a value in that parameter — till_page.dart never has
// before. Generated once, at enqueue time, and reused for every sync
// attempt of that entry: if attempt 1 reaches the server and writes the
// Sale but the response is lost to the same outage that's about to
// start, attempt 2 (after reconnecting) must resolve to the SAME sale,
// not a duplicate. That safety only holds if the reference is fixed at
// enqueue time and never regenerated per attempt.

import 'dart:convert';
import 'dart:math';

import 'local_storage.dart';

/// One sale that could not reach the server and is waiting to sync.
///
/// Deliberately mirrors `SaleEndpoint.ringUpSale`'s own parameter list
/// (see `kola_server/lib/src/endpoints/sale_endpoint.dart`) rather than
/// inventing a different shape — 11g-d's sync engine passes these
/// fields straight through to that same method.
class QueuedSale {
  QueuedSale({
    required this.clientReference,
    required this.linesJson,
    required this.paymentMethod,
    required this.queuedAt,
    this.cashReceivedMinor,
    this.customerPhone,
    this.customerName,
    this.attempts = 0,
    this.lastError,
  });

  final String clientReference;
  final String linesJson;
  final String paymentMethod;
  final DateTime queuedAt;
  final int? cashReceivedMinor;
  final String? customerPhone;
  final String? customerName;

  /// How many sync attempts have failed so far. 0 means "never tried
  /// yet" — the normal state right after `_completeSale` queues it and
  /// before the sync engine's next pass runs.
  final int attempts;

  /// The most recent sync failure, human-readable, or null if it has
  /// never failed. Not shown raw to the shop owner — 11g-c/11g-d turn
  /// this into the brief's calm "Sync problem" framing rather than a
  /// stack trace.
  final String? lastError;

  QueuedSale copyWith({int? attempts, String? lastError}) => QueuedSale(
        clientReference: clientReference,
        linesJson: linesJson,
        paymentMethod: paymentMethod,
        queuedAt: queuedAt,
        cashReceivedMinor: cashReceivedMinor,
        customerPhone: customerPhone,
        customerName: customerName,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );

  Map<String, dynamic> toJson() => {
        'clientReference': clientReference,
        'linesJson': linesJson,
        'paymentMethod': paymentMethod,
        'queuedAt': queuedAt.toIso8601String(),
        'cashReceivedMinor': cashReceivedMinor,
        'customerPhone': customerPhone,
        'customerName': customerName,
        'attempts': attempts,
        'lastError': lastError,
      };

  static QueuedSale fromJson(Map<String, dynamic> json) => QueuedSale(
        clientReference: json['clientReference'] as String,
        linesJson: json['linesJson'] as String,
        paymentMethod: json['paymentMethod'] as String,
        queuedAt: DateTime.parse(json['queuedAt'] as String),
        cashReceivedMinor: json['cashReceivedMinor'] as int?,
        customerPhone: json['customerPhone'] as String?,
        customerName: json['customerName'] as String?,
        attempts: json['attempts'] as int? ?? 0,
        lastError: json['lastError'] as String?,
      );
}

/// The outbox itself — one queue per browser (this deliberately does
/// NOT scope by workspace id in the storage key; a cashier's device is
/// realistically tied to one workspace at a time, and scoping by
/// workspace would only add a place to silently orphan queued sales if
/// the selected workspace ever changed while entries were pending).
abstract class OfflineSaleQueue {
  static const _key = 'kola_offline_sale_queue';
  static final _rand = Random.secure();

  /// A reference unique enough for this purpose: this queue never holds
  /// more than a handful of entries at once, and a collision would only
  /// ever occur across two DIFFERENT devices generating one in the same
  /// microsecond — vanishingly unlikely, and even then caught by the
  /// server's own unique index on (workspaceId, clientReference) rather
  /// than silently miscounted. Not a cryptographic UUID; doesn't need
  /// to be one.
  static String _generateReference() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = List.generate(8, (_) => _rand.nextInt(16).toRadixString(16)).join();
    return 'offline-$ts-$rnd';
  }

  static List<QueuedSale> list() {
    final raw = LocalStorage.getItem(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return [for (final e in decoded) QueuedSale.fromJson(e as Map<String, dynamic>)];
    } catch (_) {
      // A corrupted entry (a browser extension touching localStorage, a
      // half-written value from a crashed tab) must never crash the
      // till. Treat it as an empty queue rather than throwing — real
      // queued sales are extremely unlikely to be lost this way since
      // writes are small, single, atomic setItem calls.
      return const [];
    }
  }

  static void _save(List<QueuedSale> entries) {
    LocalStorage.setItem(_key, jsonEncode([for (final e in entries) e.toJson()]));
  }

  static int get pendingCount => list().length;

  /// Queues a sale and returns it (with its freshly-generated
  /// `clientReference`) so the caller can show it on the receipt screen
  /// immediately — the brief's "the owner must be able to see the money
  /// is not lost" applies the instant the sale is queued, not only once
  /// the sync engine gets to it.
  static QueuedSale enqueue({
    required String linesJson,
    required String paymentMethod,
    int? cashReceivedMinor,
    String? customerPhone,
    String? customerName,
  }) {
    final entry = QueuedSale(
      clientReference: _generateReference(),
      linesJson: linesJson,
      paymentMethod: paymentMethod,
      queuedAt: DateTime.now().toUtc(),
      cashReceivedMinor: cashReceivedMinor,
      customerPhone: customerPhone,
      customerName: customerName,
    );
    _save([...list(), entry]);
    return entry;
  }

  /// Removes an entry once the server confirms it — either just synced,
  /// or (via `clientReference`'s idempotency guarantee) discovered to
  /// already exist from an earlier attempt whose response never made it
  /// back.
  static void markSynced(String clientReference) {
    _save([for (final e in list()) if (e.clientReference != clientReference) e]);
  }

  /// A sync attempt failed. Stays in the queue — per the brief, "nothing
  /// is lost, it will retry" — with the failure recorded so the sync
  /// engine (11g-d) can back off and the UI (11g-c) can surface "Sync
  /// problem" after enough of these accumulate, without the shop owner
  /// ever seeing the raw error text.
  static void markFailed(String clientReference, String error) {
    _save([
      for (final e in list())
        if (e.clientReference == clientReference)
          e.copyWith(attempts: e.attempts + 1, lastError: error)
        else
          e,
    ]);
  }
}
