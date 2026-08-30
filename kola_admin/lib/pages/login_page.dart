// login_page.dart — the only entry point into kola_admin. Deliberately
// no sign-up UI: matches admin_auth_endpoint.dart's own design (no
// signup method exists server-side — see that file's header). The
// first admin account is created by direct database insert; this page
// can never create one.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';

class LoginPage extends StatefulComponent {
  const LoginPage({required this.client, required this.onLoggedIn});

  final Client client;
  final void Function(String adminToken) onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _email = '';
  String _password = '';
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
      final token = await component.client.adminAuth.login(_email.trim(), _password);
      if (!mounted) return;
      component.onLoggedIn(token);
    } catch (e) {
      if (!mounted) return;
      // AdminAuthService.login() already collapses "no such account" and
      // "wrong password" into one message server-side, on purpose — a
      // login form shouldn't distinguish them, and that message
      // ('Invalid email or password.') is safe to show verbatim.
      //
      // Anything else here is NOT a credentials problem and showing the
      // same generic copy for it hides a real, diagnosable failure — e.g.
      // 'Endpoint not found' (kola_server hasn't been redeployed with the
      // admin endpoints yet — see kola_server/deploy.sh's header: pushing
      // to git does NOT redeploy it), or a network/CORS failure reaching
      // KOLA_SERVER_URL entirely. Surface those distinctly so the next
      // person hitting this doesn't have to open devtools to find out
      // it's a deploy gap, not a typo'd password.
      final message = e.toString();
      final isCredentialsError = message.contains('Invalid email or password');
      setState(() {
        _error = isCredentialsError
            ? 'Sign-in failed. Check the email and password and try again.'
            : 'Could not reach the admin server ($message). Check that '
                'KOLA_SERVER_URL is correct and that kola_server has been '
                'redeployed with the admin endpoints.';
        _loading = false;
      });
    }
  }

  static const _inputStyle =
      'width:100%;box-sizing:border-box;background:${AdminColors.bg};'
      'border:1px solid ${AdminColors.border};border-radius:8px;padding:10px 12px;'
      "color:${AdminColors.text};font-family:${AdminFonts.body};font-size:14px;outline:none";

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${AdminFonts.body};background:${AdminColors.bg};color:${AdminColors.text};"
            'width:100%;height:100vh;height:100svh;overflow-y:auto;display:flex;'
            'align-items:center;justify-content:center;box-sizing:border-box;padding:24px',
      },
      [
        div(
          attributes: {
            'style':
                'width:100%;max-width:360px;background:${AdminColors.card};'
                'border:1px solid ${AdminColors.border};border-radius:12px;padding:28px;box-sizing:border-box',
          },
          [
            div(
              attributes: {'style': 'display:flex;align-items:center;gap:8px;margin-bottom:22px'},
              [
                div(
                  attributes: {
                    'style': 'width:16px;height:16px;border-radius:4px;background:${AdminColors.accent};flex:none',
                  },
                  [],
                ),
                span(
                  [Component.text('kola_admin')],
                  attributes: {
                    'style': "font-family:${AdminFonts.display};font-size:15px;font-weight:700;color:${AdminColors.heading}",
                  },
                ),
              ],
            ),
            div(
              attributes: {'style': 'font-size:19px;font-weight:700;font-family:${AdminFonts.display};color:${AdminColors.heading};margin-bottom:20px'},
              [Component.text('Admin sign-in')],
            ),
            if (_error != null)
              div(
                attributes: {
                  'style': 'background:${AdminColors.dangerBg};border:1px solid ${AdminColors.dangerBorder};'
                      'color:${AdminColors.danger};border-radius:8px;padding:10px 12px;'
                      'font-size:13px;margin-bottom:16px',
                },
                [Component.text(_error!)],
              ),
            div(
              attributes: {'style': 'margin-bottom:14px'},
              [
                div(
                  attributes: {'style': 'font-size:12px;color:${AdminColors.muted};margin-bottom:6px'},
                  [Component.text('Email')],
                ),
                input<String>(
                  type: InputType.email,
                  value: _email,
                  onInput: (v) => setState(() => _email = v),
                  attributes: {'style': _inputStyle, 'placeholder': 'you@kola.internal'},
                ),
              ],
            ),
            div(
              attributes: {'style': 'margin-bottom:18px'},
              [
                div(
                  attributes: {'style': 'font-size:12px;color:${AdminColors.muted};margin-bottom:6px'},
                  [Component.text('Password')],
                ),
                input<String>(
                  type: InputType.password,
                  value: _password,
                  onInput: (v) => setState(() => _password = v),
                  attributes: {'style': _inputStyle, 'placeholder': '••••••••'},
                ),
              ],
            ),
            button(
              [Component.text(_loading ? 'Signing in…' : 'Sign in')],
              type: ButtonType.submit,
              disabled: _loading,
              onClick: _submit,
              attributes: {
                'style':
                    'width:100%;background:${AdminColors.accent};color:${AdminColors.accentText};'
                    'border:none;border-radius:8px;padding:11px;font-size:14px;font-weight:600;'
                    'cursor:pointer;opacity:${_loading ? '0.7' : '1'}',
              },
            ),
            div(
              attributes: {'style': 'font-size:11.5px;color:${AdminColors.muted};margin-top:16px;line-height:1.5'},
              [
                Component.text(
                  'No self-service sign-up. Accounts are provisioned directly '
                  'against the database — ask an existing Owner-level admin.',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
