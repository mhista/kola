// recommendations_page.dart — Phase 13a, restyled Phase 15 (design-parity
// pass) against `Kola Recommendations.dc.html` read fresh, not from memory.
//
// ── A REAL, NAMED SCOPE CUT — READ BEFORE EXTENDING THIS PAGE ─────────
//
// Kola Recommendations.dc.html specifies something materially richer than
// what ships here today: each recommendation carries a `kind` ('executes'
// | 'advises'), an `impact` line, and — for 'executes' recommendations —
// a cost-to-send estimate and an "Approve & send" button that actually
// performs the action (the sample data shows kola sending a
// delivery-delay apology + credit to 14 customers on approval).
//
// Re-verified 2026-09-10, not assumed stale: `WorkspaceFinding` (the only
// model backing this page — `kola_server/lib/src/generated/workspace_finding
// .dart`) still has no `kind`-as-executes-vs-advises field (its own `kind`
// is the detector name, e.g. `productLowStock`, `ticketOverdue` — see
// `finding_kinds.dart` — a different axis entirely), no `impact` field, no
// `cost` field, and `FindingEndpoint` still exposes only `listFindings` /
// `dismissFinding` — no defer, no reject, no approve-and-execute. This
// matches DEVELOPMENT_PLAN.md's Phase 13a note verbatim: the gap is
// real, documented there before this pass, and still open now — nothing
// in the codebase closed it in between.
//
// docs/DESIGN_DELTA.md's own rule is explicit: "there is no endpoint
// yet" is not a valid reason to cut a design's scope — that is a work
// item. This page does not violate that rule by omission; it names the
// item instead of quietly building a smaller thing and calling it done.
// The 'executes' concept needs a real backend that does not exist
// anywhere in this codebase yet: an executable-recommendation model, a
// stored approve/defer/reject state distinct from WorkspaceFinding's
// plain dismissedAt, a cost-estimation step, and something that actually
// performs the approved action (send a message, apply a credit). That
// is a genuinely separate, larger piece of work than "wire up a page,"
// and belongs in its own pass.
//
// What ships here instead, honestly: the same WorkspaceFinding data
// Observations reads (via FindingEndpoint.listFindings), sorted worst
// first, every row rendered as advice-only (no fabricated 'kola will do
// this' badge, no invented cost, no impact line that was never computed,
// no Defer/Reject buttons pretending to be distinct backend states when
// only one dismiss action exists) — with a single real action: dismiss,
// labelled "Mark done" per the export's own `advises` action label. When
// the executable-recommendation backend above gets built, this page is
// where the 'executes' badge, cost line, impact line, and Defer/Reject/
// Approve & send buttons belong — the seam is intentionally left where
// the export puts it (see _kindBadge and the button row below), not
// removed.
//
// ── HEADER LAYOUT ──────────────────────────────────────────────────────
//
// The export's own "‹ Dashboard" link points at an isolated per-page
// preview file with no persistent chrome around it. This app's shell
// always keeps the sidebar nav on screen, so a literal back-arrow reads
// as redundant rather than orienting. Same adaptation timeline_page.dart
// already made and the owner has already seen: a small "Dashboard /
// Recommendations" breadcrumb, real `Link` to `/`, on its own line above
// the title — not the arrow glyph, not a fake extra nav layer.
//
// The export's top-right "Empty / Populated" toggle is a design-tool
// preview control (it lets the designer flip between the two states on
// one static page) — same category as the Overview export's `age`
// toggle, which DESIGN_DELTA.md is explicit is "a design-tool control,
// not a feature" and must become real loading/empty/populated states
// instead of a switch a real owner could click. This page already does
// that (skeleton while loading, the export's own empty-state copy when
// there is nothing, the list otherwise) — no manual switch is added.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/page_help_button.dart';
import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../theme.dart';

