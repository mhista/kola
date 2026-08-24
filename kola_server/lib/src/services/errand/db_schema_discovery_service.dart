// db_schema_discovery_service.dart
//
// Gate 5 (Kolaa Connections-as-the-Backbone, Rev 5, Part VIII): "Level 3
// proven — Guided REST builder + read-only Postgres with schema
// discovery." Before this, createDbCredentialErrand asked a business to
// hand-type queryTemplateSql against a database whose shape kola had
// never looked at — a blank textarea with a placeholder example, and
// nothing to check a guess against. This is the missing "guided" half:
// given a connection string, list every table and column actually in
// its 'public' schema, so the dashboard's query-template builder can
// offer a table/column picker instead of asking the owner (or Bot
// Mother) to already know the schema by heart.
//
// READ-ONLY, DELIBERATELY, AND SCHEMA-ONLY: opens a fresh connection,
// runs two information_schema SELECTs, and closes it — same "fresh
// connection per call, always closed" posture as
// DbCredentialErrandExecutor. This never reads a single row of the
// business's own data, only catalog metadata. Mapping discovered
// columns into the business graph (PART V of the direction doc) is a
// later step, once a query template has actually been chosen and
// saved — not this file's job.
//
// 'public' schema only, base tables only (views excluded on purpose —
// a view can hide arbitrary logic behind a name that looks like a
// plain table, and the goal here is "show me my own tables", not
// "understand every view anyone has ever built"). Table/column counts
// are capped so a business's enormous production database can't turn
// one discovery click into a multi-second, multi-megabyte response.

import 'package:postgres/postgres.dart';
import 'package:kola_server/kola_logger.dart';

/// Thrown when a connection string is missing/empty, or when the
/// connection/introspection itself fails (bad credentials, unreachable
/// host, connection refused, timeout). Always carries an owner-safe
/// message — never the raw driver exception, which can echo back
/// connection-string internals.
class DbSchemaDiscoveryException implements Exception {
  final String message;
  const DbSchemaDiscoveryException(this.message);

  @override
  String toString() => 'DbSchemaDiscoveryException: $message';
}

class DiscoveredColumn {
  const DiscoveredColumn({
    required this.name,
    required this.dataType,
    required this.nullable,
  });

  final String name;
  final String dataType;
  final bool nullable;

  Map<String, dynamic> toJson() => {
    'name': name,
    'dataType': dataType,
    'nullable': nullable,
  };
}

class DiscoveredTable {
  const DiscoveredTable({required this.name, required this.columns});

  final String name;
  final List<DiscoveredColumn> columns;

  Map<String, dynamic> toJson() => {
    'name': name,
    'columns': columns.map((c) => c.toJson()).toList(),
  };
}

class DbSchemaDiscoveryService {
  const DbSchemaDiscoveryService();

  /// Connects to [connectionString] and returns every base table in its
  /// 'public' schema, each with its columns' name/type/nullability, in
  /// table then ordinal-position order. Capped at [maxTables] tables and
  /// [maxColumnsPerTable] columns per table — a picker, not a full data
  /// dictionary dump.
  Future<List<DiscoveredTable>> discover(
    String connectionString, {
    int maxTables = 50,
    int maxColumnsPerTable = 60,
  }) async {
    if (connectionString.trim().isEmpty) {
      throw const DbSchemaDiscoveryException('Connection string cannot be empty.');
    }

    // NOT VERIFIED: package:postgres v3's ConnectionSettings almost
    // certainly exposes a connectTimeout, but that wasn't confirmed
    // against the installed version in the environment that wrote this
    // (no pub cache / doc access here) — per this project's own rule
    // ("verify package APIs from documentation, not memory"), left out
    // rather than guessed. Connection.openFromUrl's single-argument
    // call below is copied verbatim from DbCredentialErrandExecutor,
    // which already ships and runs, so that much is real.
    Connection? conn;
    try {
      conn = await Connection.openFromUrl(connectionString);

      final tableRows = await conn.execute(
        Sql.named(
          "select table_name from information_schema.tables "
          "where table_schema = 'public' and table_type = 'BASE TABLE' "
          "order by table_name limit @maxTables",
        ),
        parameters: {'maxTables': maxTables},
      );

      final tables = <DiscoveredTable>[];
      for (final row in tableRows) {
        final tableName = row.toColumnMap()['table_name'] as String;

        final columnRows = await conn.execute(
          Sql.named(
            "select column_name, data_type, is_nullable from information_schema.columns "
            "where table_schema = 'public' and table_name = @tableName "
            "order by ordinal_position limit @maxColumns",
          ),
          parameters: {'tableName': tableName, 'maxColumns': maxColumnsPerTable},
        );

        final columns = columnRows.map((r) {
          final map = r.toColumnMap();
          return DiscoveredColumn(
            name: map['column_name'] as String,
            dataType: map['data_type'] as String,
            nullable: (map['is_nullable'] as String).toUpperCase() == 'YES',
          );
        }).toList();

        tables.add(DiscoveredTable(name: tableName, columns: columns));
      }

      return tables;
    } on DbSchemaDiscoveryException {
      rethrow;
    } catch (e) {
      Log.error('DB schema discovery failed', error: e);
      throw DbSchemaDiscoveryException(
        "Couldn't read this database's schema — check the connection string and that the "
        'database accepts connections from kola. (${e.runtimeType})',
      );
    } finally {
      await conn?.close();
    }
  }
}

// NEXT INCREMENT, NOT BUILT HERE: once an owner picks a table/column
// from what this returns and saves a queryTemplateSql, mapping the rows
// that query actually returns into business-graph entities (Customer,
// Order, ...) with provenance — PART V of the direction doc. This
// service only ever reads catalog metadata, never a row of business
// data, and is not itself a step toward that — it's what makes a human
// able to write a safe query template in the first place.
