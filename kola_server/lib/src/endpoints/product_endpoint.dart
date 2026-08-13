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

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/product_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/kola_logger.dart';

class ProductEndpoint extends Endpoint {
  ProductRepository get _products => getIt<ProductRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();

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
    String? tag,
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
        tag: _clean(tag),
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
    String? tag,
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
    if (tag != null) product.tag = _clean(tag);

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
}
