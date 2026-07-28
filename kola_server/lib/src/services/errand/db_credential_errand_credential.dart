// db_credential_errand_credential.dart
//
// The dbCredential-Errand-specific credential shape stored inside
// ErrandCredential.encryptedCredential — same encryption service and
// "JSON blob under one opaque encrypted column" pattern as
// webhook_errand_credential.dart/whatsapp_credential.dart.
//
// DELIBERATELY JUST A CONNECTION STRING, NOT HOST/PORT/USER/PASS AS
// SEPARATE FIELDS: `postgres` (the Dart driver used by
// db_credential_errand_executor.dart) accepts a full
// `postgresql://user:pass@host:port/db?sslmode=...` URL directly via
// `Connection.openFromUrl` — asking a business to paste one string they
// almost certainly already have (Supabase, RDS, Neon, etc. all hand you
// this exact format) is simpler and less error-prone than a five-field
// form that has to be reassembled into the same string anyway.
//
// THE QUERY TEMPLATE ITSELF LIVES ON THE ERRAND, NOT HERE:
// Errand.queryTemplateSql (errand.spy.yaml) — not part of this
// credential — because the template is "what this Errand is allowed to
// ask," a property of the Errand's registration, while this file is
// only "how to reach the database." Keeping them separate means
// rotating a connection string never touches the approved query, and
// vice versa.

import 'dart:convert';

class DbCredentialErrandCredential {
  const DbCredentialErrandCredential({required this.connectionString});

  final String connectionString;

  String encode() => jsonEncode({'connection_string': connectionString});

  factory DbCredentialErrandCredential.decode(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return DbCredentialErrandCredential(
      connectionString: map['connection_string'] as String,
    );
  }
}
