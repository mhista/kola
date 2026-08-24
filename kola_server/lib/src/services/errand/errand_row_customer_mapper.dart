// errand_row_customer_mapper.dart
//
// Gate 5's second half: "someone else's system, mapped to entities."
// Applies a saved errand_entity_mappings row (see migration 044) to a
// dbCredential Errand's query result: for every returned row, builds an
// IdentitySignal from the owner-declared phone/email/name columns and
// hands it to CustomerIdentityResolver — the SAME resolver
// paystack_adapter.dart, flutterwave_adapter.dart and bumpa_adapter.dart
// already use, not a second implementation of identity matching. See
// migration 044's own header on why Customer is the only entity this
// maps into today (no generic Order model exists in this codebase, and
// Sale/PaymentTransaction are both too domain-specific to reuse
// honestly for an arbitrary business's own rows).
//
// ONLY 'rows' RESULTS ARE UNDERSTOOD, WHICH MEANS ONLY dbCredential
// ERRANDS: DbCredentialErrandExecutor's result shape is always
// {'rows': [...]} (see that file). A webhook Errand's response is
// arbitrary JSON with no such guaranteed shape — mapping that
// generically is a real, separate design question (does it look for a
// 'rows'/'customers'/'data' key? what if the response is a single
// object, not a list?) and is deliberately NOT attempted here. A row
// whose shape this cannot recognise is silently skipped, not guessed
// at.
//
// NEVER THROWS, NEVER BLOCKS THE ERRAND'S OWN RESULT: same discipline
// as CustomerIdentityResolver.resolve itself — this runs AFTER a real
// Errand execution has already succeeded and already been logged; a
// mapping failure must never retroactively make that execution look
// like it failed, and must never delay the caller waiting on the
// Errand's actual result any more than the mapping work itself takes.

import 'dart:convert';

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/repository/errand_entity_mapping_repository.dart';

class ErrandRowCustomerMapper {
  ErrandRowCustomerMapper({
    required ErrandEntityMappingRepository mappings,
    required CustomerIdentityResolver identity,
    required EventBus events,
  }) : _mappings = mappings,
       _identity = identity,
       _events = events;

  final ErrandEntityMappingRepository _mappings;
  final CustomerIdentityResolver _identity;
  final EventBus _events;

  /// Caps how many rows one execution will attempt to resolve — a
  /// misconfigured "select * from orders" with no WHERE clause (that Gate
  /// 5's own query-template UI's "limit 20" default guards against, but a
  /// hand-edited template might not) should degrade to "only the first
  /// 200 rows got linked," never to a multi-minute stall on an Errand
  /// call a conversation is waiting on.
  static const _maxRowsPerRun = 200;

  /// No-op if [errand] has no saved mapping, the mapping is disabled, or
  /// [executionResult] isn't the {'rows': [...]} shape a dbCredential
  /// Errand produces. Otherwise resolves/creates a Customer per row via
  /// [CustomerIdentityResolver] and emits ONE summary event for the
  /// whole run (not one per row — see EventBus/workspace_findings'
  /// existing "don't flood the timeline" discipline).
  Future<void> applyIfMapped({
    required int workspaceId,
    required Errand errand,
    required Map<String, dynamic> executionResult,
  }) async {
    final errandId = errand.id;
    if (errandId == null || errand.source != 'dbCredential') return;

    try {
      final mappingRow = await _mappings.findByErrandId(errandId);
      if (mappingRow == null) return;

      final Map<String, dynamic> mapping;
      try {
        mapping = jsonDecode(mappingRow.mappingJson) as Map<String, dynamic>;
      } catch (e) {
        Log.warning('ErrandRowCustomerMapper: mapping_json for errand $errandId is not valid JSON: $e');
        return;
      }
      if (mapping['enabled'] != true) return;

      final phoneColumn = (mapping['phoneColumn'] as String?)?.trim();
      final emailColumn = (mapping['emailColumn'] as String?)?.trim();
      final nameColumn = (mapping['nameColumn'] as String?)?.trim();
      final hasPhone = phoneColumn != null && phoneColumn.isNotEmpty;
      final hasEmail = emailColumn != null && emailColumn.isNotEmpty;
      if (!hasPhone && !hasEmail) return; // ErrandEndpoint.setEntityMapping should already prevent this from being saved — re-checked here rather than trusted.

      final rowsRaw = executionResult['rows'];
      if (rowsRaw is! List) return;

      var resolved = 0;
      var skipped = 0;
      final rowsToProcess = rowsRaw.take(_maxRowsPerRun).toList();

      for (final rawRow in rowsToProcess) {
        if (rawRow is! Map) {
          skipped++;
          continue;
        }

        IdentitySignal? primary;
        IdentitySignal? secondary;

        if (hasPhone) {
          final raw = rawRow[phoneColumn]?.toString().trim();
          if (raw != null && raw.isNotEmpty) {
            primary = IdentitySignal(
              type: 'phone',
              value: CustomerIdentityResolver.normalizePhone(raw),
              sourceRef: 'errand:$errandId',
            );
          }
        }
        if (hasEmail) {
          final raw = rawRow[emailColumn]?.toString().trim();
          if (raw != null && raw.isNotEmpty) {
            final emailSignal = IdentitySignal(
              type: 'email',
              value: CustomerIdentityResolver.normalizeEmail(raw),
              sourceRef: 'errand:$errandId',
            );
            if (primary == null) {
              primary = emailSignal;
            } else {
              secondary = emailSignal;
            }
          }
        }

        if (primary == null) {
          // This particular row had neither a usable phone nor email
          // value (blank cell, null, etc.) — not an error, just nothing
          // to resolve identity from.
          skipped++;
          continue;
        }

        final customerId = await _identity.resolve(
          workspaceId: workspaceId,
          primary: primary,
          secondary: secondary,
          source: 'errand',
        );

        if (customerId == null) {
          skipped++;
          continue;
        }

        if (nameColumn != null && nameColumn.isNotEmpty) {
          final rawName = rawRow[nameColumn]?.toString().trim();
          if (rawName != null && rawName.isNotEmpty) {
            await _identity.attachSignal(
              workspaceId: workspaceId,
              customerId: customerId,
              signal: IdentitySignal(
                type: 'name',
                value: CustomerIdentityResolver.normalizeName(rawName),
                sourceRef: 'errand:$errandId',
              ),
              source: 'errand',
            );
          }
        }

        resolved++;
      }

      final now = DateTime.now().toUtc();
      await _events.emit(
        workspaceId: workspaceId,
        eventType: 'errand_rows_mapped_to_customers',
        fingerprint: 'errand_rows_mapped_to_customers:$errandId:${now.microsecondsSinceEpoch}',
        payload: {
          'errandId': errandId,
          'rowsSeen': rowsRaw.length,
          'rowsProcessed': rowsToProcess.length,
          'customersResolved': resolved,
          'rowsSkipped': skipped,
        },
        occurredAt: now,
      );

      Log.success(
        'Errand rows mapped to customers',
        data: {
          'workspaceId': workspaceId,
          'errandId': errandId,
          'customersResolved': resolved,
          'rowsSkipped': skipped,
        },
      );
    } catch (e, stackTrace) {
      // Never rethrow — see file header. A mapping failure must never
      // undo or hide an Errand execution that already succeeded.
      Log.error(
        'ErrandRowCustomerMapper.applyIfMapped failed for errand $errandId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
