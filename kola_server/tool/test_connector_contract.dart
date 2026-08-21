// ignore_for_file: avoid_print
// ^ One-off CLI script: stdout IS the output. Same targeted ignore as
//   every other tool/test_*.dart in this project.
//
// tool/test_connector_contract.dart
//
// Gate 1 verification, against the LIVE Supabase — same spirit and same
// harness shape as tool/test_connectors.dart, because this codebase has
// no automated test suite yet (PART II of the connections brief marks
// "Evaluations" PARTIAL: "manual harnesses in tool/"). This is that
// harness for the connector contract added in migration 036.
//
// Exercises the three things PART VIII's own testing section asks for
// that this gate's code actually touches:
//
//   1. REPLAY IDEMPOTENCY — the same external_message_id inserted twice
//      via MessageRepository.create must produce ONE row, not two.
//   2. DEAD-LETTER ON PERMANENT FAILURE — ConnectorRetry.run against an
//      action that always throws must exhaust its attempts and leave
//      exactly one 'error' row in connector_sync_log, not one per
//      attempt.
//   3. CROSS-TENANT ISOLATION — ConnectorSyncLogRepository.recentFor for
//      workspace A must never return a row written under workspace B,
//      even when both share a connectorKey (a realistic case: two
//      workspaces both have a 'whatsapp' channel).
//
// USAGE (run from kola_server/, with your .env in place):
//
//   dart run tool/test_connector_contract.dart --conversation-id=1 --workspace-id=1 --other-workspace-id=2
//
// --conversation-id must be a REAL conversations.id your database
// already has (test 1 inserts messages against it, then deletes them —
// see cleanup below). --workspace-id and --other-workspace-id must be
// two DIFFERENT real workspaces.id values for test 3 to mean anything;
// if you only have one workspace, pass the same id twice — test 3 will
// report itself SKIPPED rather than passing on a check that never
// actually crossed a tenant boundary.

import 'dart:io';

import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/supabase_client.dart';
import 'package:kola_server/src/services/repository/message_repository.dart';
import 'package:kola_server/src/services/repository/connector_sync_log_repository.dart';
import 'package:kola_server/src/services/connectors/contract/connector_retry.dart';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);
  final conversationId = int.tryParse(flags['conversation-id'] ?? '');
  final workspaceId = int.tryParse(flags['workspace-id'] ?? '');
  final otherWorkspaceId = int.tryParse(flags['other-workspace-id'] ?? '');

  if (conversationId == null || workspaceId == null) {
    print('❌ Usage: dart run tool/test_connector_contract.dart '
        '--conversation-id=<id> --workspace-id=<id> [--other-workspace-id=<id>]');
    exit(1);
  }

  await initSupabase();
  setupDependencyInjection();

  var failures = 0;

  failures += await _testIdempotentReplay(conversationId);
  failures += await _testDeadLetterOnPermanentFailure(workspaceId);
  failures += await _testCrossTenantIsolation(workspaceId, otherWorkspaceId);

  print('');
  if (failures == 0) {
    print('✅ All connector-contract checks passed.');
    exit(0);
  } else {
    print('❌ $failures check(s) failed.');
    exit(1);
  }
}

/// Test 1 — replay idempotency (migration 036's unique index on
/// (conversation_id, external_message_id)).
Future<int> _testIdempotentReplay(int conversationId) async {
  print('── Test 1: replay idempotency');
  final messages = getIt<MessageRepository>();
  final externalId = 'test-contract-${DateTime.now().microsecondsSinceEpoch}';

  try {
    await messages.create(
      conversationId: conversationId,
      direction: 'inbound',
      senderType: 'customer',
      body: 'first delivery',
      sourcePlatform: 'whatsapp',
      externalMessageId: externalId,
    );
    // Same external id, simulating the platform retrying the same
    // webhook delivery — must upsert onto the same row, not insert a
    // second one.
    await messages.create(
      conversationId: conversationId,
      direction: 'inbound',
      senderType: 'customer',
      body: 'first delivery',
      sourcePlatform: 'whatsapp',
      externalMessageId: externalId,
    );

    final rows = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .eq('external_message_id', externalId);

    final count = (rows as List).length;
    // Cleanup regardless of outcome — this is a live database.
    await supabase
        .from('messages')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('external_message_id', externalId);

    if (count == 1) {
      print('   ✅ two creates with the same external_message_id produced 1 row');
      return 0;
    } else {
      print('   ❌ expected 1 row, found $count — idempotency is broken');
      return 1;
    }
  } catch (e) {
    print('   ❌ threw: $e');
    return 1;
  }
}

