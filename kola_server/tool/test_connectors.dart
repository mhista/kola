// ignore_for_file: avoid_print
// ^ One-off CLI script: stdout IS the output. avoid_print stays ON for
//   lib/ — this is a targeted ignore rather than an analyzer exclude, so
//   real errors in this file are still reported.
// tool/test_connectors.dart
//
// Exercises ConnectorService against the LIVE Supabase, printing the
// resolved marketplace exactly as ConnectorEndpoint.listConnectors would
// return it. Same spirit as test_grounded_qa.dart and
// test_builtin_errand.dart — bypasses Session/requireWorkspaceAccess,
// because there is no Integrations UI yet to call it from.
//
// This is the only way to test the merge today, and it tests the part
// that can actually be wrong: four sources (catalog, feature flags,
// channels, payment gateways, workspace_connectors) combined into one
// status per connector.
//
// USAGE (run from kola_server/, with your .env in place):
//
//   dart run tool/test_connectors.dart --workspace-id=1
//
// Omit --workspace-id and it uses the first workspace it finds, which is
// usually what you want on a dev database.
//
// WHAT TO EXPECT on a workspace with nothing connected, given the flag
// states currently in the live database:
//
//   available   WhatsApp, Telegram      (channels.* are released)
//   available   Slack                   (notifications.owner is released)
//   soon        the other 12            (their connectors.* / payments.collect
//                                        / platform.public_api flags are locked)
//
// If Paystack shows `soon` that is CORRECT, not a bug — payments.collect
// is locked and scheduled R2. Flip it in kola_admin and re-run; it should
// become `available` with no code change and no redeploy. That round trip
// is the real thing being tested here, because it is the whole premise of
// the locked-release model.
//
// FLAG SANITY: pass --flags to print which capability flag each connector
// resolved against, which is the fastest way to spot a mis-mapped key.

import 'dart:io';

import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/connectors/connector_catalog.dart';
import 'package:kola_server/src/services/connectors/connector_service.dart';
import 'package:kola_server/src/services/repository/supabase_client.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);
  final showFlags = flags.containsKey('flags');

  await initSupabase();
  setupDependencyInjection();

  // Needed only for the masked "Secret key: ••••3f2a" detail on a
  // connected payment gateway. ConnectorService already degrades
  // gracefully without it, so this is a warning rather than a failure.
  if (Env.channelCredentialMasterKey.isNotEmpty) {
    ChannelCredentialEncryptionService.init(Env.channelCredentialMasterKey);
  } else {
    print('⚠  CHANNEL_CREDENTIAL_MASTER_KEY not set — gateway secrets '
        'cannot be masked for display. Everything else still works.');
  }

  final workspaces = const WorkspaceRepository();
  final workspace = flags.containsKey('workspace-id')
      ? await workspaces.findById(int.parse(flags['workspace-id']!))
      : null;

  if (workspace == null && flags.containsKey('workspace-id')) {
    print('❌ Workspace ${flags['workspace-id']} not found.');
    exit(1);
  }

  final target = workspace ?? await _firstWorkspace(workspaces);
  if (target == null) {
    print('❌ No workspaces exist. Create one first, or pass --workspace-id.');
    exit(1);
  }

  print('Workspace: id=${target.id} name=${target.name}');
  print('');

  final service = getIt<ConnectorService>();
  final resolved = await service.listForWorkspace(target);

  // Sanity check the merge did not lose or duplicate anything. A silent
  // drop is exactly the failure a field-order regex caused when this
  // catalog was first parsed, so it is worth asserting rather than
  // eyeballing 15 rows.
  final expected = ConnectorCatalog.all.length;
  if (resolved.length != expected) {
    print('❌ MERGE LOST ROWS: expected $expected, got ${resolved.length}');
    exit(1);
  }
  final keys = resolved.map((c) => c.key).toSet();
  if (keys.length != resolved.length) {
    print('❌ DUPLICATE KEYS in merged output');
    exit(1);
  }

  final counts = <String, int>{};
  for (final c in resolved) {
    counts[c.status] = (counts[c.status] ?? 0) + 1;
  }

  for (final category in ConnectorCatalog.categories) {
    print('── ${category.label} (${category.subtitle})');
    for (final c in resolved.where((c) => c.category == category.id)) {
      final line = StringBuffer()
        ..write('   ${_icon(c.status)} ${c.name.padRight(18)}')
        ..write(c.status.padRight(11))
        ..write(c.authType.padRight(11));
      if (showFlags) {
        final def = ConnectorCatalog.byKey(c.key);
        line.write((def?.featureKey ?? '?').padRight(24));
      }
      if (c.displayDetail != null) line.write('· ${c.displayDetail}');
      if (c.lastError != null) line.write('· ${c.lastError}');
      print(line);
    }
    print('');
  }

  print('Totals: ${counts.entries.map((e) => '${e.key}=${e.value}').join('  ')}');
  print('Merged ${resolved.length}/$expected connectors, no duplicates. ✅');
  exit(0);
}

Future<Workspace?> _firstWorkspace(WorkspaceRepository repo) async {
  // findById(1) rather than a list call: WorkspaceRepository has no
  // "list all", and adding one to the production repository purely for a
  // test script would be the tail wagging the dog.
  for (var id = 1; id <= 10; id++) {
    final w = await repo.findById(id);
    if (w != null) return w;
  }
  return null;
}

String _icon(String status) => switch (status) {
      'connected' => '✅',
      'available' => '⬜',
      'error' => '❌',
      _ => '🔒',
    };

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
