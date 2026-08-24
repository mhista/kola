// ignore_for_file: avoid_print
// ^ One-off CLI script: stdout IS the output. avoid_print stays ON for
//   lib/ — this is a targeted ignore rather than an analyzer exclude, so
//   real errors in this file are still reported.
// tool/test_db_schema_discovery.dart
//
// Gate 5. Exercises DbSchemaDiscoveryService against a REAL Postgres
// database — same "you must supply a real connection string" shape as
// tool/test_db_credential_errand.dart (your own Supabase project's
// direct Postgres connection string works fine: Project Settings >
// Database > Connection string > URI, NOT the REST URL this project
// otherwise uses). No workspace/Errand/credential row is created —
// DbSchemaDiscoveryService is a standalone read-only service, called
// directly here exactly the way ErrandEndpoint.discoverDbSchema calls
// it.
//
// USAGE (run from kola_server/):
//   dart run tool/test_db_schema_discovery.dart \
//     --connection-string="postgresql://user:pass@host:5432/postgres"
//
// This is also the script to run first after any change to this file —
// it is the only thing in this project that has actually executed
// DbSchemaDiscoveryService.discover() against a real database, since
// the environment that wrote the service had no Dart toolchain at all.

import 'dart:io';
import 'package:kola_server/src/services/errand/db_schema_discovery_service.dart';

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

  const service = DbSchemaDiscoveryService();

  print('Discovering schema...');
  print('');

  try {
    final tables = await service.discover(connectionString);
    if (tables.isEmpty) {
      print('✅ Connected, but found no base tables in the public schema.');
      exit(0);
    }
    print('✅ Found ${tables.length} table(s):');
    for (final t in tables) {
      print('');
      print('  ${t.name}');
      for (final c in t.columns) {
        print('    - ${c.name}: ${c.dataType}${c.nullable ? ' (nullable)' : ''}');
      }
    }
    exit(0);
  } on DbSchemaDiscoveryException catch (e) {
    stderr.writeln('❌ ${e.message}');
    exit(1);
  } catch (e) {
    stderr.writeln('❌ Unexpected error: $e');
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
