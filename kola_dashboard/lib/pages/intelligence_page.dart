// intelligence_page.dart — Phase 14g, rebuilt Phase 14/186 against
// `Kola Business Intelligence.dc.html` (the design export) after the
// owner sent real screenshots of the authoritative UI and asked for an
// exact match. nav_model.dart has pointed here since Phase 13e (gated on
// `Features.businessIntelligence`) — see PHASE_14_HANDOFF.pdf's 14g
// section for the grep that first confirmed the route existed with no
// page behind it, and analytics_endpoint.dart's own header for why
// Phase 13e deliberately scoped this page out — it needed a real
// AI-reasoning layer this codebase didn't have yet.
// intelligence_endpoint.dart / intelligence_narrative_service.dart are
// that layer.
//
// ── WHAT THIS PAGE COMPOSES FROM, AND WHY ──────────────────────────────
//
// Three real fetches, in parallel:
//   1. IntelligenceEndpoint.getIntelligence — the narrative paragraph,
//      revenue total + delta, top products (now including a real
//      Velocity classification — see below), orders-by-weekday, and the
//      correlation callout.
//   2. AnalyticsEndpoint.getSummary — the day-by-day revenue chart AND
//      (Phase 14/186) the channel segments used for "On WhatsApp — N%
//      of conversations" below. Already real, already built (Phase
//      13e) — reused rather than recomputing the same aggregation twice.
//   3. CustomerEndpoint.listCustomersWithSummary — backs the real
//      Repeat/First-time revenue split in the Customer segments card.
//
// ── PHASE 14/186 — REBUILT AGAINST THE EXPORT, NOT AGAINST THE OLD PAGE ─
//
// DESIGN_DELTA.md's own post-mortem: the export is the specification,
// consulted first: extract its `state`/data shape, build to THAT list,
// consult the old page only to salvage working logic. Salvaged from the
// old page: the real correlation callout, the real orders-by-weekday
// chart, the honest Customer Satisfaction empty state, and the dynamic
// (never-fabricated) "What this suggests" deep-links. Corrected against
// the export:
//
//   • Title was "Intelligence" — the export says "Business Intelligence".
//   • Subtitle was invented copy — now the export's own line verbatim.
//   • The old page had NO back-link at all. The export's own "‹
//     Dashboard" points at an isolated per-page preview file with no
//     persistent chrome; this app always keeps the sidebar nav on
//     screen, so — same adaptation recommendations_page.dart and
//     timeline_page.dart already made — a "Dashboard / Business
//     Intelligence" breadcrumb replaces the arrow, not a fake extra nav
//     layer.
//   • Period toggle was labelled "7d/30d/90d" — the export says
//     Week/Month/Quarter. Same three real values underneath
//     (_periodDays 7/30/90), relabelled to match.
//   • The old page had a standalone "WHAT THIS SUGGESTS" narrative-
//     paragraph card above the revenue chart. The export has no such
//     card — instead every chart gets ITS OWN one-line caption (see the
//     subtitle: "a sentence next to every chart, not just the chart").
//     [intel.narrative] — the one real synthesized paragraph this
//     endpoint produces — is now that caption on the Revenue card,
//     which is exactly what it already describes (revenue + top
//     products), rather than a seventh card the export doesn't have.
//   • "Response time" was skipped outright. Re-checked against
//     DESIGN_DELTA.md: a missing endpoint is a work item to name, not a
//     license to drop a card from the layout. Still genuinely no
//     first-response-time computation anywhere in this codebase
//     (grepped again this pass: responseTime/avgResponse/firstResponse
//     — zero matches; intelligence_endpoint.dart's own header carries
//     the same note). So it renders now, honestly, as a "not measured
//     yet" card in the export's own row-1 position — the same posture
//     the Customer Satisfaction card already uses, per the export's own
//     precedent, rather than a fabricated "6m / −40%".
//   • Top products was missing the Velocity column and showed Revenue
//     instead of Margin. intelligence_endpoint.dart now computes a real
//     velocity classification from Product.stock + this period's sales
//     rate + WorkspaceFinding's real out-of-stock duration (see that
//     file's own header) — genuinely buildable, so built, per
//     DESIGN_DELTA.md's central rule. Revenue column dropped (the
//     export doesn't show it either); Margin now shows the real naira
//     amount, not just a percentage.
//   • Customer segments showed "Top / New / Everyone else" — a real
//     but DIFFERENT card than the export specifies. The export's three
//     rows are Repeat customers / First-time customers / On WhatsApp,
//     all "% of revenue" or "% of conversations". Rebuilt against real
//     data: repeat/first-time is a lifetime orderCount>=2 vs ==1 split
//     of CustomerSummary.ltvMinor (already fetched); "On WhatsApp" is
//     AnalyticsSegment.conversations, already computed server-side.
//     Dropped the export's own unverifiable "...and it's growing" from
//     the caption — there is no period-over-period comparison behind
//     that claim, and asserting a trend with nothing to back it is the
//     exact mistake this file's honesty rules exist to prevent.
//   • The correlation banner was tinted with the WARNING (amber)
//     tokens. The export's callout is a green-tinted banner. Recoloured
//     to the design system's success tokens.
//   • Added a real top-level empty state ("Business Intelligence needs
//     a few weeks of activity...", the export's own copy) for a
//     workspace with genuinely no revenue/orders/products yet — the
//     "never show a wall of zero cards" rule DESIGN_DELTA.md names
//     elsewhere, applied here for the first time on this page.
//   • The export's Day-1/Week-1/Month-6-style Empty/Populated toggle is
//     a design-tool preview control, not a product feature (see
//     DESIGN_DELTA.md's Overview note on the identical `age` toggle) —
//     not built. The real equivalent is the empty state above, driven
//     by real data rather than a switch.
//
// ── ONE GAP STILL NAMED, NOT SHIPPED ─────────────────────────────────────
//
// "Response time" has no real number behind it anywhere in this
// codebase — see above. Computing one is a real, separate aggregation
// over Message timestamps, out of this pass's scope.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/page_help_button.dart';
import '../services/error_text.dart';
import '../services/feature_gate.dart';
import '../services/money_format.dart';
import '../services/responsive.dart';
import '../theme.dart';

