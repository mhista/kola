// login_page.dart — the dashboard's real entry point for Phase 4e's
// "Build real Supabase Auth flow now" decision. Talks directly to
// AuthService (Supabase Auth REST API — see services/auth_service.dart's
// header for why there's no `supabase` package involved).
//
// Deliberately minimal chrome: no design-file mock for this page exists
// yet (SRS's dual dashboard interface designs start from an already-
// authenticated session), so this reuses the shell's existing dark
// palette/fonts rather than inventing new visual language. A polished
// login screen matching a future design export is a follow-up, not a
// blocker for the real auth wiring underneath it.
//
// [onAuthenticated] is how this page hands the resulting AuthSession
// back up to DashboardApp's State — this page owns no session storage
// of its own beyond what AuthService already persists to LocalStorage.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;

import '../config/env.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/google_identity.dart';
import '../models/auth_session.dart';
import '../components/shell/kola_icon.dart';

class LoginPage extends StatefulComponent {
  const LoginPage({required this.authService, required this.onAuthenticated});

  final AuthService authService;
  final void Function(AuthSession session) onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _email = '';
  String _password = '';
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  // Google Identity Services' button renders into a real DOM element by
  // id, which has to exist before GoogleIdentity.renderSignInButton runs
  // — see _setupGoogleSignIn. Unique-ish id (not just "google-button")
  // deliberately, so it can never collide with anything AppShell or
  // another page puts in the DOM.
  static const _googleButtonId = 'kola-google-signin-container';

  @override
  void initState() {
    super.initState();
    if (Env.googleClientId.isNotEmpty) _setupGoogleSignIn();
  }

