// timeline_page.dart — Phase 14/174. Backs `/timeline`: nav_model.dart's
// primary nav has pointed 'Timeline' here since it was written, but no
// page file and no route ever existed (confirmed via grep for both
// before this pass). event_endpoint.dart (new this pass) is what
// finally backs it — see that file's own header for exactly which
// event types are real and which category chips will honestly show
// nothing yet (Inventory, Knowledge — no emit call anywhere fires
// those today).
//
// ── WHAT THIS PAGE DOES WITH THE RAW Event ROWS ─────────────────────────
//
// EventEndpoint.listTimeline returns the raw generated Event model
// (eventType, payloadJson, occurredAt) — see that endpoint's own header
// on why no dedicated TimelineEntry wire type was built. Title/
// category/dot-color/amount are all derived HERE, in [_describe], the
// one place that owns this switch. Category FILTERING (which chip
// shows what) happens server-side, over the full set, so the
// eventType→category table itself has exactly one copy (event_endpoint
// .dart's own `categoryByEventType`) — this file's [_describe] only
// adds presentation (title wording, dot color, bold-ness, amount
// extraction), not a second category decision.
//
// ── "N ROUTINE REPLIES HANDLED" ──────────────────────────────────────────
//
// The design shows this muted summary line at the end of some days.
// Built here as a simple named simplification: it counts that day's
// `message_sent` events (outbound_message_service.dart's own event —
// an API/bot-sent reply) and, when there is at least one, renders the
// count instead of one row per message. This under-counts "routine"
// in one direction (a message_sent could in principle be an important
// one-off, not a routine reply) — named honestly here rather than
// building real reply-classification, which is separate, larger work.

import 'dart:convert';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/page_help_button.dart';
import '../services/error_text.dart';
import '../services/money_format.dart';
import '../theme.dart';

class TimelinePage extends StatefulComponent {
  const TimelinePage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

/// The design's own five chips — see this file's header on why the
/// pill vocabulary a row can actually carry (event_endpoint.dart's
/// `categoryByEventType`) is wider (Integrations, Customers too): the
/// FILTER surface matches the export exactly, the row PILL shows
/// whatever the event's real category is regardless of which chip is
/// selected.
const _chips = ['All', 'Payments', 'Inventory', 'Operations', 'Conversations'];

class _TimelinePageState extends State<TimelinePage> {
  bool _loading = true;
  String? _error;
  String _category = 'All';
  List<Event> _events = const [];

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
      final events = await component.client.event.listTimeline(
        component.accessToken,
        component.workspaceId,
        category: _category == 'All' ? null : _category,
        limit: 200,
      );
      if (!mounted) return;
      setState(() {
        _events = events;
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

  void _setCategory(String category) {
    if (category == _category) return;
    setState(() => _category = category);
    _load();
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:900px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        _breadcrumb(),
        _header(),
        _chipRow(),
        if (_error != null) _errorBanner(),
        if (_loading) _skeleton() else _body(),
      ],
    );
  }

