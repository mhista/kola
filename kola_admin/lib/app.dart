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
// FORCED-RESET GUARD: migration 055 — a freshly logged-in admin session
// is checked against AdminAuthEndpoint.mustResetPassword; if true, the
// same [_redirect] function locks every route except /reset-password
// until ResetPasswordPage's changePassword call succeeds and clears it.
// This is a client-side convenience only — the real enforcement, if any
// endpoint ever needed it, would have to live server-side; today nothing
// but this guard depends on the flag, which is an honest, small gap: an
// admin who bypasses the UI and calls another endpoint's RPC directly
// with a valid token is not blocked by this flag server-side. Revisit if
// that ever matters for a genuinely sensitive action.
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
import 'pages/reset_password_page.dart';
import 'pages/workspace_admin_page.dart';
import 'pages/customer_service_page.dart';
import 'pages/announcements_page.dart';
import 'pages/platform_health_page.dart';
import 'pages/support_queue_page.dart';
import 'pages/audit_log_page.dart';
import 'pages/admin_accounts_page.dart';
import 'pages/overview_page.dart';
import 'pages/security_page.dart';

class AdminApp extends StatefulComponent {
  const AdminApp();

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final Client _client;
  String? _adminToken;

  /// null = not yet checked (or nothing to check because logged out).
  /// Deliberately starts null rather than false so the redirect guard
  /// never lets a genuinely-must-reset admin slip past this page during
  /// the brief window before the server round-trip resolves — see
  /// [_redirect]'s handling of the null case.
  bool? _mustResetPassword;

  @override
  void initState() {
    super.initState();
    _client = Client(Env.kolaServerUrl);
    _adminToken = AdminLocalStorage.getToken();
    final token = _adminToken;
    if (token != null) _checkMustResetPassword(token);
  }

  Future<void> _checkMustResetPassword(String token) async {
    try {
      final must = await _client.adminAuth.mustResetPassword(token);
      if (!mounted) return;
      setState(() => _mustResetPassword = must);
    } catch (_) {
      // A stale/forged token fails here the same way it would fail any
      // other admin call — don't guess at a value; leave it null and let
      // the next real page's own API call surface
      // 'admin_session_invalid' the normal way (see release_control_page
      // .dart's existing error handling). Treating this as "false" would
      // risk letting a placeholder-password account through.
    }
  }

  void _handleLoggedIn(String token) {
    AdminLocalStorage.setToken(token);
    setState(() {
      _adminToken = token;
      _mustResetPassword = null;
    });
    _checkMustResetPassword(token);
  }

  /// Passed to ResetPasswordPage — called once changePassword succeeds.
  void _handlePasswordReset() {
    setState(() => _mustResetPassword = false);
  }

  /// Passed down so any page can force a fresh login when the server
  /// rejects a stale/forged token (AdminAuthService.verify throwing
  /// 'admin_session_invalid') — the one recovery path a plain stored
  /// token needs, since there is no client-side expiry check to catch
  /// it earlier.
  void _handleSignOut() {
    AdminLocalStorage.clearToken();
    setState(() {
      _adminToken = null;
      _mustResetPassword = null;
    });
  }

  String? _redirect(BuildContext context, RouteState state) {
    final loc = state.location;
    final loggedIn = _adminToken != null;

    if (!loggedIn) {
      return loc == '/login' ? null : '/login';
    }
    if (loc == '/login') return '/';
    if (_mustResetPassword == true && loc != '/reset-password') {
      return '/reset-password';
    }
    if (_mustResetPassword == false && loc == '/reset-password') {
      return '/';
    }
    // _mustResetPassword == null: still checking (or the check failed) —
    // stay put rather than guess; the next setState from
    // _checkMustResetPassword re-runs this and corrects course.
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
          path: '/reset-password',
          builder: (context, state) => ResetPasswordPage(
            client: _client,
            adminToken: _adminToken ?? '',
            forced: _mustResetPassword ?? true,
            onDone: _handlePasswordReset,
            onSignOut: _handleSignOut,
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
        Route(
          path: '/security',
          builder: (context, state) => SecurityPage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
        Route(
          path: '/overview',
          builder: (context, state) => OverviewPage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
        Route(
          path: '/workspaces',
          builder: (context, state) => WorkspaceAdminPage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
        Route(
          path: '/customer-service',
          builder: (context, state) => CustomerServicePage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
        Route(
          path: '/announcements',
          builder: (context, state) => AnnouncementsPage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
        Route(
          path: '/platform-health',
          builder: (context, state) => PlatformHealthPage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
        Route(
          path: '/support-queue',
          builder: (context, state) => SupportQueuePage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
        Route(
          path: '/audit-log',
          builder: (context, state) => AuditLogPage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
        Route(
          path: '/admin-accounts',
          builder: (context, state) => AdminAccountsPage(
            client: _client,
            adminToken: _adminToken ?? '',
            onSignOut: _handleSignOut,
          ),
        ),
      ],
    );
  }
}
