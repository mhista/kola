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

import '../theme.dart';
import '../services/auth_service.dart';
import '../models/auth_session.dart';

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
                'style':
                    'font-family:${KolaDashboardFonts.display};font-size:22px;font-weight:700;'
                    'margin-bottom:6px',
              },
              [Component.text('kymaa')],
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
