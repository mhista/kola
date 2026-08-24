// documents_page.dart — receipts, invoices and reports, one sale in
// every form it needs to take. Linked from Kola Till.dc.html's header
// and its post-sale "Print" action; rebuilt against
// Kola Documents.dc.html, pixel-for-pixel, using this codebase's own
// KolaVar/KolaType/KolaRadius tokens rather than the export's literal
// hex values.
//
// ── WHAT IS REAL HERE, AND WHAT ISN'T — STATED PLAINLY ─────────────────
//
// THERMAL RECEIPT and DIGITAL — WHATSAPP tabs render the workspace's
// actual most recent Sale (SaleEndpoint.listSales + getSaleLines) — real
// line items, real totals, the real reference number. What is NOT shown
// is what does not exist yet: no address/phone/TIN on Workspace (see
// workspace.spy.yaml — those fields were never added), and no "served
// by" attribution anywhere on Sale. The export's Aisha's Fashion House
// mock has all three; this page omits them rather than inventing a
// business fact that isn't in the database, the same rule
// WorkspaceDto's own comments follow throughout this codebase.
//
// A4 INVOICE and END-OF-DAY REPORT tabs have no real backend at all —
// there is no Invoice/Order entity (PART V's own gap table names this;
// Gate 5's entity-mapping status note hit the identical wall) and no
// EOD aggregation endpoint. Building either is a real design decision on
// its own, not a corner of "redesign Till to match its export." So
// these two tabs are rendered as clearly labeled PREVIEWS using the
// export's own example numbers — visually exact, honestly marked, never
// presented as this workspace's real data.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../services/error_text.dart';
import '../services/money_format.dart';
import '../theme.dart';

class DocumentsPage extends StatefulComponent {
  const DocumentsPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.workspaceName,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final String workspaceName;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

enum _Tab { thermal, a4, digital, report }

class _DocumentsPageState extends State<DocumentsPage> {
  bool _loading = true;
  String? _loadError;
  Sale? _sale;
  List<SaleLine> _lines = const [];

  _Tab _tab = _Tab.thermal;
  String _thermalSize = '58';
  String _returnDate = '';

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
      final sales = await component.client.sale.listSales(
        component.accessToken,
        component.workspaceId,
        // Serverpod's generated client drops default values — the same
        // documented landmine till_page.dart's own header notes for
        // ProductEndpoint.listProducts. Both required params here must
        // be passed explicitly.
        limit: 1,
        offset: 0,
      );
      final sale = sales.isEmpty ? null : sales.first;
      final lines = sale?.id == null
          ? const <SaleLine>[]
          : await component.client.sale.getSaleLines(
              component.accessToken,
              component.workspaceId,
              sale!.id!,
            );
      if (!mounted) return;
      setState(() {
        _sale = sale;
        _lines = lines;
        _returnDate = sale == null ? '' : _formatShortDate(sale.soldAt.add(const Duration(days: 7)));
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

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatShortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': "font-family:${KolaFonts.sans};background:${KolaVar.bg};"
            'color:${KolaVar.text};min-height:100vh;box-sizing:border-box',
      },
      [
        div(
          attributes: {'style': 'max-width:960px;margin:0 auto;padding:32px 24px 60px'},
          [
            _header(),
            _tabs(),
            _returnDateRow(),
            if (_loading)
              _loadingState()
            else if (_loadError != null)
              _errorState()
            else
              switch (_tab) {
                _Tab.thermal => _thermalTab(),
                _Tab.a4 => _a4Tab(),
                _Tab.digital => _digitalTab(),
                _Tab.report => _reportTab(),
              },
            div(
              attributes: {
                'style': 'text-align:center;font-size:${KolaType.tiny};color:${KolaVar.muted};'
                    'margin-top:26px',
              },
              [Component.text('No margin, cost or supplier price ever appears on a customer-facing document.')],
            ),
          ],
        ),
      ],
    );
  }

