// overview_page.dart — the admin app's landing page. Added in a
// robustness pass: this was the last nav item still pointing nowhere,
// and by the time it was built every surface it summarizes (workspaces,
// platform health, audit log, support queue) already had real data
// behind it — see AdminOverviewEndpoint's header for exactly what's
// aggregated vs. genuinely not tracked anywhere (error rates, queue
// depth — same honest gaps as the Platform health page).

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../services/admin_error.dart';
import '../theme.dart';

class OverviewPage extends StatefulComponent {
  const OverviewPage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  bool _loading = true;
  String? _error;
  Map<String, String> _summary = const {};
  List<String> _activity = const [];

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
      final summaryLines = await component.client.adminOverview.getSummary(component.adminToken);
      final activity = await component.client.adminOverview.getRecentActivity(component.adminToken);
      if (!mounted) return;
      setState(() {
        _summary = {
          for (final line in summaryLines)
            if (line.contains('|')) line.split('|')[0]: line.split('|').sublist(1).join('|'),
        };
        _activity = activity;
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

  String _v(String key, [String fallback = '-']) => _summary[key] ?? fallback;

  @override
  Component build(BuildContext context) => AdminShell(
        activeLabel: 'Overview',
        onUnbuiltNav: (_) {},
        onSignOut: component.onSignOut,
        child: div(attributes: {'style': 'max-width:1000px'}, [
          div(
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:20px;font-weight:700;"
                  'color:${AdminColors.heading};margin-bottom:4px',
            },
            [Component.text('Overview')],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:16px'},
            [Component.text('A snapshot pulled from the same data every other page here reads — nothing new tracked just for this view.')],
          ),
          if (_loading) div([Component.text('Loading…')], attributes: {'style': 'color:${AdminColors.muted}'}),
          if (_error != null)
            div(attributes: {'style': 'color:${AdminColors.danger};font-size:13px'}, [Component.text(_error!)]),
          if (!_loading && _error == null) ..._sections(),
        ]),
      );

  List<Component> _sections() => [
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));'
                'gap:12px;margin-bottom:22px',
          },
          [
            _statCard('Workspaces', _v('workspaces_total', '0')),
            _statCard('Active', _v('workspaces_active', '0'), color: AdminColors.releasedFg),
            _statCard('Trialing', _v('workspaces_trialing', '0'), color: AdminColors.accent),
            _statCard('Paused', _v('workspaces_paused', '0'), color: AdminColors.betaFg),
            _statCard('Open tickets', _v('open_tickets', '0')),
            _statCard('Sweep jobs OK', _v('sweep_jobs_ok', '0'), color: AdminColors.releasedFg),
            _statCard('Sweep jobs failed', _v('sweep_jobs_failed', '0'),
                color: _v('sweep_jobs_failed', '0') == '0' ? AdminColors.muted : AdminColors.danger),
            _statCard('AI providers configured', _v('ai_providers_configured', '0')),
            _statCard('Embedding available', _v('embedding_available', 'false')),
          ],
        ),
        div(
          attributes: {'style': 'font-size:13px;font-weight:700;color:${AdminColors.heading};margin:0 0 8px'},
          [Component.text('Recent activity')],
        ),
        div(
          attributes: {'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden'},
          _activity.isEmpty
              ? [
                  div(attributes: {'style': 'padding:14px;font-size:12.5px;color:${AdminColors.faint}'}, [
                    Component.text('No audit entries yet.'),
                  ]),
                ]
              : [for (final line in _activity) _activityRow(line)],
        ),
      ];

  Component _statCard(String label, String value, {String? color}) => div(
        attributes: {
          'style': 'border:1px solid ${AdminColors.border};border-radius:8px;background:${AdminColors.card};'
              'padding:14px',
        },
        [
          div(
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:22px;font-weight:700;"
                  'color:${color ?? AdminColors.heading}',
            },
            [Component.text(value)],
          ),
          div(
            attributes: {'style': 'font-size:11.5px;color:${AdminColors.muted};margin-top:4px'},
            [Component.text(label)],
          ),
        ],
      );

  Component _activityRow(String line) {
    final parts = line.split('|');
    final when = parts.isNotEmpty ? parts[0] : '';
    final actor = parts.length > 1 ? parts[1] : '';
    final action = parts.length > 2 ? parts[2] : '';
    return div(
      attributes: {
        'style': 'padding:9px 14px;border-bottom:1px solid ${AdminColors.rowBorder};font-size:12px;'
            'display:flex;gap:12px',
      },
      [
        span([Component.text(when)], attributes: {"style": "font-family:${AdminFonts.mono};color:${AdminColors.faint};width:150px;flex:none"}),
        span([Component.text(action)], attributes: {'style': 'color:${AdminColors.accent};width:200px;flex:none;font-weight:600'}),
        span([Component.text(actor)], attributes: {'style': 'color:${AdminColors.text}'}),
      ],
    );
  }
}
