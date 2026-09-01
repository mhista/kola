// observations_page.dart — Phase 13a. `/observations`, the first of two
// previously-404ing sidebar routes fixed in this pass — nav_model.dart
// always pointed here correctly; app.dart simply never registered the
// route, and no page file existed anywhere in the dashboard. See
// docs/PHASE_13_HANDOFF.pdf and DEVELOPMENT_PLAN.md's Phase 13 for the
// full audit that found this.
//
// Built against Kola Observations.dc.html (7.1 KB export), state
// extracted per DESIGN_DELTA.md's method before writing any Dart:
// `mode` ('empty'|'full'), `open` (per-row evidence-expanded flags),
// `dismissed`. Data array `OBS`: headline, conf ('high'|'medium'|'low'),
// score, evidence (a list of strings).
//
// ── WHY THIS PAGE WAS CHEAP: THE BACKEND ALREADY EXISTS ──────────────
//
// docs/DESIGN_DELTA.md's coverage table marked Observations "❌ — R2/R3,
// need the event bus first." The event bus is now built (Phase 12), and
// so is the Observation Engine behind it: FindingEndpoint.listFindings /
// WorkspaceFinding, via WorkspaceSweepService. This page is a second,
// dedicated consumer of that same endpoint — overview_page.dart's
// _findingsList/_topRecommendation/_dismissFinding is the first, and was
// read directly as the working reference for the rendering/dismiss code
// below (same shapes, same dismissFinding call).
//
// ── ONE HONEST GAP: MULTI-LINE "EVIDENCE" ─────────────────────────────
//
// The export's `evidence` is a list of independent supporting facts per
// observation (e.g. two separate sentences). WorkspaceFinding stores one
// optional `detail` string per row, not a list — see that model's own
// header on why (rendered-at-sweep-time, stored, never re-derived). This
// page renders `detail` as a single-item evidence list when present, and
// hides the whole "Show evidence" affordance when it is null, rather
// than inventing a second bullet that was never computed.
//
// ── CONFIDENCE IS ALWAYS "HIGH" TODAY, AND THAT IS HONEST ─────────────
//
// Every detector in finding_kinds.dart is deterministic (confidence:
// 1.0) — see workspace_sweep_service.dart's own header on why a model is
// deliberately not consulted yet. So every row here reads as "counted,
// not guessed" rather than a percentage, mirroring the exact wording
// overview_page.dart already uses for the same reason — not because a
// medium/low reading is impossible, but because nothing in this codebase
// produces one yet. When a model-authored observation eventually lands
// with confidence < 1.0, this page already renders that band correctly.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/page_help_button.dart';
import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../theme.dart';

class ObservationsPage extends StatefulComponent {
  const ObservationsPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final FeatureGate gate;

  @override
  State<ObservationsPage> createState() => _ObservationsPageState();
}

