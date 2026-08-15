// product_editor.dart — the one product form.
//
// ── WHY THIS IS A COMPONENT AND NOT PART OF THE CATALOG PAGE ─────────
//
// It lived inside catalog_page.dart, which meant the ONLY way to edit a
// product was to go back to the list — the product detail page could
// offer nothing better than an "Edit in catalog" link that threw the
// owner out of the thing they were looking at.
//
// Editing a record from the page that displays it is the obvious
// expectation, so the form moved here and both pages mount it. There is
// still exactly one editor: one place that decides what a valid product
// is, one place that handles photo uploads, one set of rules. Two
// copies would be two places to disagree.
//
// ── IT OWNS ITS OWN LOADING ──────────────────────────────────────────
//
// Given a product, it fetches that product's variants and photos itself
// rather than making every caller do it first. A caller only has to say
// WHICH product; the editor knows what a product editor needs.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/dom_files.dart';
import '../services/error_text.dart';
import '../services/imagekit_url.dart';
import '../services/media_upload.dart';
import '../services/money.dart';
import '../theme.dart';

class ProductDraft {
  ProductDraft();

  ProductDraft.from(Product p, List<ProductVariant> variants) {
    id = p.id;
    name = p.name;
    description = p.description ?? '';
    archetype = p.archetype;
    sku = p.sku ?? '';
    category = p.category ?? '';
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
  String category = '';
  String currency = 'NGN';
  String price = '';
  String cost = '';
  String priceUnit = '';
  String stock = '';
  String lowStock = '5';
  List<({String label, String stock, String price})> rows = [];

  /// Photos already saved against this product (edit mode).
  List<ProductMedia> media = [];

  /// Photos uploaded to ImageKit during THIS editing session but not yet
  /// attached to a product row.
  ///
  /// Needed because a new product has no id until it is saved, and an
  /// owner should not have to save a half-filled form before they can
  /// add the picture they are looking at. They upload now; the rows are
  /// written the moment createProduct returns an id.
  ///
  /// The tradeoff is orphans: abandoning a new product leaves those
  /// files on the CDN with nothing pointing at them. Accepted knowingly
  /// — a periodic sweep of untagged files is the cleanup, and the
  /// alternative is refusing to let someone add a photo until they have
  /// filled in a form, which is the complaint that started this work.
  List<UploadedMedia> pendingMedia = [];
}

class ProductEditor extends StatefulComponent {
  const ProductEditor({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.onSaved,
    required this.onClose,
    this.product,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  /// Null creates a new product.
  final Product? product;

  /// Fired with the saved product. Callers reload from this rather than
  /// trusting their own stale copy.
  final void Function(Product) onSaved;

  final void Function() onClose;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  ProductDraft _draft = ProductDraft();
  String _tab = 'details';
  bool _saving = false;
  bool _loading = false;
  String? _editorError;

  /// Live uploads, keyed by a per-file id. Value is 0.0-1.0.
  Map<int, ({String name, double progress, String? error})> _uploads = {};
  int _uploadSeq = 0;

  /// Cached signed credentials. One round trip per editing session
  /// rather than one per photo.
  String? _uploadAuth;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches what an existing product's editor needs.
  ///
  /// Variants only for the archetype that has them — a shop of packaged
  /// goods should not pay for a call whose answer is always empty.
  Future<void> _load() async {
    final p = component.product;
    if (p == null || p.id == null) {
      setState(() => _draft = ProductDraft());
      return;
    }

    setState(() => _loading = true);

    var variants = const <ProductVariant>[];
    if (p.archetype == 'variants') {
      try {
        variants = await component.client.product.listVariants(
          component.accessToken,
          component.workspaceId,
          p.id!,
        );
      } catch (_) {}
    }

    var media = const <ProductMedia>[];
    try {
      media = await component.client.product.listMedia(
        component.accessToken,
        component.workspaceId,
        p.id!,
      );
    } catch (_) {
      // No photos shown rather than no editor.
    }

    if (!mounted) return;
    setState(() {
      _draft = ProductDraft.from(p, variants)..media = [...media];
      _loading = false;
    });
  }

  String? _orNull(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _save() async {
    final draft = _draft;
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
          category: _orNull(draft.category),
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
          category: draft.category,
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

      // Photos uploaded before the product existed get their rows now
      // that there is an id to attach them to. See ProductDraft.pendingMedia.
      if (saved.id != null && draft.pendingMedia.isNotEmpty) {
        await _attachPendingMedia(saved.id!, draft);
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
      setState(() => _saving = false);
      component.onSaved(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editorError = ErrorText.of(e);
      });
    }
  }

  // ── Photos ──────────────────────────────────────────────────────────

  Future<String?> _authForUpload() async {
    if (_uploadAuth != null) return _uploadAuth;
    try {
      final auth = await component.client.product.getMediaUploadAuth(
        component.accessToken,
        component.workspaceId,
      );
      _uploadAuth = auth;
      return auth;
    } catch (e) {
      if (mounted) setState(() => _editorError = ErrorText.of(e));
      return null;
    }
  }

  /// Uploads each picked file, reporting progress per file.
  ///
  /// Sequential rather than parallel. Four photos at once on a shared
  /// mobile connection makes all four slow and the progress bars jump
  /// around; one at a time finishes the first one quickly, which is what
  /// makes the wait feel bounded.
  Future<void> _onPhotosPicked(List<web.File> files) async {
    final draft = _draft;
    if (files.isEmpty) return;

    final auth = await _authForUpload();
    if (auth == null) return;

    for (final file in files) {
      final id = _uploadSeq++;
      if (!mounted) return;
      setState(() {
        _uploads = {
          ..._uploads,
          id: (name: file.name, progress: 0, error: null),
        };
      });

      try {
        final uploaded = await MediaUpload.send(
          file: file,
          fileName: file.name,
          auth: auth,
          onProgress: (p) {
            if (!mounted) return;
            setState(() {
              final row = _uploads[id];
              if (row != null) {
                _uploads = {
                  ..._uploads,
                  id: (name: row.name, progress: p, error: null),
                };
              }
            });
          },
        );

        if (!mounted) return;

        // Attached immediately when the product already exists, held
        // otherwise — see ProductDraft.pendingMedia.
        if (draft.id != null) {
          final saved = await component.client.product.addProductMedia(
            component.accessToken,
            component.workspaceId,
            draft.id!,
            uploaded.fileId,
            uploaded.url,
            kind: 'image',
            thumbnailUrl: uploaded.thumbnailUrl,
            width: uploaded.width,
            height: uploaded.height,
          );
          if (!mounted) return;
          setState(() {
            draft.media = [...draft.media, saved];
            _uploads = {..._uploads}..remove(id);
          });
        } else {
          setState(() {
            draft.pendingMedia = [...draft.pendingMedia, uploaded];
            _uploads = {..._uploads}..remove(id);
          });
        }
      } catch (e) {
        if (!mounted) return;
        // The row STAYS, carrying the reason. A failed upload that
        // simply vanishes leaves the owner wondering whether it worked.
        setState(() {
          final row = _uploads[id];
          _uploads = {
            ..._uploads,
            id: (
              name: row?.name ?? file.name,
              progress: 0,
              error: e is UploadException ? e.message : ErrorText.of(e),
            ),
          };
        });
      }
    }
  }

  Future<void> _removePhoto(ProductMedia media) async {
    final draft = _draft;
    if (draft == null || draft.id == null || media.id == null) return;
    setState(() {
      draft.media = [for (final m in draft.media) if (m.id != media.id) m];
    });
    try {
      await component.client.product.deleteProductMedia(
        component.accessToken,
        component.workspaceId,
        draft.id!,
        media.id!,
      );
    } catch (_) {
      // Already removed from view. Reload on next open will correct it
      // if the server disagreed.
    }
  }

  /// Writes pendingMedia against a product that now has an id.
  Future<void> _attachPendingMedia(int productId, ProductDraft draft) async {
    for (final m in draft.pendingMedia) {
      try {
        await component.client.product.addProductMedia(
          component.accessToken,
          component.workspaceId,
          productId,
          m.fileId,
          m.url,
          kind: 'image',
          thumbnailUrl: m.thumbnailUrl,
          width: m.width,
          height: m.height,
        );
      } catch (_) {
        // One photo failing to attach must not fail the product save —
        // the product is the thing the owner was creating.
      }
    }
  }

  @override
  Component build(BuildContext context) {
    if (_loading) {
      return div(
        attributes: {
          'role': 'dialog',
          'aria-modal': 'true',
          'aria-label': 'Loading product',
          'style': 'position:fixed;inset:0;z-index:300;'
              'background:rgba(0,0,0,0.55);display:flex;'
              'align-items:center;justify-content:center;color:#FFF6EE;'
              'font-size:14px',
        },
        [Component.text('Loading…')],
      );
    }
    return _editorShell(_draft);
  }

  Component _editorShell(ProductDraft d) => div(
        attributes: {
          'role': 'dialog',
          'aria-modal': 'true',
          'aria-label': d.id == null ? 'New product' : 'Edit ${d.name}',
          'style': 'position:fixed;inset:0;z-index:300;'
              'background:rgba(0,0,0,0.55);display:flex;'
              'align-items:center;justify-content:center;padding:20px',
        },
        events: {'click': (_) => component.onClose()},
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
              if (_tab == 'media') ..._editorMedia(d),
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
                    events: {'click': (_) => component.onClose()},
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

  List<Component> _editorDetails(ProductDraft d) => [
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
        // "Category", not "Tag". The column was renamed in migration
        // 031 because that is what an owner calls it, and the CSV
        // importer uses the same word in its header.
        _field('Category (optional)', d.category,
            (v) => setState(() => d.category = v),
            placeholder: 'e.g. Dresses, Fabric, Accessories'),
      ];

  /// The Photos & video tab.
  ///
  /// Two ways in, both the design's: choose files, or take one with the
  /// camera. On a phone `capture="environment"` opens the rear camera
  /// directly instead of the gallery — which is the whole point for
  /// someone photographing stock on a market stall.
  ///
  /// Progress is REAL, not a spinner. See media_upload.dart: XHR's
  /// upload.onprogress is the only browser API that reports bytes sent,
  /// which is why the upload does not go through kola_server.
  List<Component> _editorMedia(ProductDraft d) {
    final saved = d.media;
    final pending = d.pendingMedia;
    final total = saved.length + pending.length;

    return [
      div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'line-height:1.55;margin-bottom:14px;max-width:60ch',
        },
        [
          Component.text(
            total == 0
                ? 'A photo is what a customer asks for first. The one you '
                    'put first is the one kolaa sends.'
                : 'The first photo is the one kolaa sends when a customer '
                    'asks to see this.',
          ),
        ],
      ),

      // Pickers
      div(
        attributes: {'style': 'display:flex;gap:10px;flex-wrap:wrap;margin-bottom:14px'},
        [
          _pickerButton(
            text: 'Choose photos',
            inputId: 'kola-photo-pick',
            capture: false,
          ),
          _pickerButton(
            text: 'Take a photo',
            inputId: 'kola-photo-camera',
            capture: true,
          ),
        ],
      ),

      // In-flight uploads
      if (_uploads.isNotEmpty)
        div(
          attributes: {'style': 'margin-bottom:14px'},
          [for (final e in _uploads.entries) _uploadRow(e.key, e.value)],
        ),

      if (total == 0)
        div(
          attributes: {
            'style': 'border:1px dashed ${KolaVar.border};'
                'border-radius:${KolaRadius.md};padding:24px;'
                'text-align:center;font-size:${KolaType.small};'
                'color:${KolaVar.muted};background:${KolaVar.bg}',
          },
          [Component.text('No photos yet.')],
        )
      else
        div(
          attributes: {
            'style': 'display:grid;gap:10px;'
                'grid-template-columns:repeat(auto-fill,minmax(96px,1fr))',
          },
          [
            for (var i = 0; i < saved.length; i++)
              _photoTile(
                // Derived from `url`, NOT the stored thumbnailUrl. That
                // column holds ImageKit's ML-preset URL, which does not
                // resolve on this account — the reason every photo tile
                // here rendered blank. See services/imagekit_url.dart.
                url: ImageKitUrl.thumb(saved[i].url, size: 192),
                isMain: i == 0,
                onRemove: () => _removePhoto(saved[i]),
              ),
            for (var i = 0; i < pending.length; i++)
              _photoTile(
                url: ImageKitUrl.thumb(pending[i].url, size: 192),
                isMain: saved.isEmpty && i == 0,
                // Not yet a row on the server, so there is nothing to
                // delete server-side — it is dropped from the draft and
                // simply never attached.
                onRemove: () => setState(() {
                  d.pendingMedia = [
                    for (var j = 0; j < d.pendingMedia.length; j++)
                      if (j != i) d.pendingMedia[j],
                  ];
                }),
              ),
          ],
        ),

      if (d.id == null && pending.isNotEmpty)
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'line-height:1.5;margin-top:12px',
          },
          [
            Component.text(
              'These attach to the product when you save it.',
            ),
          ],
        ),
    ];
  }

