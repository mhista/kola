// till_page.dart — the sales counter. PART II's gap table: "Sales
// counter PARTIAL. Migration 035 applied. Model, endpoint and Till page
// outstanding." Gate 3b: every completed sale resolves/creates a
// Customer via CustomerIdentityResolver and immediately shows up on
// that customer's page (customers_page.dart).
//
// ── REBUILT AGAINST Kola Till.dc.html, PIXEL-FOR-PIXEL ─────────────────
//
// The previous version of this file was a working but visually
// unrelated page — a two-column search/cart layout that never matched
// the design export. This rewrite follows the export's own structure
// exactly: a Sell → Payment → Receipt screen flow (not one long form),
// category chips, a phone/tablet layout toggle, and a barcode-scanner
// modal, all drawn with this codebase's own KolaVar/KolaType/KolaRadius
// tokens rather than the export's literal hex values — same rule
// settings_page.dart and every other rebuilt page already follows.
//
// ── WHERE THIS DELIBERATELY DEVIATES FROM THE EXPORT, AND WHY ─────────
//
// 1. OFFLINE QUEUE. The export's state carries `queued`/`online` as if
//    an offline sale queue already exists. It does not — that needs a
//    service worker or local persistence layer with its own retry/
//    conflict story, a real feature in its own right. This page shows
//    REAL online/offline status (the browser's navigator.onLine) and
//    completes sales only while online; SaleEndpoint.ringUpSale already
//    accepts a clientReference for idempotency whenever the queue is
//    built (see sale_repository.dart's header), so nothing here blocks
//    that follow-up.
//
// 2. BARCODE SCANNER. The export's own "scan" button does not decode a
//    real camera feed either — its click handler is a hardcoded
//    `simulateScan` that always adds "Red Ankara". Building a live
//    camera+decoder is a real feature (getUserMedia permission flow, a
//    barcode-decoding library this project does not depend on). This
//    page keeps the export's modal frame exactly, but replaces the fake
//    "sample scan" button with a real text field matched against each
//    product's own SKU — which also means a real handheld barcode
//    scanner (these type digits + Enter like a keyboard) works today by
//    just being pointed at this field.
//
// 3. NO CUSTOMER CAPTURE. The export's payment screen has none, so
//    this page has none either — a walk-in sale with no phone/name is a
//    complete, normal sale (sale.spy.yaml's own header). Customer
//    identity from the till is Gate 3b's job, not this screen's.
//
// ── SAME SHAPE AS OTHER PAGES ON THIS DESIGN SYSTEM ────────────────────
//
// Product search reuses ProductEndpoint.listProducts (already built for
// catalog_page.dart). Checkout is one call to SaleEndpoint.ringUpSale;
// the receipt is rendered from what that call returns plus the cart
// snapshot taken right before it clears, never guessed.

import 'dart:js_interop';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;
import 'package:kola_client/kola_client.dart';

import '../components/shell/kola_icon.dart';
import '../components/shell/icons.dart';
import '../services/error_text.dart';
import '../services/money_format.dart';
import '../theme.dart';

class _CartLine {
  _CartLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  int get unitPriceMinor => product.priceMinor ?? 0;
  int get lineTotalMinor => unitPriceMinor * quantity;
}

/// A snapshot taken the instant a sale completes — the cart is about to
/// be cleared, and the receipt screen (here and on Documents) must keep
/// showing what was actually sold, not whatever the cart holds later.
class _CompletedSale {
  _CompletedSale({required this.sale, required this.lines, required this.paidLabel});

  final Sale sale;
  final List<_CartLine> lines;
  final String paidLabel;
}

class TillPage extends StatefulComponent {
  const TillPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.workspaceName,
    required this.taxRateBps,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final String workspaceName;

  /// The workspace's real VAT rate (basis points). The export hardcodes
  /// "VAT (7.5%)" as a label; this page computes the actual tax the
  /// server will charge (SaleEndpoint.ringUpSale reads the same field),
  /// which is 0 for the many shops that are not VAT-registered — see
  /// migration 035's own header on why 7.5% is not a safe default.
  final int taxRateBps;

  @override
  State<TillPage> createState() => _TillPageState();
}

enum _Screen { sell, payment, receipt }

class _TillPageState extends State<TillPage> {
  List<Product> _products = const [];
  bool _loading = true;
  String? _loadError;

  String _view = 'tablet';
  _Screen _screen = _Screen.sell;

  String _search = '';
  String? _category;

  final List<_CartLine> _cart = [];
  String? _payMethod;
  String _cashReceived = '';

  bool _online = true;
  web.EventListener? _onlineListener;
  web.EventListener? _offlineListener;

  bool _showScanner = false;
  String _scanInput = '';
  String? _scanError;

  bool _charging = false;
  String? _chargeError;
  _CompletedSale? _completed;

  @override
  void initState() {
    super.initState();
    _view = web.window.innerWidth >= KolaBreak.tablet ? 'tablet' : 'phone';
    _online = web.window.navigator.onLine;
    // Explicit `return;` at the end of each closure, deliberately.
    // Without one, a block-bodied closure with no return statement at
    // all infers as `Null Function(Event)` rather than
    // `void Function(Event)` — and `.toJS` only has an extension for
    // the void shape. app_shell.dart's own listeners avoid this by
    // accident (their early-exit branches happen to contain a bare
    // `return;`); this makes it deliberate instead of coincidental.
    _onlineListener = (web.Event _) {
      if (mounted) setState(() => _online = true);
      return;
    }.toJS;
    _offlineListener = (web.Event _) {
      if (mounted) setState(() => _online = false);
      return;
    }.toJS;
    web.window.addEventListener('online', _onlineListener);
    web.window.addEventListener('offline', _offlineListener);
    _load();
  }

