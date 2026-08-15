// answer_products.dart — the products an answer refers to, as real rows.
//
// ── WHY THE MODEL DOES NOT WRITE THESE ───────────────────────────────
//
// The old Overview answer printed retrieved chunk text, so a product
// arrived as prose the model (or a document) had written:
//
//     - Baby Ankara wrap (Children)
//       Price: ₦3,500
//       In stock.
//
// Every number there is a claim, and nothing on screen distinguished a
// correct one from a stale or invented one. A price that changed
// yesterday still reads as authoritative in a chunk embedded last week.
//
// So WorkspaceAnswer carries product IDS, and this component loads those
// rows and their photos itself. The price, the stock badge and the photo
// are read from the database at the moment of display. The model chooses
// WHICH products are relevant; it never gets to say anything about them
// that reaches the screen as fact.
//
// ── LOADED HERE, NOT BY THE PARENT ───────────────────────────────────
//
// ask_kola already juggles a request, a staged "thinking" caption and a
// streaming timer. Threading a second async fetch through that state
// machine is how the streaming and the product list end up disagreeing
// about which question they belong to.
//
// This component takes ids and owns its own fetch, so a new answer
// replaces it wholesale.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../services/imagekit_url.dart';
import '../services/money.dart';
import '../theme.dart';
import 'shell/icons.dart';
import 'shell/kola_icon.dart';

