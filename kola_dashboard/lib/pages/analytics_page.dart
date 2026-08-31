// analytics_page.dart — Phase 13e. `/analytics`, previously 404ing —
// nav_model.dart pointed here correctly, app.dart never registered the
// route, no page file existed. Built against the buildable half of
// `Kola Analytics.dc.html` — see analytics_endpoint.dart's own header
// for the full scope note (channel segments, not geography or customer
// tenure; no Business Intelligence page this pass, it needs an
// AI-reasoning layer that doesn't exist yet).
//
// The export's `view: 'empty'|'populated'` toggle is a design-tool
// preview control, not a real feature — same treatment every other
// Phase 13 page gives it. The "Compare to previous period" toggle IS
// real here, unlike the export's version: AnalyticsSummary always
// computes the prior-period delta server-side, so this page's toggle
// just shows/hides the already-computed "vs. prior" column rather than
// triggering a second fetch.
//
// CSV EXPORT builds the file client-side from already-loaded data —
// no server endpoint needed for that part.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../services/dom_files.dart';
import '../theme.dart';

class AnalyticsPage extends StatefulComponent {
  const AnalyticsPage({
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
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _loading = true;
  String? _error;
  AnalyticsSummary? _summary;
  int _periodDays = 30;
  bool _compare = true;
  String _sortKey = 'revenue';
  bool _sortDesc = true;

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
      final summary = await component.client.analytics.getSummary(
        component.accessToken,
        component.workspaceId,
        periodDays: _periodDays,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
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

  void _sortBy(String key) {
    setState(() {
      if (_sortKey == key) {
        _sortDesc = !_sortDesc;
      } else {
        _sortKey = key;
        _sortDesc = true;
      }
    });
  }

  List<AnalyticsSegment> get _sortedSegments {
    final segments = [...(_summary?.segments ?? const <AnalyticsSegment>[])];
    int cmp(AnalyticsSegment a, AnalyticsSegment b) {
      switch (_sortKey) {
        case 'conversations':
          return a.conversations.compareTo(b.conversations);
        case 'orders':
          return a.orders.compareTo(b.orders);
        case 'segment':
          return a.label.compareTo(b.label);
        case 'revenue':
        default:
          return a.revenueMinor.compareTo(b.revenueMinor);
      }
    }

    segments.sort((a, b) => _sortDesc ? cmp(b, a) : cmp(a, b));
    return segments;
  }

  void _exportCsv() {
    final summary = _summary;
    if (summary == null) return;
    final buf = StringBuffer('Segment,Conversations,Orders,Revenue,vs prior\n');
    for (final s in _sortedSegments) {
      final delta = s.deltaPct == null ? '' : '${s.deltaPct!.toStringAsFixed(1)}%';
      buf.writeln(
        '"${s.label}",${s.conversations},${s.orders},${_naira(s.revenueMinor, summary.currency)},$delta',
      );
    }
    // downloadText (dom_files.dart) is the already-proven download path
    // in this dashboard — no server round trip for data the page
    // already has in memory.
    downloadText(buf.toString(), fileName: 'analytics-${summary.periodDays}d.csv');
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
        _controls(),
        if (_error != null) _errorBanner(),
        if (_loading)
          _skeleton()
        else ...[
          _revenueChart(),
          _segmentTable(),
        ],
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
                [Component.text('Analytics')],
              ),
              div(
                attributes: {
                  'style':
                      'font-size:${KolaType.small};color:${KolaVar.muted}',
                },
                [
                  Component.text(
                    'Self-serve exploration. For channel and revenue trends over time.',
                  ),
                ],
              ),
            ],
          ),
          button(
            attributes: {
              'type': 'button',
              if (_summary == null) 'disabled': '',
              'style': 'background:transparent;'
                  'border:1px solid ${KolaVar.border};color:${KolaVar.text};'
                  'border-radius:${KolaRadius.sm};padding:9px 16px;'
                  'font-size:${KolaType.small};font-family:inherit;'
                  'cursor:${_summary == null ? 'default' : 'pointer'}',
            },
            events: {'click': (_) => _exportCsv()},
            [Component.text('Export CSV')],
          ),
        ],
      );

  Component _controls() => div(
        attributes: {
          'style': 'display:flex;gap:10px;flex-wrap:wrap;'
              'margin-bottom:${KolaSpace.lg}',
        },
        [
          for (final days in [7, 30, 90]) _periodChip(days),
          button(
            attributes: {
              'type': 'button',
              'style': 'background:${_compare ? KolaVar.pill : 'transparent'};'
                  'border:1px solid ${KolaVar.border};'
                  'color:${_compare ? KolaVar.text : KolaVar.muted};'
                  'border-radius:${KolaRadius.pill};padding:8px 16px;'
                  'font-size:${KolaType.small};font-family:inherit;'
                  'cursor:pointer',
            },
            events: {'click': (_) => setState(() => _compare = !_compare)},
            [Component.text('Compare to previous period')],
          ),
        ],
      );

  Component _periodChip(int days) {
    final active = _periodDays == days;
    return button(
      attributes: {
        'type': 'button',
        'style': 'background:${active ? KolaVar.accentFill : 'transparent'};'
            'border:1px solid ${active ? KolaVar.accentFill : KolaVar.border};'
            'color:${active ? KolaVar.accentText : KolaVar.muted};'
            'border-radius:${KolaRadius.pill};padding:8px 16px;'
            'font-size:${KolaType.small};font-weight:600;font-family:inherit;'
            'cursor:pointer',
      },
      events: {'click': (_) => _setPeriod(days)},
      [Component.text('Last $days days')],
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
          'style': 'display:flex;flex-direction:column;'
              'gap:${KolaSpace.md}',
        },
        [
          for (var i = 0; i < 2; i++)
            div(
              attributes: {
                'style': 'height:140px;border-radius:${KolaRadius.lg};'
                    'background:${KolaVar.card};'
                    'border:1px solid ${KolaVar.border};opacity:0.6',
              },
              [],
            ),
        ],
      );

  Component _revenueChart() {
    final summary = _summary;
    if (summary == null || summary.dailyRevenue.isEmpty) {
      return const Component.text('');
    }
    final maxMinor = summary.dailyRevenue
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
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin-bottom:14px',
          },
          [Component.text('Revenue by day — last ${summary.periodDays} days')],
        ),
        div(
          attributes: {
            'style': 'display:flex;align-items:flex-end;gap:3px;height:100px',
          },
          [
            for (final p in summary.dailyRevenue)
              div(
                attributes: {
                  'title': _naira(p.grossMinor, summary.currency),
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

  Component _segmentTable() {
    final summary = _summary;
    if (summary == null) return const Component.text('');
    if (summary.segments.isEmpty) {
      return div(
        attributes: {
          'style': 'text-align:center;padding:44px 20px;'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};color:${KolaVar.muted};'
              'font-size:${KolaType.small}',
        },
        [
          Component.text(
            'No activity yet in the last ${summary.periodDays} days — try a wider period.',
          ),
        ],
      );
    }

    final cols = _compare ? '1.6fr 1fr 1fr 1fr 1fr' : '1.6fr 1fr 1fr 1fr';

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};overflow:hidden',
      },
      [
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:$cols;'
                'background:${KolaVar.card};padding:11px 16px;'
                'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'text-transform:uppercase;letter-spacing:0.04em',
          },
          [
            _headerCell('Segment', 'segment'),
            _headerCell('Conversations', 'conversations'),
            _headerCell('Orders', 'orders'),
            _headerCell('Revenue', 'revenue'),
            if (_compare)
              div(attributes: {'style': 'cursor:default'}, [Component.text('vs. prior')]),
          ],
        ),
        for (final s in _sortedSegments) _segmentRow(s, summary.currency, cols),
      ],
    );
  }

  Component _headerCell(String label, String key) => div(
        attributes: {'style': 'cursor:pointer'},
        events: {'click': (_) => _sortBy(key)},
        [
          Component.text(
            _sortKey == key ? '$label ${_sortDesc ? '↓' : '↑'}' : label,
          ),
        ],
      );

  Component _segmentRow(AnalyticsSegment s, String currency, String cols) {
    final deltaColor = s.deltaPct == null
        ? KolaVar.muted
        : s.deltaPct! < 0
            ? KolaVar.danger
            : KolaVar.success;
    return div(
      attributes: {
        'style': 'display:grid;grid-template-columns:$cols;'
            'padding:12px 16px;border-top:1px solid ${KolaVar.border};'
            'font-size:${KolaType.small};align-items:center',
      },
      [
        div([Component.text(s.label)]),
        div([Component.text('${s.conversations}')]),
        div([Component.text('${s.orders}')]),
        div(
          attributes: {'style': 'font-family:${KolaFonts.mono}'},
          [Component.text(_naira(s.revenueMinor, currency))],
        ),
        if (_compare)
          div(
            attributes: {'style': 'color:$deltaColor;font-weight:600'},
            [
              Component.text(
                s.deltaPct == null
                    ? '—'
                    : '${s.deltaPct! >= 0 ? '+' : ''}${s.deltaPct!.toStringAsFixed(0)}%',
              ),
            ],
          ),
      ],
    );
  }

  /// Same minor-unit-divided-by-100 approach used across this dashboard
  /// (till_display_page.dart's `_money`, operations_page.dart's
  /// `_naira`) — including the same named gap: zero-decimal currencies
  /// aren't handled specially.
  static String _naira(int minor, String currency) {
    final major = minor / 100;
    return '$currency ${major.toStringAsFixed(2)}';
  }
}
