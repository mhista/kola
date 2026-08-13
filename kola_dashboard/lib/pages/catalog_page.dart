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

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/error_text.dart';
import '../services/file_intake.dart';
import '../services/dom_files.dart';
import '../services/media_upload.dart';
import '../services/money.dart';
import '../services/product_csv.dart';
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

  /// Live uploads, keyed by a per-file id. Value is 0.0–1.0.
  ///
  /// Kept on the STATE and not the draft, because it describes work in
  /// flight rather than the product being edited — closing the editor
  /// mid-upload should not leave a stale bar in the draft.
  Map<int, ({String name, double progress, String? error})> _uploads = {};
  int _uploadSeq = 0;

  /// Cached signed credentials. One round trip per editor session
  /// rather than one per photo — MediaUpload.send takes the auth string
  /// precisely so a batch can share it.
  String? _uploadAuth;

  /// Bulk import. Null when the sheet is closed.
  ({int done, int total, String label, List<String> problems})? _import;

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
      // that there is an id to attach them to. See _Draft.pendingMedia.
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

  // ── Bulk import ─────────────────────────────────────────────────────

  /// Reads a spreadsheet and creates every row as a product.
  ///
  /// Sequential, and deliberately so: fifty parallel createProduct calls
  /// would race on the SKU uniqueness check and hammer the server, and
  /// the owner would get a progress bar that means nothing. One at a
  /// time gives a real count and a real ETA.
  ///
  /// A row that fails does NOT stop the import. Its reason is collected
  /// and shown at the end — an import that abandons row 12 of 50 and
  /// leaves the owner guessing which ones landed is worse than one that
  /// finishes and reports.
  Future<void> _importCsv(web.File file) async {
    setState(() {
      _import = (done: 0, total: 0, label: 'Reading the file…', problems: []);
    });

    final String text;
    try {
      text = await FileIntake.readText(file);
    } catch (e) {
      setState(() => _import = (
            done: 0,
            total: 0,
            label: "Couldn't read that file",
            problems: [ErrorText.of(e)],
          ));
      return;
    }

    final parsed = ProductCsv.parse(text);
    if (parsed.rows.isEmpty) {
      setState(() => _import = (
            done: 0,
            total: 0,
            label: 'Nothing to import',
            problems: [
              if (parsed.skipped.isEmpty)
                'That file has no rows kola could read. It needs a header '
                    'row with at least a "name" column.'
              else
                'Every row was missing a product name.',
            ],
          ));
      return;
    }

    final problems = <String>[
      for (final s in parsed.skipped) 'Row ${s.row}: ${s.reason}',
      if (parsed.unknownHeaders.isNotEmpty)
        'Ignored columns kola does not use: '
            '${parsed.unknownHeaders.join(', ')}',
    ];

    var done = 0;
    setState(() => _import = (
          done: 0,
          total: parsed.rows.length,
          label: 'Adding your products…',
          problems: problems,
        ));

    for (final row in parsed.rows) {
      try {
        final priceMinor =
            row.price == null ? null : Money.parse(row.price!, 'NGN');
        final costMinor =
            row.cost == null ? null : Money.parse(row.cost!, 'NGN');

        final product = await component.client.product.createProduct(
          component.accessToken,
          component.workspaceId,
          row.name,
          description: row.description,
          archetype: row.archetype ?? 'packaged',
          sku: row.sku,
          category: row.category,
          priceMinor: priceMinor,
          priceUnit: row.unit,
          costMinor: costMinor,
          stock: row.stock == null ? null : int.tryParse(row.stock!),
          lowStockThreshold:
              row.lowStock == null ? 5 : (int.tryParse(row.lowStock!) ?? 5),
        );

        // The image is fetched SERVER-SIDE from the url in the sheet —
        // see ProductEndpoint.importMediaFromUrl. A failure here is
        // reported but never fails the product: the row is worth having
        // without its picture.
        if (row.imageUrl != null && product.id != null) {
          try {
            final media = await component.client.product.importMediaFromUrl(
              component.accessToken,
              component.workspaceId,
              product.id!,
              row.imageUrl!,
            );
            if (media == null) {
              problems.add('Row ${row.rowNumber}: saved, but the photo '
                  "link didn't load");
            }
          } catch (_) {
            problems.add('Row ${row.rowNumber}: saved, but the photo '
                "link didn't load");
          }
        }
      } catch (e) {
        problems.add('Row ${row.rowNumber} (${row.name}): ${ErrorText.of(e)}');
      }

      done++;
      if (!mounted) return;
      setState(() => _import = (
            done: done,
            total: parsed.rows.length,
            label: 'Adding your products…',
            problems: problems,
          ));
    }

    if (!mounted) return;
    setState(() => _import = (
          done: done,
          total: parsed.rows.length,
          label: 'Done',
          problems: problems,
        ));
    await _load();
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
    final draft = _editing;
    if (draft == null || files.isEmpty) return;

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
        // otherwise — see _Draft.pendingMedia.
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
    final draft = _editing;
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
  Future<void> _attachPendingMedia(int productId, _Draft draft) async {
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
        _uploads = {};
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

    var media = const <ProductMedia>[];
    if (p.id != null) {
      try {
        media = await component.client.product.listMedia(
          component.accessToken,
          component.workspaceId,
          p.id!,
        );
      } catch (_) {
        // No photos shown rather than no editor.
      }
    }

    if (!mounted) return;
    setState(() {
      _editing = _Draft.from(p, variants)..media = [...media];
      _tab = 'details';
      _editorError = null;
      // A fresh editor session gets fresh upload state — a bar left
      // over from the last product would be nonsense here.
      _uploads = {};
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
          if (_import != null) _importSheet(_import!),
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
          // Import sits beside New product, not buried in a menu. An
          // owner arriving with an existing product list wants it first,
          // and adding fifty things one at a time is the reason people
          // never finish setting up.
          label(
            htmlFor: 'kola-csv-import',
            attributes: {
              'class': 'kola-pressable',
              'style': 'flex:none;padding:11px 18px;cursor:pointer;'
                  'border-radius:${KolaRadius.pill};'
                  'border:1px solid ${KolaVar.border};'
                  'font-size:${KolaType.small};font-weight:600;'
                  'color:${KolaVar.text}',
            },
            [
              Component.text('Import a list'),
              input(
                type: InputType.file,
                attributes: {
                  'id': 'kola-csv-import',
                  // .txt included because plenty of exports arrive with
                  // the wrong extension, and FileIntake sniffs content
                  // anyway. Refusing on extension alone would turn away
                  // a perfectly readable file.
                  'accept': '.csv,text/csv,text/plain',
                  'style': 'display:none',
                },
                events: {
                  'change': (e) {
                    final target = e.target;
                    if (target == null) return;
                    final files = filesFrom(target as JSObject);
                    if (files.isNotEmpty) _importCsv(files.first);
                    resetFileInput(target);
                  },
                },
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
  List<Component> _editorMedia(_Draft d) {
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
                    'put first is the one kola sends.'
                : 'The first photo is the one kola sends when a customer '
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
                url: saved[i].thumbnailUrl ?? saved[i].url,
                isMain: i == 0,
                onRemove: () => _removePhoto(saved[i]),
              ),
            for (var i = 0; i < pending.length; i++)
              _photoTile(
                url: pending[i].thumbnailUrl ?? pending[i].url,
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

  /// Progress and outcome for a bulk import.
  ///
  /// Stays on screen when it finishes rather than vanishing, because the
  /// problems list is the point: "47 of 50 added" with the three
  /// failures named is the answer an owner needs, and a toast that
  /// disappears is not.
  Component _importSheet(
    ({int done, int total, String label, List<String> problems}) st,
  ) {
    final finished = st.label == 'Done' || st.total == 0;
    final pct = st.total == 0 ? 0.0 : st.done / st.total;

    return div(
      attributes: {
        'role': 'dialog',
        'aria-modal': 'true',
        'aria-label': 'Importing products',
        'style': 'position:fixed;inset:0;z-index:320;'
            'background:rgba(0,0,0,0.55);display:flex;'
            'align-items:center;justify-content:center;padding:20px',
      },
      [
        div(
          attributes: {
            'style': 'width:100%;max-width:520px;max-height:80vh;'
                'overflow-y:auto;background:${KolaVar.card};'
                'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.xl};padding:${KolaSpace.md}',
          },
          [
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.display};'
                    'font-size:${KolaType.title};font-weight:700;'
                    'color:${KolaVar.text};margin-bottom:6px',
              },
              [
                Component.text(
                  finished
                      ? (st.total == 0
                          ? st.label
                          : 'Added ${st.done} of ${st.total}')
                      : st.label,
                ),
              ],
            ),
            if (!finished)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};'
                      'color:${KolaVar.muted};margin-bottom:12px',
                },
                [Component.text('${st.done} of ${st.total}')],
              ),
            if (st.total > 0)
              div(
                attributes: {
                  'style': 'height:6px;border-radius:3px;margin-bottom:14px;'
                      'background:${KolaVar.border};overflow:hidden',
                },
                [
                  div(
                    attributes: {
                      'style': 'height:100%;width:${(pct * 100).round()}%;'
                          'background:${KolaVar.accent};'
                          'transition:width 160ms linear',
                    },
                    [],
                  ),
                ],
              ),
            if (!finished)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};'
                      'color:${KolaVar.muted};line-height:1.5',
                },
                [
                  Component.text(
                    'Leave this open until it finishes. Photos are fetched '
                    'as each product is added, so a long list takes a '
                    'minute.',
                  ),
                ],
              ),
            if (st.problems.isNotEmpty) ...[
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};font-weight:700;'
                      'color:${KolaVar.mutedStrong};margin:14px 0 6px',
                },
                [Component.text('Worth a look')],
              ),
              div(
                attributes: {
                  'style': 'border:1px solid ${KolaVar.border};'
                      'border-radius:${KolaRadius.md};padding:10px 12px;'
                      'max-height:220px;overflow-y:auto;'
                      'background:${KolaVar.bg}',
                },
                [
                  for (final p in st.problems)
                    div(
                      attributes: {
                        'style': 'font-size:${KolaType.tiny};'
                            'color:${KolaVar.muted};line-height:1.55;'
                            'padding:3px 0',
                      },
                      [Component.text(p)],
                    ),
                ],
              ),
            ],
            if (finished)
              button(
                attributes: {
                  'type': 'button',
                  'style': 'margin-top:16px;padding:11px 20px;'
                      'border-radius:${KolaRadius.md};border:none;'
                      'background:${KolaVar.accentFill};'
                      'color:${KolaVar.accentText};font-family:inherit;'
                      'font-size:${KolaType.small};font-weight:600;'
                      'cursor:pointer',
                },
                events: {'click': (_) => setState(() => _import = null)},
                [Component.text('Done')],
              ),
          ],
        ),
      ],
    );
  }
}
