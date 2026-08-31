// automation_runs_page.dart — Phase 13d. `/errands/:errandId/runs`, one
// Errand's own execution history — reachable via the new "History" link
// on each row in errand_builder_page.dart's list.
//
// ── A DELIBERATELY SMALL SLICE OF THE EXPORT — READ BEFORE EXTENDING ──
//
// `Kola Automation Builder.dc.html` shows something this codebase
// cannot build yet: a chain of ordered steps ("Update stock" →
// "Notify the warehouse" → "Message the customer" → "Schedule
// delivery"), each optionally gated behind "Needs your approval", with
// a run history whose entries describe PER-STEP outcomes ("stopped at
// step 3, awaiting your approval", "failed at step 2: warehouse
// webhook timed out").
//
// Nothing in this codebase models that. Checked directly, not assumed
// stale from an older note:
//   - Errand (errand.spy.yaml) is ONE action — name, descriptionForAi,
//     a single builtinHandlerKey/webhook/db-credential fulfillment.
//     There is no concept of an Errand containing other Errands.
//   - ErrandExecutionLog (errand_execution_log.spy.yaml) is ONE
//     execution record of ONE Errand — success/errorMessage/latencyMs
//     for that single call. No step index, no per-step status, no
//     approval/hold state at all.
//
// Building the export faithfully would mean designing a genuinely new
// "Automation" entity above Errand — an ordered list of steps, a
// pause-for-approval state machine, a run record that tracks progress
// through that list. That is real, substantial, separate work, not a
// page-only gap — naming it here rather than faking a step list this
// codebase cannot actually execute.
//
// ── WHAT SHIPS HERE: THE PART THAT WAS ALREADY REAL ────────────────────
//
// One Errand's own run history, newest first, styled like the export's
// run list (colored status dot, timestamp, one-line summary) —
// backed by the new ErrandEndpoint.listExecutions (this pass), which
// itself just exposes ErrandExecutionLogRepository.listByErrand, a
// method that already existed and had no endpoint in front of it.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../theme.dart';

class AutomationRunsPage extends StatefulComponent {
  const AutomationRunsPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.errandId,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final int errandId;
  final FeatureGate gate;

  @override
  State<AutomationRunsPage> createState() => _AutomationRunsPageState();
}

class _AutomationRunsPageState extends State<AutomationRunsPage> {
  bool _loading = true;
  String? _error;
  Errand? _errand;
  List<ErrandExecutionLog> _runs = const [];

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
      final results = await Future.wait([
        component.client.errand.getErrand(
          component.accessToken,
          component.workspaceId,
          component.errandId,
        ),
        component.client.errand.listExecutions(
          component.accessToken,
          component.workspaceId,
          component.errandId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _errand = results[0] as Errand;
        _runs = results[1] as List<ErrandExecutionLog>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:760px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        _header(),
        if (_error != null) _errorBanner(),
        if (_loading) _skeleton() else ...[
          _whatItDoes(),
          _runHistory(),
        ],
      ],
    );
  }

  Component _header() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.lg}'},
        [
          h1(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h2};font-weight:700;'
                  'color:${KolaVar.text};margin:0 0 4px',
            },
            [Component.text('Run history')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
            },
            [
              Component.text(
                _errand == null
                    ? 'What actually happened, each time this Errand ran.'
                    : '${_errand!.name} — what actually happened, each time it ran.',
              ),
            ],
          ),
        ],
      );

  /// Stands in for the export's step chain, honestly — see this file's
  /// header. One Errand is one action, so this shows the one thing it
  /// does rather than an invented multi-step timeline.
  Component _whatItDoes() {
    final errand = _errand;
    if (errand == null) return const Component.text('');
    return div(
      attributes: {
        'style': 'background:${KolaVar.card};'
            'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:16px 20px;'
            'margin-bottom:${KolaSpace.lg}',
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};font-weight:600;'
                'color:${KolaVar.text};margin-bottom:4px',
          },
          [Component.text('What this Errand does')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.5',
          },
          [Component.text(errand.descriptionForAi)],
        ),
      ],
    );
  }

  Component _runHistory() {
    if (_runs.isEmpty) {
      return div(
        attributes: {
          'style': 'background:${KolaVar.card};'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};'
              'padding:${KolaSpace.xl} ${KolaSpace.lg};text-align:center',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                  'margin-bottom:6px;color:${KolaVar.text}',
            },
            [Component.text('No runs yet')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
            },
            [Component.text('This Errand hasn\'t executed yet.')],
          ),
        ],
      );
    }

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};overflow:hidden',
      },
      [for (final r in _runs) _runRow(r)],
    );
  }

  Component _runRow(ErrandExecutionLog r) => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:12px;'
              'padding:12px 16px;border-bottom:1px solid ${KolaVar.border}',
        },
        [
          span(
            attributes: {
              'style': 'width:7px;height:7px;flex:none;'
                  'border-radius:${KolaRadius.circle};'
                  'background:${r.success ? KolaVar.success : KolaVar.danger}',
            },
            [],
          ),
          span(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.micro};color:${KolaVar.muted};'
                  'width:110px;flex:none',
            },
            [Component.text(_time(r.executedAt))],
          ),
          span(
            attributes: {
              'style': 'flex:1;font-size:${KolaType.small};'
                  'color:${KolaVar.text};overflow:hidden;'
                  'text-overflow:ellipsis;white-space:nowrap',
            },
            [
              Component.text(
                r.success
                    ? 'Completed in ${r.latencyMs}ms'
                    : 'Failed: ${r.errorMessage ?? 'unknown error'}',
              ),
            ],
          ),
        ],
      );

  Component _skeleton() => div(
        attributes: {
          'style': 'display:flex;flex-direction:column;'
              'gap:${KolaSpace.sm}',
        },
        [
          for (var i = 0; i < 4; i++)
            div(
              attributes: {
                'style': 'height:48px;border-radius:${KolaRadius.md};'
                    'background:${KolaVar.card};'
                    'border:1px solid ${KolaVar.border};opacity:0.6',
              },
              [],
            ),
        ],
      );

  Component _errorBanner() => div(
        attributes: {
          'style': 'background:${KolaVar.dangerBg};'
              'border:1px solid ${KolaVar.danger};'
              'border-radius:${KolaRadius.md};padding:${KolaSpace.sm};'
              'color:${KolaVar.danger};font-size:${KolaType.small};'
              'margin-bottom:${KolaSpace.md}',
        },
        [Component.text(_error!)],
      );

  static String _time(DateTime d) {
    final local = d.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day} $h:$m';
  }
}
