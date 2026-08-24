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
// A4 INVOICE and END-OF-DAY REPORT tabs have no real backend at all —
// there is no Invoice/Order entity (PART V's own gap table names this;
// Gate 5's entity-mapping status note hit the identical wall) and no
// EOD aggregation endpoint. Building either is a real design decision on
// its own, not a corner of "redesign Till to match its export."
//
// An earlier pass rendered these two as populated mock documents using
// the export's own dummy numbers (a fake "Kemi Catering Co." bill-to,
// a fake ₦340,000 day) sitting next to this workspace's REAL name —
// real and fabricated data side by side on the same document, which is
// worse than either alone: it reads as a bug, not a preview. Fixed to
// the same honest empty-state pattern settings_page.dart's `_notYet`
// already uses elsewhere in this codebase — what's missing, and what it
// takes to get it — rather than a screen that looks populated but
// isn't.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

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
    // Viewport-locked, per styles.css's own convention (html/body carry
    // overflow:hidden app-wide — a page must own a bounded height and
    // scroll internally, or content taller than the viewport gets
    // silently clipped with no way to reach the rest of it, which is
    // exactly what was happening here before this had its own
    // height:100vh + overflow-y:auto).
    return div(
      attributes: {
        'style': "font-family:${KolaFonts.sans};background:${KolaVar.bg};"
            'color:${KolaVar.text};height:100vh;overflow-y:auto;box-sizing:border-box',
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

  // ── A4 invoice and End-of-day report — no backend for either ──────
  //
  // See the file header: there is no Invoice/Order entity and no EOD
  // aggregation endpoint, so there is nothing real to show. Both tabs
  // use the same honest "not built yet" treatment settings_page.dart's
  // `_notYet` already established elsewhere in this codebase, instead
  // of a populated mock document that mixes this workspace's real name
  // with someone else's fabricated invoice.

  Component _a4Tab() => _comingSoon(
        icon: Icons.billing,
        headline: 'Invoicing isn\'t built yet',
        body: 'There\'s no Invoice entity behind this tab yet — creating one, '
            'and deciding how a sale becomes a bill with terms and a due '
            'date, is its own piece of work. Nothing here is wired to real '
            'data.',
      );

  Component _reportTab() => _comingSoon(
        icon: Icons.barChart,
        headline: 'End-of-day reports aren\'t built yet',
        body: 'There\'s no aggregation endpoint behind this tab yet — '
            'summing a day\'s takings by payment method needs its own '
            'server-side work. Nothing here is wired to real data.',
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