class RecommendationsPage extends StatefulComponent {
  const RecommendationsPage({
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
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  bool _loading = true;
  String? _error;
  List<WorkspaceFinding> _findings = const [];
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
        // Worst first — same ordering rule overview_page.dart's
        // _topRecommendation relies on the server already applying, made
        // explicit here since this page has no single "top" card to lean
        // on the server's default order for.
        _findings = [...findings]
          ..sort((a, b) => a.severity.compareTo(b.severity));
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
        _breadcrumb(),
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
                  'gap:${KolaSpace.lmd}',
            },
            [for (final f in _findings) _card(f)],
          ),
      ],
    );
  }

  /// "Dashboard / Recommendations" — same adaptation of the export's
  /// "‹ Dashboard" link that timeline_page.dart's own `_breadcrumb`
  /// already made for this persistent-shell app; copied for consistency
  /// rather than re-invented.
  Component _breadcrumb() => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:6px;'
              'font-size:${KolaType.small};color:${KolaVar.muted};'
              'margin-bottom:${KolaSpace.smd}',
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
            [Component.text('Recommendations')],
          ),
        ],
      );

  Component _header() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.xxl}'},
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
                [Component.text('Recommendations')],
              ),
              const PageHelpButton(
                pageKey: 'recommendations',
                body: [
                  "What's worth acting on, worst first — sales and "
                      "growth opportunities kola has spotted. Every one "
                      "is advice only today: kola doesn't send or "
                      "execute anything on your behalf yet, so the "
                      "action is always yours to take.",
                  "Use 'Mark done' on a card once you've acted on it "
                      "elsewhere — kola doesn't send or execute anything "
                      "itself yet, so there's nothing to approve or "
                      "reject here, only to note as handled.",
                ],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
            },
            [
              // The export's own subtitle — "Some kola can do itself
              // once you approve. Some are advice. They never look the
              // same." — describes the two-kind split named in this
              // file's header, which has no backend yet. Printing it
              // verbatim would tell a real owner deciding whether to
              // trust this page that kola can already act for them,
              // which is false today: see the header comment on why
              // that crosses from "simplification" into the one thing
              // that outranks matching the design, a false statement of
              // present capability. This line stays honest instead.
              Component.text(
                "What's worth acting on, worst first. Every one is "
                    'advice today — kola doesn\'t act on your behalf '
                    'yet, so the action is always yours.',
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
              'gap:${KolaSpace.lmd}',
        },
        [
          for (var i = 0; i < 3; i++)
            div(
              attributes: {
                'style': 'height:110px;border-radius:${KolaRadius.lg};'
                    'background:${KolaVar.card};'
                    'border:1px solid ${KolaVar.border};opacity:0.6',
              },
              [],
            ),
        ],
      );

  /// The export's own "Nothing to recommend yet" copy, verbatim.
  Component _emptyState() => div(
        attributes: {
          'style': 'background:${KolaVar.card};'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};'
              'padding:${KolaSpace.xxxl} ${KolaSpace.xl};text-align:center',
        },
        [
          div(
            attributes: {'style': 'font-size:26px;margin-bottom:12px'},
            [Component.text('🌱')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'margin-bottom:8px;color:${KolaVar.text}',
            },
            [Component.text('Nothing to recommend yet')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'max-width:380px;margin:0 auto;line-height:1.5',
            },
            [
              Component.text(
                "Recommendations show up once there's enough activity to spot a pattern worth acting on.",
              ),
            ],
          ),
        ],
      );

  Component _card(WorkspaceFinding f) {
    final id = f.id;
    final busy = id != null && _dismissing.contains(id);
    final hasDetail = f.detail != null && f.detail!.trim().isNotEmpty;

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};'
            'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:18px 20px;'
            'opacity:${busy ? '0.5' : '1'}',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:10px;'
                'margin-bottom:10px',
          },
          [
            _kindBadge(),
            _confidenceDots(f.confidence),
            _confidenceScore(f.confidence),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.lead};font-weight:600;'
                'margin-bottom:6px;color:${KolaVar.text}',
          },
          [Component.text(f.title)],
        ),
        if (hasDetail)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.5;margin-bottom:8px',
            },
            [
              span(
                attributes: {
                  'style': 'color:${KolaVar.mutedStrong};font-weight:600',
                },
                [Component.text('Reason: ')],
              ),
              Component.text(f.detail!),
            ],
          ),
        // The export's "Expected impact" line and, for 'executes' rows,
        // its "Cost to send" box are deliberately absent — neither
        // `impact` nor `cost` is computed anywhere server-side today
        // (re-checked against WorkspaceFinding directly this pass, not
        // assumed). See this file's header for the full reasoning.
        div(
          attributes: {'style': 'display:flex;gap:8px;margin-top:12px'},
          [
            // The export's row is Defer / Reject / actionLabel — three
            // buttons backed by three distinct stored states. Only one
            // exists here (`WorkspaceFinding.dismissedAt`), so only one
            // button is real. Rendering Defer and Reject beside it would
            // imply two more real, distinct outcomes that do not exist
            // yet — the same "don't fake the branch" rule this file's
            // header already applies to the kind badge and cost box.
            button(
              attributes: {
                'type': 'button',
                if (busy || id == null) 'disabled': '',
                'style': 'background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};border:none;'
                    'border-radius:${KolaRadius.sm};padding:8px 18px;'
                    'font-size:${KolaType.small};font-weight:600;'
                    'font-family:inherit;'
                    'cursor:${busy ? 'default' : 'pointer'}',
              },
              events: {
                'click': (_) {
                  if (!busy) _dismiss(f);
                },
              },
              [Component.text(busy ? 'Marking done…' : 'Mark done')],
            ),
          ],
        ),
      ],
    );
  }

  /// Always "advice only" today — see this file's header. Left as a
  /// standalone helper (rather than inlined) precisely so the future
  /// 'executes' branch has an obvious place to go without restructuring
  /// the card.
  Component _kindBadge() => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:6px;'
              'background:${KolaVar.pill};border-radius:${KolaRadius.pill};'
              'padding:4px 10px',
        },
        [
          span(
            attributes: {
              'style': 'width:6px;height:6px;'
                  'border-radius:${KolaRadius.circle};'
                  'background:${KolaVar.muted}',
            },
            [],
          ),
          span(
            attributes: {
              'style': 'font-size:${KolaType.tiny};font-weight:600;'
                  'color:${KolaVar.muted}',
            },
            [Component.text('advice only')],
          ),
        ],
      );

  /// The export's own three-dot confidence meter — copied from
  /// observations_page.dart's identical helper rather than shared, since
  /// these are private State methods; kept in sync by eye until enough
  /// pages need it to justify pulling it into a components/ file.
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

  /// The export's score slot is a bare number (`{{ r.score }}`, no
  /// "% confident" suffix, no tier word — unlike Observations' own
  /// "{tier} confidence · {score}" shape). Every detector today is
  /// deterministic (confidence 1.0), and printing a manufactured-looking
  /// "1.00" for a plain counted fact is the "dressing certainty up" this
  /// codebase has already decided against — same reasoning
  /// overview_page.dart's _confidenceLabel and observations_page.dart's
  /// own copy already document. So 1.0 keeps "Counted, not guessed";
  /// anything less (a future, genuinely probabilistic detector) prints
  /// the export's own bare-score shape, which is accurate once
  /// confidence is real.
  Component _confidenceScore(double confidence) => span(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
        },
        [
          Component.text(
            confidence >= 1.0
                ? 'Counted, not guessed'
                : confidence.toStringAsFixed(2),
          ),
        ],
      );
}
