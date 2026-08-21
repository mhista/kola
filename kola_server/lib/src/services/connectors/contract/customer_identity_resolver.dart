// customer_identity_resolver.dart — Gate 3. The single entry point
// every signal-bearing intake path (conversation start, payment
// webhook, till sale) goes through to resolve "which Customer is this."
// PART V: "Deterministic matching first — normalized phone, then
// email, then exact name plus one corroborating field. No fuzzy
// matching in the first version." "Never merge on name alone."
//
// ── WHY NAME IS NOT MATCHED ON HERE ──────────────────────────────────
//
// See migration 039's header: this codebase has no corroborating field
// (address, city, anything) to legitimately pair a name with today.
// Rather than invent one to technically satisfy the PDF's third tier,
// this resolver only matches on phone or email — both real, portable
// identity facts. A bare name is still recorded as a signal (via
// [attachSignal]) for display and for the day a real corroborating
// field exists, but it never drives a match or a create-vs-reuse
// decision.
//
// ── THE CONFLICT CASE: WHERE A MERGE PROPOSAL COMES FROM ────────────
//
// A single incoming event can carry more than one signal at once (a
// payment has both a phone and an email). If the phone resolves to
// Customer A and the email resolves to a DIFFERENT existing Customer B,
// that is a genuine conflict this resolver cannot safely settle on its
// own — so it does not silently pick one, and it does not merge them.
// It raises a CustomerMergeProposal (A, B) with both signal values as
// evidence, resolves the CURRENT event against whichever signal was
// checked first (phone takes priority over email, matching the PDF's
// own ordering), and lets the owner confirm or reject the suspected
// merge later. This is fully deterministic — it never compares two
// customers for similarity, only reacts to a real conflict a real event
// just produced.
//
// ── WHY emit() NEVER THROWS ──────────────────────────────────────────
//
// Same discipline as EventBus.emit and ConnectorSyncLogRepository
// .record — identity resolution failing must never be the reason a
// real business action (a conversation starting, a payment confirming,
// a sale ringing up) fails. A resolution failure means the record
// simply has no customerId yet; it is not lost, and nothing about the
// action itself is undone.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/customer_repository.dart';
import 'package:kola_server/src/services/repository/customer_identity_signal_repository.dart';
import 'package:kola_server/src/services/repository/customer_merge_proposal_repository.dart';

/// One signal extracted from an incoming event — a phone, an email, a
/// platform id, or a name. [type] is 'phone' | 'email' | 'name' |
/// 'platform_user'; callers should already have normalized [value]
/// (see this file's static normalize* helpers) before constructing one.
class IdentitySignal {
  const IdentitySignal({
    required this.type,
    required this.value,
    this.sourceRef,
  });

  final String type;
  final String value;
  final String? sourceRef;
}

class CustomerIdentityResolver {
  CustomerIdentityResolver({
    required CustomerRepository customers,
    required CustomerIdentitySignalRepository signals,
    required CustomerMergeProposalRepository mergeProposals,
  }) : _customers = customers,
       _signals = signals,
       _mergeProposals = mergeProposals;

  final CustomerRepository _customers;
  final CustomerIdentitySignalRepository _signals;
  final CustomerMergeProposalRepository _mergeProposals;

