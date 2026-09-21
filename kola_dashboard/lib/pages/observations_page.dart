// observations_page.dart — Phase 13a, restyled Phase 15 (design-parity
// pass) against `Kola Observations.dc.html` read fresh, not from memory.
//
// Built against Kola Observations.dc.html. State extracted per
// DESIGN_DELTA.md's method before writing any Dart: `mode`
// ('empty'|'full'), `open` (per-row evidence-expanded flags), `dismissed`.
// Data array `OBS`: headline, conf ('high'|'medium'|'low'), score,
// evidence (a list of strings).
//
// ── WHY THIS PAGE WAS CHEAP: THE BACKEND ALREADY EXISTS ──────────────
//
// FindingEndpoint.listFindings / WorkspaceFinding, via
// WorkspaceSweepService, already carries everything this page needs.
// overview_page.dart's findings list is the first consumer of that same
// endpoint and was read directly as the working reference for the
// rendering/dismiss code below (same shapes, same dismissFinding call).
//
// ── ONE HONEST GAP: MULTI-LINE "EVIDENCE" ─────────────────────────────
//
// The export's `evidence` is a list of independent supporting facts per
// observation (e.g. two separate sentences). WorkspaceFinding stores one
// optional `detail` string per row, not a list — see that model's own
// header on why (rendered-at-sweep-time, stored, never re-derived).
// Rather than inventing a second bullet that was never computed, `detail`
// is split on its own real sentence boundaries (". ") into 1+ evidence
// boxes — a presentation choice, not new content: a one-sentence detail
// still renders as one box, and a multi-sentence one (several detectors,
// e.g. invoiceOverdue, genuinely write more than one sentence) renders as
// the export's own multi-box list, using nothing but text already
// computed server-side. The whole affordance hides when `detail` is
// null.
//
// ── CONFIDENCE IS ALWAYS "HIGH" TODAY, AND THAT IS HONEST ─────────────
//
// Every detector in finding_kinds.dart is deterministic (confidence:
// 1.0) — see workspace_sweep_service.dart's own header on why a model is
// deliberately not consulted yet. So every row here reads as "counted,
// not guessed" rather than a percentage, mirroring the exact wording
// overview_page.dart's _confidenceLabel already uses for the same
// reason — not because a medium/low reading is impossible, but because
// nothing in this codebase produces one yet. When a model-authored
// observation eventually lands with confidence < 1.0, this page already
// renders the export's own "{tier} confidence · {score}" shape correctly.
//
// ── HEADER LAYOUT: WHY THE TITLE READS AS CENTERED HERE ────────────────
//
// Re-read directly from the export before assuming this was a mistake to
// fix: `Kola Observations.dc.html` puts the "‹ Dashboard" link, the
// title, and the Day one/Populated toggle inside ONE flex row with
// `justify-content:space-between` — three children, not two. Recommendations'
// export instead puts its back-link on its OWN line above a separate
// title+toggle row. That is a real, deliberate structural difference
// between the two exports, not a copy-paste artifact — it is what makes
// this page's title visually sit between two flanking elements while
// Recommendations' title reads flush left. Reproduced here with real,
// functioning pieces rather than the export's design-tool-only toggle:
// the breadcrumb link on the left, PageHelpButton on the right (same
// "toggle becomes a real control, not a fake switch" rule DESIGN_DELTA.md
// already applies to the Overview `age` toggle), title in the middle.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
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
    required this.workspaceCreatedAt,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final FeatureGate gate;

  /// Same signal intelligence_page.dart's Customer Satisfaction card
  /// already threads through from app.dart at this call site — workspace
  /// age is real, already in hand, and is what backs the empty state's
  /// progress dots below rather than a hardcoded "day 3 of 7" copied
  /// from the export's own static preview data.
  final DateTime workspaceCreatedAt;

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
                  'gap:${KolaSpace.md}',
            },
            [for (final f in _findings) _row(f)],
          ),
      ],
    );
  }

  /// See this file's header on why the breadcrumb, title and help button
  /// share one space-between row here rather than the breadcrumb sitting
  /// on its own line the way recommendations_page.dart's does.
  Component _header() => div(
        attributes: {
          'style': 'display:flex;align-items:center;'
              'justify-content:space-between;gap:12px;'
              'margin-bottom:${KolaSpace.xxl}',
        },
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:center;gap:6px;'
                  'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'flex:1',
            },
            [
              Link(
                to: '/',
                attributes: {
                  'style': 'color:${KolaVar.muted};text-decoration:none',
                },
                children: [Component.text('Dashboard')],
              ),
              span([Component.text('/')]),
              span(
                attributes: {'style': 'color:${KolaVar.mutedStrong}'},
                [Component.text('Observations')],
              ),
            ],
          ),
          h1(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h2};font-weight:700;'
                  'color:${KolaVar.text};margin:0;text-align:center;'
                  'white-space:nowrap',
            },
            [Component.text('Observations')],
          ),
          div(
            attributes: {
              'style': 'flex:1;display:flex;justify-content:flex-end',
            },
            [
              const PageHelpButton(
                pageKey: 'observations',
                body: [
                  "What kola noticed on its own, from what it counted "
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
              'gap:${KolaSpace.md}',
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

  /// "kola is still learning your business" — the export's own copy,
  /// including its progress-dot strip and "See what kola already knows"
  /// link to Knowledge, both now built rather than omitted. The dots
  /// were the export's own static demo data (`[1,1,1,0,0,0,0]`, a
  /// hardcoded "day 3"); rendered here from the real
  /// `workspaceCreatedAt` signal instead, so a workspace that is
  /// genuinely on day 1 shows one filled dot, not three.
  Component _emptyState() {
    final daysOld = DateTime.now().difference(component.workspaceCreatedAt).inDays;
    final filled = daysOld.clamp(0, 7);
    return div(
      attributes: {
        'style': 'background:${KolaVar.card};'
            'border:1px dashed ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};'
            'padding:${KolaSpace.xxxl} ${KolaSpace.xl};text-align:center',
      },
      [
        div(
          attributes: {'style': 'font-size:28px;margin-bottom:14px'},
          [Component.text('🌱')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.subhead};font-weight:600;'
                'margin-bottom:8px;color:${KolaVar.text}',
          },
          [Component.text('kola is still learning your business')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                'max-width:420px;margin:0 auto 20px;line-height:1.5',
          },
          [
            Component.text(
              "It takes a week or two of conversations before patterns are worth surfacing. Nothing to review yet — that's expected, not a problem.",
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'display:flex;gap:6px;justify-content:center;'
                'margin-bottom:20px',
          },
          [
            for (var i = 0; i < 7; i++)
              span(
                attributes: {
                  'style': 'width:22px;height:5px;'
                      'border-radius:${KolaRadius.pill};'
                      'background:${i < filled ? KolaVar.accent : KolaVar.border}',
                },
                [],
              ),
          ],
        ),
        Link(
          to: '/knowledge',
          attributes: {
            'style': 'background:transparent;'
                'border:1px solid ${KolaVar.border};color:${KolaVar.text};'
                'border-radius:${KolaRadius.pill};padding:9px 18px;'
                'font-size:${KolaType.small};text-decoration:none;'
                'display:inline-block',
          },
          children: [Component.text('See what kola already knows →')],
        ),
      ],
    );
  }

  Component _row(WorkspaceFinding f) {
    final id = f.id;
    final isOpen = id != null && _open.contains(id);
    final busy = id != null && _dismissing.contains(id);
    final evidence = _evidenceFor(f.detail);
    final hasEvidence = evidence.isNotEmpty;

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
            'style': 'font-size:${KolaType.uiLg};font-weight:600;'
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
            attributes: {
              'style': 'margin-top:8px;display:flex;'
                  'flex-direction:column;gap:6px',
            },
            [
              for (final ev in evidence)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.small};'
                        'color:${KolaVar.mutedStrong};'
                        'background:${KolaVar.bg};'
                        'border-radius:${KolaRadius.sm};padding:9px 12px',
                  },
                  [Component.text(ev)],
                ),
            ],
          ),
      ],
    );
  }

  /// Splits a real `detail` string on its own sentence boundaries so a
  /// detail that already carries more than one fact (several detectors
  /// do — see this file's header) renders as the export's own multi-box
  /// evidence list instead of one long paragraph in a single box. Never
  /// invents a second sentence: a one-sentence detail returns exactly
  /// one item, and a null/blank detail returns none.
  List<String> _evidenceFor(String? detail) {
    if (detail == null) return const [];
    final trimmed = detail.trim();
    if (trimmed.isEmpty) return const [];
    return trimmed
        .split('. ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.endsWith('.') ? s : '$s.')
        .toList();
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

  /// The export's own copy shape is "{tier} confidence · {score}" (e.g.
  /// "Medium confidence · 0.62"). Every finding this codebase detects
  /// today is counted rather than judged — confidence is always exactly
  /// 1.0 — and printing a tier name over a manufactured-looking score for
  /// a deterministic count is the "dressing certainty up" this codebase
  /// has already decided against elsewhere (overview_page.dart's own
  /// _confidenceLabel makes the identical call). So 1.0 keeps the honest
  /// "Counted, not guessed" wording; anything less (a future, genuinely
  /// probabilistic detector) renders the design's own tier-plus-score
  /// shape, which is accurate once confidence is real.
  Component _confidenceLabel(double confidence) => span(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
        },
        [Component.text(_confidenceText(confidence))],
      );

  String _confidenceText(double confidence) {
    if (confidence >= 1.0) return 'Counted, not guessed';
    final tier = confidence >= 0.8
        ? 'High'
        : confidence >= 0.5
            ? 'Medium'
            : 'Low';
    return '$tier confidence · ${confidence.toStringAsFixed(2)}';
  }
}
