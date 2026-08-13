// catalog_page.dart — Kola Catalog.dc.html.
//
// The first commerce screen. Migration 029 built the tables, migration
// 028 locked the flags because there was nothing behind them, and this
// is the thing that earns them back.
//
// ── THE EXPORT'S STATE, AND WHERE EACH PIECE WENT ────────────────────
//
//   searchQuery, cat            → _query, _archetype     (filters)
//   selected{}                  → _selected              (bulk actions)
//   loadingCatalog              → _phase
//   showEmptyCatalog            → NOT a toggle here. In the export it is
//                                 a preview switch so a designer can see
//                                 the empty state; in production nobody
//                                 chooses whether they have products.
//                                 It is `_products.isEmpty`.
//   showEditor, editorTab       → _editing, _tab
//   edit* + variantRows         → the _Draft below
//   showDetail, detailKey       → a Link to /catalog/:id, not a modal.
//                                 Product Detail is its own export and
//                                 its own screen; making it a modal here
//                                 would mean it could not be linked to,
//                                 and a bot citing a product needs a URL.
//   descListening               → dropped. Voice capture is
//                                 commerce.voice_capture, locked, R2.
//
// ── STATUS IS DERIVED, AND THE DESIGN'S THRESHOLD IS A DEFAULT ───────
//
// The export computes `stock <= 5 ? 'low'`. Five is hardcoded there
// because a static export has nowhere to put a setting. The editor's own
// editLowStock field, and products.low_stock_threshold, are where it
// really lives — so this reads the product's own threshold and 5 remains
// the default a new product gets.
//
// ── NULL STOCK IS NOT ZERO ───────────────────────────────────────────
//
// The export gets this exactly right and it is worth restating: a
// service has null stock and renders "Booked, not stocked", NOT "Out of
// stock". Showing a tailor as sold out turns away work they can take.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/error_text.dart';
import '../services/money.dart';
import '../theme.dart';

class CatalogPage extends StatefulComponent {
  const CatalogPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

enum _Phase { loading, error, ready }

/// The editor's working copy.
///
/// Everything is a String because these are text inputs, and the moment
/// they are typed parsing them eagerly means a half-typed "45" is a real
/// price of ₦45. Parsing happens once, on save.
class _Draft {
  _Draft();

  _Draft.from(Product p, List<ProductVariant> variants) {
    id = p.id;
    name = p.name;
    description = p.description ?? '';
    archetype = p.archetype;
    sku = p.sku ?? '';
    tag = p.tag ?? '';
    currency = p.priceCurrency;
    price = p.priceMinor == null ? '' : Money.toInput(p.priceMinor!, p.priceCurrency);
    cost = p.costMinor == null ? '' : Money.toInput(p.costMinor!, p.priceCurrency);
    priceUnit = p.priceUnit ?? '';
    stock = p.stock?.toString() ?? '';
    lowStock = p.lowStockThreshold.toString();
    rows = [
      for (final v in variants)
        (
          label: v.label,
          stock: v.stock?.toString() ?? '',
          price: v.priceMinor == null
              ? ''
              : Money.toInput(v.priceMinor!, p.priceCurrency),
        ),
    ];
  }

  int? id;
  String name = '';
  String description = '';
  String archetype = 'packaged';
  String sku = '';
  String tag = '';
  String currency = 'NGN';
  String price = '';
  String cost = '';
  String priceUnit = '';
  String stock = '';
  String lowStock = '5';
  List<({String label, String stock, String price})> rows = [];
}

class _CatalogPageState extends State<CatalogPage> {
  _Phase _phase = _Phase.loading;
  String? _error;

  List<Product> _products = const [];
  Map<int, int> _variantCounts = const {};

  String _query = '';
  String _archetype = 'all';
  Set<int> _selected = {};

  _Draft? _editing;
  String _tab = 'details';
  bool _saving = false;
  String? _editorError;

