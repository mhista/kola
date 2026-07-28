// site_header.dart
//
// Sticky top nav: logo, Product dropdown (pure-CSS hover, see
// web/styles.css's .kola-product-hover rule — no Dart state needed for
// something this simple), Resources/Pricing/Sign in links, "Start free"
// CTA. Matches Kola Landing.dc.html's header exactly on copy and color.
//
// Nav links collapse on mobile via .kola-nav-links in styles.css — the
// logo + Start-free CTA remain the minimum viable mobile header; a full
// hamburger menu is a fast-follow, not blocking Phase 1e's first ship.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class SiteHeader extends StatelessComponent {
  const SiteHeader();

  static const _kolaDropSvg =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none">'
      '<path d="M13 2C13 2 6 8.5 6 15.5C6 20 9 24 13 24C17 24 20 20 20 15.5C20 8.5 13 2 13 2Z" fill="#C1552E"/>'
      '<path d="M13 6C13 6 9.5 10.8 9.5 15.5C9.5 18.5 11 21 13 21" stroke="#FAF6EF" stroke-width="1.4" stroke-linecap="round" fill="none"/>'
      '</svg>';

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            'position:sticky;top:0;z-index:40;background:rgba(250,246,239,0.9);'
            'backdrop-filter:blur(10px);border-bottom:1px solid ${KolaColors.border}',
      },
      [
        div(
          attributes: {
            'style':
                'max-width:1240px;margin:0 auto;padding:16px 32px;display:flex;'
                'align-items:center;justify-content:space-between;gap:24px',
          },
          [
            // ── Logo ────────────────────────────────────────────────
            div(
              attributes: {'style': 'display:flex;align-items:center;gap:10px'},
              [
                raw(_kolaDropSvg),
                span(
                  attributes: {
                    'style':
                        'font-family:${KolaFonts.serif};font-size:22px;font-weight:600;'
                        'letter-spacing:-0.01em;color:${KolaColors.text}',
                  },
                  [Component.text('kola')],
                ),
              ],
            ),

            // ── Nav links ───────────────────────────────────────────
            div(
              classes: 'kola-nav-links',
              attributes: {
                'style':
                    'display:flex;align-items:center;gap:28px;font-size:15px;color:${KolaColors.textNav}',
              },
              [
                div(
                  classes: 'kola-product-hover',
                  [
                    span(
                      attributes: {
                        'style': 'cursor:pointer;display:flex;align-items:center;gap:4px',
                      },
                      [
                        Component.text('Product '),
                        span(attributes: {'style': 'font-size:11px'}, [
                          Component.text('▾'),
                        ]),
                      ],
                    ),
                    div(
                      classes: 'kola-dropdown',
                      attributes: {
                        'style':
                            'position:absolute;top:28px;left:-16px;background:${KolaColors.cardBg};'
                            'border:1px solid ${KolaColors.border};border-radius:14px;'
                            'box-shadow:0 12px 32px rgba(28,24,21,0.12);padding:8px;width:240px',
                      },
                      [
                        for (final item in const [
                          'WhatsApp & Telegram bots',
                          'Dashboard',
                          'Templates',
                          'Integrations',
                        ])
                          div(
                            classes: 'kola-dropdown-item',
                            attributes: {
                              'style':
                                  'padding:10px 12px;border-radius:9px;cursor:pointer;font-size:14px',
                            },
                            [Component.text(item)],
                          ),
                      ],
                    ),
                  ],
                ),
                a(
                  attributes: {'style': 'color:${KolaColors.textNav}'},
                  [Component.text('Resources')],
                  href: '#',
                ),
                a(
                  attributes: {'style': 'color:${KolaColors.textNav}'},
                  [Component.text('Pricing')],
                  href: '#pricing',
                ),
                a(
                  attributes: {'style': 'color:${KolaColors.textNav}'},
                  [Component.text('Sign in')],
                  href: '#',
                ),
              ],
            ),

            // ── CTA ─────────────────────────────────────────────────
            a(
              classes: 'kola-btn-lift',
              attributes: {
                'style':
                    'background:${KolaColors.dark};color:${KolaColors.darkText};padding:11px 20px;'
                    'border-radius:100px;font-size:14px;font-weight:600;white-space:nowrap',
              },
              [Component.text('Start free')],
              href: '#pricing',
            ),
          ],
        ),
      ],
    );
  }
}
