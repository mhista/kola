// admin_accounts_page.dart — "Admin accounts" as its own page (deferred
// nav item, built this pass). Read-only list + activate/deactivate only
// — see AdminAccountsEndpoint's header on why there is deliberately no
// create-account UI here. Owner-only server-side; a non-Owner sees a
// clear access-denied message rather than a broken page.

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../theme.dart';

class AdminAccountsPage extends StatefulComponent {
  const AdminAccountsPage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage> {
  bool _loading = true;
  String? _error;
  List<String> _rows = const [];
  bool _busy = false;
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
      final rows = await component.client.adminAccounts.listAdmins(component.adminToken);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().contains('admin_access_denied')
            ? "Your admin level doesn't permit viewing admin accounts — Owner only."
            : 'Something went wrong: $e';
        _loading = false;
      });
    }
  }

  Future<void> _toggle(int id, String email, bool currentlyActive) async {
    setState(() => _busy = true);
    try {
      await component.client.adminAccounts.setActive(
        component.adminToken,
        id,
        !currentlyActive,
        'Toggled from admin accounts page',
      );
      if (!mounted) return;
      setState(() {
        _banner = '$email is now ${!currentlyActive ? "active" : "deactivated"}.';
        _bannerIsError = false;
        _busy = false;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _banner = 'Failed: $e';
        _bannerIsError = true;
        _busy = false;
      });
    }
  }

  @override
  Component build(BuildContext context) => AdminShell(
        activeLabel: 'Admin accounts',
        onUnbuiltNav: (_) {},
        onSignOut: component.onSignOut,
        child: div(attributes: {'style': 'max-width:800px'}, [
          div(
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:20px;font-weight:700;"
                  'color:${AdminColors.heading};margin-bottom:4px',
            },
            [Component.text('Admin accounts')],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:16px'},
            [
              Component.text(
                'Read-only. There is no in-app account creation — see AdminUserRepository.create\'s '
                'header for why the first password for a new account is always a direct database action.',
              ),
            ],
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
          if (!_loading && _error == null)
            div(
              attributes: {'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden'},
              _rows.isEmpty
                  ? [
                      div(attributes: {'style': 'padding:16px;font-size:12.5px;color:${AdminColors.faint}'}, [
                        Component.text('No admin accounts found.'),
                      ]),
                    ]
                  : [for (final r in _rows) _row(r)],
            ),
        ]),
      );

  Component _row(String line) {
    final parts = line.split('|');
    final id = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final email = parts.length > 1 ? parts[1] : line;
    final level = parts.length > 2 ? parts[2] : '';
    final active = parts.length > 3 ? parts[3] == 'true' : true;
    final mustReset = parts.length > 4 ? parts[4] == 'true' : false;
    final lastSeen = parts.length > 5 ? parts[5] : '-';
    return div(
      attributes: {
        'style': 'display:flex;gap:12px;padding:10px 14px;border-bottom:1px solid ${AdminColors.rowBorder};'
            'font-size:12.5px;align-items:center',
      },
      [
        span([Component.text(email)], attributes: {'style': 'width:220px;flex:none;color:${AdminColors.text}'}),
        span([Component.text(level)], attributes: {'style': 'width:80px;flex:none;color:${AdminColors.accent}'}),
        span([Component.text(active ? 'active' : 'deactivated')], attributes: {
          'style': 'width:90px;flex:none;color:${active ? AdminColors.releasedFg : AdminColors.danger}',
        }),
        span([Component.text(mustReset ? 'must reset password' : '')], attributes: {
          'style': 'width:140px;flex:none;color:${AdminColors.betaFg};font-size:11px',
        }),
        span([Component.text('last seen: $lastSeen')], attributes: {'style': 'flex:1;color:${AdminColors.faint};font-size:11px'}),
        if (id != null)
          button(
            [Component.text(_busy ? '…' : (active ? 'Deactivate' : 'Activate'))],
            events: {'click': (_) => _busy ? null : _toggle(id, email, active)},
            attributes: {
              'style': 'padding:5px 10px;border-radius:6px;border:1px solid ${AdminColors.border};'
                  "background:transparent;color:${AdminColors.accent};font-size:11px;cursor:pointer;flex:none",
            },
          ),
      ],
    );
  }
}
