// product_detail_page.dart — Kola Product Detail.dc.html.
//
// Reached from the Catalog list. That link existed before this page did
// — I shipped `/catalog/:id` as a Link with no route behind it, which is
// precisely the defect the rest of this work removed. Caught by the same
// sweep that found the other six.
//
// ── THE SELLER / CUSTOMER TOGGLE IS THE POINT OF THIS SCREEN ─────────
//
// The export's state is `{ side, productKey }`, and `side` flips the
// whole page between what the owner sees and what a customer is told.
// That is not a preview gimmick. kola answers customers FROM this
// record, so the honest question an owner has is "what will it actually
// say about this?" — and the answer differs from their own view in ways
// worth seeing:
//
//   • cost and margin are seller-only, and must never leak
//   • the status wording is deliberately softer:
//
//       stock state   seller view            customer view
//       ───────────   ────────────────────   ──────────────────
//       plenty        In stock               In stock
//       low           Low stock              Only a few left
//       zero          Out of stock           Out of stock
//       null          Booked, not stocked    Made to order
//
// "Made to order" and "Only a few left" are the export's own words, and
// they are better than the seller equivalents for the person reading
// them. A customer told "Booked, not stocked" learns nothing; a customer
// told "Made to order" knows they can still buy.
//
// ── WHAT THE EXPORT SHOWS THAT THE SERVER CANNOT ─────────────────────
//
//   supplier   'Lagos Textile Market — Stall 24, Balogun'. There is no
//              supplier column (migration 029) and no suppliers table.
//              Omitted rather than faked; recorded as design debt.
//   history    'Stock and price last updated' / 'Added to catalog'.
//              There is no product audit log. updatedAt and createdAt
//              are real, so a two-line history IS shown — built from
//              those two facts and nothing invented around them.
//   photos     product_media exists, no upload pipeline. Omitted.
//
// The export also derives cost as `price * 0.55`, which is a demo
// figure. costMinor is real here, and margin renders only when the owner
// has actually entered a cost.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/product_editor.dart';
import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/error_text.dart';
import '../services/money.dart';
import '../theme.dart';

class ProductDetailPage extends StatefulComponent {
  const ProductDetailPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.productId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final int productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

enum _Phase { loading, error, ready, missing }

class _ProductDetailPageState extends State<ProductDetailPage> {
  _Phase _phase = _Phase.loading;
  String? _error;

  Product? _product;
  List<ProductVariant> _variants = const [];
  List<ProductMedia> _media = const [];

  /// 'seller' | 'customer'. The export's `side`.
  String _side = 'seller';

  /// The shared editor, mounted over this page.
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

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      final product = await component.client.product.getProduct(
        component.accessToken,
        component.workspaceId,
        component.productId,
      );
      if (!mounted) return;

      if (product == null) {
        // getProduct returns null for both "archived/deleted" and
        // "belongs to another workspace" — deliberately the same answer,
        // so an id probe cannot confirm someone else's rows. The page
        // says the same thing for both.
        setState(() => _phase = _Phase.missing);
        return;
      }

      var variants = const <ProductVariant>[];
      if (product.archetype == 'variants') {
        try {
          variants = await component.client.product.listVariants(
            component.accessToken,
            component.workspaceId,
            component.productId,
          );
        } catch (_) {
          // A missing variant list is a thinner page, not a broken one.
        }
      }

      // Photos. The design leads this page with them, and the page
      // shipped without fetching them at all — a product with four
      // images on ImageKit looked like a product with none.
      var media = const <ProductMedia>[];
      try {
        media = await component.client.product.listMedia(
          component.accessToken,
          component.workspaceId,
          component.productId,
        );
      } catch (_) {
        // A thinner page, not a broken one.
      }