  static const _archetypeLabels = <String, String>{
    'packaged': 'Packaged goods',
    'variants': 'Variants',
    'services': 'Service',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      final products = await component.client.product.listProducts(
        component.accessToken,
        component.workspaceId,
        // Explicit, because SERVERPOD DROPS DEFAULTS WHEN IT GENERATES
        // THE CLIENT. The endpoint declares `bool includeArchived =
        // false`; the generated signature is `required bool
        // includeArchived`. Same for archetype, lowStockThreshold,
        // clearPrice and clearStock on the other methods here — all of
        // which are already passed explicitly.
        //
        // The value is false because the catalog is a working list, not
        // an archive.
        includeArchived: false,
      );
      if (!mounted) return;

      // Variant counts, for the "· 3 variants" suffix. Fetched only for
      // products whose archetype actually has them — a shop of 40
      // packaged goods should not pay 40 round trips for a suffix none
      // of them will show.
      final counts = <int, int>{};
      for (final p in products.where((p) => p.archetype == 'variants')) {
        if (p.id == null) continue;
        try {
          final vs = await component.client.product.listVariants(
            component.accessToken,
            component.workspaceId,
            p.id!,
          );
          counts[p.id!] = vs.length;
        } catch (_) {
          // A missing count is a missing suffix, not a broken page.
        }
      }

      if (!mounted) return;
      setState(() {
        _products = products;
        _variantCounts = counts;
        _phase = _Phase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorText.of(e);
        _phase = _Phase.error;
      });
    }
  }

  Future<void> _save() async {
    final draft = _editing;
    if (draft == null) return;

    if (draft.name.trim().isEmpty) {
      setState(() => _editorError = 'Give the product a name.');
      return;
    }

    // Parsed HERE, once, and only what the owner actually filled in.
    // An empty price box stays null — "on request" — rather than
    // becoming free. See Money.parse.
    final priceMinor = Money.parse(draft.price, draft.currency);
    final costMinor = Money.parse(draft.cost, draft.currency);
    final stock = draft.stock.trim().isEmpty
        ? null
        : int.tryParse(draft.stock.trim());
    if (draft.stock.trim().isNotEmpty && stock == null) {
      setState(() => _editorError = 'Stock has to be a whole number.');
      return;
    }
    if (draft.price.trim().isNotEmpty && priceMinor == null) {
      setState(() => _editorError = "That price doesn't look like a number.");
      return;
    }

    setState(() {
      _saving = true;
      _editorError = null;
    });

    try {
      final Product saved;
      if (draft.id == null) {
        saved = await component.client.product.createProduct(
          component.accessToken,
          component.workspaceId,
          draft.name.trim(),
          description: _orNull(draft.description),
          archetype: draft.archetype,
          sku: _orNull(draft.sku),
          tag: _orNull(draft.tag),
          priceMinor: priceMinor,
          priceCurrency: draft.currency,
          priceUnit: _orNull(draft.priceUnit),
          costMinor: costMinor,
          stock: stock,
          lowStockThreshold: int.tryParse(draft.lowStock.trim()) ?? 5,
        );
      } else {
        saved = await component.client.product.updateProduct(
          component.accessToken,
          component.workspaceId,
          draft.id!,
          name: draft.name.trim(),
          description: draft.description,
          archetype: draft.archetype,
          sku: draft.sku,
          tag: draft.tag,
          priceMinor: priceMinor,
          // The endpoint treats null as "leave alone", so emptying the
          // box needs its own signal — otherwise a price could be set
          // but never unset, and a shop that stops publishing a price
          // would be stuck advertising the old one.
          clearPrice: draft.price.trim().isEmpty,
          priceCurrency: draft.currency,
          priceUnit: draft.priceUnit,
          costMinor: costMinor,
          stock: stock,
          clearStock: draft.stock.trim().isEmpty,
          lowStockThreshold: int.tryParse(draft.lowStock.trim()) ?? 5,
        );
      }

      if (saved.id != null && draft.archetype == 'variants') {
        final rows = draft.rows.where((r) => r.label.trim().isNotEmpty).toList();
        await component.client.product.replaceVariants(
          component.accessToken,
          component.workspaceId,
          saved.id!,
          [for (final r in rows) r.label.trim()],
          [for (final r in rows) int.tryParse(r.stock.trim())],
          [for (final r in rows) Money.parse(r.price, draft.currency)],
        );
      }

      if (!mounted) return;
      setState(() {
        _editing = null;
        _saving = false;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editorError = ErrorText.of(e);
      });
    }
  }