  /// A label styled as a button, wrapping a hidden file input.
  ///
  /// A <label for="..."> is what makes the button open the picker
  /// without any JavaScript — clicking the label activates the input.
  /// The alternative is calling input.click() through interop, which is
  /// more code and one more browser API to be wrong about.
  ///
  /// The parameter is `text`, NOT `label`. Naming it `label` shadowed
  /// jaspr's own `label()` element helper inside this method, so the
  /// call below resolved to the String and failed with "the expression
  /// doesn't evaluate to a function". A local name quietly winning over
  /// a top-level function is a Dart scoping rule, not a jaspr problem.
  Component _pickerButton({
    required String text,
    required String inputId,
    required bool capture,
  }) =>
      label(
        // htmlFor rather than attributes['for'] — jaspr's label() takes
        // it as a named parameter and writes the attribute itself.
        htmlFor: inputId,
        attributes: {
          'class': 'kola-pressable',
          'style': 'display:inline-flex;align-items:center;gap:8px;'
              'padding:10px 16px;border-radius:${KolaRadius.pill};'
              'border:1px solid ${KolaVar.border};cursor:pointer;'
              'font-size:${KolaType.tiny};font-weight:600;'
              'color:${KolaVar.text};background:transparent',
        },
        [
          kolaIcon(capture ? Icons.catalog : Icons.plus, size: 15),
          Component.text(text),
          input(
            type: InputType.file,
            attributes: {
              // id lives in attributes rather than a named param: every
              // other input in this codebase is built that way, and the
              // <label for> pairing needs it on the element either way.
              'id': inputId,
              'accept': 'image/*',
              if (!capture) 'multiple': 'multiple',
              // Opens the rear camera on a phone rather than the photo
              // library. Ignored on desktop, which is correct — there is
              // no camera roll to bypass there.
              if (capture) 'capture': 'environment',
              'style': 'display:none',
            },
            events: {
              'change': (e) {
                final target = e.target;
                if (target == null) return;
                // filesFrom uses DECLARED interop types. The
                // `(e.target as dynamic).files` form that the rest of
                // this app uses analyses clean and throws at runtime —
                // see dom_files.dart.
                final files = filesFrom(target as JSObject);
                if (files.isNotEmpty) _onPhotosPicked(files);
                // Lets the same file be re-picked after a failure.
                resetFileInput(target);
              },
            },
          ),
        ],
      );

