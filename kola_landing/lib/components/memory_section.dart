// memory_section.dart
//
// The strongest differentiator, because it is built and working: kolaa
// cites the exact document and section behind every answer.
//
// The right-hand card is a real artefact from the product, not a
// decorative illustration — it shows a stored section, its source, and a
// match score, which is precisely what the Memory inspector renders.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class MemorySection extends StatelessComponent {
  const MemorySection();

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'memory',
        'style': 'max-width:1100px;margin:110px auto 0;padding:0 32px',
      },
      [
        div(
          classes: 'kola-split',
          attributes: {
            'style': 'display:grid;grid-template-columns:1fr 1fr;gap:56px;'
                'align-items:center',
          },
          [
            div([
              div(
                attributes: {
                  'style': 'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                      'color:${KolaColors.accent};font-weight:600;margin-bottom:14px',
                },
                [Component.text('Business memory')],
              ),
              h2(
                classes: 'kola-h2',
                attributes: {
                  'style': 'font-family:${KolaFonts.serif};font-size:34px;'
                      'font-weight:500;margin:0 0 16px',
                },
                [Component.text('It remembers everything you have told it — and shows its work.')],
              ),
              p(
                attributes: {
                  'style': 'font-size:15.5px;color:${KolaColors.textMuted};'
                      'line-height:1.6;margin:0 0 16px',
                },
                [
                  Component.text(
                    'Price lists, policies, FAQs — kolaa reads them once and answers '
                    'from them forever. Every answer names the exact document and '
                    'section it came from, so "the AI got that wrong" becomes '
                    'something you can check, not argue about.',
                  ),
                ],
              ),
              p(
                attributes: {'style': 'font-size:14px;color:${KolaColors.textFaint}'},
                [Component.text('Paste it in. Searchable in seconds.')],
              ),
            ]),
            div(
              attributes: {
                'style': 'background:${KolaColors.dark};border-radius:20px;padding:22px;'
                    'color:${KolaColors.darkText}',
              },
              [
                div(
                  attributes: {
                    'style': 'font-size:12px;color:${KolaColors.darkTextMuted};'
                        'margin-bottom:10px;font-family:${KolaFonts.mono}',
                  },
                  [Component.text('Return policy → section 3')],
                ),
                div(
                  attributes: {
                    'style': 'background:${KolaColors.codeBg};border-radius:12px;'
                        'padding:16px;font-size:13.5px;line-height:1.7;'
                        'color:${KolaColors.darkTextSoft};margin-bottom:14px',
                  },
                  [Component.text('"Items may be returned within 7 days if unworn and tagged."')],
                ),
                div(
                  attributes: {'style': 'font-size:13px;color:${KolaColors.matchGreen}'},
                  [Component.text('91% match — used to answer a real customer question today')],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