  Future<void> _archiveSelected() async {
    final ids = _selected.toList();
    setState(() => _selected = {});
    for (final id in ids) {
      try {
        await component.client.product.archiveProduct(
          component.accessToken,
          component.workspaceId,
          id,
        );
      } catch (_) {
        // Reported by the reload below rather than one alert per row.
      }
    }
    await _load();
  }

  Future<void> _openEditor(Product? p) async {
    if (p == null) {
      setState(() {
        _editing = _Draft();
        _tab = 'details';
        _editorError = null;
      });
      return;
    }
    var variants = const <ProductVariant>[];
    if (p.archetype == 'variants' && p.id != null) {
      try {
        variants = await component.client.product.listVariants(
          component.accessToken,
          component.workspaceId,
          p.id!,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _editing = _Draft.from(p, variants);
      _tab = 'details';
      _editorError = null;
    });
  }

  String? _orNull(String v) => v.trim().isEmpty ? null : v.trim();

  // ── Derived ─────────────────────────────────────────────────────────

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    return [
      for (final p in _products)
        if ((_archetype == 'all' || p.archetype == _archetype) &&
            (q.isEmpty || p.name.toLowerCase().contains(q)))
          p,
    ];
  }

  /// The export's status ladder, with the product's own threshold in
  /// place of its hardcoded 5. Null stock is its own state.
  ({String label, KolaTone tone}) _status(Product p) {
    final stock = p.stock;
    if (stock == null) {
      return (label: 'Booked, not stocked', tone: KolaTone.info);
    }
    if (stock == 0) return (label: 'Out of stock', tone: KolaTone.negative);
    if (stock <= p.lowStockThreshold) {
      return (label: 'Low stock', tone: KolaTone.caution);
    }
    return (label: 'In stock', tone: KolaTone.positive);
  }

  String _priceLabel(Product p) => p.priceMinor == null
      ? 'By quote'
      : '${Money.format(p.priceMinor!, p.priceCurrency)}${p.priceUnit ?? ''}';

