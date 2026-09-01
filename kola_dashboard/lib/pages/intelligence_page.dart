// intelligence_page.dart — Phase 14g. `/intelligence`, confirmed unbuilt
// this pass — nav_model.dart has pointed here since Phase 13e (gated on
// `Features.businessIntelligence`) but no route/page ever backed it. See
// PHASE_14_HANDOFF.pdf's 14g section for the grep that confirmed the
// gap, and analytics_endpoint.dart's own header for why Phase 13e
// deliberately scoped this page out — it needed a real AI-reasoning
// layer this codebase didn't have yet. intelligence_endpoint.dart /
// intelligence_narrative_service.dart are that layer, built this pass.
//
// ── WHAT THIS PAGE COMPOSES FROM, AND WHY ──────────────────────────────
//
// Three real fetches, in parallel:
//   1. IntelligenceEndpoint.getIntelligence — the narrative paragraph,
//      revenue total + delta, and top products by revenue/velocity/
//      margin. New this pass.
//   2. AnalyticsEndpoint.getSummary — the day-by-day revenue chart.
//      Already real, already built (Phase 13e) — reused rather than
//      recomputing the same daily aggregation a second way.
//   3. CustomerEndpoint.listCustomersWithSummary — backs the
//      Top/New/Regular segment bars, using the EXACT SAME banding rule
//      customers_page.dart's own `_topCustomerIds`/`_isNewThisMonth`
//      already define (top LTV quintile; "new" = firstSeenAt in the
//      current calendar month) — copied rather than re-derived, so the
//      two pages never quietly disagree about what "Top" means.
//
// ── ONE NAMED CUT ──────────────────────────────────────────────────────
//
// The export's "Correlation spotted" callout (a revenue move explained
// by a specific linked Timeline event) is not built — there is no
// Timeline page anywhere in this codebase to link to, and real
// cross-metric correlation detection is separate, larger, deferred
// work. See intelligence_endpoint.dart's own header for the same note
// server-side.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/page_help_button.dart';
import '../services/error_text.dart';
import '../services/feature_gate.dart';
import '../services/money_format.dart';
import '../theme.dart';

