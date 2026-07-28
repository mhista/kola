// tool/test_webhook_errand.dart
//
// One-off script exercising Phase 3c's webhook Errand type end to end,
// entirely self-contained: spins up a tiny local HTTP server (in this
// same process) that echoes back whatever JSON it receives plus an auth
// header check, registers a webhook Errand pointing at that local
// server via ErrandRepository/ErrandCredentialRepository directly (same
// "bypass Session/requireWorkspaceAccess" spirit as the other tool/
// scripts), then runs WebhookErrandExecutor against it for real.
//
// USAGE (run from kola_server/):
//   dart run tool/test_webhook_errand.dart
//
// First run creates a throwaway workspace + Errand (prints their ids).
// Pass --workspace-id=<id> --errand-id=<id> on later runs to reuse them
// (note: the local echo server's port changes each run, so a reused
// Errand's stored URL will be stale — this script always re-registers
// the credential with the current run's URL to keep it working).

import 'dart:convert';
import 'dart:io';
import 'package:kola_server/src/services/repository/supabase_client.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/errand_repository.dart';
import 'package:kola_server/src/services/repository/errand_credential_repository.dart';
import 'package:kola_server/src/services/repository/errand_execution_log_repository.dart';
import 'package:kola_server/src/services/errand/webhook_errand_executor.dart';
import 'package:kola_server/src/services/errand/webhook_errand_credential.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/config/env.dart';

const _authHeaderName = 'x-kola-test-secret';
const _authHeaderValue = 'test-secret-123';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);

  if (Env.channelCredentialMasterKey.isEmpty) {
    stderr.writeln(
      '❌ CHANNEL_CREDENTIAL_MASTER_KEY is not set in .env — required to '
      'encrypt the webhook credential. See .env.example.',
    );
    exit(1);
  }
  ChannelCredentialEncryptionService.init(Env.channelCredentialMasterKey);

  await initSupabase();

  // Start a tiny local server that echoes back the request body plus
  // whether the expected auth header was present — real end-to-end
  // proof the executor sends both the JSON body and the header
  // correctly, without depending on any external service.
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  print('Local echo server listening on http://127.0.0.1:${server.port}');
  server.listen((request) async {
    final body = await utf8.decodeStream(request);
    final receivedAuth = request.headers.value(_authHeaderName);
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'echoed': jsonDecode(body.isEmpty ? '{}' : body),
        'authHeaderReceived': receivedAuth == _authHeaderValue,
      }));
    await request.response.close();
  });

  final workspaces = const WorkspaceRepository();
  final errands = const ErrandRepository();
  final credentials = const ErrandCredentialRepository();
  final executionLogs = const ErrandExecutionLogRepository();
  final executor = WebhookErrandExecutor(credentials: credentials, executionLogs: executionLogs);

  var workspace = flags.containsKey('workspace-id')
      ? await workspaces.findById(int.parse(flags['workspace-id']!))
      : null;
  workspace ??= await workspaces.create(name: 'Kola Test Workspace (Webhook Errand)');
  print('Workspace: id=${workspace.id} name=${workspace.name}');

  var errand = flags.containsKey('errand-id')
      ? await errands.findByIdScoped(int.parse(flags['errand-id']!), workspace.id!)
      : null;
  errand ??= await errands.create(
    workspaceId: workspace.id!,
    name: 'Look up order status',
    descriptionForAi: 'Use this to check the status of a customer order by order id.',
    source: 'webhook',
    createdVia: 'api',
  );
  print('Errand: id=${errand.id} name=${errand.name}');

  // Always re-register the credential with THIS run's local server URL.
  final credential = WebhookErrandCredential(
    url: 'http://127.0.0.1:${server.port}/',
    authHeaderName: _authHeaderName,
    authHeaderValue: _authHeaderValue,
  );
  await credentials.upsert(
    errandId: errand.id!,
    encryptedCredential: ChannelCredentialEncryptionService.encrypt(credential.encode()),
  );

  print('');
  print('Executing with input: {"orderId": "12345"}');
  print('');

  try {
    final result = await executor.execute(errand: errand, input: {'orderId': '12345'});
    print('✅ Execution succeeded and was logged:');
    print('   $result');
    exit(0);
  } catch (e) {
    stderr.writeln('❌ ${e.toString()}');
    stderr.writeln('(This failure was still logged — check errand_execution_logs.)');
    exit(1);
  } finally {
    await server.close(force: true);
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
