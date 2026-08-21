// customers_page.dart — Gate 3 / Gate 3b. Design brief §8.11: "Every
// person the business has talked to: profile, full conversation
// history, orders and payments... a CRM surface the product does not
// yet have and genuinely needs." This is that page, and it doubles as
// Gate 3b's proof surface — see migration 039_customer_graph.sql's
// header on why building one screen here instead of a throwaway
// timeline view plus a "real" Customers page later.
//
// ── LIST -> DETAIL AS INTERNAL STATE, NOT A SEPARATE ROUTE ────────────
//
// bots_page.dart/bot_detail_chat_page.dart use a real /bots/:id route.
// This page keeps selection as state instead — a customer id is not
// something anyone bookmarks or shares yet (no public customer-facing
// surface exists), and a single page keeps the merge-review queue
// visible from both the list and a detail view without a second route
// having to know about it too. Worth revisiting once deep-linking to a
// specific customer becomes a real need (e.g. from Operations' escalation
// inbox — see that page's own header on its still-gated customer chips).
//
// ── SAME SHAPE AS api_webhooks_page.dart ──────────────────────────────
//
// Load -> render from server state -> mutate through the endpoint ->
// reload the one section that changed. No client-side merge/dedupe
// logic of its own — CustomerEndpoint.getCustomerDetail already
// resolves through any prior merge server-side.

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

class _CustomersPageState extends State<CustomersPage> {
  List<Customer> _customers = const [];
  List<CustomerMergeProposal> _proposals = const [];
  bool _loading = true;
  String? _loadError;
  String _search = '';

  int? _selectedCustomerId;
  CustomerDetail? _detail;
  bool _detailLoading = false;
  String? _detailError;

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
        component.client.customer.listCustomers(
          component.accessToken,
          component.workspaceId,
          // Serverpod's generated client drops default values — see
          // till_page.dart's own note on this same landmine.
          limit: 100,
          offset: 0,
        ),
        component.client.customer.listMergeProposals(
          component.accessToken,
          component.workspaceId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _customers = results[0] as List<Customer>;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = ErrorText.of(e);
        _detailLoading = false;
      });
    }
  }

  void _closeDetail() => setState(() {
        _selectedCustomerId = null;
        _detail = null;
        _detailError = null;
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
      // A confirmed merge changes what listCustomers/getCustomerDetail
      // return (the loser disappears from the list; its records now
      // resolve to the survivor) — reload rather than patch client
      // state, same discipline api_webhooks_page.dart uses after revoke.
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

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:960px;margin:0 auto;'
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
            _searchBar(),
            _customerList(),
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
                'Every person your business has talked to — conversations, '
                'payments and sales, unified across WhatsApp, Telegram, '
                'Paystack, Flutterwave and your till.',
              ),
            ],
          ),
        ],
      );

  // ── Merge review queue ────────────────────────────────────────────
  //
  // PART V: "Merges are proposals, not facts... the owner confirms."
  // This is that confirmation surface.

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

  // ── Customer list ──────────────────────────────────────────────────

  Component _searchBar() => input<String>(
        type: InputType.text,
        attributes: {
          'placeholder': 'Search by name…',
          'style': 'width:100%;box-sizing:border-box;padding:11px 13px;'
              'border-radius:${KolaRadius.md};border:1px solid ${KolaVar.border};'
              'background:${KolaVar.card};color:${KolaVar.text};'
              'font-family:inherit;font-size:${KolaType.body};'
              'margin-bottom:${KolaSpace.md}',
        },
        value: _search,
        onInput: (v) => setState(() => _search = v),
      );

  Component _customerList() {
    final q = _search.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _customers
        : [
            for (final c in _customers)
              if ((c.displayName ?? '').toLowerCase().contains(q)) c,
          ];

    if (filtered.isEmpty) {
      return _emptyState(
        _customers.isEmpty
            ? 'No customers yet — they show up here the moment someone '
                'messages you, pays you, or buys something at the till.'
            : 'No customers match that search.',
      );
    }

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};overflow:hidden;'
            'background:${KolaVar.card}',
      },
      [for (final c in filtered) _customerRow(c)],
    );
  }

  Component _customerRow(Customer c) => div(
        attributes: {
          'style': 'display:flex;align-items:center;justify-content:space-between;'
              'padding:${KolaSpace.lmd} ${KolaSpace.lg};gap:${KolaSpace.md};'
              'border-top:1px solid ${KolaVar.border};cursor:pointer',
        },
        events: {'click': (_) => _openCustomer(c.id!)},
        [
          div(
            attributes: {'style': 'min-width:0;flex:1'},
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                      'color:${KolaVar.text};margin-bottom:3px',
                },
                [Component.text(c.displayName ?? 'Unnamed customer')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
                },
                [Component.text('First seen via ${_sourceLabel(c.firstSeenSource)}')],
              ),
            ],
          ),
          kolaIcon(Icons.chevronRight, size: 16, extraStyle: 'color:${KolaVar.muted}'),
        ],
      );

  // ── Customer detail — the unified timeline ────────────────────────

  Component _detailView() {
    if (_detailLoading) return _skeleton();
    if (_detailError != null) return _errorState(inDetail: true);
    final detail = _detail;
    if (detail == null) return _skeleton();

    // Every touchpoint, one feed, oldest-agnostic (each item carries
    // its own timestamp) — PART V: "every record carries... provenance"
    // made visible as a source badge per row.
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
      _identitySignalsRow(detail.signals),
      div(
        attributes: {
          'style': 'font-size:${KolaType.uiLg};font-weight:700;'
              'color:${KolaVar.text};margin:${KolaSpace.lg} 0 ${KolaSpace.md}',
        },
        [Component.text('Timeline')],
      ),
      if (items.isEmpty)
        _emptyState('Nothing recorded for this customer yet.')
      else
        div(
          attributes: {
            'style': 'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};overflow:hidden;'
                'background:${KolaVar.card}',
          },
          [for (final (_, row) in items) row],
        ),
    ]);
  }

  Component _identitySignalsRow(List<CustomerIdentitySignal> signals) {
    if (signals.isEmpty) return div(const []);
    return div(
      attributes: {'style': 'display:flex;gap:6px;flex-wrap:wrap'},
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
