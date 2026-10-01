// catalog_page.dart — '/catalog'.
//
// Documents ProductEndpoint — kolaa's product catalog, media handling,
// and the public unauthenticated catalog read. Previously undocumented
// entirely. Confirmed directly against product_endpoint.dart, including
// the two documented Serverpod list-deserialization workarounds
// (comma-separated strings instead of List<int>) so this page's
// examples match what actually deserializes, not what "should" work.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class CatalogPage extends StatelessComponent {
  const CatalogPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Catalog & Products'),
      docLede(
        "kolaa's product catalog: create, price, stock, and photograph products, and — "
        'separately — a public, unauthenticated read of whatever a workspace chooses to '
        'publish. Gated on commerce.core and commerce.catalog together on every write and '
        'authenticated read.',
      ),

      docH2('Creating and editing products'),
      docP(
        'priceMinor and costMinor are integers in the currency\'s minor unit (kobo for NGN) — '
        "nothing server-side multiplies or divides by 100, that conversion happens at whichever "
        'edge knows the currency\'s decimal places. archetype is one of packaged, variants, or '
        'services.',
      ),
      const CodeBlock(
        title: 'ProductEndpoint.createProduct',
        dart:
            "final product = await client.product.createProduct(\n"
            "  accessToken, workspaceId, \"Leather Tote\",\n"
            "  archetype: \"packaged\",\n"
            "  sku: \"TOTE-BRN-01\",\n"
            "  category: \"Bags\",\n"
            "  priceMinor: 4500000, // ₦45,000.00\n"
            "  stock: 12,\n"
            "  lowStockThreshold: 3,\n"
            ");",
      ),
      docNote(
        'A duplicate SKU is rejected with a "duplicate" error code naming the product that '
        'already holds it, not a generic conflict — the same discipline applies on '
        'updateProduct.',
      ),
      docP(
        'updateProduct treats every parameter as "leave alone" when null, which means clearing '
        'a price or a stock count (turning a priced product into an on-request one) needs its '
        'own explicit flag rather than passing null.',
      ),
      const CodeBlock(
        title: 'ProductEndpoint.updateProduct / archiveProduct',
        dart:
            "await client.product.updateProduct(\n"
            "  accessToken, workspaceId, product.id!,\n"
            "  clearPrice: true, // price is now on-request, not simply unset\n"
            ");\n"
            "await client.product.archiveProduct(accessToken, workspaceId, product.id!);\n"
            "// archiveProduct never deletes — an archived product still exists, just hidden.",
      ),

      docH2('Variants'),
      docP(
        'replaceVariants replaces the full variant set in one call — labels, stocks, and '
        "priceMinors are parallel lists (a Dart list of a custom model isn't something this "
        "Serverpod install can deserialize as a parameter), and a length mismatch is refused "
        'rather than silently zipped to the shortest.',
      ),
      const CodeBlock(
        title: 'ProductEndpoint.replaceVariants',
        dart:
            "await client.product.replaceVariants(\n"
            "  accessToken, workspaceId, product.id!,\n"
            '  ["Small", "Medium", "Large"],\n'
            "  [8, 12, 4],\n"
            "  [4000000, 4500000, 5200000],\n"
            ");",
      ),

      docH2('Product photos'),
      docP(
        'Uploads go straight from the browser to ImageKit, never through kola\'s own server — '
        'getMediaUploadAuth issues short-lived, workspace-scoped credentials, and the caller '
        'uploads directly, then calls addProductMedia to record the result. importMediaFromUrl '
        'is the separate CSV-import path: the caller supplies a url it controls (an old store, '
        'a shared drive) and kolaa fetches and re-hosts a copy — restricted to http/https and '
        'blocked from any private or link-local address, since fetching an arbitrary '
        'server-supplied URL is otherwise a server-side request forgery vector.',
      ),
      const CodeBlock(
        title: 'Photo upload (browser-direct) vs. import-by-URL',
        dart:
            "// Browser-direct upload:\n"
            "final authJson = await client.product.getMediaUploadAuth(accessToken, workspaceId);\n"
            "// ... browser uploads the file straight to ImageKit using authJson ...\n"
            "await client.product.addProductMedia(\n"
            "  accessToken, workspaceId, product.id!, imagekitFileId, url,\n"
            ");\n\n"
            "// Import-by-URL (what catalog CSV import uses per row):\n"
            "await client.product.importMediaFromUrl(\n"
            "  accessToken, workspaceId, product.id!,\n"
            '  "https://example.com/old-store/tote.jpg",\n'
            ");",
      ),
      docNote(
        "There's no dedicated bulk-import endpoint. CSV catalog import is dashboard-side "
        'orchestration: one createProduct call per row, followed by importMediaFromUrl for any '
        'image column mapped in — the same two methods documented above, called repeatedly.',
      ),
      docList([
        'listMediaForProducts takes a comma-separated productIds string, not a Dart list, for '
            'the same Serverpod list-deserialization reason as replaceVariants — this one is '
            'documented in the source with a specific failure trace, worth knowing if a list '
            'parameter you\'d expect to work silently 500s.',
        'reorderProductMedia takes mediaIdsInOrder the same way — a comma-separated string, '
            'index 0 becomes the main image.',
        'deleteProductMedia removes the file from ImageKit as well as the row, but a CDN '
            'failure never blocks the row delete.',
      ]),

      docH2('The public catalog'),
      docP(
        'getPublicCatalog is the one method on this endpoint with no accessToken — a genuinely '
        "public, unauthenticated read, meant for a link a business shares with customers "
        'directly. It requires three things together: the commerce.core/commerce.catalog '
        'flags, the commerce.public_catalog release flag, and the workspace\'s own '
        'publicCatalogEnabled opt-in — a business must deliberately turn this on, it is never '
        'on by default. All three failures collapse into the same generic error, so a probe '
        "against a random workspaceId can't learn anything about that workspace's settings.",
      ),
      const CodeBlock(
        title: 'ProductEndpoint.getPublicCatalog — public, no accessToken',
        curl: "curl -X POST https://api.kolaa.co/product \\\n"
            "  -H 'Content-Type: application/json' \\\n"
            "  -d '{\"method\": \"getPublicCatalog\", \"workspaceId\": 42}'",
      ),
      docWarning(
        'The public catalog never returns costMinor or an exact stock count — only a '
        'tri-state stockStatus (inStock / lowStock / outOfStock / notTracked). This is enforced '
        'server-side by returning a different model (PublicCatalogItem) entirely, not by the '
        'caller choosing to ignore fields it should not read.',
      ),
    ]);
  }
}
