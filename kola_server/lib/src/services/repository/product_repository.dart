// product_repository.dart
//
// Storage for `products` and `product_variants` (migration 029).
//
// ── EVERY QUERY IS SCOPED BY workspace_id ────────────────────────────
//
// Including the ones that already have a product id. `findById` takes a
// workspaceId and filters on it, so guessing an id from another business
// returns null rather than that business's pricing. RLS is on with no
// policies (the server connects as table owner), so this layer IS the
// isolation boundary — not a second line of defence behind one.
//
// Variant reads are the exception that proves it: they filter by
// product_id, and every caller reaches them through a product this
// repository already resolved for the workspace.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/product_dto.dart';
import 'package:kola_server/src/services/dto/product_variant_dto.dart';
import 'package:kola_server/src/services/dto/product_media_dto.dart';
import 'supabase_client.dart';

final _log = Logger('ProductRepository');

const _dto = ProductDto();
const _variantDto = ProductVariantDto();
const _mediaDto = ProductMediaDto();

class ProductRepository {
  const ProductRepository();

  // ── Products ───────────────────────────────────────────────────────

  /// Active products, newest edit first.
  ///
  /// Archived rows are excluded by default because the catalog screen is
  /// a working list, not an archive. [includeArchived] exists for the
  /// places that genuinely need history.
  Future<List<Product>> listByWorkspace(
    int workspaceId, {
    bool includeArchived = false,
  }) async {
    _log.fine('listByWorkspace($workspaceId, archived=$includeArchived)');

    // Written as two complete chains rather than building one up
    // conditionally. postgrest-dart's builders change type as filters
    // are added, and no other repository here reassigns one — so this
    // avoids being the first place to find out whether that inference
    // holds, at the cost of one duplicated line.
    final response = includeArchived
        ? await supabase
            .from('products')
            .select()
            .eq('workspace_id', workspaceId)
            .order('updated_at', ascending: false)
        : await supabase
            .from('products')
            .select()
            .eq('workspace_id', workspaceId)
            .eq('status', 'active')
            .order('updated_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// One product, scoped. Returns null if it belongs to someone else —
  /// deliberately indistinguishable from "does not exist", so an id
  /// probe cannot confirm another workspace's rows.
  Future<Product?> findById(int workspaceId, int productId) async {
    _log.fine('findById($workspaceId, $productId)');
    final response = await supabase
        .from('products')
        .select()
        .eq('id', productId)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Whether a SKU is already taken in this workspace.
  ///
  /// The database has a partial unique index doing the same job, and
  /// this does NOT replace it — the index is what makes the guarantee
  /// under concurrency. This exists so the owner gets "that SKU is
  /// already on Blue lace fabric" instead of a constraint violation.
  ///
  /// [excludingProductId] lets an edit re-save its own SKU without
  /// colliding with itself.
  Future<Product?> findBySku(
    int workspaceId,
    String sku, {
    int? excludingProductId,
  }) async {
    // Two chains again, and `.filter(col, 'neq', v)` rather than
    // `.neq(...)`. Same reasoning as ApiKeyRepository's `is` filter:
    // `filter` is postgrest-dart's generic escape hatch and has been
    // stable across the major versions where the dedicated helpers were
    // renamed. There is no `.neq` anywhere else in this codebase to
    // confirm the shorthand against.
    final response = excludingProductId == null
        ? await supabase
            .from('products')
            .select()
            .eq('workspace_id', workspaceId)
            .eq('sku', sku)
            .maybeSingle()
        : await supabase
            .from('products')
            .select()
            .eq('workspace_id', workspaceId)
            .eq('sku', sku)
            .filter('id', 'neq', excludingProductId)
            .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  Future<Product> create(Product product) async {
    _log.info('create workspaceId=${product.workspaceId} name=${product.name}');
    final row = _dto.toRow(product, includeId: false)
      ..remove('updated_at'); // let the column default stamp both dates

    final response =
        await supabase.from('products').insert(row).select().single();
    return _dto.fromRow(response);
  }

  Future<Product> update(Product product) async {
    _log.info('update id=${product.id}');
    final row = _dto.toRow(product, includeId: false);
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await supabase
        .from('products')
        .update(row)
        .eq('id', product.id!)
        // Scoped even though the id is unique — an update is the one
        // operation where getting the tenant wrong is silent and
        // permanent.
        .eq('workspace_id', product.workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Archives rather than deletes. See product.spy.yaml: a sold product
  /// is referenced by past orders, and removing it rewrites history the
  /// business may need for tax.
  Future<void> archive(int workspaceId, int productId) async {
    _log.info('archive workspaceId=$workspaceId id=$productId');
    await supabase
        .from('products')
        .update({
          'status': 'archived',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', productId)
        .eq('workspace_id', workspaceId);
  }

  /// Adjusts stock by a delta, for a sale or a restock.
  ///
  /// Read-then-write, and that is a KNOWN LIMITATION rather than an
  /// oversight: two sales landing in the same instant can both read the
  /// same starting figure and the second write wins, losing one
  /// decrement. Correcting it properly needs either `update ... set
  /// stock = stock - $n` expressed through postgrest, or a Postgres
  /// function, and the right fix is the second one so the clamp at zero
  /// happens in the same statement. Recorded here rather than in a
  /// backlog nobody reads, because the sales counter is what will make
  /// it matter.
  ///
  /// A null stock means "not tracked" and is left alone — incrementing
  /// it would silently start tracking something the owner chose not to.
  Future<Product?> adjustStock(
    int workspaceId,
    int productId,
    int delta,
  ) async {
    final product = await findById(workspaceId, productId);
    if (product == null) return null;

    final current = product.stock;
    if (current == null) return product;

    // Clamped at zero. Negative stock is not a state a shop can be in,
    // and letting it go negative turns one mis-scan into a number that
    // has to be explained later.
    product.stock = (current + delta) < 0 ? 0 : current + delta;
    return update(product);
  }

  // ── Variants ───────────────────────────────────────────────────────

  /// In the owner's chosen order — see product_variant.spy.yaml on why
  /// alphabetical is wrong for sizes.
  Future<List<ProductVariant>> listVariants(int productId) async {
    final response = await supabase
        .from('product_variants')
        .select()
        .eq('product_id', productId)
        .order('position', ascending: true);

    return (response as List)
        .map((row) => _variantDto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every variant for several products in ONE query.
  ///
  /// The catalog list shows a variant count per row. Fetching them per
  /// product would be a query per row — the N+1 that makes a 40-product
  /// catalog take forty round trips on a connection where each one
  /// costs 400ms.
  Future<Map<int, List<ProductVariant>>> listVariantsForProducts(
    List<int> productIds,
  ) async {
    if (productIds.isEmpty) return const {};

    final response = await supabase
        .from('product_variants')
        .select()
        .inFilter('product_id', productIds)
        .order('position', ascending: true);

    final grouped = <int, List<ProductVariant>>{};
    for (final row in response as List) {
      final variant = _variantDto.fromRow(row as Map<String, dynamic>);
      grouped.putIfAbsent(variant.productId, () => []).add(variant);
    }
    return grouped;
  }

  /// Replaces a product's whole variant set.
  ///
  /// DELETE-THEN-INSERT, deliberately. The editor hands back the full
  /// list every time (variantRows in the export), and diffing it against
  /// what is stored — matching on a label the owner may have just
  /// renamed — is guesswork that gets stock attached to the wrong row.
  ///
  /// The cost is that variant ids are not stable across a save. Nothing
  /// references them yet. When orders do, this has to become a real
  /// diff keyed on id, and that is a deliberate trade being recorded
  /// now rather than discovered then.
  Future<List<ProductVariant>> replaceVariants(
    int productId,
    List<ProductVariant> variants,
  ) async {
    _log.info('replaceVariants productId=$productId count=${variants.length}');

    await supabase.from('product_variants').delete().eq('product_id', productId);
    if (variants.isEmpty) return const [];

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < variants.length; i++) {
      final v = variants[i];
      final row = _variantDto.toRow(v, includeId: false)
        ..remove('updated_at');
      row['product_id'] = productId;
      // Position is assigned from the submitted ORDER rather than
      // trusting the client's number — two rows claiming position 0
      // would otherwise sort arbitrarily.
      row['position'] = i;
      rows.add(row);
    }

    final response =
        await supabase.from('product_variants').insert(rows).select();

    return (response as List)
        .map((row) => _variantDto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── Media ──────────────────────────────────────────────────────────

  /// A product's photos and video, main image first.
  Future<List<ProductMedia>> listMedia(int productId) async {
    final response = await supabase
        .from('product_media')
        .select()
        .eq('product_id', productId)
        .order('position', ascending: true);

    return (response as List)
        .map((row) => _mediaDto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Media for several products in ONE query.
  ///
  /// The catalog grid shows a thumbnail per row. Per-product fetches
  /// would be the same N+1 that listVariantsForProducts exists to avoid
  /// — forty products, forty round trips, on a connection where each one
  /// costs 400ms.
  Future<Map<int, List<ProductMedia>>> listMediaForProducts(
    List<int> productIds,
  ) async {
    if (productIds.isEmpty) return const {};

    final response = await supabase
        .from('product_media')
        .select()
        .inFilter('product_id', productIds)
        .order('position', ascending: true);

    final grouped = <int, List<ProductMedia>>{};
    for (final row in response as List) {
      final media = _mediaDto.fromRow(row as Map<String, dynamic>);
      grouped.putIfAbsent(media.productId, () => []).add(media);
    }
    return grouped;
  }

  /// Records a file the BROWSER already uploaded to ImageKit.
  ///
  /// Position defaults to the end of the list rather than 0, so a second
  /// photo never silently displaces the main image the owner chose.
  Future<ProductMedia> addMedia(ProductMedia media) async {
    final row = _mediaDto.toRow(media, includeId: false);

    final response =
        await supabase.from('product_media').insert(row).select().single();
    return _mediaDto.fromRow(response);
  }

  /// How many media rows a product already has. Used to append.
  Future<int> countMedia(int productId) async {
    final response = await supabase
        .from('product_media')
        .select('id')
        .eq('product_id', productId);
    return (response as List).length;
  }

  /// One media row, resolved through its product so the caller's
  /// workspace can be checked before anything is deleted.
  Future<ProductMedia?> findMediaById(int mediaId) async {
    final response = await supabase
        .from('product_media')
        .select()
        .eq('id', mediaId)
        .maybeSingle();

    if (response == null) return null;
    return _mediaDto.fromRow(response);
  }

  Future<void> deleteMedia(int mediaId) async {
    await supabase.from('product_media').delete().eq('id', mediaId);
  }

  /// Reorders a product's media. The list is the new order; index 0
  /// becomes the main image.
  Future<void> reorderMedia(int productId, List<int> mediaIdsInOrder) async {
    for (var i = 0; i < mediaIdsInOrder.length; i++) {
      await supabase
          .from('product_media')
          .update({'position': i})
          .eq('id', mediaIdsInOrder[i])
          // Scoped to the product so a crafted id list cannot reorder
          // another product's photos.
          .eq('product_id', productId);
    }
  }
}
