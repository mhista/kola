// auth_callback_page.dart — Gate 0's Google sign-in landing point.
//
// GoTrue redirects here after Google's consent screen, appending the
// session as a URL FRAGMENT rather than a query string or POST body
// (`/auth/callback#access_token=...&refresh_token=...`) — see
// services/auth_service.dart's header for why this is the implicit
// flow rather than PKCE. A fragment never reaches the server (browsers
// don't send it in the request line at all), so the only place that can
// read it is client-side JS after the page has already loaded — which is
// the entire reason this is a page-with-a-spinner and not, say, logic
// inside app.dart's redirect guard.
//
// Same "hard document navigation, not setState" reasoning as
// logout_page.dart for the success path: once AuthService has parsed and
// persisted the session, replacing the URL to '/' and letting App's own
// _bootstrap flow (restoreSession) pick it up from LocalStorage is a
// stronger guarantee than threading a callback through a page that is
// about to be torn down anyway. The one difference from logout_page.dart:
// [onAuthenticated] IS called first, synchronously, because app.dart's
// _redirect would otherwise bounce this same navigation straight back to
// /login for the one frame before _bootstrap's async restore resolves.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;

import '../theme.dart';
import '../services/auth_service.dart';
import '../models/auth_session.dart';

class AuthCallbackPage extends StatefulComponent {
  const AuthCallbackPage({required this.authService, required this.onAuthenticated});

  final AuthService authService;
  final void Function(AuthSession session) onAuthenticated;

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Deferred for the same reason logout_page.dart defers its own
    // teardown: onAuthenticated calls setState on App (an ancestor),
    // which must not happen synchronously from a descendant's initState.
    Future.microtask(() {
      if (!mounted) return;
      final session = component.authService.consumeOAuthCallback(web.window.location.hash);
      if (session == null) {
        setState(() => _failed = true);
        return;
      }
      component.onAuthenticated(session);
      web.window.location.replace('/');
    });
  }

  @override
  Component build(BuildContext context) => div(
        attributes: {
          'style': 'font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};'
              'color:${KolaDashboardColors.text};width:100%;height:100vh;'
              'display:flex;align-items:center;justify-content:center;'
              'box-sizing:border-box;padding:24px',
        },
        [
          if (_failed)
            div(
              attributes: {'style': 'text-align:center;max-width:340px'},
              [
                div(
                  attributes: {'style': 'font-size:14.5px;color:${KolaDashboardColors.text};margin-bottom:14px'},
                  [Component.text("Google sign-in didn't complete. Nothing was changed on your account.")],
                ),
                a(
                  href: '/login',
                  [Component.text('Back to sign in')],
                  attributes: {
                    'style': 'color:${KolaDashboardColors.accent};font-size:13.5px;font-weight:600',
                  },
                ),
              ],
            )
          else
            div(
              attributes: {
                'style': 'font-size:14px;color:${KolaDashboardColors.muted}',
              },
              [Component.text('Finishing sign-in…')],
            ),
        ],
      );
}
