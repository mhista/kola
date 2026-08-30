// support_queue_page.dart — "Support queue" as its own page (deferred
// nav item, built this pass). Backed by
// AdminSupportEndpoint.listOpenTickets -> SupportTicketRepository
// .listOpenGlobal (added this pass) — every open/in-progress ticket
// across every workspace, the cross-tenant view no workspace-scoped
// dashboard page can show.

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../theme.dart';

class SupportQueuePage extends StatefulComponent {
  const SupportQueuePage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<SupportQueuePage> createState() => _SupportQueuePageState();
}

class _SupportQueuePageState extends State<SupportQueuePage> {
  bool _loading = true;
  String? _error;
  List<SupportTicket> _tickets = const [];

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
      final tickets = await component.client.adminSupport.listOpenTickets(component.adminToken, limit: 200);
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
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

  String _priorityColor(String p) => switch (p) {
        'urgent' => AdminColors.danger,
        'high' => AdminColors.betaFg,
        'medium' => AdminColors.accent,
        _ => AdminColors.muted,
      };

  @override
  Component build(BuildContext context) => AdminShell(
        activeLabel: 'Support queue',
        onUnbuiltNav: (_) {},
        onSignOut: component.onSignOut,
        child: div(attributes: {'style': 'max-width:1000px'}, [
          div(
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:20px;font-weight:700;"
                  'color:${AdminColors.heading};margin-bottom:4px',
            },
            [Component.text('Support queue')],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:16px'},
            [Component.text('Every open or in-progress support ticket across every workspace, newest first.')],
          ),
          if (_loading) div([Component.text('Loading…')], attributes: {'style': 'color:${AdminColors.muted}'}),
          if (_error != null)
            div(attributes: {'style': 'color:${AdminColors.danger};font-size:13px'}, [Component.text(_error!)]),
          if (!_loading && _error == null)
            div(
              attributes: {'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden'},
              _tickets.isEmpty
                  ? [
                      div(attributes: {'style': 'padding:16px;font-size:12.5px;color:${AdminColors.faint}'}, [
                        Component.text('No open tickets. Queue is clear.'),
                      ]),
                    ]
                  : [for (final t in _tickets) _row(t)],
            ),
        ]),
      );

  Component _row(SupportTicket t) => div(
        attributes: {
          'style': 'display:flex;gap:12px;padding:10px 14px;border-bottom:1px solid ${AdminColors.rowBorder};'
              'font-size:12.5px;align-items:baseline',
        },
        [
          span([Component.text(t.priority)], attributes: {
            'style': "font-family:${AdminFonts.mono};font-weight:700;color:${_priorityColor(t.priority)};"
                'width:70px;flex:none;text-transform:uppercase',
          }),
          span([Component.text('ws=${t.workspaceId}')], attributes: {'style': 'width:80px;flex:none;color:${AdminColors.muted}'}),
          span([Component.text(t.subject)], attributes: {'style': 'flex:1;color:${AdminColors.text}'}),
          span([Component.text(t.status)], attributes: {'style': 'width:80px;flex:none;color:${AdminColors.accent}'}),
          span([Component.text(t.slaDeadline.toIso8601String())], attributes: {
            "style": "font-family:${AdminFonts.mono};color:${AdminColors.faint};font-size:11px",
          }),
        ],
      );
}
