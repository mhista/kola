// product_endpoint.dart — the catalog.
//
// Backs Kola Catalog.dc.html and Kola Product Detail.dc.html.
//
// ── GATED ON commerce.core AND commerce.catalog ──────────────────────
//
// Both, on every method. The nav item that leads here needs both, and a
// surface that is reachable by URL while its nav entry is hidden is not
// a hidden surface.
//
// This matters more than usual right now: migration 028 set both flags
// back to `locked`, because they had been `released` since migration 019
// with nothing behind them. This endpoint is the start of the something.
// The flags flip back to `released` when the Catalog page ships — that
// is one UPDATE, no deployment, per RELEASE_PHASES §0.
//
// So: everything here works, and nobody can reach it yet. That is the
// locked-release model behaving correctly, not an oversight.
//
// ── PRICES ARRIVE IN MINOR UNITS ─────────────────────────────────────
//
// priceMinor is an integer count of the currency's smallest unit. The
// dashboard converts at the edge, where it also knows how many decimal
// places the currency has. Nothing here multiplies or divides by 100 —
// a server that guesses at decimals is how a zero-decimal currency ends
// up priced 100x wrong.

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/product_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/media/imagekit_service.dart';
import 'package:kola_server/kola_logger.dart';

class ProductEndpoint extends Endpoint {
  ProductRepository get _products => getIt<ProductRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();
  ImageKitService get _imagekit => getIt<ImageKitService>();

  /// The export's ARCHETYPES, in storage form.
  static const archetypes = <String>['packaged', 'variants', 'services'];

  // ── Reads ──────────────────────────────────────────────────────────

  Future<List<Product>> listProducts(
    Session session,
    String accessToken,
    int workspaceId, {
    bool includeArchived = false,
  }) async {
    await _require(accessToken, workspaceId);
    return _products.listByWorkspace(
      workspaceId,
      includeArchived: includeArchived,
    );
  }

  Future<Product?> getProduct(
    Session session,
    String accessToken,
    int workspaceId,
    int productId,
  ) async {
    await _require(accessToken, workspaceId);
    return _products.findById(workspaceId, productId);
  }

  /// Variants for one product.
  ///
  /// Scoped through the product rather than queried directly: resolving
  /// the parent first is what proves the caller is entitled to it.
  Future<List<ProductVariant>> listVariants(
    Session session,
    String accessToken,
    int workspaceId,
    int productId,
  ) async {
    await _require(accessToken, workspaceId);

    final product = await _products.findById(workspaceId, productId);
    if (product == null) {
      throw KolaException(message: 'That product no longer exists.');
    }
    return _products.listVariants(productId);
  }

  // ── Writes ─────────────────────────────────────────────────────────

  /// Creates a product.
  ///
  /// Note what is NOT a parameter: workspaceId comes from the argument
  /// and is checked, and status is not settable — a product is created
  /// active, and archiving is its own method with its own meaning.
  Future<Product> createProduct(
    Session session,
    String accessToken,
    int workspaceId,
    String name, {
    String? description,
    String archetype = 'packaged',
    String? sku,
    String? category,
    int? priceMinor,
    String? priceCurrency,
    String? priceUnit,
    int? costMinor,
    int? stock,
    int lowStockThreshold = 5,
  }) async {
    await _require(accessToken, workspaceId);

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw KolaException(message: 'Give the product a name.');
    }
    _checkArchetype(archetype);
    _checkMoney(priceMinor, 'price');
    _checkMoney(costMinor, 'cost');
    if (stock != null && stock < 0) {
      throw KolaException(message: 'Stock cannot be less than zero.');
    }

    final cleanSku = _clean(sku);
    if (cleanSku != null) {
      final clash = await _products.findBySku(workspaceId, cleanSku);
      if (clash != null) {
        // Names the other product. "SKU already exists" sends an owner
        // hunting; this tells them where to look.
        throw KolaException(
          message: 'That SKU is already on "${clash.name}".',
          code: 'duplicate',
        );
      }
    }

