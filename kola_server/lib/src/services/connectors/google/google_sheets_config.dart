// google_sheets_config.dart — Connect Gate, subphase 4d.
//
// The single place that reads/writes the list of connected spreadsheet
// ids inside a google_sheets WorkspaceConnector's decrypted config blob
// — shared by ConnectorEndpoint (setGoogleSheetTargets/listGoogleSheets)
// and ConnectorSyncSweepService (_sweepGoogleSheets), so the two never
// drift on the key name or the backward-compat rule below.
//
// BACKWARD COMPATIBILITY: every workspace connected before this change
// has `{refreshToken, spreadsheetId: "<one id>"}` — a single string, not
// a list. [spreadsheetIdsFrom] treats that old singular key as a one-
// item list rather than requiring every existing connection to be
// migrated or reconnected. [withSpreadsheetIds] always writes the NEW
// plural key going forward and drops the old singular one, so a
// workspace naturally migrates onto the new shape the first time an
// owner touches their sheet selection — no migration script needed.

class GoogleSheetsConfig {
  const GoogleSheetsConfig._();

  static List<String> spreadsheetIdsFrom(Map<String, dynamic> config) {
    final list = config['spreadsheetIds'];
    if (list is List) {
      return list.whereType<String>().toList();
    }
    // Legacy shape — a single connection made before multi-sheet support.
    final single = config['spreadsheetId'] as String?;
    return single == null ? const [] : [single];
  }

  /// Returns a NEW map — [config] is not mutated — with [spreadsheetIds]
  /// as the plural key and the legacy singular key removed, everything
  /// else (refreshToken, etc.) carried through unchanged.
  static Map<String, dynamic> withSpreadsheetIds(
    Map<String, dynamic> config,
    List<String> spreadsheetIds,
  ) {
    final next = Map<String, dynamic>.from(config);
    next.remove('spreadsheetId');
    next['spreadsheetIds'] = spreadsheetIds;
    return next;
  }
}