  /// Resolves (finding or creating) the Customer that [primary] and, if
  /// present, [secondary] refer to. Only phone and email/platform_user
  /// types ever drive matching — see header. Returns the RESOLVED
  /// customerId, following any prior merge to its canonical root, or
  /// null if resolution itself failed (never throws — see header).
  ///
  /// [source] / [firstSeenSource]: 'whatsapp' | 'telegram' | 'paystack'
  /// | 'flutterwave' | 'till' | 'manual'.
  Future<int?> resolve({
    required int workspaceId,
    required IdentitySignal primary,
    IdentitySignal? secondary,
    required String source,
  }) async {
    try {
      final primaryMatch = await _signals.findMatch(
        workspaceId: workspaceId,
        signalType: primary.type,
        normalizedValue: primary.value,
      );

      final secondaryMatch = secondary == null
          ? null
          : await _signals.findMatch(
              workspaceId: workspaceId,
              signalType: secondary.type,
              normalizedValue: secondary.value,
            );

      // Both signals — or just the one present — agree, or only one is
      // known: straightforward attach-or-create, no conflict.
      if (primaryMatch == null && secondaryMatch == null) {
        return await _createWithSignals(
          workspaceId: workspaceId,
          source: source,
          primary: primary,
          secondary: secondary,
        );
      }

      if (primaryMatch != null &&
          (secondaryMatch == null || secondaryMatch.customerId == primaryMatch.customerId)) {
        if (secondary != null && secondaryMatch == null) {
          await _signals.attach(
            workspaceId: workspaceId,
            customerId: primaryMatch.customerId,
            signalType: secondary.type,
            normalizedValue: secondary.value,
            source: source,
            sourceRef: secondary.sourceRef,
          );
        }
        return await _canonical(primaryMatch.customerId);
      }

      if (primaryMatch == null && secondaryMatch != null) {
        await _signals.attach(
          workspaceId: workspaceId,
          customerId: secondaryMatch.customerId,
          signalType: primary.type,
          normalizedValue: primary.value,
          source: source,
          sourceRef: primary.sourceRef,
        );
        return await _canonical(secondaryMatch.customerId);
      }

      // Both matched, but to DIFFERENT customers — the conflict case.
      // See header. Never auto-merge; raise a proposal and resolve this
      // event against the primary signal's owner.
      Log.info(
        'CustomerIdentityResolver: conflict in workspace $workspaceId — '
        '${primary.type}:${primary.value} -> customer ${primaryMatch!.customerId}, '
        '${secondary!.type}:${secondary.value} -> customer ${secondaryMatch!.customerId}',
      );
      await _mergeProposals.raise(
        workspaceId: workspaceId,
        customerIdA: primaryMatch.customerId,
        customerIdB: secondaryMatch.customerId,
        matchedOn:
            'A new $source record has ${primary.type} "${primary.value}", which '
            'matches one existing customer, and ${secondary.type} '
            '"${secondary.value}", which matches a different existing customer.',
        evidence: {
          'primarySignal': {'type': primary.type, 'value': primary.value},
          'secondarySignal': {'type': secondary.type, 'value': secondary.value},
          'source': source,
        },
      );
      return await _canonical(primaryMatch.customerId);
    } catch (e, stackTrace) {
      Log.error(
        'CustomerIdentityResolver.resolve failed for workspace $workspaceId '
        '($source) — the triggering action itself still succeeded; only '
        'customer linkage was lost',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Attach an extra signal (typically 'name') to an already-resolved
  /// customer without it ever participating in matching. Never throws.
  Future<void> attachSignal({
    required int workspaceId,
    required int customerId,
    required IdentitySignal signal,
    required String source,
  }) async {
    try {
      await _signals.attach(
        workspaceId: workspaceId,
        customerId: customerId,
        signalType: signal.type,
        normalizedValue: signal.value,
        source: source,
        sourceRef: signal.sourceRef,
      );
      if (signal.type == 'name') {
        await _customers.setDisplayName(customerId, signal.value);
      }
    } catch (e) {
      Log.error('CustomerIdentityResolver.attachSignal failed', error: e);
    }
  }

  Future<int?> _createWithSignals({
    required int workspaceId,
    required String source,
    required IdentitySignal primary,
    IdentitySignal? secondary,
  }) async {
    final customer = await _customers.create(
      workspaceId: workspaceId,
      firstSeenSource: source,
    );
    final id = customer.id;
    if (id == null) return null;

    await _signals.attach(
      workspaceId: workspaceId,
      customerId: id,
      signalType: primary.type,
      normalizedValue: primary.value,
      source: source,
      sourceRef: primary.sourceRef,
    );
    if (secondary != null) {
      await _signals.attach(
        workspaceId: workspaceId,
        customerId: id,
        signalType: secondary.type,
        normalizedValue: secondary.value,
        source: source,
        sourceRef: secondary.sourceRef,
      );
    }
    return id;
  }

  Future<int?> _canonical(int customerId) async {
    final resolved = await _customers.resolveCanonical(customerId);
    return resolved?.id;
  }

  // ── NORMALIZATION HELPERS ────────────────────────────────────────────
  // Every call site should build IdentitySignal values through these
  // rather than hand-rolling normalization — one definition of "the
  // same phone number" for the whole codebase.

  static String normalizePhone(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

  static String normalizeEmail(String raw) => raw.trim().toLowerCase();

  static String normalizeName(String raw) => raw.trim().toLowerCase();

  static String normalizePlatformUser(String platform, String externalId) =>
      '$platform:$externalId';
}
