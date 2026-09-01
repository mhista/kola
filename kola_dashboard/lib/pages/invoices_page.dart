// invoices_page.dart — Phase 14a-4. `/invoices`, a standalone,
// sidebar-reachable page for the A4 invoice — previously one tab
// buried inside documents_page.dart's four-tab "Documents" surface
// (Thermal receipt / A4 invoice / Digital-WhatsApp / End-of-day
// report). The owner's own words: "Invoice must become its own
// standalone section... a business always needs its invoice... give
// it real design attention." Documents keeps the other three tabs —
// a receipt and a report are genuinely secondary/one-off documents; an
// invoice is a recurring, list-worthy business object that deserves
// its own list + detail view, same bar customers_page.dart and
// tasks_page.dart already set for a "real page" on this design system.
//
// ── WHAT'S REUSED, WHAT'S NEW ──────────────────────────────────────────
//
// InvoiceEndpoint (createInvoice/listInvoices/getInvoice/
// updateInvoiceStatus/recordPayment) already existed end to end —
// task #29, "A4 Invoice: entity + endpoint + real payment link" — and
// is untouched here. So is PaymentEndpoint.initializeCheckout for the
// real "Pay now" checkout link. What's new is this page: a genuine list
// of every invoice the workspace has issued (documents_page.dart only
// ever showed the single most recent sale's invoice, one at a time),
// with search, status filter, four summary stat cards, a compact
// detail/print view per invoice, and a "New invoice" flow that picks a
// source sale from the recent list — the same bill-to mini-form
// documents_page.dart had, just reachable from a real list instead of
// gated behind "whatever the last sale happened to be."
//
// ── NAMED SIMPLIFICATION ───────────────────────────────────────────────
//
// An invoice can only be created FROM an existing Sale (its line items
// copied over), same constraint documents_page.dart already had — there
// is no free-form "type your own line items" invoice builder here.
// InvoiceEndpoint.createInvoice itself doesn't require a saleId, so a
// standalone invoice is a real, smaller follow-up, not attempted this
// pass; naming it rather than silently deciding it.

import 'dart:async';
import 'dart:convert';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';
import 'package:web/web.dart' as web;

import '../components/shell/kola_icon.dart';
import '../components/shell/icons.dart';
import '../components/shell/page_help_button.dart';
import '../services/error_text.dart';
import '../services/money_format.dart';
import '../theme.dart';

