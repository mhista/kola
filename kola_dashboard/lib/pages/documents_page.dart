// documents_page.dart — receipts, invoices and reports, one sale in
// every form it needs to take. Linked from Kola Till.dc.html's header
// and its post-sale "Print" action; built from Kola Documents.dc.html's
// structure and visual language (this codebase's own
// KolaVar/KolaType/KolaRadius tokens), not copied from it verbatim —
// see till_page.dart's own header for why that distinction matters.
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
// A4 INVOICE tab is real: InvoiceEndpoint backs it end to end, and
// "Pay ₦X now" opens a genuine PaymentEndpoint.initializeCheckout
// checkout against whichever gateway the workspace connected — not a
// mockup button. What it does NOT do: auto-credit paidMinor when that
// checkout completes (no webhook → invoice link yet, see
// invoice_endpoint.dart's header); recordPayment there is a manual
// owner-confirmed "mark as paid" for now.
//
// END-OF-DAY REPORT tab is real too: ReportEndpoint.getEndOfDayReport
// aggregates today's Sale rows fresh on every open — gross takings,
// transaction count, refunds, and a by-payment-method breakdown, plus
// a "what kola noticed" callout comparing to yesterday when there is a
// yesterday to compare against.
//
// An earlier pass rendered both tabs as populated mock documents using
// an export's own dummy numbers (a fake "Kemi Catering Co." bill-to, a
// fake ₦340,000 day) sitting next to this workspace's REAL name — real
// and fabricated data side by side on the same document, which reads
// as a bug, not a preview. Both are now backed by real endpoints
// instead; where a field genuinely doesn't exist (business address/
// phone/TIN on Workspace, "served by" staff attribution), it is
// omitted rather than invented — same rule WorkspaceDto's own comments
// follow throughout this codebase.

import 'dart:async';
import 'dart:convert';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';
import 'package:web/web.dart' as web;

