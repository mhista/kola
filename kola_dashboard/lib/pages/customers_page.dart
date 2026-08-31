// customers_page.dart — Gate 3 / Gate 3b, rebuilt Phase 13f against
// `Kola Customers.dc.html` (the design export). Previously this page
// built an entirely different concept — a bare list plus a "unified
// provenance timeline" — that its own header described as a deliberate
// choice made for Gate 3b's proof-of-graph purpose, without reference
// to this export. Checked directly this pass: the export specifies a
// real CRM list (stat cards, search, sort, Top/New segment chips, a
// compact detail side panel with lifetime value / orders / saved dates
// / recent orders) that this page didn't have at all. Rebuilt to match,
// per DESIGN_DELTA.md's own method: export's state/data extracted
// first, old page consulted only to salvage working logic.
//
// ── WHAT WAS SALVAGED FROM THE OLD PAGE, ON PURPOSE ────────────────────
//
// The merge-review queue (PART V: "merges are proposals, not facts") is
// real, valuable, and not in the export at all — kept as an addition,
// same "adding what's needed is fine, cutting what's shown is not"
// rule this codebase applies everywhere else. The old page's full
// per-touchpoint timeline (every conversation/payment/sale, one feed,
// each with a provenance badge) is ALSO kept, but demoted from the
// whole detail view to a "View full timeline" reveal inside the new
// compact panel — it's a real capability the export's own "View full
// conversation history" link gestures at without actually building,
// and deleting working code just because the export drew a simpler
// link would be the subtraction DESIGN_DELTA.md forbids.
//
// ── THREE NAMED GAPS, READ BEFORE EXTENDING ────────────────────────────
//
// 1. NOTES. The export's detail panel has a free-text "Notes" section
//    ("Prefers deliveries after 5pm..."). Customer has no notes field,
//    and nothing anywhere in this codebase lets an owner annotate a
//    customer. Not rendered — a fabricated always-empty section would
//    be worse than omitting it. Real, separate future work: a
//    `Customer.notes` column plus a small edit endpoint.
//
// 2. PHONE/CHANNEL ON THE LIST ROW. The export's list row shows a
//    channel per customer ("35m ago · WhatsApp"). Cheaply available
//    for one customer (its most recent Conversation, already fetched
//    for the detail panel) but NOT cheaply available for a whole list
//    of customers at once — CustomerEndpoint.listCustomersWithSummary
//    deliberately avoids per-customer N+1 fetches for the same reason
//    it avoids one for lifetime value (see its own header). List rows
//    here show "Last contact {ago}" without a channel; the detail
//    panel — which already loads one customer's full history — shows
//    it correctly.
//
// 3. "TOP CUSTOMERS" IS A COMPUTED BAND, NOT A STORED FLAG. The export's
//    `isVip` is a fixture in its sample data. There is no VIP concept
//    anywhere server-side. This page defines "Top" as the highest-LTV
//    fifth of customers with any recorded revenue — a defensible,
//    documented rule (see `_isTop` below), not an invented one, but a
//    rule this codebase has never been asked to formalize before.

import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/kola_icon.dart';
import '../components/shell/icons.dart';
import '../services/error_text.dart';
import '../theme.dart';

class CustomersPage extends StatefulComponent {
  const CustomersPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

enum _Sort { recent, ltv, orders }

enum _Segment { all, top, newThisMonth }

class _CustomersPageState extends State<CustomersPage> {
  List<CustomerSummary> _summaries = const [];
  List<CustomerMergeProposal> _proposals = const [];
  bool _loading = true;
  String? _loadError;

  String _search = '';
  _Sort _sort = _Sort.recent;
  _Segment _segment = _Segment.all;

  int? _selectedCustomerId;
  CustomerDetail? _detail;
  bool _detailLoading = false;
  String? _detailError;
  DateTime? _detailBirthday;
  bool _showFullTimeline = false;

