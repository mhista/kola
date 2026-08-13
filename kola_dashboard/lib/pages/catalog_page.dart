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
//   showEditor, editorTab       → ProductEditor, which owns both. The
//                                 form moved to components/
//                                 product_editor.dart so the product
//                                 DETAIL page can mount the same one —
//                                 editing a record from the page showing
//                                 it is the obvious expectation, and
//                                 "Edit in catalog" threw the owner out
//                                 of what they were looking at.
//   edit* + variantRows         → ProductDraft, same file
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
import '../components/product_editor.dart';
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

class _CatalogPageState extends State<CatalogPage> {
  _Phase _phase = _Phase.loading;
  String? _error;

  List<Product> _products = const [];
  Map<int, int> _variantCounts = const {};

  /// Main image per product, for the list rows.
  ///
  /// The design puts a thumbnail FIRST in every row — it is how an owner
  /// recognises a product at a glance, faster than reading the name.
  /// Fetched in one batched call rather than per row.
  Map<int, ProductMedia> _mainImages = const {};

  String _query = '';
  String _archetype = 'all';
  Set<int> _selected = {};

  /// Which product the editor is open on. Null id means "new".
  Product? _editTarget;
  bool _editorOpen = false;

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

      // Thumbnails, batched. One call for the whole page instead of one
      // per row — see ProductEndpoint.listMediaForProducts.
      final images = <int, ProductMedia>{};
      final ids = [for (final p in products) if (p.id != null) p.id!];
      if (ids.isNotEmpty) {
        try {
          final media = await component.client.product.listMediaForProducts(
            component.accessToken,
            component.workspaceId,
            ids,
          );
          for (final m in media) {
            // position 0 is the main image. Only the first wins, so a
            // product with four photos still shows the one the owner
            // chose rather than whichever row arrived last.
            final existing = images[m.productId];
            if (existing == null || m.position < existing.position) {
              images[m.productId] = m;
            }
          }
        } catch (_) {
          // No thumbnails rather than no catalog.
        }
      }

      if (!mounted) return;
      setState(() {
        _products = products;
        _variantCounts = counts;
        _mainImages = images;
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

  /// Archives every selected product.
  ///
  /// Failures are swallowed per row and surfaced by the reload rather
  /// than as one alert per product — an owner archiving twelve things
  /// does not want twelve dialogs.
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
      } catch (_) {}
    }
    await _load();
  }

  /// Opens the shared editor.
  ///
  /// The editor fetches the product's variants and photos itself, so
  /// this only has to say WHICH product — see product_editor.dart.
  void _openEditor(Product? p) {
    setState(() {
      _editTarget = p;
      _editorOpen = true;
    });
  }

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
          if (_editorOpen)
            ProductEditor(
              client: component.client,
              accessToken: component.accessToken,
              workspaceId: component.workspaceId,
              product: _editTarget,
              onSaved: (_) {
                setState(() => _editorOpen = false);
                // Reload rather than patching the local list: a save can
                // change more than was edited (photos attached, SKU
                // normalised), and the server's copy is the true one.
                _load();
              },
              onClose: () => setState(() => _editorOpen = false),
            ),
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
          // Goes to the import SCREEN rather than importing inline.
          // The old inline version skipped straight from "file chosen"
          // to "creating products", with no chance to check that kola
          // read the columns correctly — see catalog_import_page.dart.
          Link(
            to: '/catalog/import',
            attributes: {
              'class': 'kola-pressable',
              'style': 'flex:none;padding:11px 18px;'
                  'border-radius:${KolaRadius.pill};'
                  'border:1px solid ${KolaVar.border};'
                  'font-size:${KolaType.small};font-weight:600;'
                  'color:${KolaVar.text};text-decoration:none',
            },
            children: [Component.text('Import a list')],
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
        // Thumbnail. A placeholder square when there is none, rather
        // than nothing — a ragged left edge where some rows have an
        // image and others do not is harder to scan than a uniform one.
        _rowThumb(id == null ? null : _mainImages[id]),
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

  Component _rowThumb(ProductMedia? media) {
    const box = 'width:42px;height:42px;flex:none;border-radius:8px;'
        'overflow:hidden;background:var(--kola-pill);'
        'border:1px solid var(--kola-border)';

    if (media == null) {
      return div(
        attributes: {
          'style': '$box;display:flex;align-items:center;'
              'justify-content:center;color:var(--kola-muted)',
          'aria-hidden': 'true',
        },
        [kolaIcon(Icons.catalog, size: 16)],
      );
    }
    return div(
      attributes: {'style': box},
      [
        img(
          src: media.thumbnailUrl ?? media.url,
          // Decorative: the product name sits immediately beside it.
          alt: '',
          attributes: {
            'loading': 'lazy',
            'style': 'width:100%;height:100%;object-fit:cover;display:block',
          },
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

}
