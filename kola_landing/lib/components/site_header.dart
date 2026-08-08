// site_header.dart
//
// Sticky, blurred top bar. Matches the v2 Kola Landing export: logo,
// four nav links, and a solid dark "Start free" CTA.
//
// The nav collapses to a horizontal scroll strip below 720px rather
// than a hamburger — with only four short links, a menu button costs a
// tap for no gain, and the strip keeps every destination one tap away.
// See web/styles.css `.kola-nav`.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../config/links.dart';
import '../i18n/strings.dart';

class SiteHeader extends StatelessComponent {
  const SiteHeader({required this.s});

  /// Localised copy. Passed in from app.dart — a component never
  /// resolves its own locale. See i18n/strings.dart.
  final Strings s;

  /// The kola-drop mark, inline so it needs no network fetch and can't
  /// break from a missing asset. Both paths matter — the second is the
  /// inner highlight stroke that makes it read as a drop rather than a
  /// blob; an earlier pass of this rewrite dropped it by accident.
  static const _kolaDropSvg =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" aria-hidden="true">'
      '<path d="M13 2C13 2 6 8.5 6 15.5C6 20 9 24 13 24C17 24 20 20 20 15.5C20 8.5 13 2 13 2Z" fill="#C1552E"/>'
      '<path d="M13 6C13 6 9.5 10.8 9.5 15.5C9.5 18.5 11 21 13 21" stroke="#FAF6EF" stroke-width="1.4" stroke-linecap="round" fill="none"/>'
      '</svg>';

  /// Nav entries. `Docs` is omitted entirely until Links.docs is set —
  /// see config/links.dart on why a dead nav item is worse than a
  /// missing one.
  List<(String, String)> get _links => [
        (s.navProduct, Links.product),
        (s.navSalesCounter, Links.commerce),
        if (Links.isLive(Links.docs)) (s.navDocs, Links.docs!),
        (s.navPricing, Links.pricing),
        (s.navChangelog, Links.changelog),
      ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'position:sticky;top:0;z-index:40;'
            'background:rgba(250,246,239,0.9);backdrop-filter:blur(10px);'
            'border-bottom:1px solid ${KolaColors.border}',
      },
      [
        div(
          classes: 'kola-header-inner',
          attributes: {
            'style': 'max-width:1240px;margin:0 auto;padding:16px 32px;'
                'display:flex;align-items:center;justify-content:space-between;gap:24px',
          },
          [
            // ── Logo ──────────────────────────────────────────────────
            a(
              href: '#top',
              attributes: {
                'style': 'display:flex;align-items:center;gap:10px;flex:none;'
                    'color:${KolaColors.text}',
              },
              [
                raw(_kolaDropSvg),
                span(
                  attributes: {
                    'style': 'font-family:${KolaFonts.serif};font-size:22px;'
                        'font-weight:600;letter-spacing:-0.01em',
                  },
                  [Component.text('kola')],
                ),
              ],
            ),

            // ── Nav ───────────────────────────────────────────────────
            nav(
              classes: 'kola-nav',
              attributes: {
                'style': 'display:flex;align-items:center;gap:26px;'
                    'font-size:14.5px;color:${KolaColors.textNav}',
              },
              [
                for (final (label, href) in _links)
                  a(
                    href: href,
                    classes: 'kola-nav-link',
                    attributes: {
                      'style': 'color:${KolaColors.textNav};white-space:nowrap',
                    },
                    [Component.text(label)],
                  ),
              ],
            ),

            a(
              href: '#pricing',
              classes: 'kola-btn-lift',
              attributes: {
                'style': 'background:${KolaColors.dark};color:${KolaColors.darkText};'
                    'padding:11px 20px;border-radius:100px;font-size:14px;'
                    'font-weight:600;white-space:nowrap;flex:none',
              },
              [Component.text(s.ctaStartFree)],
            ),
          ],
        ),
      ],
    );
  }
}