class InvoicesPage extends StatefulComponent {
  const InvoicesPage({
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
  State<InvoicesPage> createState() => _InvoicesPageState();
}

enum _StatusFilter { all, draft, sent, viewed, partlyPaid, paid, overdue }

class _InvoicesPageState extends State<InvoicesPage> {
  List<Invoice> _invoices = const [];
  List<PaymentGatewayCredential> _gateways = const [];
  bool _loading = true;
  String? _loadError;

  String _search = '';
  _StatusFilter _filter = _StatusFilter.all;

  int? _selectedId;

  // ── "New invoice" flow — picks a recent Sale, then the same bill-to
  // mini-form documents_page.dart already had. ──────────────────────
  bool _creating = false;
  bool _salesLoading = false;
  String? _salesError;
  List<Sale> _recentSales = const [];
  Sale? _sourceSale;
  List<SaleLine> _sourceLines = const [];
  bool _linesLoading = false;

  String _billToName = '';
  String _billToPhone = '';
  String _billToAddress = '';
  String _billToEmail = '';
  String _dueDate = '';
  String _paymentInstructions = '';
  bool _submitting = false;
  String? _createError;

  bool _charging = false;
  String? _payError;

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
        component.client.invoice.listInvoices(
          component.accessToken,
          component.workspaceId,
          limit: 200,
          offset: 0,
        ),
        component.client.payment.listConnectedGateways(
          component.accessToken,
          component.workspaceId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _invoices = results[0] as List<Invoice>;
        _gateways = results[1] as List<PaymentGatewayCredential>;
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

  Invoice? get _selected {
    final id = _selectedId;
    if (id == null) return null;
    final match = _invoices.where((i) => i.id == id).toList();
    return match.isEmpty ? null : match.first;
  }

  bool _isOverdue(Invoice i) =>
      i.status != 'paid' && i.dueAt != null && i.dueAt!.isBefore(DateTime.now());

  // ── List filtering ────────────────────────────────────────────────

  List<Invoice> get _filtered {
    final q = _search.trim().toLowerCase();
    return [
      for (final i in _invoices)
        if (_matchesFilter(i) &&
            (q.isEmpty ||
                i.billToName.toLowerCase().contains(q) ||
                i.reference.toLowerCase().contains(q)))
          i,
    ];
  }

  bool _matchesFilter(Invoice i) => switch (_filter) {
        _StatusFilter.all => true,
        _StatusFilter.draft => i.status == 'draft',
        _StatusFilter.sent => i.status == 'sent',
        _StatusFilter.viewed => i.status == 'viewed',
        _StatusFilter.partlyPaid => i.status == 'partly_paid',
        _StatusFilter.paid => i.status == 'paid',
        _StatusFilter.overdue => _isOverdue(i),
      };

  // ── "New invoice" flow ────────────────────────────────────────────

  Future<void> _openCreate() async {
    setState(() {
      _creating = true;
      _sourceSale = null;
      _sourceLines = const [];
      _billToName = '';
      _billToPhone = '';
      _billToAddress = '';
      _billToEmail = '';
      _dueDate = '';
      _paymentInstructions = '';
      _createError = null;
    });
    if (_recentSales.isNotEmpty) return;
    setState(() {
      _salesLoading = true;
      _salesError = null;
    });
    try {
      final sales = await component.client.sale.listSales(
        component.accessToken,
        component.workspaceId,
        limit: 20,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _recentSales = sales;
        _salesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salesError = ErrorText.of(e);
        _salesLoading = false;
      });
    }
  }

  void _cancelCreate() => setState(() => _creating = false);

  Future<void> _pickSale(Sale sale) async {
    setState(() {
      _sourceSale = sale;
      _sourceLines = const [];
      _linesLoading = true;
      _createError = null;
    });
    try {
      final lines = await component.client.sale.getSaleLines(
        component.accessToken,
        component.workspaceId,
        sale.id!,
      );
      if (!mounted) return;
      setState(() {
        _sourceLines = lines;
        _linesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _createError = ErrorText.of(e);
        _linesLoading = false;
      });
    }
  }

  Future<void> _submitCreate() async {
    final sale = _sourceSale;
    if (sale == null || _sourceLines.isEmpty) return;
    final name = _billToName.trim();
    if (name.isEmpty) {
      setState(() => _createError = 'Bill-to name is required.');
      return;
    }
    setState(() {
      _submitting = true;
      _createError = null;
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
          for (final l in _sourceLines)
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
        _invoices = [invoice, ..._invoices];
        _selectedId = invoice.id;
        _creating = false;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _createError = ErrorText.of(e);
      });
    }
  }

  // ── Detail actions ────────────────────────────────────────────────

  Future<void> _setStatus(String status) async {
    final invoice = _selected;
    if (invoice?.id == null) return;
    try {
      final updated = await component.client.invoice.updateInvoiceStatus(
        component.accessToken,
        component.workspaceId,
        invoice!.id!,
        status,
      );
      if (!mounted) return;
      setState(() {
        _invoices = [for (final i in _invoices) if (i.id == updated.id) updated else i];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _payError = ErrorText.of(e));
    }
  }

  Future<void> _payNow() async {
    final invoice = _selected;
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
        customerPhone: (invoice.billToPhone?.trim().isEmpty ?? true) ? null : invoice.billToPhone!.trim(),
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

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:1180px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        _printStyles(),
        if (_creating)
          _createFlow()
        else if (_selected != null)
          _detailView(_selected!)
        else ...[
          _header(),
          if (_loading)
            _loadingState()
          else if (_loadError != null)
            _errorState()
          else ...[
            _statsRow(),
            _searchAndFilter(),
            _invoiceList(),
          ],
        ],
      ],
    );
  }

  /// Scopes browser printing to just the invoice document itself — the
  /// same #kola-print-area trick documents_page.dart's own _printStyles
  /// uses, copied rather than shared: this page has no dependency on
  /// that file, and the trick is three lines of CSS, not worth a shared
  /// helper for.
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

