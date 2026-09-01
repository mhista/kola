// recommendations_page.dart — Phase 13a. `/recommendations`, the second
// of two previously-404ing sidebar routes fixed in this pass — see
// observations_page.dart's header for the shared backstory (nav_model.dart
// always pointed here correctly, app.dart never registered the route,
// no page file existed).
//
// ── A REAL, NAMED SCOPE CUT — READ BEFORE EXTENDING THIS PAGE ─────────
//
// Kola Recommendations.dc.html (7.4 KB export) specifies something
// materially richer than what ships here today: each recommendation
// carries a `kind` ('executes' | 'advises'), an `impact` line, and —
// for 'executes' recommendations — a cost-to-send estimate and an
// "Approve & send" button that actually performs the action (the sample
// data shows kola sending a delivery-delay apology + credit to 14
// customers on approval).
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
// and belongs in its own pass — same reasoning DEVELOPMENT_PLAN.md's
// Phase 12 already gave for why the AI-reasoning layer over findings is
// a deliberately unfilled seam, not an oversight.
//
// What ships here instead, honestly: the same WorkspaceFinding data
// Observations reads (via FindingEndpoint.listFindings), sorted worst
// first, framed as "what to look at" rather than "what kola noticed" —
// every row renders as advice-only (no fabricated 'kola will do this'
// badge, no invented cost, no impact line that was never computed), with
// a single real action: dismiss. When the executable-recommendation
// backend above gets built, this page is where the 'executes' badge,
// cost line and Approve & send button belong — the seam is intentionally
// left where the export puts it (see _kindBadge below), not removed.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
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
            [for (final f in _findings) _card(f)],
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
              Component.text(
                "What's worth acting on, worst first. Advice today — kola doesn't act on your behalf yet.",
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
                'style': 'height:110px;border-radius:${KolaRadius.lg};'
                    'background:${KolaVar.card};'
                    'border:1px solid ${KolaVar.border};opacity:0.6',
              },
              [],
            ),
        ],
      );

  /// The export's own "Nothing to recommend yet" copy.
  Component _emptyState() => div(
        attributes: {
          'style': 'background:${KolaVar.card};'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};'
              'padding:${KolaSpace.xl} ${KolaSpace.lg};text-align:center',
        },
        [
          div(
            attributes: {'style': 'font-size:26px;margin-bottom:12px'},
            [Component.text('🌱')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                  'margin-bottom:8px;color:${KolaVar.text}',
            },
            [Component.text('Nothing to recommend yet')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
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
            // 14c: the export's confidence dot-meter + score, missing
            // here before this pass even though the data has carried a
            // real `confidence` field since migration 034 and
            // observations_page.dart already renders it — see this
            // file's own _confidenceDots/_confidenceLabel below, copied
            // from that page's identical shape rather than re-invented.
            _confidenceDots(f.confidence),
            _confidenceLabel(f.confidence),
            _severityLabel(f.severity),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
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
              Component.text('Reason: '),
              Component.text(f.detail!),
            ],
          ),
        // The export's "Expected impact" and "Cost to send" lines are
        // deliberately absent — neither is computed anywhere server-side
        // today. See this file's own header on why that is named here
        // rather than filled with a plausible-looking guess.
        div(
          attributes: {'style': 'display:flex;gap:8px;margin-top:12px'},
          [
            button(
              attributes: {
                'type': 'button',
                if (busy || id == null) 'disabled': '',
                'style': 'background:transparent;'
                    'border:1px solid ${KolaVar.border};'
                    'color:${KolaVar.mutedStrong};'
                    'border-radius:${KolaRadius.sm};padding:8px 14px;'
                    'font-size:${KolaType.small};font-family:inherit;'
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

  /// 14c. Same three-dot confidence indicator the export specifies —
  /// copied from observations_page.dart's identical helper rather than
  /// shared, since these are private State methods; kept in sync by
  /// eye until enough pages need it to justify pulling it into a
  /// components/ file.
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
  /// detector today) rather than a fake-precise "100% confident" — same
  /// wording observations_page.dart and overview_page.dart's
  /// _topRecommendation already settled on for the identical reason.
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

  Component _severityLabel(int severity) => span(
        attributes: {
          'style': 'font-size:${KolaType.tiny};'
              'color:${severity <= 1 ? KolaVar.danger : KolaVar.muted}',
        },
        [
          Component.text(
            severity <= 1
                ? 'High priority'
                : severity == 2
                    ? 'Medium priority'
                    : 'Low priority',
          ),
        ],
      );
}
