// ignore_for_file: avoid_print
// tool/test_event_bus.dart
//
// Gate 2 verification, against the LIVE Supabase — same harness shape as
// tool/test_connector_contract.dart (Gate 1) and every other
// tool/test_*.dart in this project, since this codebase has no
// automated test suite yet.
//
// Exercises the two things PART VIII's testing section and Gate 2's own
// bar ask for that this file's code actually implements:
//
//   1. FINGERPRINT DEDUPLICATION — the same (workspaceId, fingerprint)
//      emitted twice must produce ONE row in `events`, not two, and the
//      second call must report wasNew=false.
//   2. WEBHOOK DELIVERY ACTUALLY FIRES — register a real endpoint
//      (pass --webhook-url pointing at something like
//      https://webhook.site/<id> or a local echo server) subscribed to
//      a test event type, emit it, and confirm last_delivery_at moves
//      and status stays 'active'. Skipped if --webhook-url is omitted,
//      since there is nothing live to deliver to without one.
//
// USAGE (run from kola_server/, with your .env in place):
//
//   dart run tool/test_event_bus.dart --workspace-id=1
//   dart run tool/test_event_bus.dart --workspace-id=1 --webhook-url=https://webhook.site/xxxx

import 'dart:io';

import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/supabase_client.dart';
import 'package:kola_server/src/services/repository/event_repository.dart';
import 'package:kola_server/src/services/repository/webhook_endpoint_repository.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);
  final workspaceId = int.tryParse(flags['workspace-id'] ?? '');
  if (workspaceId == null) {
    print('❌ Usage: dart run tool/test_event_bus.dart --workspace-id=<id> [--webhook-url=<url>]');
    exit(1);
  }

  await initSupabase();
  setupDependencyInjection();

  var failures = 0;
  failures += await _testDeduplication(workspaceId);

  final webhookUrl = flags['webhook-url'];
  if (webhookUrl != null) {
    failures += await _testWebhookDelivery(workspaceId, webhookUrl);
  } else {
    print('── Test 2: webhook delivery — ⚠️  SKIPPED (pass --webhook-url to exercise this)');
  }

  print('');
  if (failures == 0) {
    print('✅ All event-bus checks passed.');
    exit(0);
  } else {
    print('❌ $failures check(s) failed.');
    exit(1);
  }
}

Future<int> _testDeduplication(int workspaceId) async {
  print('── Test 1: fingerprint deduplication');
  final events = getIt<EventRepository>();
  final fingerprint = 'test-event-bus-${DateTime.now().microsecondsSinceEpoch}';

  try {
    final (first, firstWasNew) = await events.emit(
      workspaceId: workspaceId,
      eventType: 'new_conversation',
      fingerprint: fingerprint,
      payloadJson: '{"test":true}',
    );
    final (second, secondWasNew) = await events.emit(
      workspaceId: workspaceId,
      eventType: 'new_conversation',
      fingerprint: fingerprint,
      payloadJson: '{"test":true}',
    );

    final rows = await supabase
        .from('events')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('fingerprint', fingerprint);
    final count = (rows as List).length;

    // Cleanup regardless of outcome.
    await supabase.from('events').delete().eq('workspace_id', workspaceId).eq('fingerprint', fingerprint);

    var ok = true;
    if (count != 1) {
      print('   ❌ expected 1 stored row, found $count');
      ok = false;
    }
    if (!firstWasNew) {
      print('   ❌ first emit reported wasNew=false — should be true');
      ok = false;
    }
    if (secondWasNew) {
      print('   ❌ second emit reported wasNew=true — should be false (it is a duplicate)');
      ok = false;
    }
    if (first.id != second.id) {
      print('   ❌ first and second emit returned DIFFERENT event ids — should be the same row');
      ok = false;
    }
    if (ok) print('   ✅ two emits with the same fingerprint produced 1 row, wasNew=[true, false]');
    return ok ? 0 : 1;
  } catch (e) {
    print('   ❌ threw: $e');
    return 1;
  }
}

Future<int> _testWebhookDelivery(int workspaceId, String webhookUrl) async {
  print('── Test 2: webhook delivery actually fires');
  final endpoints = getIt<WebhookEndpointRepository>();
  final eventBus = getIt<EventBus>();
  const eventType = 'new_conversation';

  try {
    final endpoint = await endpoints.upsert(
      workspaceId: workspaceId,
      url: webhookUrl,
      events: [eventType],
    );
    final endpointId = endpoint.id!;
    final beforeDeliveryAt = endpoint.lastDeliveryAt;

    await eventBus.emit(
      workspaceId: workspaceId,
      eventType: eventType,
      fingerprint: 'test-event-bus-delivery-${DateTime.now().microsecondsSinceEpoch}',
      payload: {'test': true},
    );

    // Give the HTTP POST + retry logic a moment — ConnectorRetry can
    // take a few hundred ms even on a first-attempt success.
    await Future.delayed(const Duration(seconds: 2));

    final rows = await supabase.from('webhook_endpoints').select().eq('id', endpointId).single();
    final afterDeliveryAt = rows['last_delivery_at'] as String?;
    final status = rows['status'] as String?;

    var ok = true;
    if (afterDeliveryAt == null || afterDeliveryAt == beforeDeliveryAt?.toIso8601String()) {
      print('   ❌ last_delivery_at did not move — delivery did not fire, or failed silently');
      ok = false;
    }
    if (status != 'active') {
      print('   ❌ endpoint status is "$status", not "active" — check last_error: ${rows['last_error']}');
      ok = false;
    }
    if (ok) print('   ✅ delivery fired, endpoint marked active, last_delivery_at moved');

    await endpoints.delete(workspaceId, endpointId);
    return ok ? 0 : 1;
  } catch (e) {
    print('   ❌ threw: $e');
    return 1;
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
