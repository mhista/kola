// site_footer.dart
//
// LINKS THAT DO NOT EXIST ARE NOT RENDERED. Every destination is
// declared in config/links.dart; anything still null is skipped, and a
// column with nothing left in it disappears entirely rather than
// shipping an empty heading.
//
// The reasoning is in links.dart, but briefly: a dead "Careers" link in
// a footer signals a company that does not check its own site, which is
// exactly the wrong signal for a product asking a sceptical buyer to
// trust it with their business data.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../config/links.dart';

class SiteFooter extends StatelessComponent {
  const SiteFooter();

  /// (column title, [(label, url-or-null)])
  static List<(String, List<(String, String?)>)> get _columns => [
        (
          'Product',
          [
            ('Sales counter', Links.commerce),
            ('Business memory', Links.product),
            ('Pricing', Links.pricing),
          ]
        ),
        (
          'Resources',
          [
            ('Docs', Links.docs),
            ('Changelog', Links.changelog),
            ('Questions', Links.faq),
          ]
        ),
        (
          'Company',
          [
            ('About', Links.about),
            ('Contact', Links.contact),
            ('Privacy', Links.privacy),
            ('Terms', Links.terms),
          ]
        ),
      ];

  @override
  Component build(BuildContext context) {
    // Drop any column left with no live links at all.
    final columns = _columns
        .map((c) => (c.$1, c.$2.where((l) => Links.isLive(l.$2)).toList()))
        .where((c) => c.$2.isNotEmpty)
        .toList();

    return footer(
      attributes: {
        'style': 'background:${KolaColors.dark};color:${KolaColors.darkText};'
            'margin-top:120px;padding-top:70px',
      },
      [
        div(
          classes: 'kola-footer-grid',
          attributes: {
            'style': 'max-width:1100px;margin:0 auto;padding:0 32px 50px;display:grid;'
                'grid-template-columns:1.4fr repeat(${columns.length},1fr);gap:40px',
          },
          [
            div(
              attributes: {
                'style': 'font-size:14.5px;color:${KolaColors.darkTextMuted};'
                    'line-height:1.6;max-width:300px',
              },
              [
                Component.text(
                  'kola connects your tools, remembers everything, runs your counter, '
                  'and gets the next step done — on WhatsApp and Telegram, no '
                  'developer required.',
                ),
              ],
            ),
            for (final (title, links) in columns)
              div([
                div(
                  attributes: {
                    'style': 'font-size:12px;letter-spacing:0.06em;text-transform:uppercase;'
                        'color:${KolaColors.darkTextFaint};margin-bottom:16px',
                  },
                  [Component.text(title)],
                ),
                for (final (label, url) in links)
                  a(
                    href: url!,
                    classes: 'kola-footer-link',
                    attributes: {
                      'style': 'display:block;font-size:14.5px;'
                          'color:${KolaColors.darkTextSoft};padding:6px 0',
                    },
                    [Component.text(label)],
                  ),
              ]),
          ],
        ),
        div(
          attributes: {
            'style': 'border-top:1px solid ${KolaColors.darkBorder};padding:20px 32px;'
                'text-align:center;font-size:13px;color:${KolaColors.darkTextFaint}',
          },
          [Component.text('© 2026 kola. Made for businesses that never open a laptop.')],
        ),
      ],
    );
  }
}