class AnswerProducts extends StatefulComponent {
  const AnswerProducts({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.productIds,
    this.onChanged,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final List<int> productIds;

  /// Called after an inline edit lands, so the page holding this can
  /// refresh anything else showing the same numbers.
  final void Function()? onChanged;

  @override
  State<AnswerProducts> createState() => _AnswerProductsState();
}

class _AnswerProductsState extends State<AnswerProducts> {
  List<Product> _products = const [];
  Map<int, ProductMedia> _images = const {};
  bool _loading = true;

  /// Ids currently mid-archive, so the row can show it rather than
  /// appearing to do nothing for a second.
  Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateComponent(AnswerProducts old) {
    super.didUpdateComponent(old);
    // A new answer means new ids. Compared by VALUE — the parent rebuilds
    // this on every keystroke of the composer, and identity comparison
    // would refetch the same products each time.
    if (!_sameIds(old.productIds, component.productIds)) _load();
  }

  static bool _sameIds(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _load() async {
    final ids = component.productIds;
    if (ids.isEmpty) {
      setState(() {
        _products = const [];
        _images = const {};
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      // One products call, one media call. Not one pair per id.
      final products = <Product>[];
      for (final id in ids) {
        final p = await component.client.product.getProduct(
          component.accessToken,
          component.workspaceId,
          id,
        );
        // Null means archived or not ours. Skipped silently: the answer
        // text has already been written and quietly showing one fewer
        // card is better than an error about a product the owner did not
        // ask about by name.
        if (p != null) products.add(p);
      }

      final images = <int, ProductMedia>{};
      if (products.isNotEmpty) {
        try {
          final media = await component.client.product.listMediaForProducts(
            component.accessToken,
            component.workspaceId,
            // Comma-separated — see the endpoint's header on why a
            // List<int> parameter could not be deserialized.
            [for (final p in products) if (p.id != null) p.id!].join(','),
          );
          for (final m in media) {
            final existing = images[m.productId];
            if (existing == null || m.position < existing.position) {
              images[m.productId] = m;
            }
          }
        } catch (_) {
          // No thumbnails rather than no cards.
        }
      }

      if (!mounted) return;
      setState(() {
        _products = products;
        _images = images;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // The answer above is still valid without these. Failing quietly
      // is right here specifically because this is a supplement to text
      // that already stands on its own.
      setState(() {
        _products = const [];
        _loading = false;
      });
    }
  }

  Future<void> _archive(Product p) async {
    final id = p.id;
    if (id == null) return;
    setState(() => _busy = {..._busy, id});
    try {
      await component.client.product.archiveProduct(
        component.accessToken,
        component.workspaceId,
        id,
      );
      if (!mounted) return;
      setState(() {
        _products = [for (final x in _products) if (x.id != id) x];
        _busy = {..._busy}..remove(id);
      });
      component.onChanged?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = {..._busy}..remove(id));
    }
  }

  @override
  Component build(BuildContext context) {
    if (component.productIds.isEmpty) return div([]);

    if (_loading) {
      return div(
        attributes: {
          'style': 'display:flex;flex-direction:column;gap:8px;'
              'margin-top:12px',
        },
        [
          for (var i = 0; i < component.productIds.length.clamp(1, 3); i++)
            div(
              attributes: {
                'style': 'height:64px;border-radius:${KolaRadius.md};'
                    'background:${KolaVar.pill};opacity:0.6',
              },
              [],
            ),
        ],
      );
    }

    if (_products.isEmpty) return div([]);

    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;gap:8px;margin-top:12px',
      },
      [for (final p in _products) _row(p)],
    );
  }

  Component _row(Product p) {
    final id = p.id;
    final media = id == null ? null : _images[id];
    final status = _status(p);
    final busy = id != null && _busy.contains(id);

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:12px;padding:10px 12px;'
            'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};background:${KolaVar.card};'
            'opacity:${busy ? '0.5' : '1'}',
      },
      [
        _thumb(media),
        div(
          attributes: {'style': 'flex:1;min-width:0'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};font-weight:600;'
                    'color:${KolaVar.text};overflow:hidden;'
                    'text-overflow:ellipsis;white-space:nowrap',
              },
              [Component.text(p.name)],
            ),
            div(
              attributes: {
                'style': 'display:flex;align-items:center;gap:8px;'
                    'flex-wrap:wrap;margin-top:3px',
              },
              [
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};'
                        'color:${KolaVar.muted}',
                  },
                  // Read from the row, not from the answer text.
                  [Component.text(_priceLabel(p))],
                ),
                div(
                  attributes: {'style': status.tone.badgeCss},
                  [Component.text(status.label)],
                ),
              ],
            ),
          ],
        ),

        // Inline actions. "Open" rather than "Edit": the product detail
        // page is where editing lives now, and a second editor mounted
        // over an answer card would be a third place the same form
        // exists.
        if (id != null) ...[
          Link(
            to: '/catalog/$id',
            attributes: {
              'style': 'flex:none;padding:7px 14px;'
                  'border-radius:${KolaRadius.pill};'
                  'border:1px solid ${KolaVar.border};'
                  'color:${KolaVar.text};text-decoration:none;'
                  'font-size:${KolaType.tiny};font-weight:600',
            },
            children: [Component.text('Open')],
          ),
          button(
            attributes: {
              'type': 'button',
              'aria-label': 'Archive ${p.name}',
              if (busy) 'disabled': '',
              'style': 'flex:none;padding:7px 10px;'
                  'border-radius:${KolaRadius.pill};'
                  'border:1px solid transparent;background:transparent;'
                  'color:${KolaVar.muted};font-family:inherit;'
                  'font-size:${KolaType.tiny};font-weight:600;'
                  'cursor:${busy ? 'default' : 'pointer'}',
            },
            events: {
              'click': (_) {
                if (!busy) _archive(p);
              },
            },
            [Component.text(busy ? 'Archiving…' : 'Archive')],
          ),
        ],
      ],
    );
  }

  Component _thumb(ProductMedia? media) {
    const box = 'width:44px;height:44px;flex:none;border-radius:8px;'
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
          // Derived from `url`. The stored thumbnailUrl is ImageKit's
          // ML-preset URL — see services/imagekit_url.dart.
          src: ImageKitUrl.thumb(media.url),
          alt: '',
          attributes: {
            'loading': 'lazy',
            'style': 'width:100%;height:100%;object-fit:cover;display:block',
          },
        ),
      ],
    );
  }

  String _priceLabel(Product p) => p.priceMinor == null
      ? 'By quote'
      : '${Money.format(p.priceMinor!, p.priceCurrency)}${p.priceUnit ?? ''}';

  /// The same ladder the catalog and the detail page use. Null stock is
  /// its own state, not zero — a tailoring service is not sold out.
  ({String label, KolaTone tone}) _status(Product p) {
    final stock = p.stock;
    if (stock == null) {
      return (label: 'Booked, not stocked', tone: KolaTone.info);
    }
    if (stock == 0) return (label: 'Out of stock', tone: KolaTone.negative);
    if (stock <= p.lowStockThreshold) {
      return (label: '$stock left', tone: KolaTone.caution);
    }
    return (label: 'In stock', tone: KolaTone.positive);
  }
}