  Component _header() => div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;align-items:flex-start;'
              'gap:12px;flex-wrap:wrap;margin-bottom:${KolaSpace.lg}',
        },
        [
          div([
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.display};font-size:${KolaType.h2};'
                    'color:${KolaVar.text};font-weight:700;margin-bottom:6px',
              },
              [Component.text('Invoices')],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                    'line-height:1.55;max-width:60ch',
              },
              [Component.text('Every invoice this business has issued, who owes what, and what\'s overdue.')],
            ),
          ]),
          button(
            attributes: {
              'type': 'button',
              'style': 'background:${KolaVar.accentFill};color:${KolaVar.accentText};border:none;'
                  'border-radius:${KolaRadius.pill};padding:11px 18px;font-size:${KolaType.body};'
                  'font-weight:600;font-family:inherit;cursor:pointer;display:inline-flex;'
                  'align-items:center;gap:6px;flex:none',
            },
            events: {'click': (_) => _openCreate()},
            [kolaIcon(Icons.plus, size: 14, strokeWidth: 2.2), Component.text('New invoice')],
          ),
          const PageHelpButton(
            pageKey: 'invoices',
            body: [
              "Every invoice this business has issued, who owes what, "
                  "and what's overdue. Numbers above summarize total, "
                  "outstanding, overdue and paid at a glance.",
            ],
          ),
        ],
      );

  Component _statsRow() {
    final total = _invoices.length;
    final outstandingMinor = _invoices
        .where((i) => i.status != 'paid')
        .fold<int>(0, (sum, i) => sum + (i.totalMinor - i.paidMinor));
    final overdueCount = _invoices.where(_isOverdue).length;
    final paidCount = _invoices.where((i) => i.status == 'paid').length;
    return div(
      attributes: {
        'style': 'display:grid;grid-template-columns:repeat(4,1fr);gap:12px;'
            'margin-bottom:${KolaSpace.lg}',
      },
      [
        _statCard('Total invoices', '$total', KolaVar.text),
        _statCard('Outstanding', formatMinor(outstandingMinor), KolaVar.accent),
        _statCard('Overdue', '$overdueCount', overdueCount > 0 ? KolaVar.danger : KolaVar.text),
        _statCard('Paid', '$paidCount', KolaVar.success),
      ],
    );
  }

  Component _statCard(String label, String value, String valueColor) => div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:14px 16px',
        },
        [
          div(
            attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:4px'},
            [Component.text(label)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;color:$valueColor;'
                  'font-family:${KolaFonts.mono}',
            },
            [Component.text(value)],
          ),
        ],
      );

  Component _searchAndFilter() => div(
        attributes: {
          'style': 'display:flex;gap:10px;flex-wrap:wrap;align-items:center;'
              'margin-bottom:${KolaSpace.md}',
        },
        [
          input<String>(
            type: InputType.text,
            value: _search,
            onInput: (v) => setState(() => _search = v),
            attributes: {
              'placeholder': 'Search by name or reference…',
              'style': 'flex:1;min-width:200px;background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};border-radius:${KolaRadius.md};'
                  'padding:10px 14px;color:${KolaVar.text};font-family:inherit;'
                  'font-size:${KolaType.small};box-sizing:border-box',
            },
          ),
          div(
            attributes: {'style': 'display:flex;gap:6px;flex-wrap:wrap'},
            [
              for (final (f, label) in const [
                (_StatusFilter.all, 'All'),
                (_StatusFilter.draft, 'Draft'),
                (_StatusFilter.sent, 'Sent'),
                (_StatusFilter.viewed, 'Viewed'),
                (_StatusFilter.partlyPaid, 'Partly paid'),
                (_StatusFilter.paid, 'Paid'),
                (_StatusFilter.overdue, 'Overdue'),
              ])
                _filterChip(f, label),
            ],
          ),
        ],
      );

  Component _filterChip(_StatusFilter f, String label) {
    final active = _filter == f;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.accentFill : KolaVar.card};'
            'color:${active ? KolaVar.accentText : KolaVar.muted};'
            'border-radius:${KolaRadius.pill};padding:7px 13px;'
            'font-size:${KolaType.tiny};font-weight:600;font-family:inherit;cursor:pointer',
      },
      events: {'click': (_) => setState(() => _filter = f)},
      [Component.text(label)],
    );
  }

  Component _invoiceList() {
    final rows = _filtered;
    if (_invoices.isEmpty) return _emptyState();
    if (rows.isEmpty) {
      return div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};border-radius:${KolaRadius.lg};'
              'padding:30px;text-align:center;color:${KolaVar.muted};font-size:${KolaType.small}',
        },
        [Component.text('No invoices match this search or filter.')],
      );
    }
    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};overflow:hidden',
      },
      [for (final i in rows) _invoiceRow(i)],
    );
  }

  Component _invoiceRow(Invoice i) {
    final overdue = _isOverdue(i);
    final balanceDue = i.totalMinor - i.paidMinor;
    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:12px;padding:14px 16px;'
            'border-bottom:1px solid ${KolaVar.border};cursor:pointer',
      },
      events: {'click': (_) => setState(() => _selectedId = i.id)},
      [
        div(
          attributes: {'style': 'flex:1;min-width:0'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:600;color:${KolaVar.text};'
                    'overflow:hidden;text-overflow:ellipsis;white-space:nowrap',
              },
              [Component.text(i.billToName)],
            ),
            div(
              attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-top:2px'},
              [Component.text('${i.reference} · Issued ${_fullDateShort(i.issuedAt)}')],
            ),
          ],
        ),
        _statusBadge(i.status, overdue: overdue),
        div(
          attributes: {'style': 'text-align:right;flex:none;min-width:110px'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:700;color:${KolaVar.text};'
                    'font-family:${KolaFonts.mono}',
              },
              [Component.text(formatMinor(i.totalMinor))],
            ),
            if (balanceDue > 0 && i.status != 'paid')
              div(
                attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}'},
                [Component.text('${formatMinor(balanceDue)} due')],
              ),
          ],
        ),
        kolaIcon(Icons.chevronRight, size: 14, strokeWidth: 2, extraStyle: 'color:${KolaVar.muted}'),
      ],
    );
  }

  Component _statusBadge(String status, {bool overdue = false}) {
    if (overdue) {
      return _badge('Overdue', '#3a1f14', '#ff9466');
    }
    final (label, bg, fg) = switch (status) {
      'paid' => ('Paid', KolaVar.successBg, KolaVar.success),
      'partly_paid' => ('Partly paid', KolaVar.warningBg, KolaVar.warning),
      'sent' => ('Sent', KolaVar.pill, KolaVar.text),
      'viewed' => ('Viewed', KolaVar.pill, KolaVar.text),
      _ => ('Draft', KolaVar.pill, KolaVar.muted),
    };
    return _badge(label, bg, fg);
  }

  Component _badge(String label, String bg, String fg) => div(
        attributes: {
          'style': 'background:$bg;color:$fg;border-radius:${KolaRadius.pill};'
              'padding:4px 10px;font-size:${KolaType.tiny};font-weight:600;flex:none;'
              'white-space:nowrap',
        },
        [Component.text(label)],
      );

  Component _emptyState() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};border-radius:${KolaRadius.lg};'
              'padding:44px 24px;text-align:center;color:${KolaVar.muted};'
              'font-size:${KolaType.body}',
        },
        [
          div(
            attributes: {'style': 'margin-bottom:10px;display:flex;justify-content:center'},
            [kolaIcon(Icons.printer, size: 22)],
          ),
          div(
            attributes: {'style': 'font-weight:700;color:${KolaVar.text};margin-bottom:6px'},
            [Component.text('No invoices yet')],
          ),
          div(
            attributes: {'style': 'font-size:${KolaType.small};line-height:1.55;margin-bottom:16px'},
            [Component.text('Ring up a sale at the counter, then turn it into an invoice here.')],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'background:${KolaVar.accentFill};color:${KolaVar.accentText};border:none;'
                  'border-radius:${KolaRadius.pill};padding:10px 18px;font-size:${KolaType.small};'
                  'font-weight:600;font-family:inherit;cursor:pointer',
            },
            events: {'click': (_) => _openCreate()},
            [Component.text('New invoice')],
          ),
        ],
      );

  Component _loadingState() => div(
        attributes: {
          'style': 'height:220px;border-radius:${KolaRadius.lg};border:1px solid ${KolaVar.border};'
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
            [Component.text('Could not load invoices')],
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

  // ── Create flow ────────────────────────────────────────────────────

  Component _createFlow() => div([
        button(
          attributes: {
            'type': 'button',
            'style': 'background:transparent;border:none;color:${KolaVar.muted};'
                'font-family:inherit;font-size:${KolaType.body};cursor:pointer;padding:0 0 14px;'
                'display:flex;align-items:center;gap:3px',
          },
          events: {'click': (_) => _cancelCreate()},
          [kolaIcon(Icons.chevronLeft, size: 12, strokeWidth: 2.5), Component.text('Back to invoices')],
        ),
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.display};font-size:${KolaType.h2};font-weight:700;'
                'margin-bottom:16px',
          },
          [Component.text('New invoice')],
        ),
        _sourceSale == null ? _saleChooser() : _billToForm(),
      ]);

  Component _saleChooser() {
    if (_salesLoading) return _loadingState();
    if (_salesError != null) {
      return div(
        attributes: {'style': 'color:${KolaVar.danger};font-size:${KolaType.small}'},
        [Component.text(_salesError!)],
      );
    }
    if (_recentSales.isEmpty) {
      return div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};border-radius:${KolaRadius.lg};'
              'padding:30px;text-align:center;color:${KolaVar.muted};font-size:${KolaType.small}',
        },
        [Component.text('No recent sales to invoice yet — ring one up at the counter first.')],
      );
    }
    return div([
      div(
        attributes: {'style': 'font-size:${KolaType.small};color:${KolaVar.muted};margin-bottom:12px'},
        [Component.text('Pick a recent sale — its line items become the invoice.')],
      ),
      div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};overflow:hidden;max-width:520px',
        },
        [for (final s in _recentSales) _saleRow(s)],
      ),
    ]);
  }

  Component _saleRow(Sale s) => div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;align-items:center;'
              'padding:12px 16px;border-bottom:1px solid ${KolaVar.border};cursor:pointer',
        },
        events: {'click': (_) => _pickSale(s)},
        [
          div([
            div(
              attributes: {'style': 'font-size:${KolaType.small};font-weight:600'},
              [Component.text(s.reference)],
            ),
            div(
              attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}'},
              [Component.text(_fullDateShort(s.soldAt))],
            ),
          ]),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};font-weight:700;font-size:${KolaType.small}',
            },
            [Component.text(formatMinor(s.totalMinor))],
          ),
        ],
      );

  Component _billToForm() => div(
        attributes: {'style': 'max-width:420px'},
        [
          div(
            attributes: {
              'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};padding:22px',
            },
            [
              div(
                attributes: {'style': 'font-size:${KolaType.ui};font-weight:700;margin-bottom:4px'},
                [Component.text('Invoicing ${_sourceSale!.reference}')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};color:${KolaVar.muted};margin-bottom:16px',
                },
                [Component.text(_linesLoading ? 'Loading line items…' : '${_sourceLines.length} line item(s) — just who it\'s billed to and when it\'s due.')],
              ),
              _field('Bill to (name)', _billToName, (v) => setState(() => _billToName = v)),
              _field('Phone', _billToPhone, (v) => setState(() => _billToPhone = v)),
              _field('Address', _billToAddress, (v) => setState(() => _billToAddress = v)),
              _field('Email (for the payment link)', _billToEmail, (v) => setState(() => _billToEmail = v)),
              _field('Due date (YYYY-MM-DD)', _dueDate, (v) => setState(() => _dueDate = v)),
              _field('Payment instructions', _paymentInstructions, (v) => setState(() => _paymentInstructions = v)),
              if (_createError != null)
                div(
                  attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};margin-bottom:10px'},
                  [Component.text(_createError!)],
                ),
              button(
                attributes: {
                  'type': 'button',
                  if (_submitting || _linesLoading) 'disabled': 'disabled',
                  'style': 'width:100%;background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                      'border:none;border-radius:${KolaRadius.pill};padding:12px;'
                      'font-size:${KolaType.bodyLg};font-weight:600;font-family:inherit;'
                      'cursor:${_submitting ? 'default' : 'pointer'};min-height:44px;'
                      'opacity:${_submitting || _linesLoading ? '0.6' : '1'}',
                },
                events: {'click': (_) => (_submitting || _linesLoading) ? null : _submitCreate()},
                [Component.text(_submitting ? 'Creating…' : 'Create invoice')],
              ),
            ],
          ),
        ],
      );

  Component _field(String label, String value, void Function(String) onChange) => div(
        attributes: {'style': 'margin-bottom:12px'},
        [
          div(
            attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:4px'},
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

  // ── Detail / print view ───────────────────────────────────────────

  Component _detailView(Invoice invoice) {
    final lines = (jsonDecode(invoice.linesJson) as List).cast<Map<String, dynamic>>();
    final balanceDue = invoice.totalMinor - invoice.paidMinor;
    final overdue = _isOverdue(invoice);

    return div([
      div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;align-items:center;'
              'flex-wrap:wrap;gap:10px;margin-bottom:16px',
        },
        [
          button(
            attributes: {
              'type': 'button',
              'style': 'background:transparent;border:none;color:${KolaVar.muted};'
                  'font-family:inherit;font-size:${KolaType.body};cursor:pointer;padding:0;'
                  'display:flex;align-items:center;gap:3px',
            },
            events: {'click': (_) => setState(() => _selectedId = null)},
            [kolaIcon(Icons.chevronLeft, size: 12, strokeWidth: 2.5), Component.text('Back to invoices')],
          ),
          _printButton(),
        ],
      ),
      div(
        attributes: {'style': 'display:flex;gap:8px;margin-bottom:20px;flex-wrap:wrap'},
        [
          for (final s in const ['draft', 'sent', 'viewed', 'partly_paid', 'paid'])
            _statusChip(s, invoice.status == s),
          if (overdue) _badge('Overdue', '#3a1f14', '#ff9466'),
        ],
      ),
      div(
        attributes: {
          'style': 'background:#fff;color:#111;width:100%;max-width:560px;padding:32px;'
              'font-family:${KolaFonts.sans};font-size:${KolaType.small};line-height:1.5;'
              'margin:0 auto;box-shadow:0 14px 40px rgba(0,0,0,0.35);box-sizing:border-box',
          'id': 'kola-print-area',
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
                  div(attributes: {'style': 'color:#666'}, [Component.text(invoice.reference)]),
                  div(
                    attributes: {'style': 'color:#666;margin-top:4px'},
                    [Component.text('Issued ${_fullDateShort(invoice.issuedAt)}')],
                  ),
                  if (invoice.dueAt != null)
                    div(
                      attributes: {
                        'style': 'font-weight:600;margin-top:2px;color:${overdue ? '#c1440e' : '#111'}',
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
              div(attributes: {'style': 'font-weight:700'}, [Component.text(invoice.billToName)]),
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
            attributes: {
              'style': 'border-top:1px solid #eee;border-bottom:1px solid #eee;padding:8px 0;margin-bottom:8px',
            },
            [
              div(
                attributes: {'style': 'display:flex;font-size:${KolaType.tiny};color:#888;font-weight:600'},
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
              _invoiceRowLine('Subtotal', formatMinor(invoice.subtotalMinor)),
              if (invoice.taxRateBps > 0)
                _invoiceRowLine('VAT (${(invoice.taxRateBps / 100).toStringAsFixed(1)}%)', formatMinor(invoice.taxMinor)),
              if (invoice.paidMinor > 0) _invoiceRowLine('Paid', '−${formatMinor(invoice.paidMinor)}'),
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
                  input<String>(
                    type: InputType.text,
                    value: _billToEmail,
                    onInput: (v) => setState(() => _billToEmail = v),
                    attributes: {
                      'placeholder': 'Customer email for the payment link',
                      'style': 'width:100%;background:#fafafa;border:1px solid #ddd;'
                          'border-radius:${KolaRadius.sm};padding:9px 12px;color:#111;'
                          'font-family:inherit;font-size:${KolaType.small};box-sizing:border-box;'
                          'margin-bottom:8px',
                    },
                  ),
                if (_gateways.isNotEmpty)
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

  Component _invoiceRowLine(String label, String value) => div(
        attributes: {'style': 'display:flex;justify-content:space-between;padding:2px 0;color:#444'},
        [Component.text(label), Component.text(value)],
      );

  Component _statusChip(String status, bool active) {
    final label = switch (status) {
      'partly_paid' => 'Partly paid',
      _ => status[0].toUpperCase() + status.substring(1),
    };
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:1px solid ${KolaVar.border};padding:7px 14px;border-radius:${KolaRadius.pill};'
            'font-size:${KolaType.tiny};font-weight:600;font-family:inherit;cursor:pointer;'
            'background:${active ? KolaVar.accentFill : KolaVar.card};'
            'color:${active ? KolaVar.accentText : KolaVar.muted}',
      },
      events: {'click': (_) => _setStatus(status)},
      [Component.text(label)],
    );
  }

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

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _fullDateShort(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
}
