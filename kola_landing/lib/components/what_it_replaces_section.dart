// what_it_replaces_section.dart
//
// REPLACES the "Building in public" changelog section, after the project
// owner asked what purpose it actually served. The honest answer: it
// spoke to investors and grant committees, not to the person deciding
// whether this will answer her customers. "Multi-provider AI routing
// shipped in June" means nothing to a shop owner, and a stale changelog
// under a heading saying "Building in public" is worse than none at all.
//
// The proof section already does the persuading — a live demo beats a
// shipping log for a sceptical buyer. So this slot goes to the argument
// that actually converts an owner: what this costs against what it
// replaces.
//
// The changelog itself still exists for the evaluator audience; it moves
// to its own page linked from the footer (Links.changelog).
//
// DELIBERATELY NO SPECIFIC SALARY FIGURE. What a part-time assistant
// costs varies enormously by market, and inventing a number would be
// both wrong somewhere and unverifiable everywhere. The comparison is
// made in structure — the shape of the cost — and the reader fills in
// their own number, which is more persuasive than a figure they might
// dispute.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../i18n/region.dart';
import '../i18n/strings.dart';

class WhatItReplacesSection extends StatelessComponent {
  const WhatItReplacesSection({required this.s, required this.region});

  final Strings s;
  final Region region;

  static const _rows = [
    (
      'Someone answering messages',
      'A part-time assistant, paid monthly, who sleeps, takes holidays, and '
          'leaves eventually — taking what they knew with them.',
      'kolaa answers every hour of every day, and what it learns stays.',
    ),
    (
      'A separate till or POS subscription',
      'Another monthly fee, another system, and it stops working when the '
          'network does.',
      'Included. Works offline. Feeds everything else kolaa knows.',
    ),
    (
      'Nothing at all',
      'Messages missed overnight. The same question answered forty times. '
          'No idea which product actually makes money.',
      'The cost of doing nothing is the one nobody puts on an invoice.',
    ),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'replaces',
        'style': 'max-width:900px;margin:120px auto 0;padding:0 32px',
      },
      [
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:34px;font-weight:500;'
                'margin:0 0 14px;text-align:center',
          },
          [Component.text(s.replacesTitle)],
        ),
        p(
          attributes: {
            'style': 'font-size:15.5px;color:${KolaColors.textMuted};text-align:center;'
                'max-width:560px;margin:0 auto 40px;line-height:1.6',
          },
          [
            Component.text(s.replacesSubtitle(region.formattedProPrice)),
          ],
        ),
        for (final (title, before, after) in _rows)
          div(
            classes: 'kola-replaces-row',
            attributes: {
              'style': 'border-top:1px solid ${KolaColors.border};padding:22px 0;'
                  'display:grid;grid-template-columns:1fr 1fr;gap:28px;align-items:start',
            },
            [
              div([
                div(
                  attributes: {
                    'style': 'font-size:16px;font-weight:600;margin-bottom:6px',
                  },
                  [Component.text(title)],
                ),
                div(
                  attributes: {
                    'style': 'font-size:14px;color:${KolaColors.textMutedLight};'
                        'line-height:1.55',
                  },
                  [Component.text(before)],
                ),
              ]),
              div(
                attributes: {
                  'style': 'font-size:14px;color:${KolaColors.textBody};line-height:1.55;'
                      'padding-left:20px;border-left:2px solid ${KolaColors.accent}',
                },
                [Component.text(after)],
              ),
            ],
          ),
      ],
    );
  }
}
