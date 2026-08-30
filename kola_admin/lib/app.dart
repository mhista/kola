// app.dart — root component. Same shape as kola_dashboard/lib/app.dart's
// StatefulComponent-holding-the-live-Client pattern, deliberately much
// smaller: this app has exactly two routes for this pass (ADMIN_APP_SPEC.md
// build order steps 1-3 — auth, audit log, release control; steps 4-7
// are explicitly NOT built yet, see docs/ADMIN_CONTROL_PLANE_STATUS.md).
//
// AUTH GUARD: [_redirect] sends an unauthenticated visitor to /login and
// an authenticated one away from /login — the same shape as the
// dashboard's guard, minus the workspace-selection step this app has no
// use for (an admin isn't scoped to one workspace).
//
// No session restore/expiry check beyond "is there a stored token" —
// an expired or forged token is caught server-side on the first real
// call (AdminAuthService.verify) and surfaces as a normal API error,
// which release_control_page.dart shows and lets the admin re-login
// from. There is deliberately no client-side JWT decoding here.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import 'config/env.dart';
import 'services/admin_local_storage.dart';
import 'pages/login_page.dart';
import 'pages/release_control_page.dart';

class AdminApp extends StatefulComponent {
  const AdminApp();

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final Client _client;
  String? _adminToken;

  @override
  void initState() {
    super.initState();
    _client = Client(Env.kolaServerUrl);
    _adminToken = AdminLocalStorage.getToken();
  }

  void _handleLoggedIn(String token) {
    AdminLocalStorage.setToken(token);
    setState(() => _adminToken = token);
  }

  /// Passed down so any page can force a fresh login when the server
  /// rejects a stale/forged token (AdminAuthService.verify throwing
  /// 'admin_session_invalid') — the one recovery path a plain stored
  /// token needs, since there is no client-side expiry check to catch
  /// it earlier.
  void _handleSignOut() {
    AdminLocalStorage.clearToken();
    setState(() => _adminToken = null);
  }

  String? _redirect(BuildContext context, RouteState state) {
    final loc = state.location;
    final loggedIn = _adminToken != null;

    if (!loggedIn) {
      return loc == '/login' ? null : '/login';
    }
    if (loc == '/login') return '/';
    return null;
  }

  @override
  Component build(BuildContext context) {
    return Router(
      redirect: _redirect,
      routes: [
        Route(
          path: '/login',
          builder: (context, state) => LoginPage(
            client: _client,
            onLoggedIn: _handleLoggedIn,
          ),
        ),
        Route(
          path: '/',
          builder: (context, state) => ReleaseControlPage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
      ],
    );
  }
}
