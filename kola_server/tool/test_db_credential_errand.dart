// ignore_for_file: avoid_print
// ^ One-off CLI script: stdout IS the output. avoid_print stays ON for
//   lib/ — this is a targeted ignore rather than an analyzer exclude, so
//   real errors in this file are still reported.
// tool/test_db_credential_errand.dart
//
// One-off script exercising Phase 3c's dbCredential Errand type end to
// end against a REAL Postgres database — unlike test_webhook_errand.dart,
// this can't spin up its own throwaway server, so you must supply a
// real connection string (your own Supabase project's direct Postgres
// connection works fine — Project Settings > Database > Connection
// string > URI, NOT the REST URL this project otherwise uses).
//
// USAGE (run from kola_server/):
//   dart run tool/test_db_credential_errand.dart \
//     --connection-string="postgresql://user:pass@host:5432/postgres" \
//     --query="select @n::int as n" \
//     --input='{"n": 42}'
//
// Defaults to a harmless "select 1" style query if --query/--input are
// omitted, so a first run just proves connectivity + the named-
// parameter path work, without needing any real business table.
//
// First run creates a throwaway workspace + Errand (prints their ids).
// Pass --workspace-id=<id> --errand-id=<id> on later runs to reuse them
// (the connection string is always re-registered with the current
// run's --connection-string, same reasoning as the webhook test script).

import 'dart:convert';
import 'dart:io';
import 'package:kola_server/src/services/repository/supabase_client.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/errand_repository.dart';
import 'package:kola_server/src/services/repository/errand_credential_repository.dart';
import 'package:kola_server/src/services/repository/errand_execution_log_repository.dart';
import 'package:kola_server/src/services/errand/db_credential_errand_executor.dart';
import 'package:kola_server/src/services/errand/db_credential_errand_credential.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/config/env.dart';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);
  final connectionString = flags['connection-string'];
  if (connectionString == null || connectionString.trim().isEmpty) {
    stderr.writeln(
      '❌ --connection-string is required — pass a real Postgres connection '
      'URL (e.g. your own Supabase project\'s direct Postgres URI from '
      'Project Settings > Database).',
    );
    exit(1);
  }
  final query = flags['query'] ?? 'select @n::int as n';
  final input = flags.containsKey('input')
      ? jsonDecode(flags['input']!) as Map<String, dynamic>
      : {'n': 42};

  if (Env.channelCredentialMasterKey.isEmpty) {
    stderr.writeln(
      '❌ CHANNEL_CREDENTIAL_MASTER_KEY is not set in .env — required to '
      'encrypt the database credential. See .env.example.',
    );
    exit(1);
  }
  ChannelCredentialEncryptionService.init(Env.channelCredentialMasterKey);

  await initSupabase();

  final workspaces = const WorkspaceRepository();
  final errands = const ErrandRepository();
  final credentials = const ErrandCredentialRepository();
  final executionLogs = const ErrandExecutionLogRepository();
  final executor = DbCredentialErrandExecutor(credentials: credentials, executionLogs: executionLogs);

  var workspace = flags.containsKey('workspace-id')
      ? await workspaces.findById(int.parse(flags['workspace-id']!))
      : null;
  workspace ??= await workspaces.create(name: 'Kola Test Workspace (DB Errand)');
  print('Workspace: id=${workspace.id} name=${workspace.name}');

  var errand = flags.containsKey('errand-id')
      ? await errands.findByIdScoped(int.parse(flags['errand-id']!), workspace.id!)
      : null;
  errand ??= await errands.create(
    workspaceId: workspace.id!,
    name: 'Test DB query',
    descriptionForAi: 'Test-only Errand exercising the dbCredential execution path.',
    source: 'dbCredential',
    createdVia: 'api',
    queryTemplateSql: query,
  );
  print('Errand: id=${errand.id} name=${errand.name} queryTemplateSql=${errand.queryTemplateSql}');

  final credential = DbCredentialErrandCredential(connectionString: connectionString);
  await credentials.upsert(
    errandId: errand.id!,
    encryptedCredential: ChannelCredentialEncryptionService.encrypt(credential.encode()),
  );

  print('');
  print('Executing with input: $input');
  print('');

  try {
    final result = await executor.execute(errand: errand, input: input);
    print('✅ Execution succeeded and was logged:');
    print('   $result');
    exit(0);
  } catch (e) {
    stderr.writeln('❌ ${e.toString()}');
    stderr.writeln('(This failure was still logged — check errand_execution_logs.)');
    exit(1);
  }
}

Map<String, String> _parseFlags(List<String> args) {
  final map = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--') || !arg.contains('=')) continue;
    final eqIndex = arg.indexOf('=');
    map[arg.substring(2, eqIndex)] = arg.substring(eqIndex + 1);
  }
  return map;
}
