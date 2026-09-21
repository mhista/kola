// customers_page.dart — Gate 3 / Gate 3b, rebuilt Phase 13f against
// `Kola Customers.dc.html`, then rebuilt again Phase 14/186 after the
// owner sent real screenshots of the authoritative UI and asked for an
// exact match. Re-checked directly against the export's own `state`/
// `renderVals()` this pass rather than against the Phase 13f page.
//
// ── WHAT WAS SALVAGED, ON PURPOSE ──────────────────────────────────────
//
// The merge-review queue (PART V: "merges are proposals, not facts") is
// real, valuable, and not in the export at all — kept as an addition,
// same "adding what's needed is fine, cutting what's shown is not" rule
// this codebase applies everywhere else. The old page's full
// per-touchpoint timeline (every conversation/payment/sale, one feed,
// each with a provenance badge) is ALSO kept, reachable via "View full
// timeline" inside the detail panel — a real capability the export's
// own "View full conversation history" link gestures at without
// actually building (it links to Operations, which has no per-customer
// deep-link target — checked operations_page.dart this pass: no
// customerId query param support exists). Deleting working code because
// the export drew a simpler link would be the subtraction
// DESIGN_DELTA.md forbids.
//
// ── PHASE 14/186 — WHAT CHANGED AGAINST THE EXPORT, NOT AGAINST 13f ────
//
//   • No back-link existed at all. Same "Dashboard / Customers"
//     breadcrumb adaptation recommendations_page.dart and
//     timeline_page.dart already made for this persistent-shell app, in
//     place of the export's isolated-preview "‹ Dashboard" arrow.
//   • THE BIGGEST GAP: the export's layout is a PERSISTENT two-column
//     split — list on the left, a detail panel for "whichever customer
//     is selected (defaults to the first)" on the right, both on screen
//     together. The 13f build instead replaced the whole page with a
//     full-width detail view on click, with no second column ever
//     rendered. Rebuilt: [_selectedCustomerId] now defaults to the
//     first customer in the loaded (most-recent-activity-first) list as
//     soon as it loads, and the detail panel renders in a permanent
//     right column beside the list — exactly the export's own
//     `selected` + two-column grid. Mobile collapses to the export's
//     own second behaviour: a full-screen overlay opened by tapping a
//     row ([_mobileDetailOpen]), closed by a back button — not a third
//     invented pattern.
//   • Search placeholder was "Search by name…"; the export's is "Search
//     by name or phone…" and means it — CustomerEndpoint now bulk-
//     fetches phone signals for the whole workspace in the SAME loop
//     that already computes lastActivityAt (see that endpoint's own
//     header), so search now matches phone too, not just a relabelled
//     text box.
//   • List rows omitted the channel ("Last contact 35m ago · WhatsApp")
//     — the 13f header named this as "not cheaply available for a
//     whole list at once." Re-checked this pass: CustomerEndpoint was
//     already looping every Sale/PaymentTransaction/Conversation to
//     compute [lastActivityAt]; recording which SOURCE won that loop
//     was free. `CustomerSummary.lastActivityChannel` is real now, no
//     new query.
//
// ── NAMED GAPS THAT REMAIN, READ BEFORE EXTENDING ──────────────────────
//
// 1. NOTES — real. `Customer.notes` (migration 062) plus
//    `CustomerEndpoint.updateCustomerNotes` back the editable free-text
//    field in the detail panel below. Owner-written only.
//
// 2. "TOP CUSTOMERS" IS A COMPUTED BAND, NOT A STORED FLAG. The export's
//    `isVip` is a fixture in its sample data. There is no VIP concept
//    anywhere server-side. This page defines "Top" as the highest-LTV
//    fifth of customers with any recorded revenue — a defensible,
//    documented rule (see `_topCustomerIds` below), not an invented one.

import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/kola_icon.dart';
import '../components/shell/icons.dart';
import '../components/shell/page_help_button.dart';
import '../services/error_text.dart';
import '../services/responsive.dart';
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