/// Test 2 — a permanently-failing action retries, then dead-letters
/// exactly once, not once per attempt.
Future<int> _testDeadLetterOnPermanentFailure(int workspaceId) async {
  print('── Test 2: dead-letter on permanent failure');
  final syncLog = getIt<ConnectorSyncLogRepository>();
  const connectorKey = 'test-contract-connector';
  var attempts = 0;

  try {
    await ConnectorRetry.run<void>(
      () async {
        attempts++;
        throw Exception('simulated permanent failure');
      },
      deadLetter: syncLog,
      workspaceId: workspaceId,
      connectorKey: connectorKey,
      store: 'generic',
      kind: 'sync',
      maxAttempts: 3,
      baseDelay: const Duration(milliseconds: 10), // fast for a test run
    );
    print('   ❌ ConnectorRetry.run did not rethrow — it should have');
    return 1;
  } catch (_) {
    // Expected — the whole point is that it exhausts attempts and
    // rethrows.
  }

  final recent = await syncLog.recentFor(
    workspaceId: workspaceId,
    connectorKey: connectorKey,
    limit: 10,
  );
  final errorRows = recent.where((r) => r.status == 'error').length;

  var ok = true;
  if (attempts != 3) {
    print('   ❌ expected 3 attempts, got $attempts');
    ok = false;
  }
  if (errorRows != 1) {
    print('   ❌ expected exactly 1 dead-letter row, found $errorRows '
        '(one per attempt would be a bug — a retried-then-failed sync is '
        'ONE failure to an owner reading the log, not three)');
    ok = false;
  }
  if (ok) {
    print('   ✅ retried 3 times, wrote exactly 1 dead-letter row');
  }

  // Cleanup.
  await supabase
      .from('connector_sync_log')
      .delete()
      .eq('workspace_id', workspaceId)
      .eq('connector_key', connectorKey);

  return ok ? 0 : 1;
}

/// Test 3 — two workspaces sharing a connectorKey must never see each
/// other's rows.
Future<int> _testCrossTenantIsolation(int workspaceId, int? otherWorkspaceId) async {
  print('── Test 3: cross-tenant isolation');
  if (otherWorkspaceId == null || otherWorkspaceId == workspaceId) {
    print('   ⚠️  SKIPPED — pass --other-workspace-id=<a different real '
        'workspace id> to actually exercise this check');
    return 0;
  }

  final syncLog = getIt<ConnectorSyncLogRepository>();
  const connectorKey = 'test-contract-isolation';

  try {
    await syncLog.record(
      workspaceId: workspaceId,
      connectorKey: connectorKey,
      store: 'generic',
      kind: 'health',
      success: true,
    );
    await syncLog.record(
      workspaceId: otherWorkspaceId,
      connectorKey: connectorKey,
      store: 'generic',
      kind: 'health',
      success: true,
    );

    final seenByA = await syncLog.recentFor(
      workspaceId: workspaceId,
      connectorKey: connectorKey,
    );
    final leaked = seenByA.any((r) => r.workspaceId != workspaceId);

    if (leaked) {
      print('   ❌ workspace $workspaceId\'s query returned a row belonging '
          'to another workspace — isolation is broken');
      return 1;
    }
    if (seenByA.every((r) => r.workspaceId == workspaceId) && seenByA.isNotEmpty) {
      print('   ✅ workspace $workspaceId only ever saw its own rows');
    }
    return 0;
  } finally {
    await supabase
        .from('connector_sync_log')
        .delete()
        .eq('connector_key', connectorKey);
  }
}

Map<String, String> _parseFlags(List<String> args) {
  final out = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) continue;
    final body = arg.substring(2);
    final eq = body.indexOf('=');
    if (eq == -1) {
      out[body] = 'true';
    } else {
      out[body.substring(0, eq)] = body.substring(eq + 1);
    }
  }
  return out;
}