import '../components/shell/kola_icon.dart';
import '../components/shell/icons.dart';
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

  // ── A4 invoice — real Invoice entity + real payment link ────────────
  Invoice? _invoice;
  List<PaymentGatewayCredential> _gateways = const [];
  bool _creatingInvoice = false;
  String? _invoiceError;
  bool _charging = false;
  String? _payError;

  // Bill-to mini-form — filled once, at invoice creation. Editing an
  // already-created invoice's bill-to details is not built here (see
  // this file's own "what this does NOT do" convention elsewhere in the
  // codebase) — create a fresh one if the details were wrong.
  String _billToName = '';
  String _billToPhone = '';
  String _billToAddress = '';
  String _billToEmail = '';
  String _dueDate = '';
  String _paymentInstructions = '';

  // ── End-of-day report — real aggregation, fetched lazily ────────────
  // Independent of _sale/_load: today's report exists whether or not
  // there has been a sale recently, so it is fetched once, the first
  // time the report tab is opened, not on every page load.
  EndOfDayReport? _report;
  bool _reportLoading = false;
  String? _reportError;

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
      final invoice = sale?.id == null
          ? null
          : await component.client.invoice.getInvoiceForSale(
              component.accessToken,
              component.workspaceId,
              sale!.id!,
            );
      final gateways = await component.client.payment.listConnectedGateways(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _sale = sale;
        _lines = lines;
        _invoice = invoice;
        _gateways = gateways;
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

  // ── A4 invoice actions ────────────────────────────────────────────

  Future<void> _createInvoice() async {
    final sale = _sale;
    if (sale == null || _lines.isEmpty) return;
    final name = _billToName.trim();
    if (name.isEmpty) {
      setState(() => _invoiceError = 'Bill-to name is required.');
      return;
    }
    setState(() {
      _creatingInvoice = true;
      _invoiceError = null;
    });
    try {
      DateTime? dueAt;
      if (_dueDate.trim().isNotEmpty) {
        dueAt = DateTime.tryParse(_dueDate.trim());
      }
      final invoice = await component.client.invoice.createInvoice(
        component.accessToken,
        component.workspaceId,
        name,
        jsonEncode([
          for (final l in _lines)
            {'name': l.name, 'quantity': l.quantity, 'unitPriceMinor': l.unitPriceMinor},
        ]),
        saleId: sale.id,
        billToAddress: _billToAddress.trim().isEmpty ? null : _billToAddress.trim(),
        billToPhone: _billToPhone.trim().isEmpty ? null : _billToPhone.trim(),
        taxRateBps: sale.taxRateBps,
        currency: sale.currency,
        paymentInstructions:
            _paymentInstructions.trim().isEmpty ? null : _paymentInstructions.trim(),
        dueAt: dueAt,
      );
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _creatingInvoice = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creatingInvoice = false;
        _invoiceError = ErrorText.of(e);
      });
    }
  }

  Future<void> _setInvoiceStatus(String status) async {
    final invoice = _invoice;
    if (invoice?.id == null) return;
    try {
      final updated = await component.client.invoice.updateInvoiceStatus(
        component.accessToken,
        component.workspaceId,
        invoice!.id!,
        status,
      );
      if (!mounted) return;
      setState(() => _invoice = updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _invoiceError = ErrorText.of(e));
    }
  }

  /// Real checkout, against whichever gateway this workspace has
  /// connected — see invoice_endpoint.dart's header on why this calls
  /// PaymentEndpoint directly rather than InvoiceEndpoint wrapping it.
  /// Opens the gateway's own hosted page in a new tab; the owner shares
  /// that URL with the customer (or pays it themselves) — same "real
  /// link, no auto-redirect" posture BillingPage's upgrade flow already
  /// established.
  Future<void> _payNow() async {
    final invoice = _invoice;
    if (invoice == null || _gateways.isEmpty) return;
    final email = _billToEmail.trim();
    if (email.isEmpty) {
      setState(() => _payError = 'A customer email is needed to start a checkout.');
      return;
    }
    final balanceDue = invoice.totalMinor - invoice.paidMinor;
    if (balanceDue <= 0) return;
    setState(() {
      _charging = true;
      _payError = null;
    });
    try {
      final transaction = await component.client.payment.initializeCheckout(
        component.accessToken,
        component.workspaceId,
        _gateways.first.gateway,
        balanceDue,
        email,
        customerPhone: _billToPhone.trim().isEmpty ? null : _billToPhone.trim(),
        // Serverpod's generated client drops default values from server
        // parameters (same documented landmine till_page.dart's own
        // header notes for ProductEndpoint.listProducts) — holdInEscrow
        // defaults to false server-side, but the generated stub makes it
        // required, so it must be passed explicitly here.
        holdInEscrow: false,
        metadata: {'invoiceId': invoice.id, 'invoiceReference': invoice.reference},
      );
      if (!mounted) return;
      setState(() => _charging = false);
      final url = transaction.checkoutUrl;
      if (url != null && url.isNotEmpty) {
        web.window.open(url, '_blank');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _charging = false;
        _payError = ErrorText.of(e);
      });
    }
  }

  // ── End-of-day report actions ────────────────────────────────────────

  void _selectTab(_Tab tab) {
    setState(() => _tab = tab);
    if (tab == _Tab.report && _report == null && !_reportLoading) {
      unawaited(_loadReport());
    }
  }

  Future<void> _loadReport() async {
    setState(() {
      _reportLoading = true;
      _reportError = null;
    });
    try {
      final report = await component.client.report.getEndOfDayReport(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _reportLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reportLoading = false;
        _reportError = ErrorText.of(e);
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    // Viewport-locked, per styles.css's own convention (html/body carry
    // overflow:hidden app-wide — a page must own a bounded height and
    // scroll internally, or content taller than the viewport gets
    // silently clipped with no way to reach the rest of it, which is
    // exactly what was happening here before this had its own
    // height:100vh + overflow-y:auto).
    return div(
      attributes: {
        // height:100vh then height:100svh — see till_page.dart's build()
        // for the full reasoning, `svh` over `dvh` included.
        'style': "font-family:${KolaFonts.sans};background:${KolaVar.bg};"
            'color:${KolaVar.text};height:100vh;height:100svh;overflow-y:auto;box-sizing:border-box',
      },
      [
        _printStyles(),
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

  /// Scopes browser printing to just the receipt itself — without this,
  /// "Print" would print the whole dark dashboard chrome (nav, tabs,
  /// return-date row) around a tiny receipt. Standard print-one-element
  /// trick: hide everything, then re-reveal only #kola-print-area.
  Component _printStyles() => Component.element(
        tag: 'style',
        children: [
          Component.text('''
@media print {
  body * { visibility: hidden; }
  #kola-print-area, #kola-print-area * { visibility: visible; }
  #kola-print-area {
    position: absolute;
    left: 0;
    top: 0;
    width: auto !important;
    box-shadow: none !important;
    margin: 0 !important;
  }
}
'''),
        ],
      );

  Component _printButton() => button(
        attributes: {
          'type': 'button',
          'style': 'border:1px solid ${KolaVar.accent};background:${KolaVar.pill};'
              'color:${KolaVar.text};border-radius:${KolaRadius.pill};padding:7px 16px;'
              'font-size:${KolaType.tiny};font-family:inherit;cursor:pointer;'
              'display:inline-flex;align-items:center;gap:6px',
        },
        events: {'click': (_) => web.window.print()},
        [kolaIcon(Icons.printer, size: 13, strokeWidth: 1.8), Component.text('Print')],
      );

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
      events: {'click': (_) => _selectTab(tab)},
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
        attributes: {
          'style': 'display:flex;gap:10px;margin-bottom:20px;align-items:center;'
              'justify-content:space-between',
        },
        [
          div(
            attributes: {'style': 'display:flex;gap:10px'},
            [_thermalSizeChip('58', '58mm'), _thermalSizeChip('80', '80mm')],
          ),
          _printButton(),
        ],
      ),
      div(
        attributes: {
          'id': 'kola-print-area',
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

  // ── A4 invoice (real Invoice entity + real payment link) ───────────
  //
  // Business address/phone/TIN are still omitted from the header, same
  // as the thermal tab — see this file's header on why: neither field
  // exists on Workspace, and inventing them would be exactly the mistake
  // WorkspaceDto's own comments warn against throughout this codebase.

  Component _a4Tab() {
    final sale = _sale;
    if (sale == null) return _noSaleYet();
    final invoice = _invoice;
    return invoice == null ? _invoiceCreateForm() : _invoiceDocument(invoice);
  }

  Component _invoiceCreateForm() => div(
        attributes: {'style': 'max-width:420px;margin:0 auto'},
        [
          div(
            attributes: {
              'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};padding:22px',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.ui};font-weight:700;margin-bottom:4px',
                },
                [Component.text('Turn this sale into an invoice')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};color:${KolaVar.muted};margin-bottom:16px',
                },
                [Component.text('Same line items as the receipt — just who it\'s billed to and when it\'s due.')],
              ),
              _invoiceField('Bill to (name)', _billToName, (v) => setState(() => _billToName = v)),
              _invoiceField('Phone', _billToPhone, (v) => setState(() => _billToPhone = v)),
              _invoiceField('Address', _billToAddress, (v) => setState(() => _billToAddress = v)),
              _invoiceField('Email (for the payment link)', _billToEmail, (v) => setState(() => _billToEmail = v)),
              _invoiceField('Due date (YYYY-MM-DD)', _dueDate, (v) => setState(() => _dueDate = v)),
              _invoiceField(
                'Payment instructions',
                _paymentInstructions,
                (v) => setState(() => _paymentInstructions = v),
              ),
              if (_invoiceError != null)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};margin-bottom:10px',
                  },
                  [Component.text(_invoiceError!)],
                ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:100%;background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                      'border:none;border-radius:${KolaRadius.pill};padding:12px;'
                      'font-size:${KolaType.bodyLg};font-weight:600;font-family:inherit;'
                      'cursor:${_creatingInvoice ? 'default' : 'pointer'};min-height:44px;'
                      'opacity:${_creatingInvoice ? '0.6' : '1'}',
                },
                events: {'click': (_) => _creatingInvoice ? null : _createInvoice()},
                [Component.text(_creatingInvoice ? 'Creating…' : 'Create invoice')],
              ),
            ],
          ),
        ],
      );

  Component _invoiceField(String label, String value, void Function(String) onChange) => div(
        attributes: {'style': 'margin-bottom:12px'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:4px',
            },
            [Component.text(label)],
          ),
          input<String>(
            type: InputType.text,
            value: value,
            onInput: onChange,
            attributes: {
              'style': 'width:100%;background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.sm};padding:9px 12px;color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.small};box-sizing:border-box',
            },
          ),
        ],
      );

  static const _invoiceStatuses = ['draft', 'sent', 'viewed', 'partly_paid', 'paid'];

  Component _invoiceDocument(Invoice invoice) {
    final lines = (jsonDecode(invoice.linesJson) as List).cast<Map<String, dynamic>>();
    final balanceDue = invoice.totalMinor - invoice.paidMinor;
    final overdue = invoice.status != 'paid' &&
        invoice.dueAt != null &&
        invoice.dueAt!.isBefore(DateTime.now());

    return div([
      // Status chips — clickable, owner-driven (see invoice_endpoint.dart
      // header). "Overdue" is shown as a badge, never a chip: it's
      // derived from dueAt, not a state anyone sets.
      div(
        attributes: {'style': 'display:flex;gap:8px;margin-bottom:20px;flex-wrap:wrap'},
        [
          for (final s in _invoiceStatuses) _statusChip(s, invoice.status == s),
          if (overdue) _statusChip('overdue', false, clickable: false, danger: true),
        ],
      ),
      div(
        attributes: {
          'style': 'background:#fff;color:#111;width:100%;max-width:560px;padding:32px;'
              'font-family:${KolaFonts.sans};font-size:${KolaType.small};line-height:1.5;'
              'margin:0 auto;box-shadow:0 14px 40px rgba(0,0,0,0.35);box-sizing:border-box',
        },
        [
          div(
            attributes: {'style': 'display:flex;justify-content:space-between;margin-bottom:22px'},
            [
              div([
                div(
                  attributes: {'style': 'font-size:${KolaType.ui};font-weight:700'},
                  [Component.text(component.workspaceName)],
                ),
              ]),
              div(
                attributes: {'style': 'text-align:right'},
                [
                  div(
                    attributes: {'style': 'font-size:${KolaType.uiLg};font-weight:700;letter-spacing:0.5px'},
                    [Component.text('INVOICE')],
                  ),
                  div(
                    attributes: {'style': 'color:#666'},
                    [Component.text(invoice.reference)],
                  ),
                  div(
                    attributes: {'style': 'color:#666;margin-top:4px'},
                    [Component.text('Issued ${_fullDateShort(invoice.issuedAt)}')],
                  ),
                  if (invoice.dueAt != null)
                    div(
                      attributes: {
                        'style': 'font-weight:600;margin-top:2px;'
                            'color:${overdue ? '#c1440e' : '#111'}',
                      },
                      [Component.text('Due ${_fullDateShort(invoice.dueAt!)}')],
                    ),
                ],
              ),
            ],
          ),
          div(
            attributes: {'style': 'margin-bottom:18px'},
            [
              div(
                attributes: {'style': 'font-size:${KolaType.tiny};color:#888;margin-bottom:2px'},
                [Component.text('BILL TO')],
              ),
              div(
                attributes: {'style': 'font-weight:700'},
                [Component.text(invoice.billToName)],
              ),
              if (invoice.billToAddress != null || invoice.billToPhone != null)
                div(
                  attributes: {'style': 'color:#555'},
                  [
                    Component.text([
                      if (invoice.billToAddress != null) invoice.billToAddress!,
                      if (invoice.billToPhone != null) invoice.billToPhone!,
                    ].join(' · ')),
                  ],
                ),
            ],
          ),
          div(
            attributes: {'style': 'border-top:1px solid #eee;border-bottom:1px solid #eee;padding:8px 0;margin-bottom:8px'},
            [
              div(
                attributes: {
                  'style': 'display:flex;font-size:${KolaType.tiny};color:#888;font-weight:600',
                },
                [
                  div(attributes: {'style': 'flex:1'}, [Component.text('ITEM')]),
                  div(attributes: {'style': 'width:50px;text-align:right'}, [Component.text('QTY')]),
                  div(attributes: {'style': 'width:90px;text-align:right'}, [Component.text('UNIT')]),
                  div(attributes: {'style': 'width:100px;text-align:right'}, [Component.text('AMOUNT')]),
                ],
              ),
            ],
          ),
          for (final l in lines)
            div(
              attributes: {'style': 'display:flex;padding:6px 0;border-bottom:1px solid #f4f4f4'},
              [
                div(attributes: {'style': 'flex:1'}, [Component.text(l['name'] as String)]),
                div(attributes: {'style': 'width:50px;text-align:right'}, [Component.text('${l['quantity']}')]),
                div(
                  attributes: {'style': 'width:90px;text-align:right'},
                  [Component.text(formatMinor(l['unitPriceMinor'] as int))],
                ),
                div(
                  attributes: {'style': 'width:100px;text-align:right'},
                  [Component.text(formatMinor((l['unitPriceMinor'] as int) * (l['quantity'] as int)))],
                ),
              ],
            ),
          div(
            attributes: {'style': 'margin-top:14px;margin-left:auto;width:220px'},
            [
              _invoiceRow('Subtotal', formatMinor(invoice.subtotalMinor)),
              if (invoice.taxRateBps > 0)
                _invoiceRow('VAT (${(invoice.taxRateBps / 100).toStringAsFixed(1)}%)', formatMinor(invoice.taxMinor)),
              if (invoice.paidMinor > 0) _invoiceRow('Paid', '−${formatMinor(invoice.paidMinor)}'),
              div(attributes: {'style': 'border-top:1px solid #111;margin:6px 0'}, []),
              div(
                attributes: {
                  'style': 'display:flex;justify-content:space-between;font-weight:700;font-size:${KolaType.ui}',
                },
                [Component.text('Balance due'), Component.text(formatMinor(balanceDue))],
              ),
            ],
          ),
          if (invoice.paymentInstructions != null)
            div(
              attributes: {
                'style': 'background:#FFF6EE;border-radius:${KolaRadius.sm};padding:12px 14px;'
                    'margin-top:22px;font-size:${KolaType.tiny};color:#555',
              },
              [
                div(attributes: {'style': 'color:#888;margin-bottom:2px'}, [Component.text('Payment instructions')]),
                Component.text(invoice.paymentInstructions!),
              ],
            ),
          if (balanceDue > 0)
            div(
              attributes: {'style': 'margin-top:16px'},
              [
                if (_payError != null)
                  div(
                    attributes: {'style': 'color:#c1440e;font-size:${KolaType.tiny};margin-bottom:8px'},
                    [Component.text(_payError!)],
                  ),
                if (_gateways.isEmpty)
                  div(
                    attributes: {'style': 'color:#888;font-size:${KolaType.tiny}'},
                    [Component.text('Connect Paystack or Flutterwave in Settings to accept a real payment here.')],
                  )
                else
                  button(
                    attributes: {
                      'type': 'button',
                      'style': 'width:100%;background:${KolaVar.accent};color:#fff;border:none;'
                          'border-radius:${KolaRadius.pill};padding:13px;font-size:${KolaType.bodyLg};'
                          'font-weight:700;font-family:inherit;'
                          'cursor:${_charging ? 'default' : 'pointer'};opacity:${_charging ? '0.6' : '1'}',
                    },
                    events: {'click': (_) => _charging ? null : _payNow()},
                    [Component.text(_charging ? 'Starting checkout…' : 'Pay ${formatMinor(balanceDue)} now')],
                  ),
              ],
            ),
        ],
      ),
    ]);
  }

  Component _invoiceRow(String label, String value) => div(
        attributes: {'style': 'display:flex;justify-content:space-between;padding:2px 0;color:#444'},
        [Component.text(label), Component.text(value)],
      );

  Component _statusChip(String status, bool active, {bool clickable = true, bool danger = false}) {
    final label = switch (status) {
      'partly_paid' => 'Partly paid',
      'overdue' => 'Overdue',
      _ => status[0].toUpperCase() + status.substring(1),
    };
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:none;padding:7px 14px;border-radius:${KolaRadius.pill};'
            'font-size:${KolaType.tiny};font-weight:600;font-family:inherit;'
            'cursor:${clickable ? 'pointer' : 'default'};'
            'background:${danger ? '#3a1f14' : active ? KolaVar.accentFill : KolaVar.card};'
            'color:${danger ? '#ff9466' : active ? KolaVar.accentText : KolaVar.muted};'
            'border:1px solid ${danger ? '#5a2c1a' : KolaVar.border}',
      },
      events: clickable ? {'click': (_) => _setInvoiceStatus(status)} : const {},
      [Component.text(label)],
    );
  }

  String _fullDateShort(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  Component _reportTab() {
    if (_reportLoading && _report == null) return _loadingState();
    if (_reportError != null && _report == null) return _reportErrorState();
    final report = _report;
    if (report == null) return _loadingState();

    final byMethod = (jsonDecode(report.byPaymentMethodJson) as Map).cast<String, dynamic>();
    final balanceMinor = report.grossMinor - report.refundsMinor;

    return div(
      attributes: {'style': 'max-width:560px;margin:0 auto'},
      [
        div(
          attributes: {'style': 'font-size:${KolaType.small};color:${KolaVar.muted};margin-bottom:18px'},
          [Component.text(_fullDateShort(report.reportDate))],
        ),
        if (report.insightText != null)
          div(
            attributes: {
              'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.accent};'
                  'border-radius:${KolaRadius.lg};padding:14px 16px;margin-bottom:20px;'
                  'font-size:${KolaType.small};color:${KolaVar.text}',
            },
            [
              div(
                attributes: {'style': 'font-weight:700;margin-bottom:3px;color:${KolaVar.accent}'},
                [Component.text('What kola noticed')],
              ),
              Component.text(report.insightText!),
            ],
          ),
        div(
          attributes: {'style': 'display:flex;gap:12px;margin-bottom:20px;flex-wrap:wrap'},
          [
            _reportStat('Gross takings', formatMinor(report.grossMinor)),
            _reportStat('Transactions', '${report.transactionCount}'),
            _reportStat('Refunds', '${formatMinor(report.refundsMinor)} (${report.refundCount})'),
            _reportStat('Net', formatMinor(balanceMinor)),
          ],
        ),
        div(
          attributes: {
            'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};padding:18px 20px',
          },
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:700;margin-bottom:12px',
              },
              [Component.text('By payment method')],
            ),
            if (byMethod.isEmpty)
              div(
                attributes: {'style': 'color:${KolaVar.muted};font-size:${KolaType.small}'},
                [Component.text('No completed sales yet today.')],
              )
            else
              for (final entry in byMethod.entries)
                div(
                  attributes: {
                    'style': 'display:flex;justify-content:space-between;padding:7px 0;'
                        'border-bottom:1px solid ${KolaVar.border};font-size:${KolaType.small}',
                  },
                  [
                    Component.text(_capitalize(entry.key)),
                    Component.text(formatMinor(entry.value as int)),
                  ],
                ),
          ],
        ),
        div(
          attributes: {'style': 'margin-top:14px;text-align:center'},
          [
            button(
              attributes: {
                'type': 'button',
                'style': 'border:none;background:transparent;color:${KolaVar.accent};'
                    'font-family:inherit;font-size:${KolaType.small};cursor:pointer',
              },
              events: {'click': (_) => _loadReport()},
              [Component.text('Refresh')],
            ),
          ],
        ),
      ],
    );
  }

  Component _reportErrorState() => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};border-radius:${KolaRadius.lg};'
              'background:${KolaVar.card};padding:${KolaSpace.lg};max-width:440px;margin:0 auto',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('Could not load today\'s report')],
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
            events: {'click': (_) => _loadReport()},
            [Component.text('Try again')],
          ),
        ],
      );

  Component _reportStat(String label, String value) => div(
        attributes: {
          'style': 'flex:1;min-width:120px;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:14px 16px',
        },
        [
          div(
            attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:4px'},
            [Component.text(label)],
          ),
          div(
            attributes: {'style': 'font-size:${KolaType.ui};font-weight:700'},
            [Component.text(value)],
          ),
        ],
      );

  /// The honest empty state for a tab with nothing real behind it yet.
  /// Two parts on purpose, same as settings_page.dart's `_notYet`: what
  /// is missing, then what it would take — "coming soon" on its own
  /// tells the owner nothing they can act on.
  Component _comingSoon({required String icon, required String headline, required String body}) => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};border-radius:${KolaRadius.lg};'
              'padding:40px 24px;text-align:center;max-width:440px;margin:0 auto',
        },
        [
          div(
            attributes: {'style': 'color:${KolaVar.muted};margin-bottom:14px;display:flex;justify-content:center'},
            [kolaIcon(icon, size: 22)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;color:${KolaVar.text};margin-bottom:8px',
            },
            [Component.text(headline)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};line-height:1.55',
            },
            [Component.text(body)],
          ),
        ],
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