class _CustomersPageState extends State<CustomersPage>
    with ResponsiveViewport<CustomersPage> {
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

  /// The export's own mobile behaviour: a full-screen overlay opened by
  /// tapping a list row, closed by its own back button. Desktop never
  /// sets this — the detail panel is always on screen there.
  bool _mobileDetailOpen = false;

  // Phase 14h — free-text notes. Draft is local state so typing doesn't
  // round-trip to the server on every keystroke; saved explicitly.
  String _notesDraft = '';
  bool _notesSaving = false;
  String? _notesError;

  final Set<int> _busyProposals = {};

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
      final summaries = results[0] as List<CustomerSummary>;
      setState(() {
        _summaries = summaries;
        _proposals = results[1] as List<CustomerMergeProposal>;
        _loading = false;
      });
      // The export's own default: `selected` is always the first
      // customer in the list, on screen in the right-hand panel before
      // anyone clicks anything — never an empty panel with a populated
      // list beside it.
      final firstId = summaries.isEmpty ? null : summaries.first.customer.id;
      if (firstId != null && _selectedCustomerId == null) {
        unawaited(_openCustomer(firstId));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  Future<void> _openCustomer(int id, {bool openMobileOverlay = false}) async {
    setState(() {
      _selectedCustomerId = id;
      _detailLoading = true;
      _detailError = null;
      _detail = null;
      _detailBirthday = null;
      _showFullTimeline = false;
      _notesDraft = '';
      _notesError = null;
      if (openMobileOverlay) _mobileDetailOpen = true;
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
        _notesDraft = detail.customer.notes ?? '';
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

  /// Mobile-only "back to the list" — never deselects the customer
  /// (desktop's detail panel would otherwise go blank), only closes the
  /// full-screen overlay.
  void _closeMobileDetail() => setState(() => _mobileDetailOpen = false);

  /// Phase 14h. Saves the current draft as this customer's note — an
  /// all-blank draft clears it (see CustomerRepository.setNotes). Patches
  /// the already-loaded CustomerDetail in place with the endpoint's
  /// returned Customer rather than re-fetching the whole detail.
  Future<void> _saveNotes() async {
    final detail = _detail;
    final customerId = detail?.customer.id;
    if (detail == null || customerId == null || _notesSaving) return;
    setState(() {
      _notesSaving = true;
      _notesError = null;
    });
    try {
      final updated = await component.client.customer.updateCustomerNotes(
        component.accessToken,
        component.workspaceId,
        customerId,
        _notesDraft,
      );
      if (!mounted || _detail?.customer.id != customerId) return;
      setState(() {
        _detail = CustomerDetail(
          customer: updated,
          signals: detail.signals,
          conversations: detail.conversations,
          payments: detail.payments,
          sales: detail.sales,
        );
        _notesDraft = updated.notes ?? '';
        _notesSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notesSaving = false;
        _notesError = ErrorText.of(e);
      });
    }
  }

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
  /// value, ranked by that value — see this file's header, point 2.
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
          if ((s.customer.displayName ?? '').toLowerCase().contains(q) ||
              (s.phone ?? '').toLowerCase().contains(q))
            s,
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
        _breadcrumb(),
        _header(),
        if (_loading)
          _skeleton()
        else if (_loadError != null)
          _errorState()
        else ...[
          if (_proposals.isNotEmpty) _mergeQueueSection(),
          if (_summaries.isEmpty) _emptyWorkspaceState() else ..._populatedBody(),
        ],
        if (isMobile && _mobileDetailOpen) _mobileDetailOverlay(),
      ],
    );
  }

  /// "Dashboard / Customers" — same adaptation of the export's "‹
  /// Dashboard" link that recommendations_page.dart and
  /// timeline_page.dart already made for this persistent-shell app.
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
            [Component.text('Customers')],
          ),
        ],
      );

  Component _header() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.lg}'},
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:flex-start;'
                  'justify-content:space-between;gap:12px',
            },
            [
              div(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};'
                      'font-size:${KolaType.h2};color:${KolaVar.text};'
                      'font-weight:700;margin-bottom:6px',
                },
                [Component.text('Customers')],
              ),
              const PageHelpButton(
                pageKey: 'customers',
                body: [
                  "Everyone the business has talked to, with what "
                      "they've bought and asked about. Use the search "
                      "and filter chips to narrow to top spenders or "
                      "customers new this month.",
                  "Open a customer to see their lifetime value, order "
                      "history, saved dates, and any notes you've kept "
                      "on them.",
                ],
              ),
            ],
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

  List<Component> _populatedBody() => [
        _statsRow(),
        div(
          attributes: {
            'style': 'display:${isMobile ? 'block' : 'grid'};'
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
            if (!isMobile) _detailColumn(),
          ],
        ),
      ];

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
        'style': 'display:grid;'
            'grid-template-columns:repeat(${isMobile ? 2 : 4},1fr);'
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
                  'placeholder': 'Search by name or phone…',
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
    final isSelected = !isMobile && c.id != null && c.id == _selectedCustomerId;
    final initial = (c.displayName?.trim().isNotEmpty ?? false) ? c.displayName!.trim()[0].toUpperCase() : '?';

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:12px;'
            'padding:13px 16px;border-bottom:1px solid ${KolaVar.border};'
            'cursor:pointer;background:${isSelected ? KolaVar.pill : 'transparent'}',
      },
      events: {
        'click': (_) => c.id != null
            ? _openCustomer(c.id!, openMobileOverlay: isMobile)
            : null,
      },
      [
        div(
          attributes: {
            'style': 'width:34px;height:34px;border-radius:${KolaRadius.circle};'
                'background:${isSelected ? KolaVar.accentFill : KolaVar.pill};'
                'color:${isSelected ? KolaVar.accentText : KolaVar.text};'
                'display:flex;align-items:center;justify-content:center;'
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
                  s.lastActivityAt == null
                      ? 'No activity yet'
                      : 'Last contact ${_ago(s.lastActivityAt!)}'
                          '${s.lastActivityChannel == null ? '' : ' · ${s.lastActivityChannel}'}',
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

  /// Desktop's persistent right column — the export's own sticky panel.
  Component _detailColumn() => div(
        attributes: {'style': 'position:sticky;top:24px'},
        [_detailPanel()],
      );

  /// The export's own mobile behaviour — a full-screen overlay with its
  /// own back button, opened by tapping a list row.
  Component _mobileDetailOverlay() => div(
        attributes: {
          'style': 'position:fixed;inset:0;background:${KolaVar.bg};'
              'z-index:100;overflow-y:auto',
        },
        [
          div(
            attributes: {
              'style': 'max-width:480px;margin:0 auto;padding:20px 16px 40px',
            },
            [
              button(
                attributes: {
                  'type': 'button',
                  'style': 'background:transparent;border:none;'
                      'color:${KolaVar.muted};cursor:pointer;display:flex;'
                      'align-items:center;gap:4px;padding:8px 0;'
                      'font-size:${KolaType.bodyLg};font-family:inherit;'
                      'min-height:44px',
                },
                events: {'click': (_) => _closeMobileDetail()},
                [kolaIcon(Icons.chevronLeft, size: 16), Component.text('Customers')],
              ),
              _detailPanel(),
            ],
          ),
        ],
      );

  /// The detail panel body — shared by the desktop sticky column and
  /// the mobile full-screen overlay, matching the export's own
  /// identical two copies of this markup.
  Component _detailPanel() {
    if (_detailLoading) return _skeleton();
    if (_detailError != null) return _errorState(inDetail: true);
    final detail = _detail;
    if (detail == null) {
      return _emptyState('Select a customer to see their details.');
    }

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
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:22px',
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
          _detailLabel('Notes'),
          div(
            attributes: {'style': 'margin-bottom:16px'},
            [
              textarea(
                [Component.text(_notesDraft)],
                rows: 3,
                onInput: (v) => setState(() => _notesDraft = v),
                attributes: {
                  'aria-label': 'Notes about this customer',
                  'placeholder': 'Prefers deliveries after 5pm…',
                  'style': 'width:100%;box-sizing:border-box;padding:9px 11px;'
                      'border-radius:${KolaRadius.sm};'
                      'border:1px solid ${KolaVar.border};'
                      'background:${KolaVar.bg};color:${KolaVar.text};'
                      'font-size:${KolaType.small};font-family:inherit;'
                      'resize:vertical',
                },
              ),
              div(
                attributes: {
                  'style': 'display:flex;justify-content:space-between;'
                      'align-items:center;margin-top:6px;gap:8px',
                },
                [
                  span(
                    attributes: {
                      'style': 'font-size:${KolaType.tiny};'
                          'color:${_notesError != null ? KolaVar.danger : KolaVar.muted}',
                    },
                    [
                      Component.text(
                        _notesError ??
                            (_notesSaving
                                ? 'Saving…'
                                : (_notesDraft.trim() == (_detail?.customer.notes ?? '').trim()
                                    ? 'Owner-written · not sent to the customer'
                                    : 'Unsaved changes')),
                      ),
                    ],
                  ),
                  button(
                    attributes: {
                      'type': 'button',
                      'style': 'flex:none;background:${KolaVar.accent};'
                          'color:${KolaVar.accentText};border:none;'
                          'border-radius:${KolaRadius.sm};padding:6px 14px;'
                          'font-size:${KolaType.tiny};font-weight:600;'
                          'font-family:inherit;'
                          '${_notesSaving || _notesDraft.trim() == (_detail?.customer.notes ?? '').trim() ? 'opacity:0.5;cursor:default' : 'cursor:pointer'}',
                      if (_notesSaving || _notesDraft.trim() == (_detail?.customer.notes ?? '').trim())
                        'disabled': 'true',
                    },
                    events: {'click': (_) => _saveNotes()},
                    [Component.text('Save')],
                  ),
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
            [Component.text(_showFullTimeline ? 'Hide full timeline' : 'View full conversation history')],
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

  Component _emptyWorkspaceState() => div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.xl};padding:48px 28px;'
              'text-align:center;margin-top:18px',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.title};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:8px',
            },
            [Component.text('No customers yet')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'max-width:380px;margin:0 auto 20px;line-height:1.5',
            },
            [
              Component.text(
                'This fills in the moment someone messages your connected '
                'channel, or you ring up a sale at the Sales Counter.',
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'display:flex;gap:10px;justify-content:center;flex-wrap:wrap',
            },
            [
              Link(
                to: '/integrations',
                attributes: {
                  'style': 'background:${KolaVar.accentFill};'
                      'color:${KolaVar.accentText};border-radius:${KolaRadius.pill};'
                      'padding:10px 18px;font-size:${KolaType.bodyLg};'
                      'font-weight:600;text-decoration:none',
                },
                children: [Component.text('Connect a channel')],
              ),
              Link(
                to: '/counter',
                attributes: {
                  'style': 'background:transparent;border:1px solid ${KolaVar.border};'
                      'color:${KolaVar.text};border-radius:${KolaRadius.pill};'
                      'padding:10px 18px;font-size:${KolaType.bodyLg};'
                      'font-weight:600;text-decoration:none',
                },
                children: [Component.text('Open Sales Counter')],
              ),
            ],
          ),
        ],
      );

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