class IntelligencePage extends StatefulComponent {
  const IntelligencePage({
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
  State<IntelligencePage> createState() => _IntelligencePageState();
}

class _IntelligencePageState extends State<IntelligencePage> {
  bool _loading = true;
  String? _error;
  int _periodDays = 30;

  IntelligenceSummary? _intelligence;
  AnalyticsSummary? _analytics;
  List<CustomerSummary> _customers = const [];

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

  // ── Customer segments — SAME rule customers_page.dart defines ──────
  //
  // Copied rather than shared via a helper file: two call sites is not
  // yet enough to justify extracting one, and copying keeps each file
  // readable without a jump. If a third page needs this banding, that's
  // the moment to pull it into services/.
  Set<int> get _topCustomerIds {
    final withRevenue = [
      for (final s in _customers)
        if (s.ltvMinor > 0 && s.customer.id != null) s,
    ]..sort((a, b) => b.ltvMinor.compareTo(a.ltvMinor));
    if (withRevenue.isEmpty) return const {};
    final count = (withRevenue.length * 0.2).ceil().clamp(1, withRevenue.length);
    return {for (final s in withRevenue.take(count)) s.customer.id!};
  }

  bool _isNewThisMonth(Customer c) {
    final now = DateTime.now().toUtc();
    final seen = c.firstSeenAt.toUtc();
    return seen.year == now.year && seen.month == now.month;
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:1180px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        _header(),
        if (_error != null) _errorBanner(),
        if (_loading) _skeleton() else ..._content(),
      ],
    );
  }

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
                [Component.text('Intelligence')],
              ),
              div(
                attributes: {
                  'style':
                      'font-size:${KolaType.small};color:${KolaVar.muted}',
                },
                [
                  Component.text(
                    "The curated read on the business — what changed, what's "
                    "driving it, and what to look at next.",
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
                      "without a cost price on its catalog entry.",
                ],
              ),
            ],
          ),
        ],
      );

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
      [Component.text('${days}d')],
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

  List<Component> _content() => [
        _narrativeCard(),
        _revenueChart(),
        _topProductsTable(),
        _customerSegmentBars(),
        _suggestions(),
      ];

  Component _narrativeCard() {
    final intel = _intelligence;
    if (intel == null) return const Component.text('');
    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:20px;'
            'margin-bottom:${KolaSpace.lg}',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:8px;'
                'margin-bottom:10px',
          },
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};font-weight:700;'
                    'color:${KolaVar.muted};letter-spacing:0.02em',
              },
              [Component.text('WHAT THIS SUGGESTS')],
            ),
            if (intel.narrativeIsTemplate)
              span(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                      'background:${KolaVar.pill};border-radius:${KolaRadius.pill};'
                      'padding:2px 8px',
                  'title': 'Every AI provider was unavailable, so this is a '
                      'plain sentence built from the real numbers below, '
                      'not a model-written summary.',
                },
                [Component.text('templated — AI unavailable')],
              ),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.bodyLg};color:${KolaVar.text};'
                'line-height:1.6',
          },
          [Component.text(intel.narrative)],
        ),
      ],
    );
  }

  Component _revenueChart() {
    final analytics = _analytics;
    final intel = _intelligence;
    if (analytics == null || intel == null) return const Component.text('');

    final maxMinor = analytics.dailyRevenue
        .map((p) => p.grossMinor)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:20px;'
            'margin-bottom:${KolaSpace.lg}',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:baseline;justify-content:space-between;'
                'gap:10px;margin-bottom:14px;flex-wrap:wrap',
          },
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
              },
              [Component.text('Revenue — last ${intel.periodDays} days')],
            ),
            div(
              attributes: {
                'style': 'display:flex;align-items:baseline;gap:8px',
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
                if (intel.revenueDeltaPct != null)
                  span(
                    attributes: {
                      'style': 'font-size:${KolaType.small};font-weight:600;'
                          'color:${intel.revenueDeltaPct! >= 0 ? KolaVar.success : KolaVar.danger}',
                    },
                    [
                      Component.text(
                        '${intel.revenueDeltaPct! >= 0 ? '+' : ''}'
                        '${intel.revenueDeltaPct!.toStringAsFixed(1)}% vs prior period',
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
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
      ],
    );
  }

  Component _topProductsTable() {
    final intel = _intelligence;
    if (intel == null) return const Component.text('');
    if (intel.topProducts.isEmpty) {
      return div(
        attributes: {
          'style': 'text-align:center;padding:32px 20px;'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};color:${KolaVar.muted};'
              'font-size:${KolaType.small};margin-bottom:${KolaSpace.lg}',
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
            'border-radius:${KolaRadius.lg};overflow:hidden;'
            'margin-bottom:${KolaSpace.lg}',
      },
      [
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:1.8fr 0.8fr 1fr 1fr;'
                'gap:8px;padding:10px 16px;background:${KolaVar.pill};'
                'font-size:${KolaType.tiny};font-weight:700;'
                'color:${KolaVar.muted};letter-spacing:0.02em',
          },
          [
            Component.text('PRODUCT'),
            Component.text('SOLD'),
            Component.text('REVENUE'),
            Component.text('MARGIN'),
          ],
        ),
        for (var i = 0; i < intel.topProducts.length; i++)
          _productRow(intel.topProducts[i], i),
      ],
    );
  }

  Component _productRow(IntelligenceProduct p, int index) => div(
        attributes: {
          'style': 'display:grid;grid-template-columns:1.8fr 0.8fr 1fr 1fr;'
              'gap:8px;padding:11px 16px;font-size:${KolaType.small};'
              'color:${KolaVar.text};'
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
          Component.text('${p.unitsSold}'),
          Component.text(formatMinor(p.revenueMinor)),
          span(
            attributes: {
              'style': 'color:${p.marginPct == null ? KolaVar.muted : KolaVar.success}',
            },
            [
              Component.text(
                p.marginPct == null
                    ? 'cost not set'
                    : '${p.marginPct!.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      );

  Component _customerSegmentBars() {
    if (!component.gate.isEnabled(Features.customers) || _customers.isEmpty) {
      return const Component.text('');
    }
    final top = _topCustomerIds;
    final newCount = _customers.where((s) => _isNewThisMonth(s.customer)).length;
    final topCount = top.length;
    final regularCount = (_customers.length - topCount - newCount).clamp(0, _customers.length);
    final total = _customers.length;

    final bars = [
      ('Top customers', topCount, KolaVar.accent),
      ('New this month', newCount, KolaVar.success),
      ('Everyone else', regularCount, KolaVar.muted),
    ];

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:20px;'
            'margin-bottom:${KolaSpace.lg}',
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin-bottom:14px',
          },
          [Component.text('Customer mix — $total total')],
        ),
        div(
          attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
          [
            for (final (label, count, color) in bars)
              _segmentBar(label, count, total, color),
          ],
        ),
      ],
    );
  }

  Component _segmentBar(String label, int count, int total, String color) {
    final pct = total == 0 ? 0.0 : count / total * 100;
    return div(
      [
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;'
                'font-size:${KolaType.tiny};color:${KolaVar.mutedStrong};'
                'margin-bottom:4px',
          },
          [
            Component.text(label),
            Component.text('$count (${pct.toStringAsFixed(0)}%)'),
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
                'style': 'height:100%;background:$color;'
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
  /// screen — not the export's "Correlation spotted" callout (there is
  /// no Timeline page to send it to; see this file's header).
  Component _suggestions() {
    final intel = _intelligence;
    if (intel == null || intel.topProducts.isEmpty) {
      return const Component.text('');
    }
    final noCost = intel.topProducts.where((p) => p.marginPct == null).toList();

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:20px',
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin-bottom:10px',
          },
          [Component.text('Where to look next')],
        ),
        div(
          attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
          [
            _suggestionRow(
              "See what kola's already flagged for you",
              '/recommendations',
            ),
            if (noCost.isNotEmpty)
              _suggestionRow(
                "${noCost.length} top-selling product${noCost.length == 1 ? '' : 's'} "
                    "${noCost.length == 1 ? 'has' : 'have'} no cost price set "
                    "— margin can't be shown until it does",
                '/catalog',
              ),
          ],
        ),
      ],
    );
  }

  Component _suggestionRow(String text, String route) => Link(
        to: route,
        attributes: {
          'style': 'display:flex;align-items:center;justify-content:space-between;'
              'gap:10px;padding:10px 12px;background:${KolaVar.pill};'
              'border-radius:${KolaRadius.md};text-decoration:none;'
              'color:${KolaVar.text};font-size:${KolaType.small}',
        },
        children: [
          Component.text(text),
          span(
            attributes: {'style': 'color:${KolaVar.muted};flex:none'},
            [Component.text('→')],
          ),
        ],
      );
}