    final now = DateTime.now().toUtc();
    final product = await _products.create(
      Product(
        workspaceId: workspaceId,
        name: trimmedName,
        description: _clean(description),
        archetype: archetype,
        sku: cleanSku,
        category: _clean(category),
        priceMinor: priceMinor,
        // Falls back to the workspace's region-appropriate currency
        // rather than hardcoding NGN — see _currencyFor.
        priceCurrency: _clean(priceCurrency) ??
            await _currencyFor(workspaceId),
        priceUnit: _clean(priceUnit),
        costMinor: costMinor,
        stock: stock,
        lowStockThreshold: lowStockThreshold < 0 ? 0 : lowStockThreshold,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );

    Log.info(
      'Product created',
      data: {'workspaceId': workspaceId, 'productId': product.id},
      session: session,
    );
    return product;
  }

  /// Edits a product. Null means "leave it alone".
  ///
  /// Clearing a price or a stock count therefore needs its own signal,
  /// because null already means unchanged — [clearPrice] and
  /// [clearStock] exist for that. Without them there would be no way to
  /// turn a priced product into an on-request one, which is exactly what
  /// happens when a shop stops publishing a price.
  Future<Product> updateProduct(
    Session session,
    String accessToken,
    int workspaceId,
    int productId, {
    String? name,
    String? description,
    String? archetype,
    String? sku,
    String? category,
    int? priceMinor,
    bool clearPrice = false,
    String? priceCurrency,
    String? priceUnit,
    int? costMinor,
    int? stock,
    bool clearStock = false,
    int? lowStockThreshold,
  }) async {
    await _require(accessToken, workspaceId);

    final product = await _products.findById(workspaceId, productId);
    if (product == null) {
      throw KolaException(message: 'That product no longer exists.');
    }

    if (name != null) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw KolaException(message: 'Give the product a name.');
      }
      product.name = trimmed;
    }
    if (description != null) product.description = _clean(description);
    if (archetype != null) {
      _checkArchetype(archetype);
      product.archetype = archetype;
    }
    if (sku != null) {
      final cleanSku = _clean(sku);
      if (cleanSku != null) {
        final clash = await _products.findBySku(
          workspaceId,
          cleanSku,
          excludingProductId: productId,
        );
        if (clash != null) {
          throw KolaException(
            message: 'That SKU is already on "${clash.name}".',
            code: 'duplicate',
          );
        }
      }
      product.sku = cleanSku;
    }
    if (category != null) product.category = _clean(category);

    if (clearPrice) {
      product.priceMinor = null;
    } else if (priceMinor != null) {
      _checkMoney(priceMinor, 'price');
      product.priceMinor = priceMinor;
    }
    if (priceCurrency != null) {
      product.priceCurrency = priceCurrency.trim().toUpperCase();
    }
    if (priceUnit != null) product.priceUnit = _clean(priceUnit);

    if (costMinor != null) {
      _checkMoney(costMinor, 'cost');
      product.costMinor = costMinor;
    }

    if (clearStock) {
      product.stock = null;
    } else if (stock != null) {
      if (stock < 0) {
        throw KolaException(message: 'Stock cannot be less than zero.');
      }
      product.stock = stock;
    }
    if (lowStockThreshold != null) {
      product.lowStockThreshold = lowStockThreshold < 0 ? 0 : lowStockThreshold;
    }

    return _products.update(product);
  }

  /// Archives. Does NOT delete — see product.spy.yaml.
  Future<void> archiveProduct(
    Session session,
    String accessToken,
    int workspaceId,
    int productId,
  ) async {
    await _require(accessToken, workspaceId);
    await _products.archive(workspaceId, productId);
    Log.info(
      'Product archived',
      data: {'workspaceId': workspaceId, 'productId': productId},
      session: session,
    );
  }

  /// Replaces a product's variant set with exactly what is submitted.
  ///
  /// [labels], [stocks] and [priceMinors] are parallel lists rather than
  /// a list of a variant model, because Serverpod cannot take a list of
  /// a custom model as an endpoint parameter. Their lengths must match;
  /// a mismatch is a client bug and is refused rather than zipped to the
  /// shortest, which would silently drop a variant the owner entered.
  Future<List<ProductVariant>> replaceVariants(
    Session session,
    String accessToken,
    int workspaceId,
    int productId,
    List<String> labels,
    List<int?> stocks,
    List<int?> priceMinors,
  ) async {
    await _require(accessToken, workspaceId);

    final product = await _products.findById(workspaceId, productId);
    if (product == null) {
      throw KolaException(message: 'That product no longer exists.');
    }
    if (labels.length != stocks.length || labels.length != priceMinors.length) {
      throw KolaException(
        message: 'Those variants did not save. Please try again.',
      );
    }

    final now = DateTime.now().toUtc();
    final variants = <ProductVariant>[];
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i].trim();
      if (label.isEmpty) {
        throw KolaException(message: 'Every variant needs a name.');
      }
      _checkMoney(priceMinors[i], 'price');
      variants.add(
        ProductVariant(
          productId: productId,
          label: label,
          priceMinor: priceMinors[i],
          stock: stocks[i],
          position: i,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return _products.replaceVariants(productId, variants);
  }

  // ── Private ────────────────────────────────────────────────────────

  /// Workspace access AND both commerce flags. See the file header.
  Future<void> _require(String accessToken, int workspaceId) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
    }

    final core = await _features.isEnabled(FeatureKeys.commerceCore, workspace);
    final catalog =
        await _features.isEnabled(FeatureKeys.commerceCatalog, workspace);
    if (!core || !catalog) {
      throw KolaException(
        message: 'The catalog is not switched on for this workspace yet.',
      );
    }
  }

  /// Empty and whitespace-only become null.
  ///
  /// A SKU of '' is not a SKU, and storing one would make the partial
  /// unique index treat two blank SKUs as a genuine collision.
  String? _clean(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _checkArchetype(String value) {
    if (!archetypes.contains(value)) {
      throw KolaException(message: 'Unknown product type: $value');
    }
  }

  /// Negative money is always an upstream bug. Caught here so it never
  /// reaches the database's own constraint as a raw Postgres error.
  void _checkMoney(int? minor, String what) {
    if (minor != null && minor < 0) {
      throw KolaException(message: 'A $what cannot be negative.');
    }
  }

  /// The workspace's currency.
  ///
  /// Region is ISO-3166 alpha-2 and 'XX' is the international default —
  /// see workspace.spy.yaml. Only NGN is mapped because Nigeria is the
  /// only market with a settled price today; everything else falls back
  /// to USD rather than guessing, and an owner can override per product.
  Future<String> _currencyFor(int workspaceId) async {
    final workspace = await _workspaces.findById(workspaceId);
    return switch (workspace?.region) {
      'NG' => 'NGN',
      _ => 'USD',
    };
  }

  // ── Media ──────────────────────────────────────────────────────────

  /// One-shot credentials so the BROWSER can upload straight to
  /// ImageKit.
  ///
  /// The file never passes through kola. See imagekit_service.dart for
  /// why: a Serverpod parameter is JSON, so proxying a 5MB photo would
  /// mean ~6.7MB of base64 crossing the wire twice with no way to report
  /// progress. The private key stays here and signs; the bytes go
  /// direct.
  ///
  /// Returned as a JSON string rather than a new model, the same shape
  /// getBillingSummary already uses — four short-lived strings do not
  /// earn a .spy.yaml and a codegen round.
  ///
  /// The folder is decided HERE, not by the client. A browser that could
  /// name its own folder could write into another workspace's.
  Future<String> getMediaUploadAuth(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await _require(accessToken, workspaceId);

    if (!_imagekit.isConfigured) {
      throw KolaException(
        message: 'Photo uploads are not switched on yet. Everything else '
            'about a product saves normally.',
      );
    }

    final auth = _imagekit.createUploadAuth();
    return jsonEncode({
      ...auth.toJson(),
      'folder': ImageKitService.folderFor(workspaceId),
      'uploadUrl': 'https://upload.imagekit.io/api/v1/files/upload',
    });
  }

  Future<List<ProductMedia>> listMedia(
    Session session,
    String accessToken,
    int workspaceId,
    int productId,
  ) async {
    await _require(accessToken, workspaceId);

    final product = await _products.findById(workspaceId, productId);
    if (product == null) {
      throw KolaException(message: 'That product no longer exists.');
    }
    return _products.listMedia(productId);
  }

  /// Media for MANY products in one call.
  ///
  /// The catalog list shows a thumbnail per row and the design puts it
  /// first in the row — it is how an owner recognises a product at a
  /// glance, far faster than reading the name. Fetching per product
  /// would be a round trip per row: forty products, forty calls, on a
  /// connection where each costs 400ms.
  ///
  /// Returns a flat list; the caller groups by productId. Serverpod
  /// cannot return Map<int, List<Model>> across the wire, and inventing
  /// a wrapper model for a shape the client regroups in three lines
  /// would be a .spy.yaml and a codegen run for nothing.
  Future<List<ProductMedia>> listMediaForProducts(
    Session session,
    String accessToken,
    int workspaceId,
    List<int> productIds,
  ) async {
    await _require(accessToken, workspaceId);
    if (productIds.isEmpty) return const [];

    // Scoped by re-reading the caller's own products and intersecting.
    // Without this, a crafted id list would return another workspace's
    // media — the ids are supplied by the client and product_media has
    // no workspace_id of its own to filter on.
    final own = await _products.listByWorkspace(workspaceId, includeArchived: true);
    final ownIds = {for (final p in own) if (p.id != null) p.id!};
    final safe = [for (final id in productIds) if (ownIds.contains(id)) id];
    if (safe.isEmpty) return const [];

    final grouped = await _products.listMediaForProducts(safe);
    return [for (final list in grouped.values) ...list];
  }

  /// Records a file the browser has already put on ImageKit.
  ///
  /// Validated even though the values came from ImageKit rather than
  /// being typed by a person: this endpoint is reachable by anyone with
  /// a session, so a crafted call could otherwise point a product's
  /// "photo" at any URL on the internet — including one that changes
  /// after review. The url must sit under the configured ImageKit
  /// endpoint, and nothing else is accepted.
  Future<ProductMedia> addProductMedia(
    Session session,
    String accessToken,
    int workspaceId,
    int productId,
    String imagekitFileId,
    String url, {
    String kind = 'image',
    String? thumbnailUrl,
    int? width,
    int? height,
  }) async {
    await _require(accessToken, workspaceId);

    final product = await _products.findById(workspaceId, productId);
    if (product == null) {
      throw KolaException(message: 'That product no longer exists.');
    }
    if (kind != 'image' && kind != 'video') {
      throw KolaException(message: 'Unknown media type: $kind');
    }

    final endpoint = Env.imagekitUrlEndpoint.trim();
    if (endpoint.isEmpty || !url.startsWith(endpoint)) {
      // Deliberately not echoed back to the caller in detail — a
      // mismatch here means the request did not come from our own
      // uploader, and the useful audience for the specifics is the log.
      Log.warning(
        'Rejected product media URL outside the ImageKit endpoint',
        data: {'workspaceId': workspaceId, 'productId': productId},
      );
      throw KolaException(message: "That file didn't come from kola's uploader.");
    }

    // Appended, not inserted at the front. Position 0 is the main image
    // and a second upload must never silently replace the one the owner
    // chose — reordering is its own explicit action.
    final position = await _products.countMedia(productId);

    final media = await _products.addMedia(
      ProductMedia(
        productId: productId,
        kind: kind,
        imagekitFileId: imagekitFileId,
        url: url,
        thumbnailUrl: thumbnailUrl,
        width: width,
        height: height,
        position: position,
        createdAt: DateTime.now().toUtc(),
      ),
    );

    Log.info(
      'Product media added',
      data: {'workspaceId': workspaceId, 'productId': productId},
      session: session,
    );
    return media;
  }

  /// Removes a photo from the product AND from ImageKit.
  ///
  /// The CDN delete is attempted first but is NOT allowed to block the
  /// row delete — see ImageKitService.deleteFile. An unreachable CDN
  /// must not stop an owner taking a photo off their own product; an
  /// orphaned file is a cost to reconcile, not a reason to refuse.
  Future<void> deleteProductMedia(
    Session session,
    String accessToken,
    int workspaceId,
    int productId,
    int mediaId,
  ) async {
    await _require(accessToken, workspaceId);

    final product = await _products.findById(workspaceId, productId);
    if (product == null) {
      throw KolaException(message: 'That product no longer exists.');
    }

    final media = await _products.findMediaById(mediaId);
    // Belongs-to check. Without it, a valid mediaId from ANOTHER
    // workspace's product would be deleted by a caller who legitimately
    // owns this one.
    if (media == null || media.productId != productId) {
      throw KolaException(message: 'That photo is already gone.');
    }

    await _imagekit.deleteFile(media.imagekitFileId);
    await _products.deleteMedia(mediaId);
  }

  /// Sets the display order. Index 0 becomes the main image.
  Future<void> reorderProductMedia(
    Session session,
    String accessToken,
    int workspaceId,
    int productId,
    List<int> mediaIdsInOrder,
  ) async {
    await _require(accessToken, workspaceId);

    final product = await _products.findById(workspaceId, productId);
    if (product == null) {
      throw KolaException(message: 'That product no longer exists.');
    }
    await _products.reorderMedia(productId, mediaIdsInOrder);
  }

  /// Imports a photo from a PUBLIC url and stores it on ImageKit.
  ///
  /// ── WHY THIS IS SEPARATE FROM addProductMedia ────────────────────
  ///
  /// addProductMedia records a file the BROWSER already uploaded, and
  /// refuses any url outside our own ImageKit endpoint — otherwise a
  /// crafted call could point a product's photo at any address on the
  /// internet, including one that changes after review.
  ///
  /// A CSV import has the opposite shape: the owner supplies a url they
  /// control (their old store, a shared drive, a stock library) and asks
  /// kola to take a copy. So the url is deliberately NOT ours, and the
  /// server fetches it — which also means the image stops depending on
  /// the source staying online.
  ///
  /// ── WHAT IT WILL NOT FETCH ───────────────────────────────────────
  ///
  /// http and https only, and nothing that resolves to a private
  /// address. Without that check this endpoint is a server-side request
  /// forgery tool: a caller could aim it at http://169.254.169.254 (the
  /// cloud metadata service) or at localhost and read whatever came
  /// back through the resulting image. The scheme and host checks below
  /// are the whole defence and are not optional.
  Future<ProductMedia?> importMediaFromUrl(
    Session session,
    String accessToken,
    int workspaceId,
    int productId,
    String sourceUrl,
  ) async {
    await _require(accessToken, workspaceId);

    final product = await _products.findById(workspaceId, productId);
    if (product == null) {
      throw KolaException(message: 'That product no longer exists.');
    }

    final uri = Uri.tryParse(sourceUrl.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw KolaException(
        message: 'That image link needs to start with http:// or https://',
      );
    }
    if (_isPrivateHost(uri.host)) {
      Log.warning(
        'Blocked media import from a private address',
        data: {'workspaceId': workspaceId, 'host': uri.host},
      );
      throw KolaException(message: "kola can't reach that address.");
    }

    final uploaded = await _imagekit.uploadFromUrl(
      sourceUrl: uri,
      fileName: _fileNameFrom(uri, productId),
      folder: ImageKitService.folderFor(workspaceId),
    );
    // Null rather than an exception: one unreachable image in a
    // fifty-row import must not fail the row. The product still saves;
    // the owner sees which ones came through.
    if (uploaded == null) return null;

    final position = await _products.countMedia(productId);
    return _products.addMedia(
      ProductMedia(
        productId: productId,
        kind: 'image',
        imagekitFileId: uploaded.fileId,
        url: uploaded.url,
        thumbnailUrl: uploaded.thumbnailUrl,
        width: uploaded.width,
        height: uploaded.height,
        position: position,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Blocks loopback, link-local and RFC1918 space.
  ///
  /// A hostname that is not a literal IP still resolves somewhere, so
  /// this is a first line rather than a complete one — a hostile DNS
  /// record can point a public name at 127.0.0.1. Closing that properly
  /// needs resolution-then-check-then-connect against the resolved
  /// address, which Dart's http client does not expose. Recorded plainly
  /// rather than left to look complete.
  bool _isPrivateHost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost' || h.endsWith('.localhost') || h.endsWith('.internal')) {
      return true;
    }
    final parts = h.split('.');
    if (parts.length == 4 && parts.every((p) => int.tryParse(p) != null)) {
      final o = parts.map(int.parse).toList();
      if (o[0] == 127 || o[0] == 10) return true;
      if (o[0] == 169 && o[1] == 254) return true; // cloud metadata
      if (o[0] == 172 && o[1] >= 16 && o[1] <= 31) return true;
      if (o[0] == 192 && o[1] == 168) return true;
      if (o[0] == 0) return true;
    }
    return false;
  }

  String _fileNameFrom(Uri uri, int productId) {
    final last = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (last.isNotEmpty && last.contains('.')) return last;
    // picsum and many CDNs serve extensionless paths. ImageKit guesses
    // from content when the name has no extension, and guessing wrong
    // breaks rendering — so give it one.
    return 'product-$productId-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}
