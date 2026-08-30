// platform_health_page.dart — ADMIN_APP_SPEC.md §3.5, build-order step
// 6, built this pass. Backed by AdminPlatformEndpoint — see that file's
// header for exactly what's real (sweep job last-run status, AI
// provider key-configured status, embedding cap) vs. explicitly NOT
// tracked (error rates, queue depth — no infrastructure for either
// exists in this codebase, shown here as a plain "not tracked" note,
// never a fabricated number).

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../services/admin_error.dart';
import '../theme.dart';

class PlatformHealthPage extends StatefulComponent {
  const PlatformHealthPage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<PlatformHealthPage> createState() => _PlatformHealthPageState();
}

class _PlatformHealthPageState extends State<PlatformHealthPage> {
  bool _loading = true;
  String? _error;
  List<String> _sweeps = const [];
  List<String> _providers = const [];
  String? _embedding;

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
      final sweeps = await component.client.adminPlatform.listSweepJobStatuses(component.adminToken);
      final providers = await component.client.adminPlatform.listAiProviderStatus(component.adminToken);
      final embedding = await component.client.adminPlatform.embeddingQuotaInfo(component.adminToken);
      if (!mounted) return;
      setState(() {
        _sweeps = sweeps;
        _providers = providers;
        _embedding = embedding;
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

  @override
  Component build(BuildContext context) => AdminShell(
        activeLabel: 'Platform health',
        onUnbuiltNav: (_) {},
        onSignOut: component.onSignOut,
        child: div(attributes: {'style': 'max-width:900px'}, [
          div(
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:20px;font-weight:700;"
                  'color:${AdminColors.heading};margin-bottom:4px',
            },
            [Component.text('Platform health')],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:16px'},
            [
              Component.text(
                'A process-local, single-instance snapshot — see PlatformHealthRegistry\'s header. '
                'Error rates and queue depth are not tracked anywhere in this codebase yet; shown as '
                'a plain note below rather than a fabricated number.',
              ),
            ],
          ),
          if (_loading) div([Component.text('Loading…')], attributes: {'style': 'color:${AdminColors.muted}'}),
          if (_error != null)
            div(attributes: {'style': 'color:${AdminColors.danger};font-size:13px'}, [Component.text(_error!)]),
          if (!_loading && _error == null) ..._sections(),
        ]),
      );

  List<Component> _sections() => [
        _sectionTitle('Sweep jobs (${_sweeps.length} reported since last restart)'),
        _box(_sweeps.isEmpty
            ? [_empty('No sweep job has ticked since this server process last started.')]
            : [for (final s in _sweeps) _sweepRow(s)]),
        _sectionTitle('AI providers'),
        _box(_providers.isEmpty
            ? [_empty('No provider status returned.')]
            : [for (final p in _providers) _providerRow(p)]),
        _sectionTitle('Embedding / long-term memory'),
        _box([
          div(
            attributes: {'style': 'padding:12px 14px;font-size:12.5px;color:${AdminColors.text}'},
            [Component.text(_embedding ?? '-')],
          ),
        ]),
        _sectionTitle('Error rates & queue depth'),
        _box([_empty('Not tracked — no error-log table or job-queue system exists in this codebase yet.')]),
      ];

  Component _sectionTitle(String t) => div(
        attributes: {'style': 'font-size:13px;font-weight:700;color:${AdminColors.heading};margin:18px 0 8px'},
        [Component.text(t)],
      );

  Component _box(List<Component> children) => div(
        attributes: {
          'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden;margin-bottom:6px',
        },
        children,
      );

  Component _empty(String t) =>
      div(attributes: {'style': 'padding:14px;font-size:12.5px;color:${AdminColors.faint}'}, [Component.text(t)]);

  Component _sweepRow(String line) {
    final parts = line.split('|');
    final job = parts.isNotEmpty ? parts[0] : line;
    final lastRun = parts.length > 1 ? parts[1] : '';
    final ok = parts.length > 2 ? parts[2] == 'true' : true;
    final summary = parts.length > 3 ? parts[3] : '';
    return div(
      attributes: {
        'style': 'display:flex;gap:12px;padding:10px 14px;border-bottom:1px solid ${AdminColors.rowBorder};'
            'font-size:12.5px;align-items:baseline',
      },
      [
        span([Component.text(ok ? 'OK' : 'FAIL')], attributes: {
          'style': "font-family:${AdminFonts.mono};font-weight:700;"
              'color:${ok ? AdminColors.releasedFg : AdminColors.danger};width:44px;flex:none',
        }),
        span([Component.text(job)], attributes: {'style': 'width:200px;flex:none;color:${AdminColors.text}'}),
        span([Component.text(summary)], attributes: {'style': 'width:200px;flex:none;color:${AdminColors.muted}'}),
        span([Component.text(lastRun)], attributes: {"style": "font-family:${AdminFonts.mono};color:${AdminColors.faint};font-size:11px"}),
      ],
    );
  }

  Component _providerRow(String line) {
    final parts = line.split('|');
    final name = parts.isNotEmpty ? parts[0] : line;
    final configured = parts.length > 1 ? parts[1] == 'true' : false;
    return div(
      attributes: {
        'style': 'display:flex;gap:12px;padding:10px 14px;border-bottom:1px solid ${AdminColors.rowBorder};'
            'font-size:12.5px',
      },
      [
        span([Component.text(name)], attributes: {'style': 'width:160px;flex:none;color:${AdminColors.text}'}),
        span([Component.text(configured ? 'configured' : 'not configured')], attributes: {
          'style': 'color:${configured ? AdminColors.releasedFg : AdminColors.faint}',
        }),
      ],
    );
  }
}