  String _stockLabel(Product p) =>
      p.stock == null ? '—' : (p.stock == 0 ? '0' : '${p.stock} left');

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) => div(
        attributes: {
          'style': 'padding:${KolaSpace.lg};max-width:1180px;margin:0 auto;'
              'width:100%;box-sizing:border-box',
        },
        [
          _header(),
          if (_phase == _Phase.loading) _skeleton(),
          if (_phase == _Phase.error) _errorCard(),
          if (_phase == _Phase.ready) ...[
            if (_products.isEmpty) _empty() else ..._populated(),
          ],
          if (_editing != null) _editor(_editing!),
        ],
      );

  Component _header() => div(
        attributes: {
          'style': 'display:flex;align-items:flex-start;gap:12px;'
              'flex-wrap:wrap;margin-bottom:${KolaSpace.md}',
        },
        [
          div(
            attributes: {'style': 'flex:1;min-width:220px'},
            [
              div(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};'
                      'font-size:${KolaType.h2};font-weight:700;'
                      'color:${KolaVar.text};margin-bottom:4px',
                },
                [Component.text('Catalog')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.body};color:${KolaVar.muted}',
                },
                [
                  Component.text(
                    'What you sell. kola quotes prices and checks stock from '
                    'this, instead of passing every question to you.',
                  ),
                ],
              ),
            ],
          ),
          button(
            attributes: {
              'type': 'button',
              'class': 'kola-pressable',
              'style': 'flex:none;padding:11px 20px;'
                  'border-radius:${KolaRadius.pill};border:none;'
                  'background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                  'font-family:inherit;font-size:${KolaType.small};'
                  'font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => _openEditor(null)},
            [Component.text('New product')],
          ),
        ],
      );

  List<Component> _populated() {
    final counts = <String, int>{'all': _products.length};
    for (final key in _archetypeLabels.keys) {
      counts[key] = _products.where((p) => p.archetype == key).length;
    }
    final items = _filtered;

    return [
      // Search + filters
      div(
        attributes: {
          'style': 'display:flex;gap:10px;flex-wrap:wrap;align-items:center;'
              'margin-bottom:14px',
        },
        [
          input<String>(
            type: InputType.text,
            value: _query,
            onInput: (v) => setState(() => _query = v),
            attributes: {
              'placeholder': 'Search products',
              'aria-label': 'Search products',
              'style': 'flex:1;min-width:200px;padding:10px 14px;'
                  'border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.bg};color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.small}',
            },
          ),
        ],
      ),
      div(
        attributes: {
          'style': 'display:flex;gap:8px;flex-wrap:wrap;margin-bottom:14px',
        },
        [
          _filterChip('all', 'All (${counts['all']})'),
          for (final e in _archetypeLabels.entries)
            _filterChip(e.key, '${e.value} (${counts[e.key]})'),
        ],
      ),

      if (_selected.isNotEmpty) _bulkBar(),

      if (items.isEmpty)
        div(
          attributes: {
            'style': 'border:1px dashed ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};padding:32px;'
                'text-align:center;font-size:${KolaType.body};'
                'color:${KolaVar.muted}',
          },
          [Component.text('Nothing matches that.')],
        )
      else
        div(
          attributes: {
            'style': 'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};overflow:hidden',
          },
          [
            for (var i = 0; i < items.length; i++) _row(items[i], i),
          ],
        ),
    ];
  }

  Component _filterChip(String id, String label) {
    final active = _archetype == id;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:8px 14px;border-radius:${KolaRadius.pill};'
            'cursor:pointer;font-family:inherit;font-size:${KolaType.tiny};'
            'font-weight:600;'
            'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.pill : 'transparent'};'
            'color:${active ? KolaVar.text : KolaVar.muted}',
      },
      events: {'click': (_) => setState(() => _archetype = id)},
      [Component.text(label)],
    );
  }

  Component _bulkBar() => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:12px;flex-wrap:wrap;'
              'padding:10px 14px;margin-bottom:12px;'
              'border-radius:${KolaRadius.md};background:${KolaVar.pill}',
        },
        [
          div(
            attributes: {
              'style': 'flex:1;font-size:${KolaType.small};'
                  'color:${KolaVar.text};font-weight:600',
            },
            [Component.text('${_selected.length} selected')],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'padding:8px 14px;border-radius:${KolaRadius.pill};'
                  'border:1px solid ${KolaVar.border};background:transparent;'
                  'color:${KolaVar.text};font-family:inherit;'
                  'font-size:${KolaType.tiny};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => setState(() => _selected = {})},
            [Component.text('Clear')],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'padding:8px 14px;border-radius:${KolaRadius.pill};'
                  'border:1px solid ${KolaVar.danger};background:transparent;'
                  'color:${KolaVar.danger};font-family:inherit;'
                  'font-size:${KolaType.tiny};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => _archiveSelected()},
            // "Archive", not "Delete" — and the word is accurate. The
            // row stops appearing in the catalog and past orders keep
            // resolving. Calling it Delete would promise something the
            // server deliberately does not do.
            [Component.text('Archive')],
          ),
        ],
      );

  Component _row(Product p, int index) {
    final status = _status(p);
    final id = p.id;
    final selected = id != null && _selected.contains(id);
    final variants = id == null ? 0 : (_variantCounts[id] ?? 0);

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:12px;'
            'padding:12px 16px;flex-wrap:wrap;'
            '${index == 0 ? '' : 'border-top:1px solid ${KolaVar.border};'}'
            'background:${selected ? KolaVar.pill : 'transparent'}',
      },
      [
        // A button with role="checkbox" rather than an <input
        // type=checkbox>. Jaspr's `input` is generic over its value
        // type, every other use in this codebase is input<String>, and
        // there is no checkbox anywhere to confirm what T and onInput
        // look like for one. Screen readers treat this identically
        // given the role and aria-checked, and it needs no API I have
        // not already used on this page.
        button(
          attributes: {
            'type': 'button',
            'role': 'checkbox',
            'aria-checked': selected ? 'true' : 'false',
            'aria-label': 'Select ${p.name}',
            'style': 'flex:none;width:18px;height:18px;padding:0;'
                'cursor:pointer;border-radius:4px;display:flex;'
                'align-items:center;justify-content:center;'
                'font-size:11px;font-weight:700;line-height:1;'
                'border:1px solid '
                '${selected ? KolaVar.accent : KolaVar.border};'
                'background:${selected ? KolaVar.accent : 'transparent'};'
                'color:${KolaVar.accentText}',
          },
          events: {
            'click': (_) {
              if (id == null) return;
              setState(() {
                final next = {..._selected};
                if (next.contains(id)) {
                  next.remove(id);
                } else {
                  next.add(id);
                }
                _selected = next;
              });
            },
          },
          [Component.text(selected ? '✓' : '')],
        ),
        div(
          attributes: {'style': 'flex:1;min-width:160px'},
          [
            id == null
                ? div(
                    attributes: {
                      'style': 'font-size:${KolaType.body};font-weight:600;'
                          'color:${KolaVar.text}',
                    },
                    [Component.text(p.name)],
                  )
                : Link(
                    to: '/catalog/$id',
                    attributes: {
                      'style': 'font-size:${KolaType.body};font-weight:600;'
                          'color:${KolaVar.text};text-decoration:none',
                    },
                    children: [Component.text(p.name)],
                  ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
              },
              [
                Component.text(
                  '${_archetypeLabels[p.archetype] ?? p.archetype}'
                  '${variants > 0 ? ' · $variants variants' : ''}',
                ),
              ],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'flex:none;min-width:110px;font-size:${KolaType.small};'
                'color:${KolaVar.text}',
          },
          [Component.text(_priceLabel(p))],
        ),
        div(
          attributes: {
            'style': 'flex:none;min-width:80px;font-size:${KolaType.small};'
                'color:${KolaVar.muted}',
          },
          [Component.text(_stockLabel(p))],
        ),
        div(
          attributes: {'style': 'flex:none;${status.tone.badgeCss}'},
          [Component.text(status.label)],
        ),
        button(
          attributes: {
            'type': 'button',
            'style': 'flex:none;padding:7px 13px;'
                'border-radius:${KolaRadius.pill};'
                'border:1px solid ${KolaVar.border};background:transparent;'
                'color:${KolaVar.text};font-family:inherit;'
                'font-size:${KolaType.tiny};font-weight:600;cursor:pointer',
          },
          events: {'click': (_) => _openEditor(p)},
          [Component.text('Edit')],
        ),
      ],
    );
  }

  // ── States ──────────────────────────────────────────────────────────

  Component _skeleton() => div(
        attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
        [
          for (var i = 0; i < 6; i++)
            div(
              attributes: {
                'class': 'kola-skel',
                'style': 'height:56px;border-radius:${KolaRadius.md}',
              },
              [],
            ),
        ],
      );

  Component _errorCard() => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.danger};'
              'border-radius:${KolaRadius.lg};padding:${KolaSpace.md}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.bodyLg};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text("Couldn't load your catalog")],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.5;margin-bottom:12px',
            },
            [Component.text(_error ?? '')],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'padding:10px 18px;border-radius:${KolaRadius.pill};'
                  'border:none;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.small};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => _load()},
            [Component.text('Try again')],
          ),
        ],
      );

  Component _empty() => div(
        attributes: {
          'style': 'text-align:center;padding:48px 20px;'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.xl}',
        },
        [
          div(
            attributes: {'style': 'color:${KolaVar.muted};margin-bottom:14px'},
            [kolaIcon(Icons.catalog, size: 30, strokeWidth: 1.6)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:8px',
            },
            [Component.text('Your catalog is empty')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.55;max-width:44ch;margin:0 auto 18px',
            },
            [
              Component.text(
                'Add one thing you sell — its name, price and how many you '
                'have. From then on kola can answer "how much?" and "is it '
                'in stock?" without waking you up.',
              ),
            ],
          ),
          button(
            attributes: {
              'type': 'button',
              'class': 'kola-pressable',
              'style': 'padding:11px 20px;border-radius:${KolaRadius.pill};'
                  'border:none;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.small};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => _openEditor(null)},
            [Component.text('Add your first product')],
          ),
        ],
      );

  // ── Editor ──────────────────────────────────────────────────────────

  Component _editor(_Draft d) => div(
        attributes: {
          'role': 'dialog',
          'aria-modal': 'true',
          'aria-label': d.id == null ? 'New product' : 'Edit ${d.name}',
          'style': 'position:fixed;inset:0;z-index:300;'
              'background:rgba(0,0,0,0.55);display:flex;'
              'align-items:center;justify-content:center;padding:20px',
        },
        events: {'click': (_) => setState(() => _editing = null)},
        [
          div(
            attributes: {
              'style': 'width:100%;max-width:560px;max-height:86vh;'
                  'overflow-y:auto;background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.xl};padding:${KolaSpace.md}',
            },
            events: {'click': (e) => e.stopPropagation()},
            [
              div(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};'
                      'font-size:${KolaType.title};font-weight:700;'
                      'color:${KolaVar.text};margin-bottom:12px',
                },
                [
                  Component.text(
                    d.id == null ? 'New product' : 'Edit ${d.name}',
                  ),
                ],
              ),
              div(
                attributes: {
                  'style': 'display:flex;gap:6px;flex-wrap:wrap;'
                      'margin-bottom:16px',
                },
                [
                  _tabChip('details', 'Details'),
                  _tabChip('media', 'Photos & video'),
                  _tabChip('pricing', 'Pricing & stock'),
                  if (d.archetype == 'variants') _tabChip('variants', 'Variants'),
                ],
              ),
              if (_tab == 'details') ..._editorDetails(d),
              if (_tab == 'media') _editorMedia(),
              if (_tab == 'pricing') ..._editorPricing(d),
              if (_tab == 'variants') ..._editorVariants(d),
              if (_editorError != null)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.small};'
                        'color:${KolaVar.danger};margin:12px 0;line-height:1.5',
                  },
                  [Component.text(_editorError!)],
                ),
              div(
                attributes: {
                  'style': 'display:flex;gap:10px;margin-top:16px',
                },
                [
                  button(
                    attributes: {
                      'type': 'button',
                      'style': 'padding:11px 18px;'
                          'border-radius:${KolaRadius.md};'
                          'border:1px solid ${KolaVar.border};'
                          'background:transparent;color:${KolaVar.text};'
                          'font-family:inherit;font-size:${KolaType.small};'
                          'font-weight:600;cursor:pointer',
                    },
                    events: {'click': (_) => setState(() => _editing = null)},
                    [Component.text('Cancel')],
                  ),
                  button(
                    attributes: {
                      'type': 'button',
                      if (_saving) 'disabled': 'disabled',
                      'style': 'flex:1;padding:11px 18px;'
                          'border-radius:${KolaRadius.md};border:none;'
                          'background:${KolaVar.accentFill};'
                          'color:${KolaVar.accentText};font-family:inherit;'
                          'font-size:${KolaType.small};font-weight:600;'
                          'cursor:pointer;opacity:${_saving ? '0.65' : '1'}',
                    },
                    events: {
                      'click': (_) {
                        if (!_saving) _save();
                      },
                    },
                    [Component.text(_saving ? 'Saving…' : 'Save product')],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  Component _tabChip(String id, String label) {
    final active = _tab == id;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:8px 13px;border-radius:${KolaRadius.pill};'
            'border:none;cursor:pointer;font-family:inherit;'
            'font-size:${KolaType.tiny};font-weight:600;'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.muted}',
      },
      events: {'click': (_) => setState(() => _tab = id)},
      [Component.text(label)],
    );
  }

  List<Component> _editorDetails(_Draft d) => [
        _field('Name', d.name, (v) => setState(() => d.name = v),
            placeholder: 'e.g. Red Ankara fabric'),
        _label('What a customer would want to know'),
        textarea(
          attributes: {
            'rows': '3',
            'aria-label': 'Description',
            'placeholder': 'Fabric, sizing, how long it lasts — anything they '
                'usually ask about',
            'style': _inputCss,
          },
          onInput: (v) => d.description = v,
          [Component.text(d.description)],
        ),
        _label('Type'),
        div(
          attributes: {
            'style': 'display:flex;gap:8px;flex-wrap:wrap;margin-bottom:14px',
          },
          [
            for (final e in const [
              ('packaged', 'Packaged goods'),
              ('variants', 'Sizes & variants'),
              ('services', 'Service'),
            ])
              button(
                attributes: {
                  'type': 'button',
                  'aria-pressed': d.archetype == e.$1 ? 'true' : 'false',
                  'style': 'padding:9px 15px;'
                      'border-radius:${KolaRadius.pill};cursor:pointer;'
                      'font-family:inherit;font-size:${KolaType.tiny};'
                      'font-weight:600;'
                      'border:1px solid '
                      '${d.archetype == e.$1 ? KolaVar.accent : KolaVar.border};'
                      'background:'
                      '${d.archetype == e.$1 ? KolaVar.pill : 'transparent'};'
                      'color:'
                      '${d.archetype == e.$1 ? KolaVar.text : KolaVar.muted}',
                },
                events: {
                  'click': (_) => setState(() {
                        d.archetype = e.$1;
                        // Leaving the Variants tab open on a product
                        // that no longer has variants would show a
                        // panel that cannot save.
                        if (e.$1 != 'variants' && _tab == 'variants') {
                          _tab = 'details';
                        }
                      }),
                },
                [Component.text(e.$2)],
              ),
          ],
        ),
        _field('SKU (optional)', d.sku, (v) => setState(() => d.sku = v),
            placeholder: 'Your own code for it'),
        _field('Tag (optional)', d.tag, (v) => setState(() => d.tag = v),
            placeholder: 'How you group it — "fabric", "ready-made"'),
      ];

  /// Photos are designed and not built.
  ///
  /// migration 029 created product_media so this needs no schema change
  /// later, but nothing uploads yet — that needs Supabase Storage, a
  /// signed-upload path and an image pipeline. A file picker that
  /// accepted a photo and dropped it would be worse than saying so.
  Component _editorMedia() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:20px;'
              'background:${KolaVar.bg};text-align:center',
        },
        [
          div(
            attributes: {'style': 'color:${KolaVar.muted};margin-bottom:8px'},
            [kolaIcon(Icons.catalog, size: 22)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('Photos are coming next')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.55;max-width:44ch;margin:0 auto',
            },
            [
              Component.text(
                'Everything else about this product saves now. A good '
                'description does most of the work in the meantime — kola '
                'quotes from that, and customers ask for photos far less '
                'than you would expect.',
              ),
            ],
          ),
        ],
      );

  List<Component> _editorPricing(_Draft d) {
    final price = Money.parse(d.price, d.currency);
    final cost = Money.parse(d.cost, d.currency);
    // The export shows margin only when BOTH are present and non-zero.
    // A margin against a zero price is 100% and means nothing.
    final showMargin = price != null && cost != null && price > 0;

    return [
      _field('Price', d.price, (v) => setState(() => d.price = v),
          placeholder: 'Leave blank if it is by quote'),
      div(
        attributes: {
          'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
              'margin:-8px 0 14px;line-height:1.5',
        },
        [
          Component.text(
            'An empty price means "ask us" — kola will not invent one, and '
            'it will never quote zero.',
          ),
        ],
      ),
      _field('Unit (optional)', d.priceUnit,
          (v) => setState(() => d.priceUnit = v),
          placeholder: 'e.g. /yd, /kg, /hour'),
      _field('What it costs you (optional)', d.cost,
          (v) => setState(() => d.cost = v),
          placeholder: 'Never shown to customers'),
      if (showMargin)
        div(
          attributes: {
            'style': 'padding:10px 12px;border-radius:${KolaRadius.md};'
                'background:${KolaVar.successBg};'
                'color:${KolaVar.successBright};'
                'font-size:${KolaType.small};font-weight:600;'
                'margin-bottom:14px',
          },
          [
            Component.text(
              'You make ${Money.format(price - cost, d.currency)} on this '
              '(${(((price - cost) * 100) ~/ price)}%)',
            ),
          ],
        ),
      _field('How many you have', d.stock, (v) => setState(() => d.stock = v),
          placeholder: 'Leave blank if this is not something you stock'),
      _field('Tell me when it drops below', d.lowStock,
          (v) => setState(() => d.lowStock = v),
          placeholder: '5'),
    ];
  }

  List<Component> _editorVariants(_Draft d) => [
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.55;margin-bottom:12px',
          },
          [
            Component.text(
              'Sizes, colours or options. Each keeps its own stock, so kola '
              'can say the XL is gone without saying the whole thing is.',
            ),
          ],
        ),
        for (var i = 0; i < d.rows.length; i++) _variantRow(d, i),
        button(
          attributes: {
            'type': 'button',
            'style': 'padding:9px 15px;border-radius:${KolaRadius.pill};'
                'border:1px dashed ${KolaVar.border};background:transparent;'
                'color:${KolaVar.text};font-family:inherit;'
                'font-size:${KolaType.tiny};font-weight:600;cursor:pointer',
          },
          events: {
            'click': (_) => setState(
                  () => d.rows = [...d.rows, (label: '', stock: '', price: '')],
                ),
          },
          [Component.text('Add a variant')],
        ),
      ];

  Component _variantRow(_Draft d, int i) {
    final row = d.rows[i];
    return div(
      attributes: {
        'style': 'display:flex;gap:8px;align-items:center;margin-bottom:8px;'
            'flex-wrap:wrap',
      },
      [
        input<String>(
          type: InputType.text,
          value: row.label,
          onInput: (v) => setState(() {
            d.rows = [...d.rows]..[i] = (label: v, stock: row.stock, price: row.price);
          }),
          attributes: {
            'placeholder': 'Small / XL / Red',
            'aria-label': 'Variant name',
            'style': '$_inputCss;flex:2;min-width:120px;margin:0',
          },
        ),
        input<String>(
          type: InputType.text,
          value: row.stock,
          onInput: (v) => setState(() {
            d.rows = [...d.rows]..[i] = (label: row.label, stock: v, price: row.price);
          }),
          attributes: {
            'placeholder': 'Stock',
            'aria-label': 'Variant stock',
            'style': '$_inputCss;flex:1;min-width:80px;margin:0',
          },
        ),
        input<String>(
          type: InputType.text,
          value: row.price,
          onInput: (v) => setState(() {
            d.rows = [...d.rows]..[i] = (label: row.label, stock: row.stock, price: v);
          }),
          attributes: {
            'placeholder': 'Same price',
            'aria-label': 'Variant price, blank to use the product price',
            'style': '$_inputCss;flex:1;min-width:100px;margin:0',
          },
        ),
        button(
          attributes: {
            'type': 'button',
            'aria-label': 'Remove variant',
            'style': 'flex:none;padding:8px 12px;'
                'border-radius:${KolaRadius.pill};border:none;'
                'background:transparent;color:${KolaVar.danger};'
                'font-family:inherit;font-size:${KolaType.tiny};'
                'font-weight:600;cursor:pointer',
          },
          events: {
            'click': (_) => setState(() {
                  d.rows = [...d.rows]..removeAt(i);
                }),
          },
          [Component.text('Remove')],
        ),
      ],
    );
  }

  // ── Shared ──────────────────────────────────────────────────────────

  static const _inputCss = 'width:100%;box-sizing:border-box;padding:11px 13px;'
      'border-radius:8px;border:1px solid var(--kola-border);'
      'background:var(--kola-bg);color:var(--kola-text);'
      'font-family:inherit;font-size:14px;margin-bottom:14px';

  Component _label(String text) => div(
        attributes: {
          'style': 'font-size:${KolaType.tiny};font-weight:600;'
              'color:${KolaVar.mutedStrong};margin-bottom:6px',
        },
        [Component.text(text)],
      );

  Component _field(
    String label,
    String value,
    void Function(String) onChanged, {
    String placeholder = '',
  }) =>
      div([
        _label(label),
        input<String>(
          type: InputType.text,
          value: value,
          onInput: onChanged,
          attributes: {
            'placeholder': placeholder,
            'aria-label': label,
            'style': _inputCss,
          },
        ),
      ]);
}
