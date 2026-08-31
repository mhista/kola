// public_catalog_page.dart — Phase 11's shareable public catalog page,
// /catalog/:workspaceId. The one page in this whole dashboard a visitor
// with no Kola account and no session can open — see app.dart's
// _redirect for the one line that lets this path bypass the auth guard
// every other route goes through.
//
// Deliberately minimal chrome, same posture login_page.dart's own header
// states for the same reason: no design-file mock exists for this
// surface yet, so it reuses the shell's existing palette/fonts rather
// than inventing new visual language.
//
// NEVER shows cost or an exact stock count — see
// ProductEndpoint.getPublicCatalog and PublicCatalogItem's own headers
// on why that is enforced server-side (the response literally cannot
// carry those fields), not just something this page chooses not to
// render. Belt-and-suspenders is nice; the belt doing the actual job is
// what matters.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';

class PublicCatalogPage extends StatefulComponent {
  const PublicCatalogPage({required this.client, required this.workspaceId});

  final Client client;
  final int workspaceId;

  @override
  State<PublicCatalogPage> createState() => _PublicCatalogPageState();
}

class _PublicCatalogPageState extends State<PublicCatalogPage> {
  PublicCatalog? _catalog;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // No accessToken — this is the one product.* call that works
      // without a session. See ProductEndpoint.getPublicCatalog's own
      // header on the three checks it makes instead.
      final catalog = await component.client.product.getPublicCatalog(
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Deliberately generic — see the endpoint's own header on why a
        // probe against a random workspaceId should not be able to tell
        // "wrong id" apart from "exists but not published" from "flag
        // locked" from any other reason.
        _error = 'This catalog is not available.';
        _loading = false;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'font-family:${KolaFonts.sans};background:${KolaVar.bg};'
            'color:${KolaVar.text};min-height:100vh;width:100%;'
            'box-sizing:border-box;padding:${KolaSpace.lg}',
      },
      [
        if (_loading) _center('Loading…'),
        if (!_loading && _error != null) _center(_error!),
        if (!_loading && _catalog != null) _body(_catalog!),
      ],
    );
  }

  Component _center(String text) => div(
        attributes: {
          'style': 'width:100%;min-height:60vh;display:flex;'
              'align-items:center;justify-content:center;'
              'color:${KolaVar.muted};font-size:${KolaType.body}',
        },
        [Component.text(text)],
      );

  Component _body(PublicCatalog catalog) {
    final available = catalog.items.where((i) => i.stockStatus != 'outOfStock').toList();
    final outOfStock = catalog.items.where((i) => i.stockStatus == 'outOfStock').toList();
    return div(
      attributes: {'style': 'max-width:960px;margin:0 auto'},
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.h2};font-weight:700;'
                'margin-bottom:4px',
          },
          [Component.text(catalog.businessName)],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'margin-bottom:${KolaSpace.lg}',
          },
          [
            Component.text(
              catalog.items.isEmpty
                  ? 'Nothing listed yet.'
                  : '${catalog.items.length} item${catalog.items.length == 1 ? '' : 's'}',
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'display:grid;'
                'grid-template-columns:repeat(auto-fill,minmax(200px,1fr));'
                'gap:${KolaSpace.md}',
          },
          [for (final item in [...available, ...outOfStock]) _card(item)],
        ),
        div(
          attributes: {
            'style': 'text-align:center;color:${KolaVar.muted};'
                'font-size:${KolaType.tiny};margin-top:${KolaSpace.xl}',
          },
          [Component.text('Powered by Kola')],
        ),
      ],
    );
  }

  Component _card(PublicCatalogItem item) {
    final soldOut = item.stockStatus == 'outOfStock';
    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};overflow:hidden;'
            'background:${KolaVar.card};'
            'opacity:${soldOut ? '0.55' : '1'}',
      },
      [
        div(
          attributes: {
            'style': 'width:100%;aspect-ratio:1;background:${KolaVar.pill};'
                'display:flex;align-items:center;justify-content:center;'
                'overflow:hidden',
          },
          item.imageUrl == null
              ? [
                  Component.text(
                    item.name.trim().isEmpty ? '?' : item.name.trim()[0].toUpperCase(),
                  ),
                ]
              : [
                  img(
                    src: item.imageUrl!,
                    alt: item.name,
                    attributes: {
                      'style': 'width:100%;height:100%;object-fit:cover',
                      'loading': 'lazy',
                    },
                  ),
                ],
        ),
        div(
          attributes: {'style': 'padding:${KolaSpace.sm}'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};font-weight:600;'
                    'margin-bottom:2px',
              },
              [Component.text(item.name)],
            ),
            if (item.category != null)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                      'margin-bottom:4px',
                },
                [Component.text(item.category!)],
              ),
            div(
              attributes: {
                'style': 'display:flex;align-items:center;'
                    'justify-content:space-between;gap:8px',
              },
              [
                Component.text(_priceLabel(item)),
                if (soldOut)
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};'
                          'font-weight:600',
                    },
                    [Component.text('Sold out')],
                  )
                else if (item.stockStatus == 'lowStock')
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.tiny};color:${KolaVar.accent};'
                          'font-weight:600',
                    },
                    [Component.text('Low stock')],
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// priceMinor is an integer count of the smallest unit — see
  /// product.spy.yaml's own money note. No decimal-place table exists
  /// on this deliberately auth-free page (that lookup lives in the
  /// authenticated dashboard's money-formatting helper), so this shows
  /// the minor-unit count divided by 100 for the common two-decimal
  /// case, prefixed with the raw currency code rather than a symbol —
  /// honest about the one thing not resolved here rather than guessing
  /// a symbol for a currency code this page never asked the workspace
  /// for. Good enough for the common case; a zero-decimal currency is a
  /// known, named gap, not an invented "it's fine."
  String _priceLabel(PublicCatalogItem item) {
    if (item.priceMinor == null) return 'Ask us';
    final major = item.priceMinor! / 100;
    final unit = item.priceUnit != null && item.priceUnit!.isNotEmpty
        ? item.priceUnit!
        : '';
    return '${item.priceCurrency} ${major.toStringAsFixed(2)}$unit';
  }
}
