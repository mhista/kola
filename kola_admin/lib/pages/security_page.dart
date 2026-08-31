// security_page.dart — "my account security," reachable from every
// admin's sidebar footer regardless of level (this is self-service, not
// an Owner-only admin-accounts action). Covers MFA enrollment and
// disabling — see AdminAuthEndpoint's beginMfaEnrollment/
// confirmMfaEnrollment/disableMfa for the server-side design.
//
// NO QR CODE IMAGE: rendering an actual scannable QR code needs either a
// new pub dependency (a new `dart pub get` this environment cannot run
// or verify) or client-side JS this project has no precedent for pulling
// in. The otpauth:// URI and the raw secret are both shown as plain,
// selectable text instead — every mainstream authenticator app (Google
// Authenticator, Authy, 1Password, etc.) accepts typing a secret in
// manually, just with one extra step versus scanning. A real gap worth
// closing later, stated here rather than faked with a broken image tag.

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../services/admin_error.dart';
import '../theme.dart';

class SecurityPage extends StatefulComponent {
  const SecurityPage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _loading = true;
  String? _error;
  bool? _mfaEnabled;

  // Enrollment in progress (step 1 result, not yet persisted).
  String? _pendingSecret;
  String? _pendingUri;
  String _confirmCode = '';
  bool _enrolling = false;

  // Disable flow.
  bool _disabling = false;
  String _disablePassword = '';

  String? _banner;
  bool _bannerIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final enabled = await component.client.adminAuth.mfaEnabled(component.adminToken);
      if (!mounted) return;
      setState(() {
        _mfaEnabled = enabled;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (isAdminSessionError(e)) {
        component.onSignOut();
        return;
      }
      setState(() {
        _error = describeAdminError(e);
        _loading = false;
      });
    }
  }

