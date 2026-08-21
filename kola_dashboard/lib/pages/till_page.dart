// till_page.dart — the sales counter. PART II's gap table: "Sales
// counter PARTIAL. Migration 035 applied. Model, endpoint and Till page
// outstanding." This is the last of those three. Gate 3b: every
// completed sale resolves/creates a Customer via CustomerIdentityResolver
// and immediately shows up on that customer's page (customers_page.dart).
//
// ── SCOPE CUT, STATED PLAINLY ──────────────────────────────────────────
//
// The design export's Till state includes `queued`/`online` — an
// offline sale queue that syncs later. That needs a service worker or
// local storage layer with its own retry/conflict story, which is a
// real feature in its own right, not a corner of this one. This page
// is fully wired for ONLINE sales (SaleEndpoint.ringUpSale already
// supports clientReference-based idempotency for whenever that lands —
// see sale_repository.dart's header). Building the offline queue itself
// is follow-up work, named here rather than silently left out.
//
// ── SAME SHAPE AS OTHER PAGES ON THIS DESIGN SYSTEM ───────────────────
//
// Product search reuses ProductEndpoint.listProducts (already built for
// catalog_page.dart) rather than inventing a second product-listing
// path. Checkout is one call to SaleEndpoint.ringUpSale; the receipt is
// rendered from what that call returns, never guessed client-side.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/kola_icon.dart';
import '../components/shell/icons.dart';
import '../services/error_text.dart';
import '../theme.dart';

class _CartLine {
  _CartLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  int get unitPriceMinor => product.priceMinor ?? 0;
  int get lineTotalMinor => unitPriceMinor * quantity;
}

class TillPage extends StatefulComponent {
  const TillPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<TillPage> createState() => _TillPageState();
}

class _TillPageState extends State<TillPage> {
  List<Product> _products = const [];
  bool _loading = true;
  String? _loadError;
  String _search = '';

  final List<_CartLine> _cart = [];
  String _paymentMethod = 'cash';
  String _cashReceived = '';
  String _customerPhone = '';
  String _customerName = '';

  bool _charging = false;
  String? _chargeError;
  Sale? _lastSale;

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

  // ── Cart ───────────────────────────────────────────────────────────