  Component _uploadRow(
    int id,
    ({String name, double progress, String? error}) upload,
  ) =>
      div(
        attributes: {
          'style': 'padding:10px 12px;border-radius:${KolaRadius.md};'
              'background:${KolaVar.bg};border:1px solid '
              '${upload.error != null ? KolaVar.danger : KolaVar.border};'
              'margin-bottom:8px',
        },
        [
          div(
            attributes: {
              'style': 'display:flex;gap:10px;align-items:center;'
                  'font-size:${KolaType.tiny};margin-bottom:6px',
            },
            [
              div(
                attributes: {
                  'style': 'flex:1;min-width:0;color:${KolaVar.text};'
                      'overflow:hidden;text-overflow:ellipsis;'
                      'white-space:nowrap',
                },
                [Component.text(upload.name)],
              ),
              div(
                attributes: {
                  'style': 'flex:none;color:${KolaVar.muted}',
                },
                [
                  Component.text(
                    upload.error != null
                        ? 'Failed'
                        : '${(upload.progress * 100).round()}%',
                  ),
                ],
              ),
              if (upload.error != null)
                button(
                  attributes: {
                    'type': 'button',
                    'style': 'flex:none;border:none;background:transparent;'
                        'color:${KolaVar.muted};cursor:pointer;'
                        'font-family:inherit;font-size:${KolaType.tiny}',
                  },
                  events: {
                    'click': (_) =>
                        setState(() => _uploads = {..._uploads}..remove(id)),
                  },
                  [Component.text('Dismiss')],
                ),
            ],
          ),
          if (upload.error == null)
            div(
              attributes: {
                'style': 'height:4px;border-radius:2px;'
                    'background:${KolaVar.border};overflow:hidden',
              },
              [
                div(
                  attributes: {
                    'style': 'height:100%;'
                        'width:${(upload.progress * 100).clamp(0, 100)}%;'
                        'background:${KolaVar.accent};'
                        'transition:width 120ms linear',
                  },
                  [],
                ),
              ],
            )
          else
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};'
                    'line-height:1.45',
              },
              [Component.text(upload.error!)],
            ),
        ],
      );

  Component _photoTile({
    required String url,
    required bool isMain,
    required void Function() onRemove,
  }) =>
      div(
        attributes: {
          'style': 'position:relative;aspect-ratio:1;border-radius:'
              '${KolaRadius.md};overflow:hidden;'
              'border:1px solid ${isMain ? KolaVar.accent : KolaVar.border};'
              'background:${KolaVar.bg}',
        },
        [
          // Signature confirmed against jaspr's docs:
          //   img({required String src, String? alt, MediaLoading? loading,
          //        ..., Map<String,String>? attributes})
          //
          // `loading` is typed as a MediaLoading enum, so it goes through
          // `attributes` instead — one fewer import to be wrong about,
          // and it produces the identical attribute.
          img(
            src: url,
            // Empty alt, deliberately. The tile is decorative here: the
            // product's name is already read out beside it, and a
            // screen reader announcing "Product photo" four times adds
            // noise rather than information.
            alt: '',
            attributes: {
              'loading': 'lazy',
              'style': 'width:100%;height:100%;object-fit:cover;display:block',
            },
          ),
          if (isMain)
            div(
              attributes: {
                'style': 'position:absolute;left:6px;bottom:6px;'
                    'padding:3px 8px;border-radius:${KolaRadius.pill};'
                    'background:${KolaVar.accent};color:${KolaVar.accentText};'
                    'font-size:9.5px;font-weight:700',
              },
              [Component.text('MAIN')],
            ),
          button(
            attributes: {
              'type': 'button',
              'aria-label': 'Remove photo',
              'style': 'position:absolute;top:6px;right:6px;width:22px;'
                  'height:22px;border-radius:50%;border:none;cursor:pointer;'
                  'background:rgba(0,0,0,0.6);color:#FFF6EE;'
                  'font-size:13px;line-height:1;padding:0',
            },
            events: {'click': (_) => onRemove()},
            [Component.text('×')],
          ),
        ],
      );

  List<Component> _editorPricing(ProductDraft d) {
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
            'An empty price means "ask us" — kolaa will not invent one, and '
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

  List<Component> _editorVariants(ProductDraft d) => [
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.55;margin-bottom:12px',
          },
          [
            Component.text(
              'Sizes, colours or options. Each keeps its own stock, so kolaa '
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

  Component _variantRow(ProductDraft d, int i) {
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