  Future<void> _beginEnroll() async {
    setState(() {
      _enrolling = true;
      _banner = null;
    });
    try {
      final result = await component.client.adminAuth.beginMfaEnrollment(component.adminToken);
      final parts = result.split('|');
      if (!mounted) return;
      setState(() {
        _pendingSecret = parts.isNotEmpty ? parts[0] : null;
        _pendingUri = parts.length > 1 ? parts.sublist(1).join('|') : null;
        _enrolling = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (isAdminSessionError(e)) {
        component.onSignOut();
        return;
      }
      setState(() {
        _banner = 'Could not start enrollment: ${describeAdminError(e)}';
        _bannerIsError = true;
        _enrolling = false;
      });
    }
  }

  Future<void> _confirmEnroll() async {
    if (_pendingSecret == null || _confirmCode.trim().length != 6) {
      setState(() {
        _banner = 'Enter the 6-digit code your authenticator app is now showing.';
        _bannerIsError = true;
      });
      return;
    }
    setState(() => _enrolling = true);
    try {
      await component.client.adminAuth.confirmMfaEnrollment(
        component.adminToken,
        _pendingSecret!,
        _confirmCode.trim(),
      );
      if (!mounted) return;
      setState(() {
        _mfaEnabled = true;
        _pendingSecret = null;
        _pendingUri = null;
        _confirmCode = '';
        _enrolling = false;
        _banner = 'MFA is now enabled on your account.';
        _bannerIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (isAdminSessionError(e)) {
        component.onSignOut();
        return;
      }
      setState(() {
        _banner = describeAdminError(e);
        _bannerIsError = true;
        _enrolling = false;
      });
    }
  }

  Future<void> _disable() async {
    if (_disablePassword.isEmpty) {
      setState(() {
        _banner = 'Enter your current password to disable MFA.';
        _bannerIsError = true;
      });
      return;
    }
    setState(() => _disabling = true);
    try {
      await component.client.adminAuth.disableMfa(component.adminToken, _disablePassword);
      if (!mounted) return;
      setState(() {
        _mfaEnabled = false;
        _disablePassword = '';
        _disabling = false;
        _banner = 'MFA has been disabled on your account.';
        _bannerIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (isAdminSessionError(e)) {
        component.onSignOut();
        return;
      }
      setState(() {
        _banner = describeAdminError(e);
        _bannerIsError = true;
        _disabling = false;
      });
    }
  }

  static const _inputStyle = 'width:100%;box-sizing:border-box;padding:9px 12px;border-radius:6px;'
      'border:1px solid #232323;background:#0C0C0D;color:#D8D6D2;font-family:inherit;font-size:13px';

  @override
  Component build(BuildContext context) => AdminShell(
        activeLabel: 'Security',
        onUnbuiltNav: (_) {},
        onSignOut: component.onSignOut,
        child: div(attributes: {'style': 'max-width:560px'}, [
          div(
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:20px;font-weight:700;"
                  'color:${AdminColors.heading};margin-bottom:4px',
            },
            [Component.text('Account security')],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:16px'},
            [Component.text('Applies to your own admin account only.')],
          ),
          if (_banner != null)
            div(
              attributes: {
                'style': 'padding:10px 14px;border-radius:8px;margin-bottom:14px;font-size:13px;'
                    'background:${_bannerIsError ? AdminColors.dangerBg : AdminColors.releasedBg};'
                    'color:${_bannerIsError ? AdminColors.danger : AdminColors.releasedFg};'
                    'border:1px solid ${_bannerIsError ? AdminColors.dangerBorder : AdminColors.border}',
              },
              [Component.text(_banner!)],
            ),
          if (_loading) div([Component.text('Loading…')], attributes: {'style': 'color:${AdminColors.muted}'}),
          if (_error != null)
            div(attributes: {'style': 'color:${AdminColors.danger};font-size:13px'}, [Component.text(_error!)]),
          if (!_loading && _error == null) ..._mfaSection(),
        ]),
      );

  List<Component> _mfaSection() {
    if (_mfaEnabled == true) {
      return [
        _card([
          div(
            attributes: {'style': 'display:flex;align-items:center;gap:8px;margin-bottom:10px'},
            [
              span(
                [Component.text('Enabled')],
                attributes: {
                  'style': 'font-size:11px;font-weight:700;padding:3px 8px;border-radius:5px;'
                      'background:${AdminColors.releasedBg};color:${AdminColors.releasedFg}',
                },
              ),
              div(
                attributes: {'style': 'font-size:14px;font-weight:700;color:${AdminColors.heading}'},
                [Component.text('Two-factor authentication')],
              ),
            ],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:14px'},
            [Component.text('Your account requires a code from your authenticator app on every sign-in.')],
          ),
          _label('Current password (required to disable)'),
          input<String>(
            type: InputType.password,
            value: _disablePassword,
            onInput: (v) => _disablePassword = v,
            attributes: {'style': _inputStyle},
          ),
          div(attributes: {'style': 'margin-top:12px'}, [
            button(
              [Component.text(_disabling ? 'Disabling…' : 'Disable MFA')],
              events: {'click': (_) => _disabling ? null : _disable()},
              attributes: {
                'style': 'padding:9px 16px;border-radius:6px;border:1px solid ${AdminColors.dangerBorder};'
                    "background:transparent;color:${AdminColors.danger};font-size:13px;cursor:pointer",
              },
            ),
          ]),
        ]),
      ];
    }

    if (_pendingSecret != null) {
      return [
        _card([
          div(
            attributes: {'style': 'font-size:14px;font-weight:700;color:${AdminColors.heading};margin-bottom:10px'},
            [Component.text('Scan or enter this secret')],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:6px'},
            [Component.text('No QR image here yet — add this as a manual entry in your authenticator app:')],
          ),
          div(
            attributes: {
              'style': "font-family:${AdminFonts.mono};font-size:15px;letter-spacing:1px;color:${AdminColors.accent};"
                  'background:${AdminColors.bg};border:1px solid ${AdminColors.border};border-radius:6px;'
                  'padding:10px 12px;margin-bottom:10px;word-break:break-all',
            },
            [Component.text(_pendingSecret!)],
          ),
          div(
            attributes: {'style': 'font-size:11px;color:${AdminColors.faint};margin-bottom:14px;word-break:break-all'},
            [Component.text(_pendingUri ?? '')],
          ),
          _label('Then enter the 6-digit code it shows'),
          input<String>(
            type: InputType.text,
            value: _confirmCode,
            onInput: (v) => _confirmCode = v,
            attributes: {'style': _inputStyle, 'placeholder': '123456', 'inputmode': 'numeric', 'maxlength': '6'},
          ),
          div(attributes: {'style': 'margin-top:12px'}, [
            button(
              [Component.text(_enrolling ? 'Confirming…' : 'Confirm and enable')],
              events: {'click': (_) => _enrolling ? null : _confirmEnroll()},
              attributes: {
                'style': 'padding:9px 16px;border-radius:6px;border:none;background:${AdminColors.accent};'
                    'color:${AdminColors.accentText};font-weight:600;font-size:13px;cursor:pointer',
              },
            ),
          ]),
        ]),
      ];
    }

    return [
      _card([
        div(
          attributes: {'style': 'font-size:14px;font-weight:700;color:${AdminColors.heading};margin-bottom:8px'},
          [Component.text('Two-factor authentication is not enabled')],
        ),
        div(
          attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:14px;line-height:1.5'},
          [Component.text('Adds a 6-digit code from an authenticator app to every sign-in, on top of your password.')],
        ),
        button(
          [Component.text(_enrolling ? 'Starting…' : 'Set up MFA')],
          events: {'click': (_) => _enrolling ? null : _beginEnroll()},
          attributes: {
            'style': 'padding:9px 16px;border-radius:6px;border:none;background:${AdminColors.accent};'
                'color:${AdminColors.accentText};font-weight:600;font-size:13px;cursor:pointer',
          },
        ),
      ]),
    ];
  }

  Component _card(List<Component> children) => div(
        attributes: {
          'style': 'border:1px solid ${AdminColors.border};border-radius:8px;background:${AdminColors.card};'
              'padding:18px',
        },
        children,
      );

  Component _label(String t) => div(
        attributes: {'style': 'font-size:11.5px;font-weight:700;color:${AdminColors.muted};margin-bottom:6px'},
        [Component.text(t)],
      );
}