  void _addToCart(Product product) {
    setState(() {
      final existing = _cart.where((l) => l.product.id == product.id).toList();
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(_CartLine(product: product));
      }
    });
  }

  void _changeQuantity(_CartLine line, int delta) {
    setState(() {
      line.quantity += delta;
      if (line.quantity <= 0) _cart.remove(line);
    });
  }

  int get _subtotalMinor => _cart.fold(0, (sum, l) => sum + l.lineTotalMinor);

  int? get _cashReceivedMinor {
    final value = double.tryParse(_cashReceived.trim());
    if (value == null) return null;
    return (value * 100).round();
  }

  int? get _changeMinor {
    final received = _cashReceivedMinor;
    if (received == null) return null;
    return received - _subtotalMinor;
  }

  bool get _canCharge {
    if (_cart.isEmpty || _charging) return false;
    if (_paymentMethod == 'cash') {
      final change = _changeMinor;
      return change != null && change >= 0;
    }
    return true;
  }

  Future<void> _charge() async {
    if (!_canCharge) return;
    setState(() {
      _charging = true;
      _chargeError = null;
    });
    try {
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
        paymentMethod: _paymentMethod,
        cashReceivedMinor: _paymentMethod == 'cash' ? _cashReceivedMinor : null,
        customerPhone: _customerPhone.trim().isEmpty ? null : _customerPhone.trim(),
        customerName: _customerName.trim().isEmpty ? null : _customerName.trim(),
      );
      if (!mounted) return;
      setState(() {
        _lastSale = sale;
        _cart.clear();
        _cashReceived = '';
        _customerPhone = '';
        _customerName = '';
        _charging = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _charging = false;
        _chargeError = ErrorText.of(e);
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:1100px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        _header(),
        if (_lastSale != null) _receipt(_lastSale!),
        if (_loading)
          _skeleton()
        else if (_loadError != null)
          _errorState()
        else
          div(
            attributes: {
              'style': 'display:grid;grid-template-columns:1.3fr 1fr;'
                  'gap:${KolaSpace.lg};align-items:start',
            },
            [_productPanel(), _cartPanel()],
          ),
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
            [Component.text('Sales counter')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.55',
            },
            [Component.text('Ring up a sale. It shows up on the customer\'s page immediately.')],
          ),
        ],
      );

  // ── Product panel ─────────────────────────────────────────────────

  Component _productPanel() {
    final q = _search.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _products
        : [for (final p in _products) if (p.name.toLowerCase().contains(q)) p];

    return div([
      input<String>(
        type: InputType.text,
        attributes: {
          'placeholder': 'Search products…',
          'style': 'width:100%;box-sizing:border-box;padding:11px 13px;'
              'border-radius:${KolaRadius.md};border:1px solid ${KolaVar.border};'
              'background:${KolaVar.card};color:${KolaVar.text};'
              'font-family:inherit;font-size:${KolaType.body};'
              'margin-bottom:${KolaSpace.md}',
        },
        value: _search,
        onInput: (v) => setState(() => _search = v),
      ),
      if (filtered.isEmpty)
        _emptyState(_products.isEmpty
            ? 'No products in your catalog yet.'
            : 'No products match that search.')
      else
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:repeat(2,1fr);'
                'gap:${KolaSpace.sm}',
          },
          [for (final p in filtered) _productTile(p)],
        ),
    ]);
  }

  Component _productTile(Product p) {
    final price = p.priceMinor;
    return button(
      attributes: {
        'type': 'button',
        if (price == null) 'disabled': 'disabled',
        'style': 'text-align:left;background:${KolaVar.card};'
            'border:1px solid ${KolaVar.border};border-radius:${KolaRadius.md};'
            'padding:${KolaSpace.smd};cursor:${price == null ? 'default' : 'pointer'};'
            'font-family:inherit',
      },
      events: {
        'click': (_) {
          if (price != null) _addToCart(p);
        },
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.body};font-weight:600;'
                'color:${KolaVar.text};margin-bottom:4px',
          },
          [Component.text(p.name)],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'font-family:${KolaFonts.mono}',
          },
          [
            Component.text(
              price == null ? 'No price set' : '${p.priceCurrency} ${(price / 100).toStringAsFixed(2)}',
            ),
          ],
        ),
      ],
    );
  }

  // ── Cart panel ─────────────────────────────────────────────────────

  Component _cartPanel() => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};background:${KolaVar.card};'
              'padding:${KolaSpace.lg};position:sticky;top:${KolaSpace.lg}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.uiLg};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:${KolaSpace.md}',
            },
            [Component.text('Cart')],
          ),
          if (_cart.isEmpty)
            _emptyState('Nothing added yet.')
          else ...[
            div(
              attributes: {'style': 'display:flex;flex-direction:column;gap:8px;margin-bottom:${KolaSpace.md}'},
              [for (final l in _cart) _cartRow(l)],
            ),
            _totalsBlock(),
            _paymentBlock(),
            _customerBlock(),
            if (_chargeError != null)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                      'line-height:1.5;margin:${KolaSpace.sm} 0',
                },
                [Component.text(_chargeError!)],
              ),
            button(
              attributes: {
                'type': 'button',
                if (!_canCharge) 'disabled': 'disabled',
                'style': 'width:100%;margin-top:${KolaSpace.md};'
                    'background:${_canCharge ? KolaVar.accentFill : KolaVar.pill};'
                    'color:${_canCharge ? KolaVar.accentText : KolaVar.muted};'
                    'border:none;border-radius:${KolaRadius.sm};padding:13px;'
                    'font-size:${KolaType.bodyLg};font-weight:700;font-family:inherit;'
                    'cursor:${_canCharge ? 'pointer' : 'default'}',
              },
              events: {
                'click': (_) {
                  if (_canCharge) _charge();
                },
              },
              [Component.text(_charging ? 'Completing…' : 'Complete sale')],
            ),
          ],
        ],
      );

  Component _cartRow(_CartLine line) => div(
        attributes: {
          'style': 'display:flex;align-items:center;justify-content:space-between;gap:8px',
        },
        [
          div(
            attributes: {'style': 'min-width:0;flex:1'},
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};color:${KolaVar.text};'
                      'font-weight:600',
                },
                [Component.text(line.product.name)],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                      'font-family:${KolaFonts.mono}',
                },
                [Component.text('${line.product.priceCurrency} ${(line.lineTotalMinor / 100).toStringAsFixed(2)}')],
              ),
            ],
          ),
          div(
            attributes: {'style': 'display:flex;align-items:center;gap:6px;flex:none'},
            [
              _qtyButton('−', () => _changeQuantity(line, -1)),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};color:${KolaVar.text};'
                      'min-width:18px;text-align:center;font-family:${KolaFonts.mono}',
                },
                [Component.text('${line.quantity}')],
              ),
              _qtyButton('+', () => _changeQuantity(line, 1)),
            ],
          ),
        ],
      );

  Component _qtyButton(String label, void Function() onTap) => button(
        attributes: {
          'type': 'button',
          'style': 'width:24px;height:24px;border-radius:${KolaRadius.sm};'
              'border:1px solid ${KolaVar.border};background:${KolaVar.pill};'
              'color:${KolaVar.text};font-family:inherit;font-size:${KolaType.small};'
              'font-weight:700;cursor:pointer;display:flex;align-items:center;'
              'justify-content:center;padding:0',
        },
        events: {'click': (_) => onTap()},
        [Component.text(label)],
      );

  Component _totalsBlock() {
    final subtotal = _subtotalMinor;
    return div(
      attributes: {
        'style': 'border-top:1px solid ${KolaVar.border};padding-top:${KolaSpace.sm};'
            'margin-bottom:${KolaSpace.md};display:flex;justify-content:space-between;'
            'font-size:${KolaType.bodyLg};font-weight:700;color:${KolaVar.text}',
      },
      [
        Component.text('Total'),
        Component.text('NGN ${(subtotal / 100).toStringAsFixed(2)}'),
      ],
    );
  }

  Component _paymentBlock() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.md}'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:6px',
            },
            [Component.text('Payment method')],
          ),
          div(
            attributes: {'style': 'display:flex;gap:6px;flex-wrap:wrap;margin-bottom:${KolaSpace.sm}'},
            [
              for (final (value, label) in const [
                ('cash', 'Cash'),
                ('transfer', 'Transfer'),
                ('card', 'Card'),
              ])
                _methodChip(value, label),
            ],
          ),
          if (_paymentMethod == 'cash')
            input<String>(
              type: InputType.text,
              attributes: {
                'placeholder': 'Cash received',
                'style': 'width:100%;box-sizing:border-box;padding:10px 12px;'
                    'border-radius:${KolaRadius.sm};border:1px solid ${KolaVar.border};'
                    'background:${KolaVar.bg};color:${KolaVar.text};'
                    'font-family:${KolaFonts.mono};font-size:${KolaType.small}',
              },
              value: _cashReceived,
              onInput: (v) => setState(() => _cashReceived = v),
            ),
          if (_paymentMethod == 'cash' && _changeMinor != null && _changeMinor! >= 0)
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-top:6px',
              },
              [Component.text('Change: NGN ${(_changeMinor! / 100).toStringAsFixed(2)}')],
            ),
        ],
      );

  Component _methodChip(String value, String label) {
    final active = _paymentMethod == value;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.pill : 'transparent'};'
            'color:${active ? KolaVar.text : KolaVar.muted};'
            'border-radius:${KolaRadius.pill};padding:7px 13px;'
            'font-size:${KolaType.tiny};font-family:inherit;cursor:pointer',
      },
      events: {'click': (_) => setState(() => _paymentMethod = value)},
      [Component.text(label)],
    );
  }

  Component _customerBlock() => div([
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:6px',
          },
          [Component.text('Customer (optional)')],
        ),
        input<String>(
          type: InputType.text,
          attributes: {
            'placeholder': 'Phone number',
            'style': 'width:100%;box-sizing:border-box;padding:10px 12px;'
                'border-radius:${KolaRadius.sm};border:1px solid ${KolaVar.border};'
                'background:${KolaVar.bg};color:${KolaVar.text};'
                'font-family:inherit;font-size:${KolaType.small};'
                'margin-bottom:6px',
          },
          value: _customerPhone,
          onInput: (v) => setState(() => _customerPhone = v),
        ),
        if (_customerPhone.trim().isNotEmpty)
          input<String>(
            type: InputType.text,
            attributes: {
              'placeholder': 'Name (optional)',
              'style': 'width:100%;box-sizing:border-box;padding:10px 12px;'
                  'border-radius:${KolaRadius.sm};border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.bg};color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.small}',
            },
            value: _customerName,
            onInput: (v) => setState(() => _customerName = v),
          ),
      ]);

  // ── Receipt ────────────────────────────────────────────────────────

  Component _receipt(Sale sale) => div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.success};'
              'border-radius:${KolaRadius.md};padding:${KolaSpace.md} ${KolaSpace.lg};'
              'margin-bottom:${KolaSpace.lg};display:flex;justify-content:space-between;'
              'align-items:center;gap:${KolaSpace.md};flex-wrap:wrap',
        },
        [
          div([
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:700;'
                    'color:${KolaVar.text};margin-bottom:3px',
              },
              [Component.text('Sale complete — ${sale.reference}')],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                    'font-family:${KolaFonts.mono}',
              },
              [Component.text('${sale.currency} ${(sale.totalMinor / 100).toStringAsFixed(2)}')],
            ),
          ]),
          button(
            attributes: {
              'type': 'button',
              'style': 'background:transparent;border:none;'
                  'color:${KolaVar.muted};cursor:pointer;display:flex;padding:4px',
            },
            events: {'click': (_) => setState(() => _lastSale = null)},
            [kolaIcon(Icons.close, size: 16)],
          ),
        ],
      );

  // ── Shared states ──────────────────────────────────────────────────

  Component _emptyState(String message) => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:${KolaSpace.lg};'
              'text-align:center;font-size:${KolaType.small};'
              'color:${KolaVar.muted}',
        },
        [Component.text(message)],
      );

  Component _skeleton() => div(
        [
          for (var i = 0; i < 2; i++)
            div(
              attributes: {
                'style': 'height:160px;border-radius:${KolaRadius.md};'
                    'border:1px solid ${KolaVar.border};'
                    'background:${KolaVar.card};margin-bottom:${KolaSpace.md}',
              },
              const [],
            ),
        ],
      );

  Component _errorState() => div(
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
            [Component.text('Could not load your catalog')],
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
            events: {'click': (_) => _load()},
            [Component.text('Try again')],
          ),
        ],
      );
}
