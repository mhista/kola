// reset_password_page.dart — kola_admin's forced (and voluntary)
// password-change screen.
//
// Reached two ways:
//   1. Forced: app.dart's redirect guard sends every admin here right
//      after login whenever AdminAuthEndpoint.mustResetPassword returns
//      true (migration 055 — true for every account until this page's
//      submit succeeds once). No "skip" button exists on purpose — see
//      ADMIN_APP_SPEC.md's posture on placeholder passwords never being
//      allowed to become the account's permanent credential.
//   2. Voluntary: nothing currently links here for an already-cleared
//      account, but the page itself doesn't assume "forced" — it always
//      asks for the CURRENT password (see AdminAuthService.changePassword's
//      header for why that holds even during a forced reset), so it's
//      already correct for a future "change password" settings link.
//
// [onSignOut] is offered because an admin who doesn't recognize the
// forced-reset screen (or got their placeholder password wrong) needs a
// way back to a real login attempt rather than being stuck on a page
// they can't get past.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';

class ResetPasswordPage extends StatefulComponent {
  const ResetPasswordPage({
    required this.client,
    required this.adminToken,
    required this.onDone,
    required this.onSignOut,
    this.forced = true,
  });

  final Client client;
  final String adminToken;

  /// Called once changePassword succeeds — app.dart clears its
  /// must-reset flag and the router's redirect guard lets the admin
  /// through to the rest of the app.
  final void Function() onDone;

  final void Function() onSignOut;

  /// Changes only the copy ("you must" vs "change your password") — the
  /// server-side requirement (current password, ≥12 chars, must differ)
  /// is identical either way.
  final bool forced;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_currentPassword.isEmpty || _newPassword.isEmpty) {
      setState(() => _error = 'Fill in every field.');
      return;
    }
    if (_newPassword.length < 12) {
      setState(() => _error = 'New password must be at least 12 characters.');
      return;
    }
    if (_newPassword != _confirmPassword) {
      setState(() => _error = 'New password and confirmation do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await component.client.adminAuth.changePassword(
        component.adminToken,
        _currentPassword,
        _newPassword,
      );
      if (!mounted) return;
      component.onDone();
    } catch (e) {
      if (!mounted) return;
      // AdminAuthEndpoint.changePassword collapses every validation
      // failure into a KolaException with a plain-English message
      // ('Current password is incorrect.', 'New password must be at
      // least 12 characters.', etc.) — safe to show verbatim, same
      // posture as login_page.dart's credentials-error branch.
      setState(() {
        _error = e.toString().replaceFirst('KolaException: ', '');
        _loading = false;
      });
    }
  }

  static const _inputStyle =
      'width:100%;box-sizing:border-box;background:${AdminColors.bg};'
      'border:1px solid ${AdminColors.border};border-radius:8px;padding:10px 12px;'
      "color:${AdminColors.text};font-family:${AdminFonts.body};font-size:14px;outline:none";

  Component _field(String label, String value, void Function(String) onInput) {
    return div(
      attributes: {'style': 'margin-bottom:14px'},
      [
        div(
          attributes: {'style': 'font-size:12px;color:${AdminColors.muted};margin-bottom:6px'},
          [Component.text(label)],
        ),
        input<String>(
          type: InputType.password,
          value: value,
          onInput: onInput,
          attributes: {'style': _inputStyle, 'placeholder': '••••••••'},
        ),
      ],
    );
  }

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
                'width:100%;max-width:380px;background:${AdminColors.card};'
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
              attributes: {'style': 'font-size:19px;font-weight:700;font-family:${AdminFonts.display};color:${AdminColors.heading};margin-bottom:8px'},
              [Component.text(component.forced ? 'Set a new password' : 'Change password')],
            ),
            div(
              attributes: {'style': 'font-size:13px;color:${AdminColors.muted};margin-bottom:20px;line-height:1.5'},
              [
                Component.text(
                  component.forced
                      ? 'This account is still using its placeholder password. '
                          'Choose a new one before continuing.'
                      : 'Enter your current password and choose a new one.',
                ),
              ],
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
            _field('Current password', _currentPassword, (v) => setState(() => _currentPassword = v)),
            _field('New password (12+ characters)', _newPassword, (v) => setState(() => _newPassword = v)),
            div(
              attributes: {'style': 'margin-bottom:20px'},
              [_field('Confirm new password', _confirmPassword, (v) => setState(() => _confirmPassword = v))],
            ),
            button(
              [Component.text(_loading ? 'Updating…' : 'Update password')],
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
            button(
              [Component.text('Sign out instead')],
              type: ButtonType.button,
              disabled: _loading,
              onClick: component.onSignOut,
              attributes: {
                'style':
                    'width:100%;background:transparent;color:${AdminColors.muted};'
                    'border:none;border-radius:8px;padding:10px;font-size:12.5px;'
                    'cursor:pointer;margin-top:10px',
              },
            ),
          ],
        ),
      ],
    );
  }
}