      if (!mounted) return;
      setState(() {
        _product = product;
        _variants = variants;
        _media = media;
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

  // ── Derived ─────────────────────────────────────────────────────────

  ({String label, KolaTone tone}) _sellerStatus(Product p) {
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

  /// The customer-facing wording. See this file's header.
  ({String label, KolaTone tone}) _customerStatus(Product p) {
    final stock = p.stock;
    if (stock == null) return (label: 'Made to order', tone: KolaTone.info);
    if (stock == 0) return (label: 'Out of stock', tone: KolaTone.negative);
    if (stock <= p.lowStockThreshold) {
      // Deliberately does NOT print the number. "Only 2 left" is a
      // pressure tactic, and it is also a promise the shop has to keep
      // if two people read it at once.
      return (label: 'Only a few left', tone: KolaTone.caution);
    }
    return (label: 'In stock', tone: KolaTone.positive);
  }

  String _priceLabel(Product p) => p.priceMinor == null
      ? 'By quote'
      : '${Money.format(p.priceMinor!, p.priceCurrency)}${p.priceUnit ?? ''}';

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) => div(
        attributes: {
          'style': 'padding:${KolaSpace.lg};max-width:900px;margin:0 auto;'
              'width:100%;box-sizing:border-box',
        },
        [
          Link(
            to: '/catalog',
            attributes: {
              'style': 'display:inline-flex;align-items:center;gap:6px;'
                  'font-size:${KolaType.small};font-weight:600;'
                  'color:${KolaVar.accent};text-decoration:none;'
                  'padding:6px 10px;border-radius:${KolaRadius.md};'
                  'margin-bottom:10px',
            },
            children: [
              kolaIcon(Icons.arrowRight,
                  size: 14, extraStyle: 'transform:rotate(180deg)'),
              Component.text('Catalog'),
            ],
          ),
          if (_editorOpen && _product != null)
            ProductEditor(
              client: component.client,
              accessToken: component.accessToken,
              workspaceId: component.workspaceId,
              product: _product,
              onSaved: (_) {
                setState(() => _editorOpen = false);
                // Re-reads rather than patching the local copy: a save
                // can change more than was edited, and the server's
                // version is the true one.
                _load();
              },
              onClose: () => setState(() => _editorOpen = false),
            ),
          switch (_phase) {
            _Phase.loading => _skeleton(),
            _Phase.error => _errorCard(),
            _Phase.missing => _missing(),
            _Phase.ready => _body(_product!),
          },
        ],
      );

  Component _body(Product p) => div([
        // Side switch
        div(
          attributes: {
            'style': 'display:flex;gap:6px;padding:4px;width:fit-content;'
                'border-radius:${KolaRadius.pill};background:${KolaVar.pill};'
                'margin-bottom:16px',
          },
          [
            _sideChip('seller', 'Your view'),
            _sideChip('customer', 'What a customer sees'),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'line-height:1.5;margin-bottom:16px;max-width:60ch',
          },
          [
            Component.text(
              _side == 'seller'
                  ? 'Everything you have recorded. Cost and margin are '
                      'yours alone — kola never repeats them to a customer.'
                  : 'This is what kola will tell someone who asks about '
                      'this product. Nothing about what it cost you appears '
                      'here.',
            ),
          ],
        ),
        if (_side == 'seller') ..._seller(p) else ..._customer(p),
      ]);

  Component _sideChip(String id, String label) {
    final active = _side == id;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:8px 14px;border-radius:${KolaRadius.pill};'
            'border:none;cursor:pointer;font-family:inherit;'
            'font-size:${KolaType.tiny};font-weight:600;'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.muted}',
      },
      events: {'click': (_) => setState(() => _side = id)},
      [Component.text(label)],
    );
  }

  // ── Seller side ─────────────────────────────────────────────────────