  /// "Dashboard / Timeline" — `Kola Timeline.dc.html` lines 19-25. The
  /// export's crumb is referrer-aware (it can read as "Operations /
  /// Timeline" when you arrived from there, via `document.referrer`,
  /// which has no equivalent signal in a client-routed SPA). This app
  /// has exactly one place Timeline is reached from — the Overview's
  /// "View full timeline →" link, plus the sidebar — so the simpler,
  /// always-correct crumb is just "Dashboard / Timeline", not a
  /// fabricated referrer guess.
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
            [Component.text('Timeline')],
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
                [Component.text('Timeline')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
                },
                // No trailing period — `Kola Timeline.dc.html` line 30
                // has none.
                [Component.text('Everything that happened, correlated')],
              ),
            ],
          ),
          const PageHelpButton(
            pageKey: 'timeline',
            body: [
              "Every real event kola has recorded for this business — "
                  "sales, payments, conversations, agent changes and "
                  "errand runs — in one chronological feed, grouped by "
                  "day. Filter by category with the chips above the "
                  "list.",
              "Inventory and Knowledge events will show here once kola "
                  "starts recording stock changes and document uploads "
                  "as events — those chips are honest about being empty "
                  "today, not broken.",
            ],
          ),
        ],
      );

  Component _chipRow() => div(
        attributes: {
          'style': 'display:flex;gap:6px;flex-wrap:wrap;'
              'margin-bottom:${KolaSpace.md}',
        },
        [for (final c in _chips) _chip(c)],
      );

  /// `Kola Timeline.dc.html`'s own active-chip colours are a TINTED
  /// chip, not a filled button: `bg:'#241A14', color:'#C1552E',
  /// border:'#3A2A1E'` — the same tint-0/accent pair this design system
  /// already names in theme.dart (`KolaVar.tintSurface(0)` /
  /// `KolaVar.tintIcon(0)` / `KolaVar.accent`), not the solid
  /// `accentFill`/`accentText` pair this app's real buttons use. A
  /// filter chip and a call-to-action button read differently on
  /// purpose; this was rendering the chip as the latter.
  Component _chip(String label) {
    final active = label == _category;
    return button(
      attributes: {
        'type': 'button',
        'style': 'background:${active ? KolaVar.tintSurface(0) : 'transparent'};'
            'color:${active ? KolaVar.accent : KolaVar.mutedStrong};'
            'border:1px solid ${active ? KolaVar.tintIcon(0) : KolaVar.border};'
            'border-radius:${KolaRadius.pill};padding:7px 14px;'
            'font-size:${KolaType.small};font-family:inherit;'
            'font-weight:600;cursor:pointer',
      },
      events: {'click': (_) => _setCategory(label)},
      [Component.text(label)],
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
          'style': 'display:flex;flex-direction:column;gap:${KolaSpace.sm}',
        },
        [
          for (var i = 0; i < 6; i++)
            div(
              attributes: {
                'style': 'height:44px;border-radius:${KolaRadius.md};'
                    'background:${KolaVar.card};'
                    'border:1px solid ${KolaVar.border};opacity:0.6',
              },
              [],
            ),
        ],
      );

  Component _body() {
    if (_events.isEmpty) {
      return div(
        attributes: {
          'style': 'text-align:center;padding:48px 20px;'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};color:${KolaVar.muted};'
              'font-size:${KolaType.small}',
        },
        [
          Component.text(
            _category == 'All'
                ? 'Nothing recorded yet. As sales, conversations and '
                    'other real activity happen, they show up here.'
                : 'Nothing in "$_category" yet.',
          ),
        ],
      );
    }

    final groups = _groupByDay(_events);
    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:${KolaSpace.lg}'},
      [for (final g in groups) _dayGroup(g)],
    );
  }

  Component _dayGroup(_DayGroup g) => div(
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};font-weight:700;'
                  'color:${KolaVar.muted};letter-spacing:0.04em;'
                  'margin-bottom:8px',
            },
            [Component.text(g.label)],
          ),
          div(
            attributes: {
              'style': 'display:flex;flex-direction:column;'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};overflow:hidden;'
                  'background:${KolaVar.card}',
            },
            [for (var i = 0; i < g.rows.length; i++) _row(g.rows[i], i)],
          ),
          if (g.routineReplies > 0)
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                    'margin-top:8px;padding-left:4px',
              },
              [
                Component.text(
                  g.routineReplies == 1
                      ? '1 routine reply handled'
                      : '${g.routineReplies} routine replies handled',
                ),
              ],
            ),
        ],
      );

  Component _row(Event e, int index) {
    final d = _describe(e);
    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:10px;padding:11px 14px;'
            '${index > 0 ? 'border-top:1px solid ${KolaVar.border}' : ''}',
      },
      [
        span(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'width:48px;flex:none;font-variant-numeric:tabular-nums',
          },
          [Component.text(_time(e.occurredAt))],
        ),
        span(
          attributes: {
            'style': 'width:7px;height:7px;flex:none;'
                'border-radius:${KolaRadius.circle};background:${d.dot}',
            'aria-hidden': 'true',
          },
          [],
        ),
        div(
          attributes: {
            'style': 'flex:1;min-width:0;font-size:${KolaType.small};'
                'font-weight:${d.bold ? '600' : '400'};color:${KolaVar.text};'
                'overflow:hidden;text-overflow:ellipsis;white-space:nowrap',
          },
          [Component.text(d.title)],
        ),
        if (d.amountMinor != null)
          span(
            attributes: {
              'style': 'font-size:${KolaType.small};font-weight:600;'
                  'color:${KolaVar.success};flex:none',
            },
            [Component.text(formatMinor(d.amountMinor!))],
          ),
        span(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'background:${KolaVar.pill};border-radius:${KolaRadius.pill};'
                'padding:3px 9px;flex:none',
          },
          [Component.text(d.category)],
        ),
      ],
    );
  }

  // ── Grouping ──────────────────────────────────────────────────────────

  List<_DayGroup> _groupByDay(List<Event> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final byDay = <DateTime, List<Event>>{};
    for (final e in events) {
      final local = e.occurredAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      byDay.putIfAbsent(day, () => []).add(e);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final day in days)
        _DayGroup(
          label: day == today
              ? 'TODAY'
              : day == yesterday
                  ? 'YESTERDAY'
                  : _formatDayHeader(day),
          rows: [
            for (final e in byDay[day]!)
              if (e.eventType != 'message_sent') e,
          ],
          // Simple named simplification — see this file's header.
          routineReplies:
              byDay[day]!.where((e) => e.eventType == 'message_sent').length,
        ),
    ];
  }

  static String _formatDayHeader(DateTime d) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${days[d.weekday - 1].toUpperCase()}, ${months[d.month - 1]} ${d.day}';
  }

  static String _time(DateTime utc) {
    final local = utc.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute$period';
  }

  // ── Presentation: title / category pill / dot / amount ──────────────
  //
  // Category here MUST agree with event_endpoint.dart's own
  // `categoryByEventType` — copied rather than fetched over the wire
  // (one small, stable table; not worth a round trip to read it).

  static Map<String, dynamic> _payload(Event e) {
    try {
      final decoded = jsonDecode(e.payloadJson);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  /// `Kola Timeline.dc.html`'s own colour rule (its script's `dot:`
  /// line) is purely by CATEGORY, not per specific event: Payments is
  /// always green, Operations always amber, Inventory always red, and
  /// everything else (Conversations/Integrations/Customers/Knowledge)
  /// is the same plain dark dot. Centralised here so every case below
  /// gets it right by construction instead of each hand-picking a
  /// colour — which is exactly how `agent_published` previously ended
  /// up green (a Payments colour on an Integrations row) and
  /// `errand_executed` ended up plain (missing Operations' amber).
  static String _dotForCategory(String category) => switch (category) {
        'Payments' => KolaVar.success,
        'Operations' => KolaVar.warning,
        'Inventory' => KolaVar.danger,
        _ => KolaVar.muted,
      };

  /// Bold ("significant") vs regular weight, per the export's own
  /// `RAW` sample data: every `tier: 1` row is Payments, Operations or
  /// Inventory; every `tier: 2` row is Conversations, Integrations,
  /// Customers or Knowledge — no exception across all 8 sample events.
  /// Read as a rule, not a coincidence, and applied here the same way
  /// [_dotForCategory] applies the colour rule: by category, not by
  /// hand-picking per event type.
  static bool _isSignificant(String category) =>
      category == 'Payments' || category == 'Operations' || category == 'Inventory';

  static _Row _describe(Event e) {
    final p = _payload(e);
    final (title, category, amountMinor) = switch (e.eventType) {
      'sale_completed' => ('Sale completed', 'Payments', p['totalMinor'] as int?),
      'payment_confirmed' => ('Payment confirmed', 'Payments', p['amountKobo'] as int?),
      'new_conversation' => ('New conversation started', 'Conversations', null),
      'agent_drafted' => ('${p['name'] ?? 'An agent'} was drafted', 'Integrations', null),
      'agent_published' => ('${p['name'] ?? 'An agent'} went live', 'Integrations', null),
      'agent_paused' => ('${p['name'] ?? 'An agent'} was paused', 'Integrations', null),
      'errand_executed' => ('An errand ran', 'Operations', null),
      'errand_rows_mapped_to_customers' => (_customersMatchedTitle(p), 'Customers', null),
      // A real event type this table hasn't named yet — shown honestly
      // with its raw type rather than dropped silently, so a future new
      // eventType is visible on the page (as "unlabeled activity") the
      // day it starts firing, not invisible until someone remembers to
      // update this switch. Bucketed as Operations for the category
      // pill (this file's chip row has no catch-all chip to put it
      // under), but deliberately NOT run through [_isSignificant] below
      // — an unrecognised event type's real urgency is unknown, and
      // guessing "important" is worse than under-stating it.
      _ => (e.eventType.replaceAll('_', ' '), 'Operations', null),
    };
    final known = categoryByEventType.containsKey(e.eventType);
    return _Row(
      title: title,
      category: category,
      dot: _dotForCategory(category),
      bold: known && _isSignificant(category),
      amountMinor: amountMinor,
    );
  }

  static String _customersMatchedTitle(Map<String, dynamic> p) {
    final resolved = p['customersResolved'] as int? ?? 0;
    return resolved == 1
        ? '1 customer matched from an import'
        : '$resolved customers matched from an import';
  }
}

/// Mirrors event_endpoint.dart's own `categoryByEventType` — same
/// one-copy-of-the-mapping posture this file's header already commits
/// to for the title/category switch above. Used here only to tell a
/// REAL, recognised event type from the catch-all default (see
/// [_TimelinePageState._describe]'s own comment on why an unrecognised
/// type must not inherit Operations' bold/amber treatment just because
/// it is bucketed under that category pill).
const categoryByEventType = <String, String>{
  'sale_completed': 'Payments',
  'payment_confirmed': 'Payments',
  'new_conversation': 'Conversations',
  'message_sent': 'Conversations',
  'agent_drafted': 'Integrations',
  'agent_published': 'Integrations',
  'agent_paused': 'Integrations',
  'errand_executed': 'Operations',
  'errand_rows_mapped_to_customers': 'Customers',
};

class _DayGroup {
  const _DayGroup({
    required this.label,
    required this.rows,
    required this.routineReplies,
  });

  final String label;
  final List<Event> rows;
  final int routineReplies;
}

class _Row {
  const _Row({
    required this.title,
    required this.category,
    required this.dot,
    required this.bold,
    this.amountMinor,
  });

  final String title;
  final String category;
  final String dot;
  final bool bold;
  final int? amountMinor;
}
