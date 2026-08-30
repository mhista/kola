// admin_local_storage.dart — persists the admin session token across a
// page reload. Same window.localStorage wrapper pattern as
// kola_dashboard/lib/services/local_storage.dart (identical dependency
// on package:web, identical reasoning — see that file's header) but
// kept as a separate copy rather than a shared package, since this app
// deliberately shares no source with kola_dashboard (see
// kola_admin/pubspec.yaml's header on why).

import 'package:web/web.dart' as web;

abstract class AdminLocalStorage {
  static const _tokenKey = 'kola_admin_session_token';

  static String? getToken() => web.window.localStorage.getItem(_tokenKey);

  static void setToken(String token) {
    web.window.localStorage.setItem(_tokenKey, token);
  }

  static void clearToken() {
    web.window.localStorage.removeItem(_tokenKey);
  }
}