  List<Component> _seller(Product p) {
    final status = _sellerStatus(p);
    final price = p.priceMinor;
    final cost = p.costMinor;
    final showMargin = price != null && cost != null && price > 0;

    return [
      if (_media.isNotEmpty) _gallery(),
      _titleBlock(p, status),
      div(
        attributes: {
          'style': 'display:grid;gap:12px;margin-bottom:18px;'
              'grid-template-columns:repeat(auto-fit,minmax(150px,1fr))',
        },
        [
          _stat('Price', _priceLabel(p)),
          _stat('You make',
              showMargin ? Money.format(price - cost, p.priceCurrency) : '—',
              note: showMargin
                  ? '${((price - cost) * 100) ~/ price}% of the price'
                  : 'Add what it costs you and this fills in'),
          _stat('Stock', p.stock == null ? '—' : '${p.stock} units',
              note: p.stock == null ? 'Not something you stock' : null),
        ],
      ),
      if (p.description != null && p.description!.trim().isNotEmpty)
        _section('Description', p.description!),
      if (p.sku != null) _section('SKU', p.sku!),
      if (p.category != null) _section('Category', p.category!),
      if (_variants.isNotEmpty) _variantTable(p),
      _history(p),
      div(
        attributes: {'style': 'margin-top:18px'},
        [
          // Edits HERE, not "edit in catalog". Sending someone back to a
          // list to change the thing they are already looking at is the
          // complaint that moved the editor into its own component —
          // this page and the catalog now mount the same one.
          button(
            attributes: {
              'type': 'button',
              'class': 'kola-pressable',
              'style': 'padding:11px 20px;border-radius:${KolaRadius.pill};'
                  'border:none;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.small};font-weight:600;'
                  'cursor:pointer',
            },
            events: {'click': (_) => setState(() => _editorOpen = true)},
            [Component.text('Edit')],
          ),
        ],
      ),
    ];
  }

  // ── Customer side ───────────────────────────────────────────────────