  final Set<int> _busyProposals = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        component.client.customer.listCustomersWithSummary(
          component.accessToken,
          component.workspaceId,
          limit: 500,
        ),
        component.client.customer.listMergeProposals(
          component.accessToken,
          component.workspaceId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _summaries = results[0] as List<CustomerSummary>;
        _proposals = results[1] as List<CustomerMergeProposal>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  Future<void> _openCustomer(int id) async {
    setState(() {
      _selectedCustomerId = id;
      _detailLoading = true;
      _detailError = null;
      _detail = null;
      _detailBirthday = null;
      _showFullTimeline = false;
    });
    try {
      final detail = await component.client.customer.getCustomerDetail(
        component.accessToken,
        component.workspaceId,
        id,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _detailLoading = false;
      });
      unawaited(_loadBirthday(detail));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = ErrorText.of(e);
        _detailLoading = false;
      });
    }
  }

  /// Best-effort "saved date" — checks each of this customer's
  /// conversations for a saved birthday, stops at the first one found.
  /// A customer can have several conversations (one per channel); the
  /// birthday is asked for and stored per-conversation (see
  /// CustomerProfile's own header from Phase 8b), so there's no single
  /// authoritative row to fetch — this is the same "small number of
  /// conversations, fine to check them all" reasoning already used for
  /// customer chips elsewhere (13c).
  Future<void> _loadBirthday(CustomerDetail detail) async {
    for (final convo in detail.conversations) {
      if (convo.id == null) continue;
      try {
        final profile = await component.client.customerProfile.getForConversation(
          component.accessToken,
          component.workspaceId,
          convo.id!,
        );
        if (profile?.birthday != null) {
          if (!mounted || _detail?.customer.id != detail.customer.id) return;
          setState(() => _detailBirthday = profile!.birthday);
          return;
        }
      } catch (_) {
        // Best-effort — a failed lookup just means no saved-date chip.
      }
    }
  }

  void _closeDetail() => setState(() {
        _selectedCustomerId = null;
        _detail = null;
        _detailError = null;
        _detailBirthday = null;
      });

  Future<void> _resolveProposal(CustomerMergeProposal proposal, bool approve) async {
    final id = proposal.id;
    if (id == null) return;
    setState(() => _busyProposals.add(id));
    try {
      await component.client.customer.resolveMergeProposal(
        component.accessToken,
        component.workspaceId,
        id,
        approve,
      );
      if (!mounted) return;
      await _load();
      if (_selectedCustomerId != null) await _openCustomer(_selectedCustomerId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyProposals.remove(id);
        _loadError = ErrorText.of(e);
      });
    }
  }

  // ── Segments / sort / filter ──────────────────────────────────────

  /// The top fifth (min. 1) of customers with any recorded lifetime
  /// value, ranked by that value — see this file's header, point 3.
  Set<int> get _topCustomerIds {
    final withRevenue = [
      for (final s in _summaries)
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

  List<CustomerSummary> get _filteredSorted {
    final top = _topCustomerIds;
    var list = [..._summaries];

    if (_segment == _Segment.top) {
      list = [for (final s in list) if (top.contains(s.customer.id)) s];
    } else if (_segment == _Segment.newThisMonth) {
      list = [for (final s in list) if (_isNewThisMonth(s.customer)) s];
    }

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = [
        for (final s in list)
          if ((s.customer.displayName ?? '').toLowerCase().contains(q)) s,
      ];
    }

    switch (_sort) {
      case _Sort.ltv:
        list.sort((a, b) => b.ltvMinor.compareTo(a.ltvMinor));
      case _Sort.orders:
        list.sort((a, b) => b.orderCount.compareTo(a.orderCount));
      case _Sort.recent:
        break; // server already returns most-recent-activity first
    }
    return list;
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:1180px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        if (_selectedCustomerId != null)
          _detailView()
        else ...[
          _header(),
          if (_loading)
            _skeleton()
          else if (_loadError != null)
            _errorState()
          else ...[
            if (_proposals.isNotEmpty) _mergeQueueSection(),
            if (_summaries.isEmpty)
              _emptyState(
                'This fills in the moment someone messages your connected '
                'channel, or you ring up a sale at the Sales Counter.',
              )
            else ...[
              _statsRow(),
              div(
                attributes: {
                  'style': 'display:grid;'
                      'grid-template-columns:1.3fr 1fr;gap:20px;'
                      'align-items:start',
                },
                [
                  div(
                    [
                      _searchAndSort(),
                      _segmentChips(),
                      _customerList(),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ],
      ],
    );
  }

  Component _header() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.lg}'},
        [
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h2};color:${KolaVar.text};'
                  'font-weight:700;margin-bottom:6px',
            },
            [Component.text('Customers')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.55;max-width:60ch',
            },
            [
              Component.text(
                "Everyone the business has talked to, with what they've "
                'bought and asked about.',
              ),
            ],
          ),
        ],
      );

  Component _statsRow() {
    final total = _summaries.length;
    final totalLtv = _summaries.fold<int>(0, (sum, s) => sum + s.ltvMinor);
    final currency = _summaries.isNotEmpty ? _summaries.first.currency : 'NGN';
    final topCount = _topCustomerIds.length;
    final newCount = _summaries.where((s) => _isNewThisMonth(s.customer)).length;

    final stats = [
      ('Total customers', '$total'),
      ('Total lifetime value', _naira(totalLtv, currency)),
      ('Top customers', '$topCount'),
      ('New this month', '$newCount'),
    ];

    return div(
      attributes: {
        'style': 'display:grid;grid-template-columns:repeat(4,1fr);'
            'gap:12px;margin-bottom:${KolaSpace.lg}',
      },
      [
        for (final (label, value) in stats)
          div(
            attributes: {
              'style': 'background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};padding:14px 16px',
            },
            [
              div(
                attributes: {
                  'style':
                      'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                      'margin-bottom:6px',
                },
                [Component.text(label)],
              ),
              div(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};'
                      'font-size:${KolaType.subhead};font-weight:600;'
                      'color:${KolaVar.text}',
                },
                [Component.text(value)],
              ),
            ],
          ),
      ],
    );
  }

  Component _searchAndSort() => div(
        attributes: {
          'style': 'display:flex;gap:8px;flex-wrap:wrap;'
              'margin-bottom:${KolaSpace.md}',
        },
        [
          div(
            attributes: {'style': 'flex:1;min-width:180px'},
            [
              input<String>(
                type: InputType.text,
                attributes: {
                  'placeholder': 'Search by name…',
                  'style': 'width:100%;box-sizing:border-box;'
                      'padding:10px 14px;border-radius:${KolaRadius.md};'
                      'border:1px solid ${KolaVar.border};'
                      'background:${KolaVar.card};color:${KolaVar.text};'
                      'font-family:inherit;font-size:${KolaType.body}',
                },
                value: _search,
                onInput: (v) => setState(() => _search = v),
              ),
            ],
          ),
          select(
            attributes: {
              'style': 'background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.md};padding:10px 12px;'
                  'color:${KolaVar.text};font-family:inherit;'
                  'font-size:${KolaType.small}',
            },
            events: {
              'change': (e) {
                final v = (e as dynamic).target?.value as String?;
                setState(() {
                  _sort = switch (v) {
                    'ltv' => _Sort.ltv,
                    'orders' => _Sort.orders,
                    _ => _Sort.recent,
                  };
                });
              },
            },
            [
              option(value: 'recent', [Component.text('Most recent')]),
              option(value: 'ltv', [Component.text('Highest value')]),
              option(value: 'orders', [Component.text('Most orders')]),
            ],
          ),
        ],
      );

  Component _segmentChips() {
    final chips = [
      (_Segment.all, 'All'),
      (_Segment.top, 'Top customers'),
      (_Segment.newThisMonth, 'New'),
    ];
    return div(
      attributes: {
        'style': 'display:flex;gap:6px;flex-wrap:wrap;'
            'margin-bottom:${KolaSpace.md}',
      },
      [
        for (final (seg, label) in chips)
          button(
            attributes: {
              'type': 'button',
              'style':
                  'border:1px solid ${_segment == seg ? '#3A3733' : KolaVar.border};'
                  'padding:7px 13px;border-radius:${KolaRadius.pill};'
                  'font-size:${KolaType.tiny};font-family:inherit;'
                  'cursor:pointer;white-space:nowrap;'
                  'background:${_segment == seg ? KolaVar.pill : 'transparent'};'
                  'color:${_segment == seg ? KolaVar.text : KolaVar.muted}',
            },
            events: {'click': (_) => setState(() => _segment = seg)},
            [Component.text(label)],
          ),
      ],
    );
  }

  Component _customerList() {
    final filtered = _filteredSorted;
    if (filtered.isEmpty) {
      return _emptyState(
        _search.trim().isEmpty
            ? 'No customers match this filter.'
            : 'No customers match "$_search"',
      );
    }
    final top = _topCustomerIds;

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};overflow:hidden',
      },
      [for (final s in filtered) _customerRow(s, isTop: top.contains(s.customer.id))],
    );
  }

  Component _customerRow(CustomerSummary s, {required bool isTop}) {
    final c = s.customer;
    final isNew = _isNewThisMonth(c);
    final initial = (c.displayName?.trim().isNotEmpty ?? false) ? c.displayName!.trim()[0].toUpperCase() : '?';

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:12px;'
            'padding:13px 16px;border-bottom:1px solid ${KolaVar.border};'
            'cursor:pointer',
      },
      events: {'click': (_) => c.id != null ? _openCustomer(c.id!) : null},
      [
        div(
          attributes: {
            'style': 'width:34px;height:34px;border-radius:${KolaRadius.circle};'
                'background:${KolaVar.pill};display:flex;'
                'align-items:center;justify-content:center;'
                'font-size:${KolaType.small};font-weight:600;flex:none',
          },
          [Component.text(initial)],
        ),
        div(
          attributes: {'style': 'flex:1;min-width:0'},
          [
            div(
              attributes: {'style': 'display:flex;align-items:center;gap:6px'},
              [
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.small};font-weight:600;'
                        'color:${KolaVar.text};overflow:hidden;'
                        'text-overflow:ellipsis;white-space:nowrap',
                  },
                  [Component.text(c.displayName ?? 'Unnamed customer')],
                ),
                if (isTop)
                  span(
                    attributes: {
                      'style': 'font-size:9.5px;font-weight:700;'
                          'background:${KolaVar.pill};color:${KolaVar.accent};'
                          'border-radius:${KolaRadius.pill};padding:1px 6px',
                    },
                    [Component.text('TOP')],
                  ),
                if (isNew)
                  span(
                    attributes: {
                      'style': 'font-size:9.5px;font-weight:700;'
                          'background:${KolaVar.infoBg};color:${KolaVar.infoText};'
                          'border-radius:${KolaRadius.pill};padding:1px 6px',
                    },
                    [Component.text('NEW')],
                  ),
              ],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
              },
              [
                Component.text(
                  s.lastActivityAt == null ? 'No activity yet' : 'Last contact ${_ago(s.lastActivityAt!)}',
                ),
              ],
            ),
          ],
        ),
        div(
          attributes: {'style': 'text-align:right;flex:none'},
          [
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.mono};'
                    'font-size:${KolaType.small};color:${KolaVar.mutedStrong}',
              },
              [Component.text(_naira(s.ltvMinor, s.currency))],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.micro};color:${KolaVar.muted}',
              },
              [Component.text('${s.orderCount} orders')],
            ),
          ],
        ),
      ],
    );
  }

  // ── Merge review queue ────────────────────────────────────────────

  Component _mergeQueueSection() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.xxl}'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.uiLg};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('Possible duplicate customers')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'margin-bottom:${KolaSpace.md};line-height:1.5',
            },
            [
              Component.text(
                'kolaa noticed these might be the same person. Nothing is '
                'combined until you confirm — a wrong merge would mix two '
                "people's order histories.",
              ),
            ],
          ),
          div(
            attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
            [for (final p in _proposals) _proposalCard(p)],
          ),
        ],
      );

  Component _proposalCard(CustomerMergeProposal p) {
    final busy = _busyProposals.contains(p.id);
    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};background:${KolaVar.card};'
            'padding:${KolaSpace.md} ${KolaSpace.lg}',
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.text};'
                'line-height:1.5;margin-bottom:10px',
          },
          [Component.text(p.matchedOn)],
        ),
        div(
          attributes: {'style': 'display:flex;gap:8px;flex-wrap:wrap'},
          [
            button(
              attributes: {
                'type': 'button',
                if (busy) 'disabled': 'disabled',
                'style': 'background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};border:none;'
                    'border-radius:${KolaRadius.sm};padding:8px 16px;'
                    'font-size:${KolaType.small};font-weight:700;'
                    'font-family:inherit;'
                    'cursor:${busy ? 'default' : 'pointer'}',
              },
              events: {
                'click': (_) {
                  if (!busy) _resolveProposal(p, true);
                },
              },
              [Component.text(busy ? 'Working…' : 'Yes, same customer')],
            ),
            button(
              attributes: {
                'type': 'button',
                if (busy) 'disabled': 'disabled',
                'style': 'background:transparent;'
                    'border:1px solid ${KolaVar.border};color:${KolaVar.muted};'
                    'border-radius:${KolaRadius.sm};padding:8px 16px;'
                    'font-size:${KolaType.small};font-weight:600;'
                    'font-family:inherit;'
                    'cursor:${busy ? 'default' : 'pointer'}',
              },
              events: {
                'click': (_) {
                  if (!busy) _resolveProposal(p, false);
                },
              },
              [Component.text('No, different people')],
            ),
          ],
        ),
      ],
    );
  }

  // ── Customer detail ────────────────────────────────────────────────

  Component _detailView() {
    if (_detailLoading) return _skeleton();
    if (_detailError != null) return _errorState(inDetail: true);
    final detail = _detail;
    if (detail == null) return _skeleton();

    final summary = _summaries.firstWhereOrNull((s) => s.customer.id == detail.customer.id);
    final latestConvo = detail.conversations.isEmpty
        ? null
        : ([...detail.conversations]..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt))).first;
    final phone = detail.signals
        .firstWhereOrNull((s) => s.signalType == 'phone')
        ?.normalizedValue;

    final recentOrders = _recentOrders(detail);

    return div([
      div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:10px;'
              'margin-bottom:${KolaSpace.lg}',
        },
        [
          button(
            attributes: {
              'type': 'button',
              'style': 'background:transparent;border:none;'
                  'color:${KolaVar.muted};cursor:pointer;display:flex;padding:4px',
            },
            events: {'click': (_) => _closeDetail()},
            [kolaIcon(Icons.chevronLeft, size: 18)],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h3};font-weight:700;color:${KolaVar.text}',
            },
            [Component.text(detail.customer.displayName ?? 'Unnamed customer')],
          ),
        ],
      ),
      div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:22px;max-width:420px',
        },
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:center;gap:12px;'
                  'margin-bottom:16px',
            },
            [
              div(
                attributes: {
                  'style': 'width:44px;height:44px;'
                      'border-radius:${KolaRadius.circle};'
                      'background:${KolaVar.accentFill};display:flex;'
                      'align-items:center;justify-content:center;'
                      'font-size:${KolaType.subhead};font-weight:600;'
                      'color:${KolaVar.accentText};flex:none',
                },
                [
                  Component.text(
                    (detail.customer.displayName?.trim().isNotEmpty ?? false)
                        ? detail.customer.displayName!.trim()[0].toUpperCase()
                        : '?',
                  ),
                ],
              ),
              div(
                [
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.lead};font-weight:600;'
                          'color:${KolaVar.text}',
                    },
                    [Component.text(detail.customer.displayName ?? 'Unnamed customer')],
                  ),
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
                    },
                    [
                      Component.text([
                        if (phone != null) phone,
                        if (latestConvo != null) _sourceLabel(latestConvo.platformType),
                      ].join(' · ')),
                    ],
                  ),
                ],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'display:grid;grid-template-columns:1fr 1fr;'
                  'gap:8px;margin-bottom:16px',
            },
            [
              _statChip('Lifetime value', _naira(summary?.ltvMinor ?? 0, summary?.currency ?? 'NGN')),
              _statChip('Orders', '${summary?.orderCount ?? 0}'),
            ],
          ),
          _detailLabel('Customer since'),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};margin-bottom:16px',
            },
            [Component.text(_ago(detail.customer.firstSeenAt))],
          ),
          _detailLabel('Saved dates'),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};margin-bottom:16px;'
                  'color:${_detailBirthday == null ? KolaVar.muted : KolaVar.text}',
            },
            [
              Component.text(
                _detailBirthday == null ? 'Nothing saved yet' : '🎂 Birthday — ${_monthDay(_detailBirthday!)}',
              ),
            ],
          ),
          _detailLabel('Recent orders'),
          div(
            attributes: {
              'style': 'display:flex;flex-direction:column;gap:6px;'
                  'margin-bottom:16px',
            },
            [
              if (recentOrders.isEmpty)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
                  },
                  [Component.text('No orders yet')],
                )
              else
                for (final o in recentOrders)
                  div(
                    attributes: {
                      'style': 'display:flex;justify-content:space-between;'
                          'font-size:${KolaType.small}',
                    },
                    [
                      span(
                        attributes: {'style': 'color:${KolaVar.muted}'},
                        [Component.text('${o.$1} · ${_shortDate(o.$2)}')],
                      ),
                      span([Component.text(o.$3)]),
                    ],
                  ),
            ],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'display:block;width:100%;text-align:center;'
                  'background:transparent;border:1px solid ${KolaVar.border};'
                  'color:${KolaVar.text};border-radius:${KolaRadius.sm};'
                  'padding:9px;font-size:${KolaType.small};'
                  'font-family:inherit;cursor:pointer',
            },
            events: {'click': (_) => setState(() => _showFullTimeline = !_showFullTimeline)},
            [Component.text(_showFullTimeline ? 'Hide full timeline' : 'View full timeline')],
          ),
        ],
      ),
      if (_showFullTimeline) ...[
        div(
          attributes: {
            'style': 'font-size:${KolaType.uiLg};font-weight:700;'
                'color:${KolaVar.text};margin:${KolaSpace.lg} 0 ${KolaSpace.md}',
          },
          [Component.text('Timeline')],
        ),
        _identitySignalsRow(detail.signals),
        _timelineList(detail),
      ],
    ]);
  }

  Component _statChip(String label, String value) => div(
        attributes: {
          'style': 'background:${KolaVar.bg};border-radius:${KolaRadius.sm};'
              'padding:10px 12px',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.micro};color:${KolaVar.muted}',
            },
            [Component.text(label)],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};font-size:${KolaType.ui};'
                  'font-weight:600;margin-top:2px;color:${KolaVar.text}',
            },
            [Component.text(value)],
          ),
        ],
      );

  Component _detailLabel(String text) => div(
        attributes: {
          'style': 'font-size:${KolaType.micro};color:${KolaVar.muted};'
              'text-transform:uppercase;letter-spacing:0.05em;'
              'margin-bottom:8px',
        },
        [Component.text(text)],
      );

  /// Sales + unmatched payments, same dedup rule as everywhere else in
  /// this phase (13c/13e/13f's own listCustomersWithSummary): a
  /// completed payment already reconciled to a Sale isn't listed twice.
  /// Newest 3.
  List<(String, DateTime, String)> _recentOrders(CustomerDetail detail) {
    final reconciledSaleIds = {
      for (final p in detail.payments)
        if (p.saleId != null) p.saleId!,
    };
    final items = <(String, DateTime, String)>[
      for (final s in detail.sales)
        if (s.status == 'completed' && (s.id == null || !reconciledSaleIds.contains(s.id)))
          (s.reference, s.soldAt, _naira(s.totalMinor, s.currency)),
      for (final p in detail.payments)
        if (p.status == 'completed')
          (p.reference, p.createdAt, _naira(p.amountKobo, p.currency)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return items.take(3).toList();
  }

  Component _identitySignalsRow(List<CustomerIdentitySignal> signals) {
    if (signals.isEmpty) return div(const []);
    return div(
      attributes: {'style': 'display:flex;gap:6px;flex-wrap:wrap;margin-bottom:${KolaSpace.md}'},
      [
        for (final s in signals)
          span(
            attributes: {
              'style': 'font-size:${KolaType.micro};background:${KolaVar.pill};'
                  'color:${KolaVar.mutedStrong};padding:4px 10px;'
                  'border-radius:${KolaRadius.pill};font-family:${KolaFonts.mono}',
            },
            [Component.text(s.normalizedValue)],
          ),
      ],
    );
  }

  Component _timelineList(CustomerDetail detail) {
    final items = <(DateTime at, Component row)>[
      for (final conv in detail.conversations)
        (conv.lastMessageAt, _timelineRow(
          source: conv.platformType,
          title: 'Conversation',
          subtitle: conv.displayName ?? conv.externalUserId,
          at: conv.lastMessageAt,
        )),
      for (final pay in detail.payments)
        (pay.createdAt, _timelineRow(
          source: pay.gateway,
          title: pay.status == 'completed' ? 'Payment received' : 'Payment ${pay.status}',
          subtitle: '${pay.currency} ${(pay.amountKobo / 100).toStringAsFixed(2)}',
          at: pay.createdAt,
        )),
      for (final sale in detail.sales)
        (sale.soldAt, _timelineRow(
          source: 'till',
          title: 'Sale ${sale.reference}',
          subtitle: '${sale.currency} ${(sale.totalMinor / 100).toStringAsFixed(2)} · ${sale.paymentMethod}',
          at: sale.soldAt,
        )),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    if (items.isEmpty) return _emptyState('Nothing recorded for this customer yet.');

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};overflow:hidden;'
            'background:${KolaVar.card}',
      },
      [for (final (_, row) in items) row],
    );
  }

  Component _timelineRow({
    required String source,
    required String title,
    required String subtitle,
    required DateTime at,
  }) =>
      div(
        attributes: {
          'style': 'display:flex;align-items:center;justify-content:space-between;'
              'padding:${KolaSpace.lmd} ${KolaSpace.lg};gap:${KolaSpace.md};'
              'border-top:1px solid ${KolaVar.border}',
        },
        [
          div(
            attributes: {'style': 'min-width:0;flex:1;display:flex;align-items:center;gap:10px'},
            [
              span(
                attributes: {
                  'style': 'font-size:${KolaType.micro};background:${KolaVar.pill};'
                      'color:${KolaVar.mutedStrong};padding:3px 9px;'
                      'border-radius:${KolaRadius.pill};flex:none',
                },
                [Component.text(_sourceLabel(source))],
              ),
              div([
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.body};font-weight:600;'
                        'color:${KolaVar.text}',
                  },
                  [Component.text(title)],
                ),
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
                  },
                  [Component.text(subtitle)],
                ),
              ]),
            ],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};flex:none',
            },
            [Component.text(_ago(at))],
          ),
        ],
      );

  // ── Shared states ──────────────────────────────────────────────────

  Component _emptyState(String message) => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:${KolaSpace.xl};'
              'text-align:center;font-size:${KolaType.small};'
              'color:${KolaVar.muted}',
        },
        [Component.text(message)],
      );

  Component _skeleton() => div(
        [
          for (var i = 0; i < 3; i++)
            div(
              attributes: {
                'style': 'height:70px;border-radius:${KolaRadius.md};'
                    'border:1px solid ${KolaVar.border};'
                    'background:${KolaVar.card};margin-bottom:${KolaSpace.sm}',
              },
              const [],
            ),
        ],
      );

  Component _errorState({bool inDetail = false}) => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:${KolaSpace.lg}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('Could not load customers')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.55;margin-bottom:12px',
            },
            [Component.text('This is a connection problem. Nothing here has changed.')],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'padding:9px 15px;border-radius:${KolaRadius.sm};'
                  'border:none;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.body};font-weight:600;cursor:pointer',
            },
            events: {
              'click': (_) => inDetail && _selectedCustomerId != null
                  ? _openCustomer(_selectedCustomerId!)
                  : _load(),
            },
            [Component.text('Try again')],
          ),
        ],
      );

  // ── Helpers ────────────────────────────────────────────────────────

  String _sourceLabel(String source) => switch (source) {
        'whatsapp' => 'WhatsApp',
        'telegram' => 'Telegram',
        'paystack' => 'Paystack',
        'flutterwave' => 'Flutterwave',
        'till' => 'Till',
        _ => source,
      };

  static String _naira(int minor, String currency) {
    final major = minor / 100;
    return '$currency ${major.toStringAsFixed(2)}';
  }

  static String _monthDay(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String _shortDate(DateTime d) => _monthDay(d);

  String _ago(DateTime when) {
    final diff = DateTime.now().toUtc().difference(when.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 365}y ago';
  }
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