class _ObservationsPageState extends State<ObservationsPage> {
  bool _loading = true;
  String? _error;
  List<WorkspaceFinding> _findings = const [];
  Set<int> _open = const {};
  Set<int> _dismissing = const {};

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
      final findings = await component.client.finding.listFindings(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _findings = findings;
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

  Future<void> _dismiss(WorkspaceFinding f) async {
    final id = f.id;
    if (id == null) return;
    setState(() => _dismissing = {..._dismissing, id});
    try {
      await component.client.finding.dismissFinding(
        component.accessToken,
        component.workspaceId,
        id,
      );
      if (!mounted) return;
      // Removed locally rather than reloaded — same reasoning
      // overview_page.dart's _dismissFinding already documents: a full
      // reload re-runs the sweep to learn one thing this already knows.
      setState(() {
        _findings = [for (final x in _findings) if (x.id != id) x];
        _dismissing = {..._dismissing}..remove(id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dismissing = {..._dismissing}..remove(id));
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:820px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        _header(),
        if (_error != null) _errorBanner(),
        if (_loading)
          _skeleton()
        else if (_findings.isEmpty)
          _emptyState()
        else
          div(
            attributes: {
              'style': 'display:flex;flex-direction:column;'
                  'gap:${KolaSpace.sm}',
            },
            [for (final f in _findings) _row(f)],
          ),
      ],
    );
  }

  Component _header() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.lg}'},
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:flex-start;'
                  'justify-content:space-between;gap:12px',
            },
            [
              h1(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};'
                      'font-size:${KolaType.h2};font-weight:700;'
                      'color:${KolaVar.text};margin:0 0 4px',
                },
                [Component.text('Observations')],
              ),
              const PageHelpButton(
                pageKey: 'observations',
                body: [
                  "What kolaa noticed on its own, from what it counted "
                      "— not advice, just what it saw. Unlike "
                      "Recommendations, there's nothing to send or "
                      "approve here.",
                  "Each finding shows a confidence score and a 'Show "
                      "evidence' link back to what it's based on. "
                      "Dismiss one with 'Not useful' if it isn't.",
                ],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
            },
            [
              Component.text(
                'What kolaa noticed on its own, from what it counted — not advice, just what it saw.',
              ),
            ],
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

  Component _skeleton() => div(
        attributes: {
          'style': 'display:flex;flex-direction:column;'
              'gap:${KolaSpace.sm}',
        },
        [
          for (var i = 0; i < 3; i++)
            div(
              attributes: {
                'style': 'height:92px;border-radius:${KolaRadius.lg};'
                    'background:${KolaVar.card};'
                    'border:1px solid ${KolaVar.border};opacity:0.6',
              },
              [],
            ),
        ],
      );

  /// "kola is still learning your business" — the export's own copy.
  /// Shown when the sweep genuinely found nothing, which for a brand new
  /// workspace is the expected first state, not a broken page.
  Component _emptyState() => div(
        attributes: {
          'style': 'background:${KolaVar.card};'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};'
              'padding:${KolaSpace.xl} ${KolaSpace.lg};text-align:center',
        },
        [
          div(
            attributes: {'style': 'font-size:28px;margin-bottom:14px'},
            [Component.text('🌱')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                  'margin-bottom:8px;color:${KolaVar.text}',
            },
            [Component.text('kolaa is still learning your business')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'max-width:420px;margin:0 auto;line-height:1.5',
            },
            [
              Component.text(
                "It takes a week or two of real activity before patterns are worth surfacing. Nothing to review yet — that's expected, not a problem.",
              ),
            ],
          ),
        ],
      );

  Component _row(WorkspaceFinding f) {
    final id = f.id;
    final isOpen = id != null && _open.contains(id);
    final busy = id != null && _dismissing.contains(id);
    final hasEvidence = f.detail != null && f.detail!.trim().isNotEmpty;

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};'
            'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:16px 18px;'
            'opacity:${busy ? '0.5' : '1'}',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:center;'
                'justify-content:space-between;margin-bottom:8px',
          },
          [
            div(
              attributes: {
                'style': 'display:flex;align-items:center;gap:8px',
              },
              [_confidenceDots(f.confidence), _confidenceLabel(f.confidence)],
            ),
            button(
              attributes: {
                'type': 'button',
                'aria-label': 'Not useful: ${f.title}',
                if (busy || id == null) 'disabled': '',
                'style': 'background:transparent;border:none;'
                    'color:${KolaVar.muted};font-size:${KolaType.tiny};'
                    'font-family:inherit;'
                    'cursor:${busy ? 'default' : 'pointer'}',
              },
              events: {
                'click': (_) {
                  if (!busy) _dismiss(f);
                },
              },
              [Component.text(busy ? 'Hiding…' : 'Not useful ✕')],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                'color:${KolaVar.text};line-height:1.4;margin-bottom:4px',
          },
          [Component.text(f.title)],
        ),
        if (hasEvidence)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'cursor:pointer;text-decoration:underline;'
                  'display:inline-block',
            },
            events: {
              'click': (_) {
                if (id == null) return;
                setState(() {
                  _open = isOpen
                      ? ({..._open}..remove(id))
                      : {..._open, id};
                });
              },
            },
            [Component.text(isOpen ? 'Hide evidence' : 'Show evidence')],
          ),
        if (hasEvidence && isOpen)
          div(
            attributes: {'style': 'margin-top:8px'},
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};'
                      'color:${KolaVar.text};background:${KolaVar.pill};'
                      'border-radius:${KolaRadius.sm};padding:9px 12px',
                },
                [Component.text(f.detail!)],
              ),
            ],
          ),
      ],
    );
  }

  /// Same three-dot confidence indicator shape the export specifies —
  /// green×3 for high, amber×2+dim for medium, red×1+dim×2 for low.
  Component _confidenceDots(double confidence) {
    final List<String> colors;
    if (confidence >= 0.8) {
      colors = [KolaVar.success, KolaVar.success, KolaVar.success];
    } else if (confidence >= 0.5) {
      colors = [KolaVar.warning, KolaVar.warning, KolaVar.border];
    } else {
      colors = [KolaVar.danger, KolaVar.border, KolaVar.border];
    }
    return div(
      attributes: {'style': 'display:flex;gap:3px'},
      [
        for (final c in colors)
          span(
            attributes: {
              'style': 'width:6px;height:6px;'
                  'border-radius:${KolaRadius.circle};background:$c',
            },
            [],
          ),
      ],
    );
  }

  /// "Counted, not guessed" for the deterministic 1.0 case (every
  /// detector today) rather than a fake-precise "100% confident" —
  /// same wording overview_page.dart's _topRecommendation already
  /// settled on for the identical reason.
  Component _confidenceLabel(double confidence) => span(
        attributes: {
          'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
        },
        [
          Component.text(
            confidence >= 1.0
                ? 'Counted, not guessed'
                : '${(confidence * 100).round()}% confident',
          ),
        ],
      );
}