  List<Component> _customer(Product p) {
    final status = _customerStatus(p);
    return [
      div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:${KolaSpace.md}',
        },
        [
          if (_media.isNotEmpty) _gallery(),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.title};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text(p.name)],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h2};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:10px',
            },
            [Component.text(_priceLabel(p))],
          ),
          div(
            attributes: {'style': status.tone.badgeCss},
            [Component.text(status.label)],
          ),
          if (p.description != null && p.description!.trim().isNotEmpty)
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                    'line-height:1.6;margin-top:14px;max-width:62ch',
              },
              [Component.text(p.description!)],
            )
          else
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                    'line-height:1.55;margin-top:14px;max-width:62ch;'
                    'padding:12px;border-radius:${KolaRadius.md};'
                    'border:1px dashed ${KolaVar.border}',
              },
              // Addressed to the OWNER, inside the customer view, because
              // this is the one place the absence is obvious. A customer
              // never sees this page; the owner does, and this is the
              // moment they will understand why a description matters.
              [
                Component.text(
                  'You have not described this yet, so kola has only the '
                  'name and price to work with. A sentence or two here is '
                  'what lets it answer "what is it like?" instead of '
                  'passing the question to you.',
                ),
              ],
            ),
          if (_variants.isNotEmpty)
            div(
              attributes: {'style': 'margin-top:16px'},
              [
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};font-weight:700;'
                        'color:${KolaVar.mutedStrong};margin-bottom:8px',
                  },
                  [Component.text('Available')],
                ),
                div(
                  attributes: {
                    'style': 'display:flex;flex-wrap:wrap;gap:8px',
                  },
                  [
                    for (final v in _variants)
                      div(
                        attributes: {
                          'style': 'padding:7px 13px;'
                              'border-radius:${KolaRadius.pill};'
                              'font-size:${KolaType.tiny};font-weight:600;'
                              'border:1px solid ${KolaVar.border};'
                              // A variant with no stock is shown, faded,
                              // rather than hidden. Someone asking for the
                              // XL should be told it is gone, not left to
                              // assume it was never offered.
                              'opacity:${(v.stock ?? 1) == 0 ? '0.45' : '1'};'
                              'color:${KolaVar.text}',
                        },
                        [
                          Component.text(
                            (v.stock ?? 1) == 0
                                ? '${v.label} — sold out'
                                : v.label,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ];
  }

  // ── Pieces ──────────────────────────────────────────────────────────

  Component _titleBlock(Product p, ({String label, KolaTone tone}) status) =>
      div(
        attributes: {'style': 'margin-bottom:16px'},
        [
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h2};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text(p.name)],
          ),
          div(
            attributes: {
              'style': 'display:flex;align-items:center;gap:10px;'
                  'flex-wrap:wrap',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};'
                      'color:${KolaVar.muted}',
                },
                [
                  Component.text(
                    _archetypeLabels[p.archetype] ?? p.archetype,
                  ),
                ],
              ),
              div(
                attributes: {'style': status.tone.badgeCss},
                [Component.text(status.label)],
              ),
            ],
          ),
        ],
      );

  Component _stat(String label, String value, {String? note}) => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:14px 16px',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                  'margin-bottom:6px',
            },
            [Component.text(label)],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.title};font-weight:700;'
                  'color:${KolaVar.text}',
            },
            [Component.text(value)],
          ),
          if (note != null)
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                    'line-height:1.45;margin-top:6px',
              },
              [Component.text(note)],
            ),
        ],
      );

  /// A labelled block.
  ///
  /// ── THE HIERARCHY WAS INVERTED ───────────────────────────────────
  ///
  /// The label used to be tiny/muted and the body full-brightness, so
  /// "Category" and "Services" read as one undifferentiated pair and it
  /// was impossible to tell which was the heading. The design does the
  /// opposite: the LABEL is the bright, weighted thing that lets you
  /// scan the page, and the value sits under it in a quieter tone.
  ///
  /// Spacing carries it too — 22px between blocks against 6px inside
  /// one, so a label visibly belongs to the value beneath it rather
  /// than floating between two.
  Component _section(String label, String body) => div(
        attributes: {'style': 'margin-bottom:22px'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:6px;'
                  'letter-spacing:0.01em',
            },
            [Component.text(label)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.6;max-width:62ch',
            },
            [Component.text(body)],
          ),
        ],
      );

  /// The photo strip.
  ///
  /// Main image large, the rest as a row beneath. Uploading and
  /// reordering stay in the editor — this page shows what is there.
  Component _gallery() {
    final main = _media.first;
    final rest = _media.skip(1).toList();

    return div(
      attributes: {'style': 'margin-bottom:18px'},
      [
        div(
          attributes: {
            'style': 'width:100%;max-width:340px;aspect-ratio:1;'
                'border-radius:${KolaRadius.lg};overflow:hidden;'
                'border:1px solid ${KolaVar.border};'
                'background:${KolaVar.pill}',
          },
          [
            img(
              src: main.url,
              alt: '',
              attributes: {
                'style': 'width:100%;height:100%;object-fit:cover;'
                    'display:block',
              },
            ),
          ],
        ),
        if (rest.isNotEmpty)
          div(
            attributes: {
              'style': 'display:flex;gap:8px;margin-top:8px;flex-wrap:wrap',
            },
            [
              for (final m in rest)
                div(
                  attributes: {
                    'style': 'width:64px;height:64px;border-radius:'
                        '${KolaRadius.md};overflow:hidden;'
                        'border:1px solid ${KolaVar.border};'
                        'background:${KolaVar.pill}',
                  },
                  [
                    img(
                      src: m.thumbnailUrl ?? m.url,
                      alt: '',
                      attributes: {
                        'loading': 'lazy',
                        'style': 'width:100%;height:100%;'
                            'object-fit:cover;display:block',
                      },
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  Component _variantTable(Product p) => div(
        attributes: {'style': 'margin-bottom:16px'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:8px',
            },
            [Component.text('Variants')],
          ),
          div(
            attributes: {
              'style': 'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.md};overflow:hidden',
            },
            [
              for (var i = 0; i < _variants.length; i++)
                div(
                  attributes: {
                    'style': 'display:flex;align-items:center;gap:12px;'
                        'padding:11px 14px;'
                        '${i == 0 ? '' : 'border-top:1px solid ${KolaVar.border};'}',
                  },
                  [
                    div(
                      attributes: {
                        'style': 'flex:1;font-size:${KolaType.small};'
                            'color:${KolaVar.text}',
                      },
                      [Component.text(_variants[i].label)],
                    ),
                    div(
                      attributes: {
                        'style': 'flex:none;font-size:${KolaType.small};'
                            'color:${KolaVar.muted}',
                      },
                      [
                        // Null price on a variant means "same as the
                        // product" — see product_variant.spy.yaml. It is
                        // resolved for DISPLAY here, and shown as the
                        // parent's price rather than as a blank, because
                        // "what does the XL cost" has an answer.
                        Component.text(
                          _variants[i].priceMinor != null
                              ? Money.format(
                                  _variants[i].priceMinor!, p.priceCurrency)
                              : (p.priceMinor != null
                                  ? Money.format(
                                      p.priceMinor!, p.priceCurrency)
                                  : 'By quote'),
                        ),
                      ],
                    ),
                    div(
                      attributes: {
                        'style': 'flex:none;min-width:70px;text-align:right;'
                            'font-size:${KolaType.small};'
                            'color:${KolaVar.muted}',
                      },
                      [
                        Component.text(
                          _variants[i].stock == null
                              ? '—'
                              : '${_variants[i].stock} left',
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ],
      );

  /// Two real dates, and nothing invented around them.
  ///
  /// The export shows a richer history ('Stock and price last updated',
  /// 'Added to catalog'). There is no product audit log, so only the two
  /// facts the row actually carries are shown. When a timeline exists
  /// (platform.event_bus, locked) this becomes the real thing.
  Component _history(Product p) => div(
        attributes: {'style': 'margin-bottom:16px'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:8px',
            },
            [Component.text('History')],
          ),
          _historyRow('Last updated', p.updatedAt),
          _historyRow('Added to catalog', p.createdAt),
        ],
      );

  Component _historyRow(String label, DateTime when) => div(
        attributes: {
          'style': 'display:flex;gap:12px;padding:8px 0;'
              'font-size:${KolaType.small}',
        },
        [
          div(
            attributes: {'style': 'flex:1;color:${KolaVar.text}'},
            [Component.text(label)],
          ),
          div(
            attributes: {'style': 'flex:none;color:${KolaVar.muted}'},
            [Component.text(_ago(when))],
          ),
        ],
      );

  /// "3h ago" / "2d ago" / "1w ago", matching the export's own phrasing.
  ///
  /// Relative rather than a date, because "updated 2 hours ago" answers
  /// the question an owner is actually asking — is this current? — and a
  /// timestamp makes them do the subtraction.
  String _ago(DateTime when) {
    final diff = DateTime.now().toUtc().difference(when.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  // ── States ──────────────────────────────────────────────────────────

  Component _skeleton() => div(
        attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
        [
          div(
            attributes: {
              'class': 'kola-skel',
              'style': 'height:40px;width:60%;border-radius:${KolaRadius.md}',
            },
            [],
          ),
          for (var i = 0; i < 3; i++)
            div(
              attributes: {
                'class': 'kola-skel',
                'style': 'height:70px;border-radius:${KolaRadius.md}',
              },
              [],
            ),
        ],
      );

  Component _missing() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:32px;text-align:center',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:8px',
            },
            [Component.text("That product isn't here")],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.55;max-width:46ch;margin:0 auto 16px',
            },
            [
              Component.text(
                'It may have been archived. Archived products keep working '
                'in past orders — they just stop showing in your catalog.',
              ),
            ],
          ),
          Link(
            to: '/catalog',
            attributes: {
              'class': 'kola-pressable',
              'style': 'display:inline-block;padding:11px 20px;'
                  'border-radius:${KolaRadius.pill};'
                  'background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-size:${KolaType.small};'
                  'font-weight:600;text-decoration:none',
            },
            children: [Component.text('Back to catalog')],
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
            [Component.text("Couldn't load this product")],
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
}
