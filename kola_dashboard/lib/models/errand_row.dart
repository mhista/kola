// errand_row.dart — one row in Structured Mode's Errands tab table,
// plus the full detail shown in the side panel when a row is selected.
// Matches Kola Bot Detail Dev.dc.html's errandDefs shape exactly
// (trigger, source, schema-as-formatted-string, fulfillment, scope) —
// this is the real shape Errand/ErrandExecutionLog already have on the
// server (see kola_server/lib/src/models/errand.spy.yaml's
// queryTemplateSql field and errand_endpoint.dart's create methods from
// Phase 3b/3c), just presented read-only here since there's no
// kola_client wiring yet in this shell pass.

import 'errand_status.dart';

class ErrandRow {
  const ErrandRow({
    required this.name,
    required this.trigger,
    required this.source,
    required this.status,
    required this.statusLabel,
    required this.lastCalled,
    required this.schema,
    required this.fulfillment,
    required this.scope,
  });

  final String name;
  final String trigger;
  final String source;
  final ErrandStatus status;
  final String statusLabel;
  final String lastCalled;

  /// Pre-formatted JSON-ish schema text for the detail panel's <pre>
  /// block — a display string, not parsed/validated here.
  final String schema;
  final String fulfillment;
  final String scope;
}
