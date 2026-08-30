// audit_log_page.dart — "Audit log" as its own page (deferred nav item,
// built this pass). Backed by AdminAuditLogEndpoint.listRecent — a
// read-only view over the same append-only table every mutating admin
// action already writes to.

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../theme.dart';

class AuditLogPage extends StatefulComponent {
  const AuditLogPage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  bool _loading = true;
  String? _error;
  List<String> _lines = const [];

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
      final lines = await component.client.adminAuditLog.listRecent(component.adminToken, limit: 200);
      if (!mounted) return;
      setState(() {
        _lines = lines;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong: $e';
        _loading = false;
      });
    }
  }

  @override
  Component build(BuildContext context) => AdminShell(
        activeLabel: 'Audit log',
        onUnbuiltNav: (_) {},
        onSignOut: component.onSignOut,
        child: div(attributes: {'style': 'max-width:1100px'}, [
          div(
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:20px;font-weight:700;"
                  'color:${AdminColors.heading};margin-bottom:4px',
            },
            [Component.text('Audit log')],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:16px'},
            [Component.text('Most recent ${_lines.length} entries, newest first. Append-only.')],
          ),
          if (_loading) div([Component.text('Loading…')], attributes: {'style': 'color:${AdminColors.muted}'}),
          if (_error != null)
            div(attributes: {'style': 'color:${AdminColors.danger};font-size:13px'}, [Component.text(_error!)]),
          if (!_loading && _error == null)
            div(
              attributes: {
                'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden;'
                    'background:${AdminColors.tableHeaderBg}',
              },
              _lines.isEmpty
                  ? [
                      div(attributes: {'style': 'padding:16px;font-size:12.5px;color:${AdminColors.faint}'}, [
                        Component.text('No audit entries yet.'),
                      ]),
                    ]
                  : [for (final l in _lines) _row(l)],
            ),
        ]),
      );

  Component _row(String line) {
    final parts = line.split('|');
    final when = parts.isNotEmpty ? parts[0] : '';
    final actor = parts.length > 1 ? parts[1] : '';
    final action = parts.length > 2 ? parts[2] : '';
    final target = parts.length > 3 ? parts[3] : '';
    final change = parts.length > 4 ? parts[4] : '';
    final note = parts.length > 5 ? parts.sublist(5).join('|') : '';
    return div(
      attributes: {
        'style': 'padding:9px 14px;border-bottom:1px solid ${AdminColors.rowBorder};font-size:11.5px;'
            'display:flex;gap:12px;flex-wrap:wrap',
      },
      [
        span([Component.text(when)], attributes: {"style": "font-family:${AdminFonts.mono};color:${AdminColors.faint};width:150px;flex:none"}),
        span([Component.text(action)], attributes: {'style': 'color:${AdminColors.accent};width:190px;flex:none;font-weight:600'}),
        span([Component.text(actor)], attributes: {'style': 'width:200px;flex:none;color:${AdminColors.text}'}),
        span([Component.text(target)], attributes: {'style': 'width:120px;flex:none;color:${AdminColors.muted}'}),
        span([Component.text(change)], attributes: {'style': 'color:${AdminColors.muted}'}),
        if (note.isNotEmpty) div(attributes: {'style': 'width:100%;color:${AdminColors.faint};margin-top:2px'}, [Component.text(note)]),
      ],
    );
  }
}