class IntelligencePage extends StatefulComponent {
  const IntelligencePage({
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

  /// The Customer Satisfaction card's real signal (see this file's
  /// header). Passed in rather than fetched: app.dart already holds the
  /// selected Workspace in full, same "caller already has it in hand"
  /// reasoning overview_page.dart's own `sellsCatalogItems` doc comment
  /// gives.
  final DateTime workspaceCreatedAt;

  @override
  State<IntelligencePage> createState() => _IntelligencePageState();
}

class _IntelligencePageState extends State<IntelligencePage>
    with ResponsiveViewport<IntelligencePage> {
  bool _loading = true;
  String? _error;
  int _periodDays = 30;

  IntelligenceSummary? _intelligence;
  AnalyticsSummary? _analytics;
  List<CustomerSummary> _customers = const [];

  @override
  void initState() {
    super.initState();
    initResponsive();
    _load();
  }

  @override
  void dispose() {
    disposeResponsive();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        component.client.intelligence.getIntelligence(
          component.accessToken,
          component.workspaceId,
          periodDays: _periodDays,
        ),
        component.client.analytics.getSummary(
          component.accessToken,
          component.workspaceId,
          periodDays: _periodDays,
        ),
        component.gate.isEnabled(Features.customers)
            ? component.client.customer.listCustomersWithSummary(
                component.accessToken,
                component.workspaceId,
                limit: 500,
              )
            : Future.value(const <CustomerSummary>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _intelligence = results[0] as IntelligenceSummary;
        _analytics = results[1] as AnalyticsSummary;
        _customers = results[2] as List<CustomerSummary>;
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

  void _setPeriod(int days) {
    if (days == _periodDays) return;
    setState(() => _periodDays = days);
    _load();
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:1180px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        _breadcrumb(),
        _header(),
        if (_error != null) _errorBanner(),
        if (_loading)
          _skeleton()
        else if (_error != null && _intelligence == null)
          _errorRetryState()
        else
          ..._content(),
      ],
    );
  }

  /// 2026-09-14 fix: a failed fetch used to fall straight into
  /// [_content], which reads a null [_intelligence] as "genuinely no
  /// data yet" and rendered [_emptyStateCard] — the honest empty state
  /// meant for a brand-new workspace — directly underneath the error
  /// banner above. A real failure and "not enough data yet" are
  /// different situations with different fixes (retry vs. wait), so
  /// they need different states. This one only shows when the fetch
  /// actually failed AND left nothing to display; a failed *reload*
  /// (period switch) that still has a previous [_intelligence] falls
  /// through to [_content] instead, so the page keeps showing the last
  /// good data under the error banner rather than blanking out.
  Component _errorRetryState() => div(
        attributes: {
          'style': 'text-align:center;padding:48px 20px;'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:8px',
            },
            [Component.text("Couldn't load Business Intelligence")],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'max-width:380px;margin:0 auto 16px',
            },
            [
              Component.text(
                'The numbers above failed to load — this is not the same '
                "as having no data yet. Try again once it's likely to "
                'work.',
              ),
            ],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'padding:9px 18px;border-radius:${KolaRadius.sm};'
                  'border:none;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.body};font-weight:600;'
                  'cursor:pointer',
            },
            events: {'click': (_) => _load()},
            [Component.text('Try again')],
          ),
        ],
      );

  /// "Dashboard / Business Intelligence" — same adaptation of the
  /// export's "‹ Dashboard" link that recommendations_page.dart and
  /// timeline_page.dart already made for this persistent-shell app;
  /// copied for consistency rather than re-invented. See this file's
  /// header.
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
            [Component.text('Business Intelligence')],
          ),
        ],
      );

  Component _header() => div(
        attributes: {
          'style': 'display:flex;align-items:flex-start;'
              'justify-content:space-between;gap:12px;flex-wrap:wrap;'
              'margin-bottom:${KolaSpace.md}',
        },
        [
          div(
            [
              h1(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};'
                      'font-size:${KolaType.h2};font-weight:700;'
                      'color:${KolaVar.text};margin:0 0 4px',
                },
                [Component.text('Business Intelligence')],
              ),
              div(
                attributes: {
                  'style':
                      'font-size:${KolaType.small};color:${KolaVar.muted}',
                },
                [
                  Component.text(
                    'How the business is doing, and why — a sentence next '
                    'to every chart, not just the chart.',
                  ),
                ],
              ),
            ],
          ),
          div(
            attributes: {'style': 'display:flex;align-items:center;gap:10px'},
            [
              _periodChips(),
              const PageHelpButton(
                pageKey: 'intelligence',
                body: [
                  "A narrative summary of the numbers below — written by "
                      "kola from real, computed figures, never invented "
                      "ones. If every AI provider is unavailable, the "
                      "summary switches to a plain templated sentence "
                      "built from the same numbers, labeled as such.",
                  "Top products are ranked by revenue for the period; "
                      "margin shows 'cost not set' for any product "
                      "without a cost price on its catalog entry. "
                      "Velocity compares current stock to this period's "
                      "sell-through rate — blank for anything not "
                      "stock-tracked, like a service.",
                  "'Correlation spotted' only appears when kola finds a "
                      "real link between a revenue drop and a rise in "
                      "escalated conversations — it stays quiet on a "
                      "flat week rather than reaching for a finding. "
                      "Response time and customer satisfaction show an "
                      "honest 'not measured yet' state instead of a "
                      "number until there's real data to trust.",
                ],
              ),
            ],
          ),
        ],
      );

  static const _periodLabels = {7: 'Week', 30: 'Month', 90: 'Quarter'};

  Component _periodChips() => div(
        attributes: {'style': 'display:flex;gap:6px'},
        [
          for (final days in [7, 30, 90]) _periodChip(days),
        ],
      );

  Component _periodChip(int days) {
    final active = days == _periodDays;
    return button(
      attributes: {
        'type': 'button',
        'style': 'background:${active ? KolaVar.accentFill : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.mutedStrong};'
            'border:1px solid ${active ? KolaVar.accentFill : KolaVar.border};'
            'border-radius:${KolaRadius.pill};padding:7px 14px;'
            'font-size:${KolaType.small};font-family:inherit;'
            'font-weight:600;cursor:pointer',
      },
      events: {'click': (_) => _setPeriod(days)},
      [Component.text(_periodLabels[days] ?? '${days}d')],
    );
  }

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
          'style': 'display:flex;flex-direction:column;gap:${KolaSpace.lg}',
        },
        [
          for (var i = 0; i < 3; i++)
            div(
              attributes: {
                'style': 'height:120px;border-radius:${KolaRadius.lg};'
                    'background:${KolaVar.card};'
                    'border:1px solid ${KolaVar.border};opacity:0.6',
              },
              [],
            ),
        ],
      );

  /// The export's own "Not enough data yet" empty state (`isEmptyView`),
  /// but driven by real computed emptiness rather than the design-tool
  /// toggle — see this file's header. True only when there is
  /// genuinely nothing to show a story about yet.
  bool get _hasAnyActivity {
    final intel = _intelligence;
    final analytics = _analytics;
    if (intel == null) return false;
    if (intel.revenueMinor > 0) return true;
    if (intel.topProducts.isNotEmpty) return true;
    if (intel.ordersByWeekday.any((c) => c > 0)) return true;
    if (analytics != null && analytics.dailyRevenue.any((p) => p.grossMinor > 0)) {
      return true;
    }
    return false;
  }

  List<Component> _content() {
    if (!_hasAnyActivity) return [_emptyStateCard()];
    return [
      _correlationCard(),
      _rowGrid([_revenueCard(), _responseTimeCard()], columns: '1.4fr 1fr'),
      _rowGrid([_ordersByDayChart(), _satisfactionCard()]),
      _rowGrid(
        [_topProductsTable(), _customerSegmentsCard()],
        columns: '1.3fr 1fr',
      ),
      _suggestions(),
    ];
  }

  Component _emptyStateCard() => div(
        attributes: {
          'style': 'text-align:center;padding:48px 20px;'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg}',
        },
        [
          div(
            attributes: {'style': 'font-size:26px;margin-bottom:12px'},
            [Component.text('🌱')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:8px',
            },
            [Component.text('Not enough data yet')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'max-width:380px;margin:0 auto',
            },
            [
              Component.text(
                'Business Intelligence needs a few weeks of activity '
                'before its story is worth telling.',
              ),
            ],
          ),
        ],
      );

  /// A two-card row, matching the export's `grid-template-columns`.
  /// Collapses to one column on mobile via the shared
  /// [ResponsiveViewport] helper rather than a hand-rolled check (task
  /// #32) — the export's own Customers page does the same collapse for
  /// the identical reason.
  Component _rowGrid(List<Component> cards, {String columns = '1fr 1fr'}) => div(
        attributes: {
          'style': 'display:grid;'
              'grid-template-columns:${isMobile ? '1fr' : columns};'
              'gap:16px;margin-bottom:${KolaSpace.lg}',
        },
        cards,
      );

  /// Phase 14/186 — the un-deferred "Correlation spotted" callout, now
  /// tinted with the design system's SUCCESS tokens (the export's own
  /// banner is green, not amber — see this file's header). Only
  /// intelligence_endpoint.dart decides whether there's something real
  /// to say; this renders nothing at all when it found nothing, same as
  /// every other "absence over fabrication" card on this page.
  Component _correlationCard() {
    final callout = _intelligence?.correlationCallout;
    if (callout == null) return const Component.text('');
    return div(
      attributes: {
        'style': 'background:${KolaVar.successBg};'
            'border:1px solid ${KolaVar.success};'
            'border-radius:${KolaRadius.lg};padding:16px 20px;'
            'margin-bottom:${KolaSpace.lg};display:flex;'
            'align-items:baseline;gap:10px;flex-wrap:wrap;'
            'justify-content:space-between',
      },
      [
        div(
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};font-weight:700;'
                    'color:${KolaVar.successBright};letter-spacing:0.02em;'
                    'margin-bottom:4px',
              },
              [Component.text('CORRELATION SPOTTED')],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.successBright};'
                    'line-height:1.5',
              },
              [Component.text(callout)],
            ),
          ],
        ),
        Link(
          to: '/timeline',
          attributes: {
            'style': 'background:${KolaVar.success};'
                'color:${KolaVar.accentText};font-size:${KolaType.small};'
                'font-weight:600;text-decoration:none;flex:none;'
                'border-radius:${KolaRadius.pill};padding:8px 16px;'
                'white-space:nowrap',
          },
          children: [Component.text('Open Timeline')],
        ),
      ],
    );
  }

  Component _cardTitle(String text) => div(
        attributes: {
          'style': 'font-size:${KolaType.body};font-weight:700;'
              'color:${KolaVar.text};margin-bottom:2px',
        },
        [Component.text(text)],
      );

  Component _cardCaption(String text) => div(
        attributes: {
          'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
              'margin-bottom:14px;line-height:1.45',
        },
        [Component.text(text)],
      );

  /// Row 1, left. Title + real narrative caption ("a sentence next to
  /// every chart, not just the chart" — the page's own subtitle) +
  /// chart + a real revenue/delta stat line. See this file's header for
  /// why [intel.narrative] lives here rather than in a standalone card.
  Component _revenueCard() {
    final analytics = _analytics;
    final intel = _intelligence;
    if (analytics == null || intel == null) return const Component.text('');

    final maxMinor = analytics.dailyRevenue
        .map((p) => p.grossMinor)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:18px 20px',
      },
      [
        _cardTitle('Revenue, last ${intel.periodDays} days'),
        _cardCaption(intel.narrative),
        if (analytics.dailyRevenue.isNotEmpty)
          div(
            attributes: {
              'style': 'display:flex;align-items:flex-end;gap:3px;height:100px',
            },
            [
              for (final p in analytics.dailyRevenue)
                div(
                  attributes: {
                    'title': formatMinor(p.grossMinor),
                    'style': 'flex:1;background:${KolaVar.accentFill};'
                        'border-radius:3px 3px 0 0;min-width:2px;'
                        'height:${maxMinor == 0 ? 0 : (p.grossMinor / maxMinor * 100).clamp(2, 100)}%',
                  },
                  [],
                ),
            ],
          ),
        div(
          attributes: {
            'style': 'display:flex;align-items:baseline;gap:8px;margin-top:8px',
          },
          [
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.display};'
                    'font-size:${KolaType.h3};font-weight:700;'
                    'color:${KolaVar.text}',
              },
              [Component.text(formatMinor(intel.revenueMinor))],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
              },
              [
                Component.text(
                  'this period'
                  '${intel.revenueDeltaPct == null ? '' : ', ${intel.revenueDeltaPct! >= 0 ? '+' : ''}${intel.revenueDeltaPct!.toStringAsFixed(1)}% vs prior'}',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Row 1, right. Real position from the export, honest content: see
  /// this file's header on why this is a "not measured yet" card rather
  /// than a skipped one or a fabricated "6m".
  Component _responseTimeCard() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:18px 20px;'
              'display:flex;flex-direction:column;justify-content:center',
        },
        [
          _cardTitle('Response time'),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.mutedStrong};'
                  'line-height:1.55',
            },
            [
              Component.text(
                "Not measured yet — this workspace doesn't track reply "
                'timing yet, so there is no honest number to show. Once '
                "it's tracked, this will show how quickly conversations "
                'get a first reply.',
              ),
            ],
          ),
        ],
      );

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Row 2, left. Real day-of-week distribution over
  /// IntelligenceSummary.ordersByWeekday (index 0 = Monday). Names the
  /// slowest day by count alone — a plain, real observation, not a
  /// statistical claim — never the export's hardcoded "Wednesdays".
  Component _ordersByDayChart() {
    final intel = _intelligence;
    if (intel == null || intel.ordersByWeekday.length != 7) {
      return const Component.text('');
    }
    final counts = intel.ordersByWeekday;
    final total = counts.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const Component.text('');

    final maxCount = counts.fold<int>(0, (a, b) => a > b ? a : b);
    var slowestIndex = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] < counts[slowestIndex]) slowestIndex = i;
    }

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:18px 20px',
      },
      [
        _cardTitle('Orders by day'),
        _cardCaption(
          '${_weekdayLabels[slowestIndex]}s are the slowest day this period '
          '(${counts[slowestIndex]} order${counts[slowestIndex] == 1 ? '' : 's'}).',
        ),
        div(
          attributes: {
            'style': 'display:flex;align-items:flex-end;gap:8px;height:80px;'
                'margin-bottom:6px',
          },
          [
            for (var i = 0; i < 7; i++)
              div(
                attributes: {'style': 'flex:1;display:flex;flex-direction:column;'
                    'align-items:center;justify-content:flex-end;gap:4px;height:100%'},
                [
                  div(
                    attributes: {
                      'title': '${counts[i]}',
                      'style': 'width:100%;border-radius:3px 3px 0 0;'
                          'background:${i == slowestIndex && counts[i] < maxCount ? KolaVar.warning : KolaVar.accentFill};'
                          'height:${maxCount == 0 ? 0 : (counts[i] / maxCount * 100).clamp(counts[i] == 0 ? 0 : 4, 100)}%',
                    },
                    [],
                  ),
                ],
              ),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;gap:8px'},
          [
            for (final label in _weekdayLabels)
              div(
                attributes: {
                  'style': 'flex:1;text-align:center;font-size:${KolaType.tiny};'
                      'color:${KolaVar.muted}',
                },
                [Component.text(label)],
              ),
          ],
        ),
      ],
    );
  }

  /// Row 2, right. Honest "not enough data yet" state built from real
  /// workspace age. No rating/CSAT field exists anywhere in this
  /// codebase (grepped: none) — see intelligence_endpoint.dart's own
  /// header — so this never renders a score.
  Component _satisfactionCard() {
    final ageDays = DateTime.now().toUtc().difference(
          component.workspaceCreatedAt.toUtc(),
        ).inDays;
    final ageText = ageDays < 14
        ? (ageDays <= 1 ? '1 day' : '$ageDays days')
        : '${(ageDays / 7).floor()} week${(ageDays / 7).floor() == 1 ? '' : 's'}';

    return div(
      attributes: {
        'style': 'border:1px dashed ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:18px 20px;'
            'display:flex;flex-direction:column;justify-content:center',
      },
      [
        _cardTitle('Customer satisfaction'),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.mutedStrong};'
                'line-height:1.55',
          },
          [
            Component.text(
              'This workspace is $ageText old — not enough conversations '
              "rated yet to show a trend without it looking misleadingly "
              'precise. Check back in a few weeks.',
            ),
          ],
        ),
      ],
    );
  }

  /// Row 3, left. Columns match the export exactly: Product / Sold /
  /// Margin / Velocity — no Revenue column (the export doesn't show
  /// one either). Margin is a real naira amount now, not just a
  /// percentage; Velocity is the real classification
  /// intelligence_endpoint.dart now computes — see this file's header.
  Component _topProductsTable() {
    final intel = _intelligence;
    if (intel == null) return const Component.text('');
    if (intel.topProducts.isEmpty) {
      return div(
        attributes: {
          'style': 'text-align:center;padding:32px 20px;'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};color:${KolaVar.muted};'
              'font-size:${KolaType.small}',
        },
        [
          Component.text(
            'No completed sales with line items in the last ${intel.periodDays} days.',
          ),
        ],
      );
    }

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};overflow:hidden',
      },
      [
        div(
          attributes: {'style': 'padding:16px 20px 12px'},
          [
            _cardTitle('Top products'),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
              },
              [Component.text('Ranked by margin contribution, not just units sold.')],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:1.4fr 0.7fr 0.9fr 1.1fr;'
                'gap:8px;padding:9px 20px;background:${KolaVar.pill};'
                'font-size:${KolaType.tiny};font-weight:700;'
                'color:${KolaVar.muted};letter-spacing:0.02em',
          },
          [
            Component.text('PRODUCT'),
            Component.text('SOLD'),
            Component.text('MARGIN'),
            Component.text('VELOCITY'),
          ],
        ),
        for (var i = 0; i < intel.topProducts.length; i++)
          _productRow(intel.topProducts[i], i),
      ],
    );
  }

  static String _velocityColor(String? tone) => switch (tone) {
        'fast' => KolaVar.warning,
        'out' => KolaVar.danger,
        _ => KolaVar.muted,
      };

  Component _productRow(IntelligenceProduct p, int index) => div(
        attributes: {
          'style': 'display:grid;grid-template-columns:1.4fr 0.7fr 0.9fr 1.1fr;'
              'gap:8px;padding:11px 20px;font-size:${KolaType.small};'
              'color:${KolaVar.text};align-items:center;'
              '${index > 0 ? 'border-top:1px solid ${KolaVar.border}' : ''}',
        },
        [
          div(
            attributes: {
              'style': 'overflow:hidden;text-overflow:ellipsis;'
                  'white-space:nowrap',
            },
            [Component.text(p.name)],
          ),
          span(
            attributes: {'style': 'color:${KolaVar.muted}'},
            [Component.text('${p.unitsSold}')],
          ),
          span(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'color:${p.marginMinor == null ? KolaVar.muted : KolaVar.successBright}',
            },
            [
              Component.text(
                p.marginMinor == null ? 'cost not set' : formatMinor(p.marginMinor!),
              ),
            ],
          ),
          span(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${_velocityColor(p.velocityTone)}',
            },
            [Component.text(p.velocityLabel ?? '—')],
          ),
        ],
      );

  /// Row 3, right. Rebuilt against the export's real three rows — see
  /// this file's header for why the old "Top/New/Everyone" card is
  /// gone from this position (it was never what the export specified;
  /// customers_page.dart already covers that segmentation on its own
  /// page).
  Component _customerSegmentsCard() {
    final repeatRevenue = _customers
        .where((s) => s.orderCount >= 2)
        .fold<int>(0, (sum, s) => sum + s.ltvMinor);
    final firstTimeRevenue = _customers
        .where((s) => s.orderCount == 1)
        .fold<int>(0, (sum, s) => sum + s.ltvMinor);
    final totalCustomerRevenue = repeatRevenue + firstTimeRevenue;

    final segments = _analytics?.segments ?? const <AnalyticsSegment>[];
    final totalConvos = segments.fold<int>(0, (sum, s) => sum + s.conversations);
    final whatsappConvos = segments
        .where((s) => s.label == 'WhatsApp')
        .fold<int>(0, (sum, s) => sum + s.conversations);

    final rows = <(String, int, int, String)>[
      if (totalCustomerRevenue > 0) ...[
        ('Repeat customers', repeatRevenue, totalCustomerRevenue, 'of revenue'),
        ('First-time customers', firstTimeRevenue, totalCustomerRevenue, 'of revenue'),
      ],
      if (totalConvos > 0 && whatsappConvos > 0)
        ('On WhatsApp', whatsappConvos, totalConvos, 'of conversations'),
    ];

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:16px 20px',
      },
      [
        _cardTitle('Customer segments'),
        _cardCaption(
          rows.isEmpty
              ? 'Not enough order and conversation history yet to break this down.'
              : 'Repeat customers are worth more.',
        ),
        if (rows.isNotEmpty)
          div(
            attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
            [for (final (label, count, total, unit) in rows) _segmentBar(label, count, total, unit)],
          ),
      ],
    );
  }

  Component _segmentBar(String label, int count, int total, String unit) {
    final pct = total == 0 ? 0.0 : count / total * 100;
    return div(
      [
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;'
                'font-size:${KolaType.small};color:${KolaVar.mutedStrong};'
                'margin-bottom:4px',
          },
          [
            Component.text(label),
            Component.text('${pct.toStringAsFixed(0)}% $unit'),
          ],
        ),
        div(
          attributes: {
            'style': 'height:6px;border-radius:${KolaRadius.pill};'
                'background:${KolaVar.pill};overflow:hidden',
          },
          [
            div(
              attributes: {
                'style': 'height:100%;background:${KolaVar.accent};'
                    'width:${pct.clamp(0, 100)}%',
              },
              [],
            ),
          ],
        ),
      ],
    );
  }

  /// Additive, real deep-links built from the same numbers already on
  /// screen. Matches the export's own row shape (text + a right-aligned
  /// coloured link-with-chevron to another real page) but never its
  /// three fixed sample sentences — every row here is conditional on
  /// real data, per DESIGN_DELTA.md.
  Component _suggestions() {
    final intel = _intelligence;
    if (intel == null || intel.topProducts.isEmpty) {
      return const Component.text('');
    }
    final noCost = intel.topProducts.where((p) => p.marginMinor == null).toList();
    final fastMovers = intel.topProducts.where((p) => p.velocityTone == 'fast').toList();

    String? slowDaySuggestion;
    if (intel.ordersByWeekday.length == 7 &&
        intel.ordersByWeekday.fold<int>(0, (a, b) => a + b) > 0) {
      final counts = intel.ordersByWeekday;
      var slowestIndex = 0;
      for (var i = 1; i < counts.length; i++) {
        if (counts[i] < counts[slowestIndex]) slowestIndex = i;
      }
      if (counts[slowestIndex] == 0) {
        slowDaySuggestion =
            "No orders at all on ${_weekdayLabels[slowestIndex]}s this period "
            "— worth checking staffing or hours for that day";
      }
    }

    return div(
      attributes: {
        'style': 'margin-top:${KolaSpace.sm}',
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.body};font-weight:700;'
                'color:${KolaVar.mutedStrong};margin-bottom:10px',
          },
          [Component.text('What this suggests')],
        ),
        div(
          attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
          [
            _suggestionRow(
              "See what kola's already flagged for you",
              'View in Recommendations',
              '/recommendations',
            ),
            if (fastMovers.isNotEmpty)
              _suggestionRow(
                '${fastMovers.first.name} keeps selling out — consider a bigger restock.',
                'Open Catalog',
                '/catalog',
              ),
            if (noCost.isNotEmpty)
              _suggestionRow(
                "${noCost.length} top-selling product${noCost.length == 1 ? '' : 's'} "
                    "${noCost.length == 1 ? 'has' : 'have'} no cost price set "
                    "— margin can't be shown until it does",
                'Open Catalog',
                '/catalog',
              ),
            if (slowDaySuggestion != null)
              _suggestionRow(slowDaySuggestion, 'Open Operations', '/operations'),
          ],
        ),
      ],
    );
  }

  Component _suggestionRow(String text, String cta, String route) => Link(
        to: route,
        attributes: {
          'style': 'display:flex;align-items:center;justify-content:space-between;'
              'gap:12px;padding:13px 16px;background:${KolaVar.card};'
              'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};text-decoration:none;'
              'color:${KolaVar.text};font-size:${KolaType.bodyLg}',
        },
        children: [
          span([Component.text(text)]),
          span(
            attributes: {
              'style': 'color:${KolaVar.accent};flex:none;white-space:nowrap;'
                  'font-size:${KolaType.tiny};display:inline-flex;'
                  'align-items:center;gap:4px',
            },
            [Component.text('$cta →')],
          ),
        ],
      );
}