  /// Waits for the async `gsi/client` <script> (web/index.html) to have
  /// actually attached `window.google` before rendering into it —
  /// GoogleIdentity.isReady is false until then, and calling
  /// renderSignInButton before that silently does nothing. Bounded at 5s
  /// (25 × 200ms): a slow/blocked script load means no Google button
  /// rather than an infinite poll, and email/password sign-in still works
  /// either way.
  /// Retries BOTH "has GIS loaded" AND "has this component's own DOM been
  /// mounted yet" together, in the same loop — not sequentially.
  ///
  /// The bug this replaces: when GoogleIdentity.isReady was ALREADY true
  /// (GIS loaded fast / cached script), the old code's wait-for-isReady
  /// loop executed zero iterations and fell straight through to
  /// getElementById in the SAME synchronous tick as initState — before
  /// Jaspr had mounted this page's first build to the real DOM at all.
  /// initState always runs before a component's first build is attached,
  /// same as Flutter; there is no guarantee the DOM exists yet even one
  /// microtask later. Retrying the container lookup itself, not just
  /// isReady, is what actually waits for mount — confirmed via the exact
  /// breadcrumb sequence this diagnosis was built from: isReady=true
  /// printed immediately, then container found=false.
  Future<void> _setupGoogleSignIn() async {
    web.HTMLElement? container;
    for (var i = 0; i < 25; i++) {
      if (GoogleIdentity.isReady) {
        final el = web.document.getElementById(_googleButtonId);
        if (el != null) {
          container = el as web.HTMLElement;
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted || container == null) return;

    final (rawNonce, hashedNonce) = AuthService.generateNonce();

    GoogleIdentity.renderSignInButton(
      container: container,
      clientId: Env.googleClientId,
      hashedNonce: hashedNonce,
      onCredential: (credential) => _handleGoogleCredential(credential, rawNonce),
    );
  }

  Future<void> _handleGoogleCredential(String credential, String rawNonce) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await component.authService.signInWithGoogleIdToken(
        idToken: credential,
        nonce: rawNonce,
      );
      if (!mounted) return;
      component.onAuthenticated(session);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Google sign-in failed. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_email.trim().isEmpty || _password.isEmpty) {
      setState(() => _error = 'Enter an email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = _isSignUp
          ? await component.authService.signUp(email: _email, password: _password)
          : await component.authService.signInWithPassword(email: _email, password: _password);
      component.onAuthenticated(session);
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};"
            'color:${KolaDashboardColors.text};width:100%;height:100vh;overflow-y:auto;'
            'display:flex;align-items:center;justify-content:center;box-sizing:border-box;padding:24px',
      },
      [
        div(
          attributes: {
            'style':
                'width:100%;max-width:380px;background:${KolaDashboardColors.card};'
                'border:1px solid ${KolaDashboardColors.border};border-radius:16px;padding:32px;'
                'box-sizing:border-box',
          },
          [
            div(
              attributes: {
                'style': 'display:flex;align-items:center;gap:8px;margin-bottom:6px',
              },
              [
                kolaMark(size: 22),
                div(
                  attributes: {
                    'style': 'font-family:${KolaDashboardFonts.display};font-size:22px;font-weight:700',
                  },
                  [Component.text('kolaa')],
                ),
              ],
            ),
            div(
              attributes: {'style': 'font-size:14px;color:${KolaDashboardColors.muted};margin-bottom:24px'},
              [Component.text(_isSignUp ? 'Create your account' : 'Sign in to your dashboard')],
            ),

            if (_error != null)
              div(
                attributes: {
                  'style':
                      'background:#2A1414;border:1px solid #4A2020;color:#E8A8A8;border-radius:8px;'
                      'padding:10px 12px;font-size:13px;margin-bottom:16px',
                },
                [Component.text(_error!)],
              ),

            _field(
              labelText: 'Email',
              child: input<String>(
                type: InputType.email,
                value: _email,
                onInput: (v) => setState(() => _email = v),
                attributes: {'style': _inputStyle, 'placeholder': 'you@business.com'},
              ),
            ),
            _field(
              labelText: 'Password',
              child: input<String>(
                type: InputType.password,
                value: _password,
                onInput: (v) => setState(() => _password = v),
                attributes: {'style': _inputStyle, 'placeholder': '••••••••'},
              ),
            ),

            button(
              [Component.text(_loading ? 'Please wait…' : (_isSignUp ? 'Sign up' : 'Sign in'))],
              type: ButtonType.submit,
              disabled: _loading,
              onClick: _submit,
              attributes: {
                'style':
                    'width:100%;background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                    'border:none;border-radius:10px;padding:12px;font-size:14.5px;font-weight:600;'
                    'margin-top:8px;cursor:pointer;opacity:${_loading ? '0.7' : '1'}',
              },
            ),

            if (Env.googleClientId.isNotEmpty) ...[
              div(
                attributes: {
                  'style': 'display:flex;align-items:center;gap:10px;margin:18px 0;'
                      'color:${KolaDashboardColors.muted};font-size:12px',
                },
                [
                  div(attributes: {'style': 'flex:1;height:1px;background:${KolaDashboardColors.border}'}, []),
                  Component.text('or'),
                  div(attributes: {'style': 'flex:1;height:1px;background:${KolaDashboardColors.border}'}, []),
                ],
              ),

              // GoogleIdentity.renderSignInButton (see _setupGoogleSignIn)
              // draws Google's OWN button into this element by id — nothing
              // Dart renders here directly, deliberately. See
              // services/google_identity.dart's header for why this
              // dashboard talks to Google directly instead of redirecting
              // through Supabase.
              div(
                attributes: {
                  'id': _googleButtonId,
                  'style': 'display:flex;justify-content:center;min-height:44px;'
                      'opacity:${_loading ? '0.6' : '1'};pointer-events:${_loading ? 'none' : 'auto'}',
                },
                [],
              ),
            ],

            div(
              attributes: {
                'style':
                    'text-align:center;margin-top:18px;font-size:13px;color:${KolaDashboardColors.muted}',
              },
              [
                Component.text(_isSignUp ? 'Already have an account? ' : "Don't have an account? "),
                span(
                  attributes: {'style': 'color:${KolaDashboardColors.accent};cursor:pointer;font-weight:600'},
                  events: {'click': (_) => setState(() => _isSignUp = !_isSignUp)},
                  [Component.text(_isSignUp ? 'Sign in' : 'Sign up')],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static const _inputStyle =
      'width:100%;background:#141416;border:1px solid #2C2A28;border-radius:9px;'
      'padding:11px 12px;font-size:14px;color:#F3EEE7;box-sizing:border-box';

  Component _field({required String labelText, required Component child}) => div(
    attributes: {'style': 'margin-bottom:14px'},
    [
      label(
        [Component.text(labelText)],
        attributes: {
          'style': 'display:block;font-size:12.5px;color:${KolaDashboardColors.mutedStrong};margin-bottom:6px',
        },
      ),
      child,
    ],
  );
}
