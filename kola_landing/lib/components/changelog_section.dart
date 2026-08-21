// changelog_section.dart
//
// "Building in public" — the second honest substitute for testimonials.
//
// A dated shipping record is real proof of momentum and needs zero
// customers. Every entry below describes something that actually
// shipped and can be verified in the codebase; nothing here is
// aspirational or a roadmap item dressed as a release.
//
// Update this list when something real ships. An out-of-date changelog
// on a page headed "Building in public" is worse than not having one.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class ChangelogSection extends StatelessComponent {
  const ChangelogSection();

  static const _entries = [
    ('Aug 2026', 'Business memory now cites the exact document and section behind '
        'every answer.'),
    ('Aug 2026', 'Sales counter groundwork — catalog, offline selling and receipts '
        'confirmed for launch.'),
    ('Jul 2026', 'WhatsApp and Telegram both live — one agent, one set of errands, '
        'both channels.'),
    ('Jul 2026', 'Payments through Paystack and Flutterwave — money goes straight '
        'to your own account.'),
    ('Jun 2026', 'Multi-provider AI routing shipped, so no single AI vendor is a '
        'single point of failure.'),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'changelog',
        'style': 'max-width:760px;margin:120px auto 0;padding:0 32px',
      },
      [
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:32px;font-weight:500;'
                'margin:0 0 30px;text-align:center',
          },
          [Component.text('Building in public.')],
        ),
        for (final (date, entry) in _entries)
          div(
            classes: 'kola-changelog-row',
            attributes: {
              'style': 'border-top:1px solid ${KolaColors.border};padding:18px 0;'
                  'display:flex;gap:20px',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:12.5px;color:${KolaColors.textFaint};width:70px;'
                      'flex:none;font-family:${KolaFonts.mono}',
                },
                [Component.text(date)],
              ),
              div(
                attributes: {
                  'style': 'font-size:14.5px;color:${KolaColors.textBody};line-height:1.5',
                },
                [Component.text(entry)],
              ),
            ],
          ),
      ],
    );
  }
}