  Component _header() => div([
        Link(
          to: '/counter',
          attributes: {
            'style': 'color:${KolaVar.muted};text-decoration:none;font-size:${KolaType.bodyLg};'
                'display:inline-flex;align-items:center;gap:3px;margin-bottom:14px',
          },
          children: [Component.text('← Sales Counter')],
        ),
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.display};font-size:${KolaType.h1};font-weight:600;'
                'margin-bottom:6px',
          },
          [Component.text('Documents')],
        ),
        div(
          attributes: {'style': 'font-size:${KolaType.bodyLg};color:${KolaVar.muted};margin-bottom:20px'},
          [Component.text('Receipts, invoices and reports — the same sale, in every form it needs to take.')],
        ),
      ]);

  Component _tabs() => div(
        attributes: {
          'style': 'display:flex;gap:4px;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.pill};padding:3px;width:fit-content;margin-bottom:20px;'
              'flex-wrap:wrap',
        },
        [
          for (final (tab, label) in const [
            (_Tab.thermal, 'Thermal receipt'),
            (_Tab.a4, 'A4 invoice'),
            (_Tab.digital, 'Digital — WhatsApp'),
            (_Tab.report, 'End-of-day report'),
          ])
            _tabButton(tab, label),
        ],
      );

  Component _tabButton(_Tab tab, String label) {
    final active = _tab == tab;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:none;padding:9px 16px;border-radius:${KolaRadius.pill};'
            'font-size:${KolaType.body};font-family:inherit;cursor:pointer;white-space:nowrap;'
            'background:${active ? KolaVar.accentFill : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.muted}',
      },
      events: {'click': (_) => setState(() => _tab = tab)},
      [Component.text(label)],
    );
  }

  Component _returnDateRow() => div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:12px 16px;margin-bottom:22px;'
              'display:flex;align-items:center;gap:12px;flex-wrap:wrap',
        },
        [
          div(
            attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}'},
            [Component.text('Return window shown on every document')],
          ),
          input<String>(
            type: InputType.text,
            value: _returnDate,
            onInput: (v) => setState(() => _returnDate = v),
            attributes: {
              'style': 'background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.sm};padding:7px 12px;color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.small};box-sizing:border-box;width:150px',
            },
          ),
        ],
      );

  // ── Thermal receipt (real sale) ───────────────────────────────────

  Component _thermalTab() {
    final sale = _sale;
    if (sale == null) return _noSaleYet();
    final width = _thermalSize == '58' ? '240px' : '300px';
    return div([
      div(
        attributes: {'style': 'display:flex;gap:10px;margin-bottom:20px'},
        [_thermalSizeChip('58', '58mm'), _thermalSizeChip('80', '80mm')],
      ),
      div(
        attributes: {
          'style': 'background:#fff;color:#111;width:$width;padding:18px;'
              'font-family:${KolaFonts.mono};font-size:${KolaType.tiny};line-height:1.5;'
              'margin:0 auto;box-shadow:0 14px 40px rgba(0,0,0,0.35)',
        },
        [
          div(
            attributes: {'style': 'text-align:center;font-weight:700;font-size:${KolaType.body}'},
            [Component.text(component.workspaceName.toUpperCase())],
          ),
          div(attributes: {'style': 'border-top:1px dashed #111;margin:6px 0'}, []),
          div(
            attributes: {'style': 'display:flex;justify-content:space-between;padding:2px 0'},
            [Component.text(_fullDate(sale.soldAt)), Component.text('Rcpt ${sale.reference}')],
          ),
          div(attributes: {'style': 'border-top:1px dashed #111;margin:6px 0'}, []),
          for (final l in _lines)
            div(
              attributes: {'style': 'margin-bottom:4px'},
              [
                div(
                  attributes: {'style': 'overflow:hidden;text-overflow:ellipsis;white-space:nowrap'},
                  [Component.text(l.name)],
                ),
                div(
                  attributes: {'style': 'display:flex;justify-content:space-between'},
                  [
                    Component.text('${l.quantity} × ${formatMinor(l.unitPriceMinor)}'),
                    Component.text(formatMinor(l.lineTotalMinor)),
                  ],
                ),
              ],
            ),
          div(attributes: {'style': 'border-top:1px dashed #111;margin:6px 0'}, []),
          _thermalRow('Subtotal', formatMinor(sale.subtotalMinor)),
          _thermalRow('VAT', formatMinor(sale.taxMinor)),
          div(
            attributes: {
              'style': 'display:flex;justify-content:space-between;font-weight:700;'
                  'font-size:${KolaType.body};padding:2px 0',
            },
            [Component.text('TOTAL'), Component.text(formatMinor(sale.totalMinor))],
          ),
          div(attributes: {'style': 'border-top:1px dashed #111;margin:6px 0'}, []),
          _thermalRow('Paid — ${_capitalize(sale.paymentMethod)}',
              sale.cashReceivedMinor == null ? formatMinor(sale.totalMinor) : formatMinor(sale.cashReceivedMinor!)),
          if (sale.changeMinor != null) _thermalRow('Change', formatMinor(sale.changeMinor!)),
          div(attributes: {'style': 'border-top:1px dashed #111;margin:8px 0 6px'}, []),
          if (_returnDate.trim().isNotEmpty)
            div(
              attributes: {'style': 'text-align:center;padding-bottom:4px'},
              [Component.text('Returns accepted until $_returnDate')],
            ),
          div(
            attributes: {'style': 'text-align:center;margin-bottom:4px'},
            [Component.text('Thank you — see you again!')],
          ),
        ],
      ),
    ]);
  }

  Component _thermalRow(String label, String value) => div(
        attributes: {'style': 'display:flex;justify-content:space-between;padding:2px 0'},
        [Component.text(label), Component.text(value)],
      );

  Component _thermalSizeChip(String value, String label) {
    final active = _thermalSize == value;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.pill : 'transparent'};'
            'color:${active ? KolaVar.text : KolaVar.muted};border-radius:${KolaRadius.pill};'
            'padding:7px 14px;font-size:${KolaType.tiny};font-family:inherit;cursor:pointer',
      },
      events: {'click': (_) => setState(() => _thermalSize = value)},
      [Component.text(label)],
    );
  }

  // ── Digital — WhatsApp (real sale) ────────────────────────────────

  Component _digitalTab() {
    final sale = _sale;
    if (sale == null) return _noSaleYet();
    return div(
      attributes: {'style': 'max-width:340px;margin:0 auto'},
      [
        div(
          attributes: {
            'style': 'background:#005C4B;color:#fff;border-radius:16px 16px 4px 16px;overflow:hidden',
          },
          [
            div(
              attributes: {'style': 'padding:16px'},
              [
                div(
                  attributes: {'style': 'font-weight:700;margin-bottom:6px;font-size:${KolaType.ui}'},
                  [Component.text('${component.workspaceName} ✓')],
                ),
                div(
                  attributes: {'style': 'font-size:${KolaType.bodyLg};margin-bottom:10px'},
                  [Component.text("Thanks for your order — here's your receipt.")],
                ),
                div(
                  attributes: {'style': 'background:#00473A;border-radius:10px;padding:12px 14px;margin-bottom:10px'},
                  [
                    for (final l in _lines)
                      div(
                        attributes: {
                          'style': 'display:flex;justify-content:space-between;font-size:${KolaType.body};'
                              'padding:3px 0',
                        },
                        [
                          Component.text('${l.name} ×${l.quantity}'),
                          Component.text(formatMinor(l.lineTotalMinor)),
                        ],
                      ),
                    div(
                      attributes: {
                        'style': 'border-top:1px solid #0B6653;margin-top:6px;padding-top:6px;'
                            'display:flex;justify-content:space-between;font-weight:700',
                      },
                      [Component.text('Total'), Component.text(formatMinor(sale.totalMinor))],
                    ),
                  ],
                ),
                if (_returnDate.trim().isNotEmpty)
                  div(
                    attributes: {'style': 'font-size:${KolaType.small};margin-bottom:12px'},
                    [Component.text('Returns accepted until $_returnDate.')],
                  ),
                div(
                  attributes: {'style': 'display:flex;gap:8px'},
                  [
                    Link(
                      to: '/catalog',
                      attributes: {
                        'style': 'flex:1;text-align:center;background:#0B6653;color:#fff;'
                            'border-radius:100px;padding:9px;font-size:${KolaType.small};font-weight:600;'
                            'text-decoration:none',
                      },
                      children: [Component.text('Reorder')],
                    ),
                    Link(
                      to: '/operations',
                      attributes: {
                        'style': 'flex:1;text-align:center;background:#FFF6EE;color:#005C4B;'
                            'border-radius:100px;padding:9px;font-size:${KolaType.small};font-weight:600;'
                            'text-decoration:none',
                      },
                      children: [Component.text('Ask a question')],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── A4 invoice (no Invoice entity — preview only) ─────────────────

  Component _a4Tab() => div([
        _previewBanner(
          'Kola does not generate invoices yet — there is no Invoice/Order '
          'entity behind this tab. This shows the export\'s own example so '
          'the layout is on record; nothing below is real data.',
        ),
        div(
          attributes: {'style': 'display:flex;gap:6px;margin-bottom:20px;flex-wrap:wrap'},
          [
            for (final (label, active) in const [
              ('Draft', false), ('Sent', false), ('Viewed', false),
              ('Partly paid', true), ('Paid', false), ('Overdue', false),
            ])
              span(
                attributes: {
                  'style': 'font-size:${KolaType.micro};font-weight:600;padding:5px 12px;'
                      'border-radius:${KolaRadius.pill};'
                      'background:${active ? KolaVar.pill : KolaVar.card};'
                      'color:${active ? KolaVar.text : KolaVar.muted}',
                },
                [Component.text(label)],
              ),
          ],
        ),
        div(
          attributes: {
            'style': 'background:#fff;color:#1C1815;width:100%;max-width:620px;margin:0 auto;'
                'padding:48px;font-family:${KolaFonts.sans};box-shadow:0 14px 40px rgba(0,0,0,0.35);'
                'box-sizing:border-box',
          },
          [
            div(
              attributes: {
                'style': 'display:flex;justify-content:space-between;align-items:flex-start;'
                    'margin-bottom:32px;gap:16px',
              },
              [
                div(
                  attributes: {'style': 'font-weight:700;font-size:${KolaType.subhead}'},
                  [Component.text(component.workspaceName)],
                ),
                div(
                  attributes: {'style': 'text-align:right'},
                  [
                    div(
                      attributes: {
                        'style': 'font-weight:700;font-size:${KolaType.title};'
                            'font-family:${KolaFonts.display}',
                      },
                      [Component.text('INVOICE')],
                    ),
                    div(attributes: {'style': 'font-size:${KolaType.tiny};color:#6B655E'}, [Component.text('#889')]),
                    div(
                      attributes: {'style': 'font-size:${KolaType.tiny};color:#6B655E;margin-top:6px'},
                      [Component.text('Issued Aug 3, 2026')],
                    ),
                    div(
                      attributes: {'style': 'font-size:${KolaType.tiny};color:#B33A2A;font-weight:600'},
                      [Component.text('Due Aug 8, 2026')],
                    ),
                  ],
                ),
              ],
            ),
            div(
              attributes: {'style': 'margin-bottom:20px'},
              [
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.micro};color:#6B655E;text-transform:uppercase;'
                        'letter-spacing:0.04em;margin-bottom:4px',
                  },
                  [Component.text('Bill to')],
                ),
                div(
                  attributes: {'style': 'font-size:${KolaType.bodyLg};font-weight:600'},
                  [Component.text('Kemi Catering Co.')],
                ),
                div(
                  attributes: {'style': 'font-size:${KolaType.small};color:#6B655E'},
                  [Component.text('Ajah, Lagos · 0805 442 1190')],
                ),
              ],
            ),
            div(
              attributes: {
                'style': 'display:grid;grid-template-columns:1fr 60px 100px 100px;gap:8px;'
                    'padding:9px 0;border-top:1px solid #1C1815;border-bottom:1px solid #E8E1D6;'
                    'font-size:${KolaType.micro};color:#6B655E;font-weight:600;text-transform:uppercase',
              },
              [
                Component.text('Item'), Component.text('Qty'), Component.text('Unit'),
                div(attributes: {'style': 'text-align:right'}, [Component.text('Amount')]),
              ],
            ),
            div(
              attributes: {
                'style': 'display:grid;grid-template-columns:1fr 60px 100px 100px;gap:8px;'
                    'padding:9px 0;border-bottom:1px solid #F1EAE0;font-size:${KolaType.bodyLg}',
              },
              [
                Component.text('Aso-ebi bundle (10yd)'), Component.text('1'), Component.text('₦42,000'),
                div(
                  attributes: {'style': 'text-align:right;font-family:${KolaFonts.mono}'},
                  [Component.text('₦42,000')],
                ),
              ],
            ),
            div(
              attributes: {'style': 'display:flex;justify-content:flex-end;margin-top:12px'},
              [
                div(
                  attributes: {'style': 'width:220px'},
                  [
                    _invoiceTotalRow('Subtotal', '₦42,000'),
                    _invoiceTotalRow('VAT (7.5%)', '₦3,150'),
                    _invoiceTotalRow('Paid Aug 3', '−₦21,000', border: true),
                    div(
                      attributes: {
                        'style': 'display:flex;justify-content:space-between;font-weight:700;'
                            'font-size:${KolaType.subhead};padding-top:8px;border-top:1px solid #1C1815;'
                            'margin-top:6px',
                      },
                      [Component.text('Balance due'), Component.text('₦24,150')],
                    ),
                  ],
                ),
              ],
            ),
            div(
              attributes: {
                'style': 'margin-top:24px;background:#F1EAE0;border-radius:10px;padding:14px 16px',
              },
              [
                div(
                  attributes: {'style': 'font-size:${KolaType.tiny};color:#6B655E;margin-bottom:2px'},
                  [Component.text('Payment instructions')],
                ),
                div(
                  attributes: {'style': 'font-size:${KolaType.small};color:#3E3934'},
                  [Component.text('Preview only — no payment link or bank details are wired up.')],
                ),
              ],
            ),
          ],
        ),
      ]);

  Component _invoiceTotalRow(String label, String value, {bool border = false}) => div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;font-size:${KolaType.body};padding:4px 0'
              '${border ? ';border-top:1px solid #E8E1D6;margin-top:4px' : ''}',
        },
        [span(attributes: {'style': 'color:#6B655E'}, [Component.text(label)]), Component.text(value)],
      );

  // ── End-of-day report (no aggregation endpoint — preview only) ────

  Component _reportTab() => div([
        _previewBanner(
          'There is no end-of-day aggregation endpoint yet. This shows the '
          "export's own example so the layout is on record; nothing below "
          'is real data.',
        ),
        div(
          attributes: {
            'style': 'background:#fff;color:#1C1815;width:100%;max-width:620px;margin:0 auto;'
                'padding:44px;font-family:${KolaFonts.sans};box-shadow:0 14px 40px rgba(0,0,0,0.35);'
                'box-sizing:border-box',
          },
          [
            div(
              attributes: {'style': 'font-weight:700;font-size:${KolaType.title};margin-bottom:2px'},
              [Component.text('End-of-day report — Z-142')],
            ),
            div(
              attributes: {'style': 'font-size:${KolaType.tiny};color:#6B655E;margin-bottom:22px'},
              [Component.text('${component.workspaceName} · Tuesday, August 5, 2026, closed 8:02pm')],
            ),
            div(
              attributes: {
                'style': 'display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:24px',
              },
              [
                _reportStat('Gross takings', '₦340,000'),
                _reportStat('Transactions', '48'),
                _reportStat('Refunds', '₦4,500'),
              ],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:#6B655E;text-transform:uppercase;'
                    'letter-spacing:0.04em;margin-bottom:8px',
              },
              [Component.text('By payment method')],
            ),
            div(
              attributes: {
                'style': 'border-top:1px solid #1C1815;border-bottom:1px solid #E8E1D6;margin-bottom:18px',
              },
              [
                for (final (name, amount) in const [
                  ('Cash', '₦186,000'), ('Transfer', '₦104,000'), ('Paystack', '₦50,000'),
                ])
                  div(
                    attributes: {
                      'style': 'display:flex;justify-content:space-between;padding:8px 0;'
                          'border-bottom:1px solid #F1EAE0;font-size:${KolaType.bodyLg}',
                    },
                    [
                      Component.text(name),
                      span(attributes: {'style': 'font-family:${KolaFonts.mono}'}, [Component.text(amount)]),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ]);

  Component _reportStat(String label, String value) => div(
        attributes: {'style': 'background:#F1EAE0;border-radius:10px;padding:14px'},
        [
          div(attributes: {'style': 'font-size:${KolaType.micro};color:#6B655E'}, [Component.text(label)]),
          div(
            attributes: {'style': 'font-size:${KolaType.h3};font-weight:700'},
            [Component.text(value)],
          ),
        ],
      );

  Component _previewBanner(String text) => div(
        attributes: {
          'style': 'background:${KolaVar.warningBg};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:12px 16px;margin-bottom:16px;'
              'font-size:${KolaType.small};color:${KolaVar.mutedStrong};line-height:1.5',
        },
        [Component.text(text)],
      );

  // ── Shared states ──────────────────────────────────────────────────

  Component _noSaleYet() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};border-radius:${KolaRadius.lg};'
              'padding:40px 20px;text-align:center;color:${KolaVar.muted};font-size:${KolaType.body}',
        },
        [
          Component.text('No sales yet. '),
          Link(
            to: '/counter',
            attributes: {'style': 'color:${KolaVar.accent};text-decoration:none;font-weight:600'},
            children: [Component.text('Ring one up at the counter')],
          ),
          Component.text(' and it shows up here.'),
        ],
      );

  Component _loadingState() => div(
        attributes: {
          'style': 'height:200px;border-radius:${KolaRadius.lg};border:1px solid ${KolaVar.border};'
              'background:${KolaVar.card}',
        },
        [],
      );

  Component _errorState() => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};border-radius:${KolaRadius.lg};'
              'background:${KolaVar.card};padding:${KolaSpace.lg}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('Could not load your last sale')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};line-height:1.55;margin-bottom:12px',
            },
            [Component.text('This is a connection problem. Nothing here has changed.')],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'padding:9px 15px;border-radius:${KolaRadius.sm};border:none;'
                  'background:${KolaVar.accentFill};color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.body};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => _load()},
            [Component.text('Try again')],
          ),
        ],
      );

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _fullDate(DateTime d) {
    final hour24 = d.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = hour24 < 12 ? 'am' : 'pm';
    return '${_months[d.month - 1]} ${d.day} ${d.year} $hour12:$minute$ampm';
  }
}
