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
import '../components/shell/page_help_button.dart';
import '../components/product_editor.dart';
import '../services/error_text.dart';
import '../services/imagekit_url.dart';
import '../services/money.dart';
import '../services/responsive.dart';
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

class _CatalogPageState extends State<CatalogPage>
    with ResponsiveViewport<CatalogPage> {
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

  /// Products we have already asked about. See _hydrate.
  Set<int> _mediaAsked = const {};

  String _query = '';
  String _archetype = 'all';
  Set<int> _selected = {};

  /// Zero-based, over the FILTERED list.
  int _page = 0;

  /// Rows per page.
  ///
  /// Twenty-five is a screen and a half — enough that scanning feels
  /// continuous, few enough that the browser is not laying out five
  /// hundred rows and the page is not firing five hundred image
  /// requests. It also bounds the variant-count round trips in _hydrate.
  ///
  /// When a catalog outgrows client-side filtering, this constant is the
  /// seam: page size moves into the listProducts call alongside a search
  /// term and an archetype, and _filtered stops existing. Until then,
  /// paging what we already hold is honest and searching stays complete.
  static const _pageSize = 25;

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
    initResponsive();
    _load();
  }

  @override
  void dispose() {
    disposeResponsive();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      // The full list, in one call.
      //
      // NOT server-side paged, and that is a considered choice rather
      // than an oversight. Search and the archetype filters run over the
      // WHOLE catalog here; paging on the server would mean they only
      // ever searched the twenty-five rows currently downloaded, which
      // is the kind of search that quietly lies. Moving them server-side
      // is the real fix and it is a larger piece of work (see the note
      // on _pageSize).
      //
      // What DID need fixing is the per-row cost, and that is now scoped
      // to the visible page — see _hydrate.
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

      setState(() {
        _products = products;
        _page = 0;
        // Cleared, not merged. A reload happens after a save or an
        // archive, and a thumbnail cached from before the edit is
        // exactly the stale thing an owner would notice.
        _variantCounts = {};
        _mainImages = {};
        _phase = _Phase.ready;
      });

      await _hydrate();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorText.of(e);
        _phase = _Phase.error;
      });
    }
  }

  /// Fetches the extras for the rows currently on screen: one batched
  /// media call, plus a variant count per variant product.
  ///
  /// ── WHY THIS IS SCOPED TO THE PAGE ──────────────────────────────────
  ///
  /// The variant counts used to run over the ENTIRE catalog, one HTTP
  /// round trip per variant product, just to render a "· 3 variants"
  /// suffix. At fifty products that is eighteen sequential requests
  /// before the list settles; at five hundred it is a page that never
  /// finishes on a Lagos mobile connection. There is no batched variant
  /// endpoint yet, so the honest containment is to only ask about rows
  /// someone is actually looking at — which caps it at the page size no
  /// matter how large the catalog grows.
  ///
  /// Results accumulate across pages, so turning back to page 1 costs
  /// nothing. `_load` clears the caches; paging never does.
  Future<void> _hydrate() async {
    final visible = _visible;
    final ids = [for (final p in visible) if (p.id != null) p.id!];
    if (ids.isEmpty) return;

    final wantMedia = [for (final id in ids) if (!_mediaAsked.contains(id)) id];
    if (wantMedia.isNotEmpty) {
      try {
        final media = await component.client.product.listMediaForProducts(
          component.accessToken,
          component.workspaceId,
          // Comma-separated, NOT a List<int>. Serverpod could not
          // deserialize a List<int> parameter — the type is only
          // registered when something else in the project uses it — so
          // every call 500'd before the endpoint ran. That is why these
          // thumbnails have never appeared. See the endpoint's header.
          wantMedia.join(','),
        );
        final images = {..._mainImages};
        for (final m in media) {
          // position 0 is the main image. Only the first wins, so a
          // product with four photos still shows the one the owner
          // chose rather than whichever row arrived last.
          final existing = images[m.productId];
          if (existing == null || m.position < existing.position) {
            images[m.productId] = m;
          }
        }
        if (!mounted) return;
        setState(() {
          _mainImages = images;
          // Recorded separately from the map, because "asked and it has
          // no photo" and "not asked yet" are different states and the
          // map can only express the second. Without this a photo-less
          // product is re-requested on every page turn.
          _mediaAsked = {..._mediaAsked, ...wantMedia};
        });
      } catch (_) {
        // No thumbnails rather than no catalog.
      }
    }

    for (final p in visible) {
      final id = p.id;
      if (id == null) continue;
      if (p.archetype != 'variants') continue;
      if (_variantCounts.containsKey(id)) continue;
      try {
        final vs = await component.client.product.listVariants(
          component.accessToken,
          component.workspaceId,
          id,
        );
        if (!mounted) return;
        setState(() => _variantCounts = {..._variantCounts, id: vs.length});
      } catch (_) {
        // A missing count is a missing suffix, not a broken page.
      }
    }
  }

  /// Moves to [page] and fetches whatever that page still needs.
  void _goToPage(int page) {
    setState(() => _page = page);
    _hydrate();
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

  int get _pageCount {
    final n = _filtered.length;
    return n == 0 ? 1 : ((n - 1) ~/ _pageSize) + 1;
  }

  /// The rows actually rendered.
  ///
  /// Clamped rather than trusted: filtering while on page 4 can leave
  /// _page past the end, and an unclamped skip would show an empty list
  /// with results sitting one page back.
  List<Product> get _visible {
    final items = _filtered;
    final page = _page.clamp(0, _pageCount - 1);
    return items.skip(page * _pageSize).take(_pageSize).toList();
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
                    'What you sell. kolaa quotes prices and checks stock from '
                    'this, instead of passing every question to you.',
                  ),
                ],
              ),
            ],
          ),
          // Goes to the import SCREEN rather than importing inline.
          // The old inline version skipped straight from "file chosen"
          // to "creating products", with no chance to check that kolaa
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
          const PageHelpButton(
            pageKey: 'catalog',
            body: [
              "What you sell. kolaa quotes prices and checks stock from "
                  "this, instead of passing every question to you — keep "
                  "it accurate and it answers customers accurately.",
              "'Import a list' brings in many products at once from a "
                  "file, with a chance to check the columns before "
                  "anything is created; 'New product' adds one by hand.",
            ],
          ),
        ],
      );

  List<Component> _populated() {
    final counts = <String, int>{'all': _products.length};
    for (final key in _archetypeLabels.keys) {
      counts[key] = _products.where((p) => p.archetype == key).length;
    }
    final items = _filtered;
    final visible = _visible;
    final page = _page.clamp(0, _pageCount - 1);

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
            // Back to page 1 on every keystroke. Narrowing a search
            // while on page 3 and being shown "nothing matches" — when
            // three things do match, on page 1 — is the classic version
            // of this bug.
            onInput: (v) {
              setState(() {
                _query = v;
                _page = 0;
              });
              _hydrate();
            },
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
            for (var i = 0; i < visible.length; i++) _row(visible[i], i),
          ],
        ),

      if (items.isNotEmpty) _pager(items.length, page),
    ];
  }

  /// Page controls.
  ///
  /// Shown even at one page, because the count sentence is the useful
  /// half. "Showing 1–25 of 50" is how an owner confirms the filter did
  /// what they meant; hiding it until a second page exists means the
  /// number only appears once it is too late to be reassuring.
  Component _pager(int total, int page) {
    final from = page * _pageSize + 1;
    final to = ((page + 1) * _pageSize).clamp(0, total);
    final pages = _pageCount;

    Component step(String label, int target, bool enabled) => button(
          attributes: {
            'type': 'button',
            if (!enabled) 'disabled': '',
            'style': 'padding:8px 14px;border-radius:${KolaRadius.pill};'
                'border:1px solid ${KolaVar.border};background:transparent;'
                'font-family:inherit;font-size:${KolaType.tiny};'
                'font-weight:600;'
                'color:${enabled ? KolaVar.text : KolaVar.muted};'
                'cursor:${enabled ? 'pointer' : 'default'};'
                'opacity:${enabled ? '1' : '0.45'}',
          },
          // A statement body, not `enabled ? _goToPage(t) : null` — that
          // is a conditional between a void call and Null, which is the
          // kind of expression the analyser is right to be unhappy
          // about. The guard is belt-and-braces anyway: `disabled`
          // already stops the click.
          events: {
            'click': (_) {
              if (enabled) _goToPage(target);
            },
          },
          [Component.text(label)],
        );

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:10px;flex-wrap:wrap;'
            'margin-top:14px',
      },
      [
        div(
          attributes: {
            'style': 'flex:1;min-width:160px;font-size:${KolaType.tiny};'
                'color:${KolaVar.muted}',
          },
          [
            Component.text(
              total == 1
                  ? 'Showing 1 product'
                  : 'Showing $from–$to of $total products',
            ),
          ],
        ),
        if (pages > 1) ...[
          step('Previous', page - 1, page > 0),
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                  'font-weight:600',
            },
            [Component.text('Page ${page + 1} of $pages')],
          ),
          step('Next', page + 1, page < pages - 1),
        ],
      ],
    );
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
      events: {
        'click': (_) {
          setState(() {
            _archetype = id;
            _page = 0;
          });
          _hydrate();
        },
      },
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

  Component _row(Product p, int index) =>
      isMobile ? _rowMobile(p, index) : _rowDesktop(p, index);

  /// The list row, collapsed to a stacked card.
  ///
  /// The desktop row is one flex line: checkbox, thumbnail, name (min
  /// 160px), price (min 110px), stock (min 80px), a status badge, and an
  /// Edit button — comfortably 600px+ of minimum content before it ever
  /// wraps. `flex-wrap:wrap` let it survive a narrow phone without
  /// overflowing the page, but wrapping six independently-sized flex
  /// items just breaks the row across an unpredictable number of lines
  /// in whatever order they happen to run out of space — checkbox and
  /// thumbnail stranded above a name that wraps mid-word, price and
  /// stock landing on their own half-empty lines. That is what "not
  /// properly aligned" looks like: not a crash, just no coherent shape.
  ///
  /// A normal mobile catalog row is two lines, not one wrapped one:
  /// identity up top (thumbnail + name + category), the numbers below it
  /// (price · stock · status), Edit trailing on its own. Same information,
  /// same fields, laid out for a column instead of a line.
  Component _rowMobile(Product p, int index) {
    final status = _status(p);
    final id = p.id;
    final selected = id != null && _selected.contains(id);
    final variants = id == null ? 0 : (_variantCounts[id] ?? 0);

    return div(
      attributes: {
        'style': 'padding:12px 14px;'
            '${index == 0 ? '' : 'border-top:1px solid ${KolaVar.border};'}'
            'background:${selected ? KolaVar.pill : 'transparent'}',
      },
      [
        div(
          attributes: {'style': 'display:flex;align-items:flex-start;gap:10px'},
          [
            button(
              attributes: {
                'type': 'button',
                'role': 'checkbox',
                'aria-checked': selected ? 'true' : 'false',
                'aria-label': 'Select ${p.name}',
                'style': 'flex:none;width:18px;height:18px;padding:0;'
                    'margin-top:2px;cursor:pointer;border-radius:4px;'
                    'display:flex;align-items:center;justify-content:center;'
                    'font-size:11px;font-weight:700;line-height:1;'
                    'border:1px solid ${selected ? KolaVar.accent : KolaVar.border};'
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
            _rowThumb(id == null ? null : _mainImages[id]),
            div(
              attributes: {'style': 'flex:1;min-width:0'},
              [
                id == null
                    ? div(
                        attributes: {
                          'style': 'font-size:${KolaType.body};font-weight:600;'
                              'color:${KolaVar.text};word-break:break-word',
                        },
                        [Component.text(p.name)],
                      )
                    : Link(
                        to: '/catalog/$id',
                        attributes: {
                          'style': 'font-size:${KolaType.body};font-weight:600;'
                              'color:${KolaVar.text};text-decoration:none;'
                              'word-break:break-word',
                        },
                        children: [Component.text(p.name)],
                      ),
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                        'margin-top:2px',
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
          ],
        ),
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:10px;'
                'flex-wrap:wrap;margin-top:8px;padding-left:28px',
          },
          [
            span(
              attributes: {
                'style': 'font-size:${KolaType.small};font-weight:600;'
                    'color:${KolaVar.text}',
              },
              [Component.text(_priceLabel(p))],
            ),
            span(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
              },
              [Component.text(_stockLabel(p))],
            ),
            div(
              attributes: {'style': status.tone.badgeCss},
              [Component.text(status.label)],
            ),
            button(
              attributes: {
                'type': 'button',
                'style': 'margin-left:auto;padding:6px 13px;'
                    'border-radius:${KolaRadius.pill};'
                    'border:1px solid ${KolaVar.border};background:transparent;'
                    'color:${KolaVar.text};font-family:inherit;'
                    'font-size:${KolaType.tiny};font-weight:600;cursor:pointer',
              },
              events: {'click': (_) => _openEditor(p)},
              [Component.text('Edit')],
            ),
          ],
        ),
      ],
    );
  }

  Component _rowDesktop(Product p, int index) {
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
          // Derived from the ORIGINAL url, not the stored thumbnailUrl.
          // That column holds ImageKit's ML-preset URL, which does not
          // resolve on this account — it is why every row here showed a
          // grey box while the detail page (which renders `url`) showed
          // the photo. See services/imagekit_url.dart.
          src: ImageKitUrl.thumb(media.url),
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
                'have. From then on kolaa can answer "how much?" and "is it '
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
