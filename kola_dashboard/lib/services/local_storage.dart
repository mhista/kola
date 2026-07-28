// local_storage.dart — thin wrapper around the browser's real
// window.localStorage (the standard Web Storage API — getItem/setItem/
// removeItem, per the actual spec: https://developer.mozilla.org/docs/Web/API/Storage
// — not dart:html's older Map-wrapper, which this project doesn't use
// since jaspr's own dependency chain is package:web/universal_web, not
// dart:html). Originally written to persist only the Supabase session
// across page reloads (see auth_session.dart) — task #131 / Phase 8d
// added a second, much smaller use: app.dart persists which workspace
// was last selected (see its own `_selectedWorkspaceIdKey`), so a manual
// switch survives a reload instead of silently reverting to
// `workspaces.first` every time.

import 'package:web/web.dart' as web;

abstract class LocalStorage {
  static String? getItem(String key) => web.window.localStorage.getItem(key);

  static void setItem(String key, String value) {
    web.window.localStorage.setItem(key, value);
  }

  static void removeItem(String key) {
    web.window.localStorage.removeItem(key);
  }
}