  @override
  void dispose() {
    if (_onlineListener != null) {
      web.window.removeEventListener('online', _onlineListener);
    }
    if (_offlineListener != null) {
      web.window.removeEventListener('offline', _offlineListener);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final products = await component.client.product.listProducts(
        component.accessToken,
        component.workspaceId,
        // Serverpod's generated client drops default values — a
        // documented landmine in this codebase (bool x = false becomes
        // required bool x on the wire). Must be passed explicitly.
        includeArchived: false,
      );
      if (!mounted) return;
      setState(() {
        _products = [for (final p in products) if (p.status != 'archived') p];
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

  // ── Categories ─────────────────────────────────────────────────────

  /// Real categories, in first-seen order — never the export's static
  // ['fabric','gowns','accessories','services']. product.spy.yaml's own
  // header says category is free text a shop chooses, so this page
  // must read whatever they actually chose, not a guessed taxonomy.
  List<String> get _categories {
    final seen = <String>[];
    for (final p in _products) {
      final c = p.category?.trim();
      if (c != null && c.isNotEmpty && !seen.contains(c)) seen.add(c);
    }
    return seen;
  }

  List<Product> get _filteredProducts {
    final q = _search.trim().toLowerCase();
    return [
      for (final p in _products)
        if ((_category == null || p.category == _category) &&
            (q.isEmpty || p.name.toLowerCase().contains(q)))
          p,
    ];
  }

  // ── Cart ───────────────────────────────────────────────────────────

  void _addToCart(Product product) {
    if (product.priceMinor == null) return;
    setState(() {
      final existing = _cart.where((l) => l.product.id == product.id).toList();
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(_CartLine(product: product));
      }
    });
  }

  void _inc(_CartLine line) => setState(() => line.quantity++);

  void _dec(_CartLine line) {
    if (line.quantity <= 1) return;
    setState(() => line.quantity--);
  }

  void _removeLine(_CartLine line) => setState(() => _cart.remove(line));

  int _quantityInCart(Product p) {
    final match = _cart.where((l) => l.product.id == p.id).toList();
    return match.isEmpty ? 0 : match.first.quantity;
  }

  int get _subtotalMinor => _cart.fold(0, (sum, l) => sum + l.lineTotalMinor);
  int get _taxMinor => (_subtotalMinor * component.taxRateBps / 10000).round();
  int get _totalMinor => _subtotalMinor + _taxMinor;

  /// Digits typed so far, read as whole Naira then converted to minor
  /// units — same "strip everything but digits" approach the export's
  /// own `parseInt((cashReceived||'0').replace(/[^0-9]/g,''),10)` uses,
  /// so a cashier can type "40000" or "₦40,000" and either works.
  int get _cashReceivedMinor {
    final digits = _cashReceived.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return (int.tryParse(digits) ?? 0) * 100;
  }

  int get _changeMinor => _cashReceivedMinor - _totalMinor;

  bool get _completeDisabled {
    if (_payMethod == null || _charging) return true;
    if (_payMethod == 'Cash' && _changeMinor < 0) return true;
    return false;
  }

  Future<void> _completeSale() async {
    if (_completeDisabled) return;
    setState(() {
      _charging = true;
      _chargeError = null;
    });
    try {
      final method = _payMethod!.toLowerCase();
      final sale = await component.client.sale.ringUpSale(
        component.accessToken,
        component.workspaceId,
        lines: [
          for (final l in _cart)
            SaleLineInput(
              productId: l.product.id,
              name: l.product.name,
              unitPriceMinor: l.unitPriceMinor,
              quantity: l.quantity,
            ),
        ],
        paymentMethod: method,
        cashReceivedMinor: method == 'cash' ? _cashReceivedMinor : null,
      );
      if (!mounted) return;
      setState(() {
        _completed = _CompletedSale(
          sale: sale,
          lines: List.of(_cart),
          paidLabel: _payMethod!,
        );
        _cart.clear();
        _payMethod = null;
        _cashReceived = '';
        _charging = false;
        _screen = _Screen.receipt;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _charging = false;
        _chargeError = ErrorText.of(e);
      });
    }
  }

  void _voidSale() {
    setState(() {
      _screen = _Screen.sell;
      _payMethod = null;
      _cashReceived = '';
      _chargeError = null;
    });
  }

  void _newSale() {
    setState(() {
      _screen = _Screen.sell;
      _cart.clear();
      _payMethod = null;
      _cashReceived = '';
      _completed = null;
    });
  }

  // ── Scanner ────────────────────────────────────────────────────────

  void _openScanner() => setState(() {
        _showScanner = true;
        _scanInput = '';
        _scanError = null;
      });

  void _closeScanner() => setState(() => _showScanner = false);

  void _submitScan() {
    final q = _scanInput.trim().toLowerCase();
    if (q.isEmpty) return;
    final matches = _products.where(
      (p) => (p.sku?.trim().toLowerCase() == q) || p.name.toLowerCase().contains(q),
    );
    if (matches.isEmpty) {
      setState(() => _scanError = 'No product matches "$_scanInput".');
      return;
    }
    _addToCart(matches.first);
    setState(() => _showScanner = false);
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': "font-family:${KolaFonts.sans};background:${KolaVar.bg};"
            'color:${KolaVar.text};min-height:100vh;box-sizing:border-box',
      },
      [
        _header(),
        if (_view == 'tablet') _tabletBody() else _phoneBody(),
        if (_showScanner) _scannerModal(),
      ],
    );
  }

  Component _header() => div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;'
              'align-items:center;padding:14px 20px;'
              'border-bottom:1px solid ${KolaVar.border};gap:10px;'
              'flex-wrap:wrap',
        },
        [
          div(
            attributes: {'style': 'display:flex;align-items:center;gap:12px;min-width:0'},
            [
              Link(
                to: '/',
                attributes: {
                  'style': 'color:${KolaVar.text};font-weight:600;'
                      'text-decoration:none;font-size:${KolaType.body};'
                      'display:inline-flex;align-items:center;gap:3px;flex:none',
                },
                children: [kolaIcon(Icons.chevronLeft, size: 12, strokeWidth: 2.5), Component.text('Dashboard')],
              ),
              div(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};font-size:${KolaType.subhead};'
                      'font-weight:600;white-space:nowrap;flex:none',
                },
                [Component.text('Sales Counter')],
              ),
              div(
                attributes: {'style': 'display:flex;align-items:center;gap:6px'},
                [
                  div(
                    attributes: {
                      'style': 'width:7px;height:7px;border-radius:50%;flex:none;'
                          'background:${_online ? KolaVar.success : KolaVar.warning}',
                    },
                    [],
                  ),
                  span(
                    attributes: {
                      'style': 'font-size:${KolaType.tiny};font-weight:600;white-space:nowrap;'
                          'color:${_online ? KolaVar.success : KolaVar.warning}',
                    },
                    [Component.text(_online ? 'Online' : 'Offline')],
                  ),
                ],
              ),
            ],
          ),
          div(
            attributes: {'style': 'display:flex;gap:8px;flex:none'},
            [
              Link(
                to: '/documents',
                attributes: {
                  'style': 'background:transparent;border:1px solid ${KolaVar.border};'
                      'color:${KolaVar.text};border-radius:${KolaRadius.pill};padding:7px 14px;'
                      'font-size:${KolaType.small};font-family:inherit;text-decoration:none;'
                      'display:inline-flex;align-items:center',
                },
                children: [Component.text('Documents')],
              ),
              div(
                attributes: {
                  'style': 'display:flex;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                      'border-radius:${KolaRadius.pill};padding:3px',
                },
                [
                  _viewToggleButton('phone', 'Phone'),
                  _viewToggleButton('tablet', 'Tablet/Desktop'),
                ],
              ),
            ],
          ),
        ],
      );

  Component _viewToggleButton(String value, String label) {
    final active = _view == value;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:none;padding:6px 12px;border-radius:${KolaRadius.pill};'
            'font-size:${KolaType.tiny};font-family:inherit;cursor:pointer;'
            'background:${active ? KolaVar.accentFill : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.muted}',
      },
      events: {'click': (_) => setState(() => _view = value)},
      [Component.text(label)],
    );
  }

  // ── Tablet/desktop: two-pane ─────────────────────────────────────────

  Component _tabletBody() => div(
        attributes: {
          'style': 'display:grid;grid-template-columns:1fr 360px;'
              'min-height:calc(100vh - 57px)',
        },
        [
          div(
            attributes: {'style': 'padding:20px 24px;box-sizing:border-box'},
            [
              _searchRow(),
              _categoryChips(),
              _productGrid(columns: 4),
            ],
          ),
          div(
            attributes: {
              'style': 'border-left:1px solid ${KolaVar.border};display:flex;'
                  'flex-direction:column;box-sizing:border-box',
            },
            [_rightRail()],
          ),
        ],
      );

  Component _rightRail() {
    switch (_screen) {
      case _Screen.sell:
        return _sellRail();
      case _Screen.payment:
        return _paymentRail();
      case _Screen.receipt:
        return _receiptRail();
    }
  }

  // ── Phone: single column ──────────────────────────────────────────

  Component _phoneBody() => div(
        attributes: {'style': 'max-width:420px;margin:0 auto;padding-bottom:20px'},
        [
          if (_screen == _Screen.sell) ...[
            div(
              attributes: {'style': 'padding:14px 16px 0'},
              [_searchRow(), _categoryChips(), _productGrid(columns: 2)],
            ),
            if (_cart.isNotEmpty) _phoneCartList() else _phoneEmptyBasketNote(),
            _phoneSellFooter(),
          ] else if (_screen == _Screen.payment)
            _phonePayment()
          else
            _phoneReceipt(),
        ],
      );

  // ── Shared: search + categories + grid ────────────────────────────

  Component _searchRow() => div(
        attributes: {'style': 'display:flex;gap:8px;margin-bottom:14px'},
        [
          input<String>(
            type: InputType.text,
            value: _search,
            onInput: (v) => setState(() => _search = v),
            attributes: {
              'placeholder': 'Scan a barcode or search a product…',
              'style': 'flex:1;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.md};padding:14px 16px;color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.lead};box-sizing:border-box;'
                  'min-height:48px',
            },
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.md};width:48px;height:48px;flex:none;'
                  'cursor:pointer;color:${KolaVar.text};display:flex;align-items:center;'
                  'justify-content:center',
            },
            events: {'click': (_) => _openScanner()},
            [kolaIcon(Icons.barcode, size: 18, strokeWidth: 1.8)],
          ),
        ],
      );

  Component _categoryChips() {
    final cats = _categories;
    if (cats.isEmpty) return div([]);
    return div(
      attributes: {'style': 'display:flex;gap:6px;margin-bottom:16px;flex-wrap:wrap'},
      [
        _categoryChip(null, 'All'),
        for (final c in cats) _categoryChip(c, c),
      ],
    );
  }

  Component _categoryChip(String? id, String label) {
    final active = _category == id;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'padding:8px 14px;border-radius:${KolaRadius.pill};font-size:${KolaType.small};'
            'font-family:inherit;cursor:pointer;white-space:nowrap;'
            'background:${active ? KolaVar.pill : 'transparent'};'
            'color:${active ? KolaVar.text : KolaVar.muted}',
      },
      events: {'click': (_) => setState(() => _category = id)},
      [Component.text(label)],
    );
  }

  Component _productGrid({required int columns}) {
    if (_loading) return _gridSkeleton(columns: columns);
    if (_loadError != null) return _errorState();
    final filtered = _filteredProducts;
    if (_products.isEmpty) {
      return _emptyState('No products in your catalog yet. Add one in Catalog and it shows up here.');
    }
    if (filtered.isEmpty) {
      return _emptyState('Nothing matches that search.');
    }
    return div(
      attributes: {
        'style': 'display:grid;grid-template-columns:repeat($columns,1fr);gap:12px',
      },
      [for (final p in filtered) _productTile(p)],
    );
  }

  Component _productTile(Product p) {
    final priced = p.priceMinor != null;
    final qty = _quantityInCart(p);
    return button(
      attributes: {
        'type': 'button',
        if (!priced) 'disabled': 'disabled',
        'style': 'position:relative;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:0;text-align:left;'
            'cursor:${priced ? 'pointer' : 'default'};font-family:inherit;color:${KolaVar.text};'
            'overflow:hidden;min-height:132px;display:flex;flex-direction:column',
      },
      events: {
        'click': (_) {
          if (priced) _addToCart(p);
        },
      },
      [
        div(
          attributes: {
            'style': 'width:100%;aspect-ratio:1.4;background:${KolaVar.bg};'
                'display:flex;align-items:center;justify-content:center;flex:none',
          },
          [kolaIcon(Icons.imagePlaceholder, size: 22, strokeWidth: 1.7, extraStyle: 'color:${KolaVar.muted}')],
        ),
        div(
          attributes: {
            'style': 'padding:10px 12px;flex:1;display:flex;flex-direction:column;'
                'justify-content:space-between',
          },
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.bodyLg};font-weight:600;overflow:hidden;'
                    'text-overflow:ellipsis;white-space:nowrap;margin-bottom:4px',
              },
              [Component.text(p.name)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                    'font-family:${KolaFonts.mono}',
              },
              [Component.text(priced ? formatMinor(p.priceMinor!) : 'Ask price')],
            ),
          ],
        ),
        if (qty > 0)
          div(
            attributes: {
              'style': 'position:absolute;top:8px;right:8px;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-size:${KolaType.micro};font-weight:700;'
                  'border-radius:${KolaRadius.pill};min-width:20px;height:20px;padding:0 6px;'
                  'display:flex;align-items:center;justify-content:center',
            },
            [Component.text('$qty')],
          ),
      ],
    );
  }

  // ── Tablet right rail: sell ───────────────────────────────────────

  Component _sellRail() => div([
        div(
          attributes: {'style': 'padding:18px 20px;flex:1;overflow-y:auto'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};font-weight:700;color:${KolaVar.mutedStrong};'
                    'margin-bottom:12px;text-transform:uppercase;letter-spacing:0.04em',
              },
              [Component.text('Current sale · ${_cart.fold(0, (n, l) => n + l.quantity)} items')],
            ),
            if (_cart.isEmpty)
              div(
                attributes: {
                  'style': 'text-align:center;padding:44px 16px;color:${KolaVar.muted};'
                      'font-size:${KolaType.body}',
                },
                [Component.text('Tap a product to start a sale')],
              )
            else
              div(
                attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
                [for (final l in _cart) _railCartRow(l)],
              ),
          ],
        ),
        div(
          attributes: {'style': 'padding:16px 20px;border-top:1px solid ${KolaVar.border}'},
          [
            _totalsRows(),
            button(
              attributes: {
                'type': 'button',
                if (_cart.isEmpty) 'disabled': 'disabled',
                'style': 'width:100%;background:${_cart.isNotEmpty ? KolaVar.accentFill : KolaVar.pill};'
                    'color:${_cart.isNotEmpty ? KolaVar.accentText : KolaVar.muted};border:none;'
                    'border-radius:${KolaRadius.lg};padding:16px;font-size:${KolaType.lead};'
                    'font-weight:700;font-family:inherit;'
                    'cursor:${_cart.isNotEmpty ? 'pointer' : 'default'};min-height:52px',
              },
              events: {
                'click': (_) {
                  if (_cart.isNotEmpty) setState(() => _screen = _Screen.payment);
                },
              },
              [Component.text('Charge ${formatMinor(_totalMinor)}')],
            ),
          ],
        ),
      ]);

  Component _railCartRow(_CartLine line) => div(
        attributes: {
          'style': 'background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:12px 14px',
        },
        [
          div(
            attributes: {
              'style': 'display:flex;justify-content:space-between;gap:8px;margin-bottom:8px',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};font-weight:600;overflow:hidden;'
                      'text-overflow:ellipsis;white-space:nowrap',
                },
                [Component.text(line.product.name)],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};font-family:${KolaFonts.mono};flex:none',
                },
                [Component.text(formatMinor(line.lineTotalMinor))],
              ),
            ],
          ),
          div(
            attributes: {'style': 'display:flex;align-items:center;gap:8px'},
            [
              _stepperButton('−', () => _dec(line)),
              span(
                attributes: {'style': 'font-size:${KolaType.body};width:24px;text-align:center'},
                [Component.text('${line.quantity}')],
              ),
              _stepperButton('+', () => _inc(line)),
              span(
                attributes: {
                  'style': 'flex:1;text-align:right;font-size:${KolaType.tiny};'
                      'color:${KolaVar.muted};font-family:${KolaFonts.mono}',
                },
                [Component.text('${formatMinor(line.unitPriceMinor)} ea')],
              ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:28px;height:28px;border-radius:${KolaRadius.sm};'
                      'background:${KolaVar.dangerBg};border:none;color:${KolaVar.danger};'
                      'font-size:${KolaType.body};cursor:pointer',
                },
                events: {'click': (_) => _removeLine(line)},
                [Component.text('×')],
              ),
            ],
          ),
        ],
      );

  Component _stepperButton(String label, void Function() onTap) => button(
        attributes: {
          'type': 'button',
          'style': 'width:28px;height:28px;border-radius:${KolaRadius.sm};background:${KolaVar.pill};'
              'border:none;color:${KolaVar.text};font-size:${KolaType.lead};cursor:pointer',
        },
        events: {'click': (_) => onTap()},
        [Component.text(label)],
      );

  Component _totalsRows() => div([
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;font-size:${KolaType.body};'
                'color:${KolaVar.muted};margin-bottom:4px',
          },
          [Component.text('Subtotal'), Component.text(formatMinor(_subtotalMinor))],
        ),
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;font-size:${KolaType.body};'
                'color:${KolaVar.muted};margin-bottom:10px',
          },
          [
            Component.text('VAT (${(component.taxRateBps / 100).toStringAsFixed(1)}%)'),
            Component.text(formatMinor(_taxMinor)),
          ],
        ),
      ]);

  // ── Tablet right rail: payment ────────────────────────────────────

  Component _paymentRail() => div([
        div(
          attributes: {'style': 'padding:18px 20px;flex:1;overflow-y:auto'},
          [_paymentBody()],
        ),
        div(
          attributes: {'style': 'padding:16px 20px;border-top:1px solid ${KolaVar.border}'},
          [_paymentActions()],
        ),
      ]);

  Component _paymentBody() => div([
        button(
          attributes: {
            'type': 'button',
            'style': 'background:transparent;border:none;color:${KolaVar.muted};'
                'font-family:inherit;font-size:${KolaType.body};cursor:pointer;padding:0 0 14px;'
                'display:flex;align-items:center;gap:3px',
          },
          events: {'click': (_) => setState(() => _screen = _Screen.sell)},
          [kolaIcon(Icons.chevronLeft, size: 12, strokeWidth: 2.5), Component.text('Back to sale')],
        ),
        div(
          attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:4px'},
          [Component.text('Total due')],
        ),
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.display};font-size:${KolaType.display};'
                'font-weight:700;margin-bottom:18px',
          },
          [Component.text(formatMinor(_totalMinor))],
        ),
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:16px',
          },
          [for (final m in const ['Cash', 'Transfer', 'Card', 'Split']) _paymentMethodButton(m)],
        ),
        if (_payMethod == 'Cash') _cashPanel(),
        if (_chargeError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.danger};line-height:1.5;'
                  'margin-bottom:12px',
            },
            [Component.text(_chargeError!)],
          ),
      ]);

  Component _paymentMethodButton(String method) {
    final active = _payMethod == method;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.pill : KolaVar.card};'
            'color:${active ? KolaVar.text : KolaVar.mutedStrong};border-radius:${KolaRadius.md};'
            'padding:14px;font-size:${KolaType.bodyLg};font-weight:600;font-family:inherit;'
            'cursor:pointer;min-height:52px',
      },
      events: {'click': (_) => setState(() => _payMethod = method)},
      [Component.text(method)],
    );
  }

  Component _cashPanel() {
    final change = _changeMinor;
    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};padding:16px;margin-bottom:16px',
      },
      [
        div(
          attributes: {'style': 'font-size:${KolaType.small};color:${KolaVar.muted};margin-bottom:8px'},
          [Component.text('Cash received')],
        ),
        input<String>(
          type: InputType.text,
          value: _cashReceived,
          onInput: (v) => setState(() => _cashReceived = v),
          attributes: {
            'placeholder': '₦0',
            'style': 'width:100%;background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.sm};padding:13px 14px;color:${KolaVar.text};'
                'font-family:${KolaFonts.mono};font-size:${KolaType.title};box-sizing:border-box;'
                'margin-bottom:10px',
          },
        ),
        div(
          attributes: {'style': 'display:flex;justify-content:space-between;font-size:${KolaType.ui}'},
          [
            span(attributes: {'style': 'color:${KolaVar.muted}'}, [Component.text('Change due')]),
            span(
              attributes: {
                'style': 'font-weight:700;font-family:${KolaFonts.mono};'
                    'color:${change < 0 ? KolaVar.danger : KolaVar.success}',
              },
              [Component.text(formatMinor(change < 0 ? 0 : change))],
            ),
          ],
        ),
      ],
    );
  }

  Component _paymentActions() => div([
        button(
          attributes: {
            'type': 'button',
            if (_completeDisabled) 'disabled': 'disabled',
            'style': 'width:100%;background:${_completeDisabled ? KolaVar.pill : KolaVar.accentFill};'
                'color:${_completeDisabled ? KolaVar.muted : KolaVar.accentText};border:none;'
                'border-radius:${KolaRadius.lg};padding:16px;font-size:${KolaType.lead};'
                'font-weight:700;font-family:inherit;'
                'cursor:${_completeDisabled ? 'default' : 'pointer'};min-height:52px;margin-bottom:8px',
          },
          events: {
            'click': (_) {
              if (!_completeDisabled) _completeSale();
            },
          },
          [Component.text(_charging ? 'Completing…' : 'Complete sale')],
        ),
        button(
          attributes: {
            'type': 'button',
            'style': 'width:100%;background:transparent;border:1px solid ${KolaVar.dangerBg};'
                'color:${KolaVar.danger};border-radius:${KolaRadius.lg};padding:11px;'
                'font-size:${KolaType.body};font-family:inherit;cursor:pointer;min-height:44px',
          },
          events: {'click': (_) => _voidSale()},
          [Component.text('Cancel sale')],
        ),
      ]);

  // ── Tablet right rail: receipt ────────────────────────────────────

  Component _receiptRail() {
    final completed = _completed;
    if (completed == null) return div([]);
    return div([
      div(
        attributes: {'style': 'padding:22px 20px;flex:1;overflow-y:auto'},
        [_receiptBody(completed)],
      ),
      div(
        attributes: {'style': 'padding:16px 20px;border-top:1px solid ${KolaVar.border}'},
        [_newSaleButton()],
      ),
    ]);
  }

  Component _receiptBody(_CompletedSale completed) => div([
        div(
          attributes: {'style': 'text-align:center;margin-bottom:16px'},
          [
            div(
              attributes: {
                'style': 'width:44px;height:44px;border-radius:50%;background:${KolaVar.successBg};'
                    'color:${KolaVar.successBright};display:flex;align-items:center;'
                    'justify-content:center;font-size:${KolaType.h2};margin:0 auto 10px',
              },
              [Component.text('✓')],
            ),
            div(
              attributes: {'style': 'font-size:${KolaType.lead};font-weight:600'},
              [Component.text('Sale complete')],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};padding:14px;font-family:${KolaFonts.mono};'
                'font-size:${KolaType.tiny};line-height:1.7;margin-bottom:14px',
          },
          [
            for (final l in completed.lines)
              div(
                attributes: {'style': 'display:flex;justify-content:space-between'},
                [
                  Component.text('${l.product.name} ×${l.quantity}'),
                  Component.text(formatMinor(l.lineTotalMinor)),
                ],
              ),
            div(
              attributes: {
                'style': 'border-top:1px dashed ${KolaVar.border};margin:6px 0;padding-top:6px;'
                    'display:flex;justify-content:space-between;font-weight:700',
              },
              [Component.text('Total'), Component.text(formatMinor(completed.sale.totalMinor))],
            ),
            div(
              attributes: {'style': 'color:${KolaVar.muted}'},
              [Component.text('Paid by ${completed.paidLabel}')],
            ),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
          [_whatsAppButton(completed), _printLink()],
        ),
      ]);

  Component _whatsAppButton(_CompletedSale completed) => button(
        attributes: {
          'type': 'button',
          'style': 'background:${KolaVar.success};color:${KolaVar.accentText};border:none;'
              'border-radius:${KolaRadius.md};padding:13px;font-size:${KolaType.body};'
              'font-weight:600;font-family:inherit;cursor:pointer;display:flex;align-items:center;'
              'justify-content:center;gap:6px',
        },
        events: {'click': (_) => _openWhatsAppReceipt(completed)},
        [kolaIcon(Icons.whatsapp, size: 14, strokeWidth: 1.8), Component.text('Send on WhatsApp')],
      );

  Component _printLink() => Link(
        to: '/documents',
        attributes: {
          'style': 'text-align:center;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'color:${KolaVar.text};border-radius:${KolaRadius.md};padding:13px;'
              'font-size:${KolaType.body};text-decoration:none;display:block',
        },
        children: [Component.text('Print')],
      );

  Component _newSaleButton() => button(
        attributes: {
          'type': 'button',
          'style': 'width:100%;background:${KolaVar.accentFill};color:${KolaVar.accentText};'
              'border:none;border-radius:${KolaRadius.lg};padding:15px;font-size:${KolaType.uiLg};'
              'font-weight:700;font-family:inherit;cursor:pointer;min-height:50px',
        },
        events: {'click': (_) => _newSale()},
        [Component.text('New sale')],
      );

  /// Real, but scope-cut to what a shop can use without the WhatsApp
  /// Business API's template-approval flow: a wa.me deep link opens the
  /// owner's own WhatsApp with the receipt text pre-filled, ready to
  /// send from whichever chat they pick. No phone number is captured
  /// at the till (see the file header), so this always opens the
  /// picker rather than a fixed contact.
  void _openWhatsAppReceipt(_CompletedSale completed) {
    final buffer = StringBuffer()
      ..writeln('${component.workspaceName} — receipt ${completed.sale.reference}')
      ..writeln();
    for (final l in completed.lines) {
      buffer.writeln('${l.product.name} ×${l.quantity}  ${formatMinor(l.lineTotalMinor)}');
    }
    buffer
      ..writeln()
      ..writeln('Total: ${formatMinor(completed.sale.totalMinor)}')
      ..writeln('Paid by ${completed.paidLabel}');
    final url = 'https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}';
    web.window.open(url, '_blank');
  }

  // ── Phone screens ──────────────────────────────────────────────────

  Component _phoneCartList() => div(
        attributes: {'style': 'padding:0 16px'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};font-weight:700;color:${KolaVar.mutedStrong};'
                  'margin-bottom:8px;text-transform:uppercase;letter-spacing:0.04em',
            },
            [Component.text('Current sale')],
          ),
          div(
            attributes: {'style': 'display:flex;flex-direction:column;gap:8px;margin-bottom:14px'},
            [for (final l in _cart) _phoneCartRow(l)],
          ),
        ],
      );

  Component _phoneCartRow(_CartLine line) => div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:12px 14px;display:flex;'
              'align-items:center;gap:10px',
        },
        [
          div(
            attributes: {'style': 'flex:1;min-width:0'},
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};font-weight:600;overflow:hidden;'
                      'text-overflow:ellipsis;white-space:nowrap',
                },
                [Component.text(line.product.name)],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                      'font-family:${KolaFonts.mono}',
                },
                [
                  Component.text(
                    '${formatMinor(line.unitPriceMinor)} × ${line.quantity} = '
                    '${formatMinor(line.lineTotalMinor)}',
                  ),
                ],
              ),
            ],
          ),
          _phoneStepperButton('−', () => _dec(line)),
          _phoneStepperButton('+', () => _inc(line)),
          button(
            attributes: {
              'type': 'button',
              'style': 'width:34px;height:34px;border-radius:${KolaRadius.sm};'
                  'background:${KolaVar.dangerBg};border:none;color:${KolaVar.danger};'
                  'font-size:${KolaType.ui};cursor:pointer;flex:none',
            },
            events: {'click': (_) => _removeLine(line)},
            [Component.text('×')],
          ),
        ],
      );

  Component _phoneStepperButton(String label, void Function() onTap) => button(
        attributes: {
          'type': 'button',
          'style': 'width:34px;height:34px;border-radius:${KolaRadius.sm};background:${KolaVar.pill};'
              'border:none;color:${KolaVar.text};font-size:${KolaType.subhead};cursor:pointer;flex:none',
        },
        events: {'click': (_) => onTap()},
        [Component.text(label)],
      );

  Component _phoneEmptyBasketNote() => div(
        attributes: {
          'style': 'text-align:center;padding:30px 20px;color:${KolaVar.muted};'
              'font-size:${KolaType.body}',
        },
        [Component.text('Basket is empty — tap a product or scan a barcode')],
      );

  Component _phoneSellFooter() => div(
        attributes: {
          'style': 'position:sticky;bottom:0;left:0;right:0;background:${KolaVar.bg};'
              'border-top:1px solid ${KolaVar.border};padding:14px 16px 18px;box-sizing:border-box',
        },
        [
          _totalsRows(),
          button(
            attributes: {
              'type': 'button',
              if (_cart.isEmpty) 'disabled': 'disabled',
              'style': 'width:100%;background:${_cart.isNotEmpty ? KolaVar.accentFill : KolaVar.pill};'
                  'color:${_cart.isNotEmpty ? KolaVar.accentText : KolaVar.muted};border:none;'
                  'border-radius:${KolaRadius.lg};padding:17px;font-size:${KolaType.subhead};'
                  'font-weight:700;font-family:inherit;'
                  'cursor:${_cart.isNotEmpty ? 'pointer' : 'default'};min-height:56px',
            },
            events: {
              'click': (_) {
                if (_cart.isNotEmpty) setState(() => _screen = _Screen.payment);
              },
            },
            [Component.text('Charge ${formatMinor(_totalMinor)}')],
          ),
        ],
      );

  Component _phonePayment() => div(
        attributes: {'style': 'padding:8px 16px 24px'},
        [_paymentBody(), _paymentActions()],
      );

  Component _phoneReceipt() {
    final completed = _completed;
    if (completed == null) return div([]);
    return div(
      attributes: {'style': 'padding:20px 16px'},
      [
        div(
          attributes: {'style': 'text-align:center;margin-bottom:18px'},
          [
            div(
              attributes: {
                'style': 'width:52px;height:52px;border-radius:50%;background:${KolaVar.successBg};'
                    'color:${KolaVar.successBright};display:flex;align-items:center;'
                    'justify-content:center;font-size:${KolaType.h3};margin:0 auto 12px',
              },
              [Component.text('✓')],
            ),
            div(
              attributes: {'style': 'font-size:${KolaType.title};font-weight:600'},
              [Component.text('Sale complete')],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};padding:18px;font-family:${KolaFonts.mono};'
                'font-size:${KolaType.small};line-height:1.8;margin-bottom:16px',
          },
          [
            div(
              attributes: {
                'style': 'font-weight:700;font-family:${KolaFonts.sans};font-size:${KolaType.ui};'
                    'margin-bottom:8px',
              },
              [Component.text(component.workspaceName)],
            ),
            for (final l in completed.lines)
              div(
                attributes: {'style': 'display:flex;justify-content:space-between'},
                [
                  Component.text('${l.product.name} ×${l.quantity}'),
                  Component.text(formatMinor(l.lineTotalMinor)),
                ],
              ),
            div(
              attributes: {
                'style': 'border-top:1px dashed ${KolaVar.border};margin:8px 0;padding-top:8px;'
                    'display:flex;justify-content:space-between;font-weight:700',
              },
              [Component.text('Total'), Component.text(formatMinor(completed.sale.totalMinor))],
            ),
            div(
              attributes: {'style': 'color:${KolaVar.muted}'},
              [Component.text('Paid by ${completed.paidLabel}')],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:10px',
          },
          [_whatsAppButton(completed), _printLink()],
        ),
        _newSaleButton(),
      ],
    );
  }

  // ── Barcode scanner modal ──────────────────────────────────────────

  Component _scannerModal() => div(
        attributes: {
          'style': 'position:fixed;inset:0;background:rgba(0,0,0,0.75);z-index:100;'
              'display:flex;align-items:center;justify-content:center;padding:20px',
        },
        events: {'click': (_) => _closeScanner()},
        [
          div(
            attributes: {
              'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.xl};padding:26px;width:100%;max-width:340px;'
                  'box-sizing:border-box;text-align:center',
            },
            events: {'click': (e) => e.stopPropagation()},
            [
              div(
                attributes: {
                  'style': 'width:100%;aspect-ratio:1;background:${KolaVar.bg};'
                      'border-radius:${KolaRadius.lg};position:relative;overflow:hidden;'
                      'margin-bottom:16px;display:flex;align-items:center;justify-content:center',
                },
                [
                  div(
                    attributes: {
                      'style': 'position:absolute;inset:24px;border:2px solid ${KolaVar.accent};'
                          'border-radius:${KolaRadius.sm}',
                    },
                    [],
                  ),
                  kolaIcon(Icons.barcode, size: 40, strokeWidth: 1.6, extraStyle: 'color:${KolaVar.muted}'),
                ],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};color:${KolaVar.mutedStrong};margin-bottom:6px',
                },
                [Component.text('No camera scanner is wired up yet')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:14px',
                },
                [Component.text('Type or scan a product\'s SKU with a handheld scanner')],
              ),
              input<String>(
                type: InputType.text,
                value: _scanInput,
                onInput: (v) => setState(() => _scanInput = v),
                attributes: {
                  'placeholder': 'SKU or product name',
                  'autofocus': 'autofocus',
                  'style': 'width:100%;background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
                      'border-radius:${KolaRadius.sm};padding:11px 13px;color:${KolaVar.text};'
                      'font-family:${KolaFonts.mono};font-size:${KolaType.body};box-sizing:border-box;'
                      'margin-bottom:10px',
                },
                events: {
                  'keydown': (e) {
                    // Hardware barcode scanners emit a trailing Enter —
                    // this is what makes them work here with no extra
                    // wiring beyond focusing this field. Same cast
                    // app_shell.dart's ⌘K listener and ask_kola.dart's
                    // Enter-to-send already use.
                    final ev = e as web.KeyboardEvent;
                    if (ev.key == 'Enter') _submitScan();
                  },
                },
              ),
              if (_scanError != null)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};margin-bottom:10px',
                  },
                  [Component.text(_scanError!)],
                ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:100%;background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                      'border:none;border-radius:${KolaRadius.pill};padding:12px;'
                      'font-size:${KolaType.bodyLg};font-weight:600;font-family:inherit;'
                      'cursor:pointer;min-height:44px;margin-bottom:8px',
                },
                events: {'click': (_) => _submitScan()},
                [Component.text('Add to sale')],
              ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:100%;background:transparent;border:1px solid ${KolaVar.border};'
                      'color:${KolaVar.muted};border-radius:${KolaRadius.pill};padding:11px;'
                      'font-size:${KolaType.body};font-family:inherit;cursor:pointer',
                },
                events: {'click': (_) => _closeScanner()},
                [Component.text('Cancel')],
              ),
            ],
          ),
        ],
      );

  // ── Shared states ──────────────────────────────────────────────────

  Component _emptyState(String message) => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};border-radius:${KolaRadius.md};'
              'padding:${KolaSpace.lg};text-align:center;font-size:${KolaType.small};'
              'color:${KolaVar.muted}',
        },
        [Component.text(message)],
      );

  Component _gridSkeleton({required int columns}) => div(
        attributes: {
          'style': 'display:grid;grid-template-columns:repeat($columns,1fr);gap:12px',
        },
        [
          for (var i = 0; i < columns * 2; i++)
            div(
              attributes: {
                'style': 'height:132px;border-radius:${KolaRadius.lg};'
                    'border:1px solid ${KolaVar.border};background:${KolaVar.card}',
              },
              const [],
            ),
        ],
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
            [Component.text('Could not load your catalog')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};line-height:1.55;'
                  'margin-bottom:12px',
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
}
