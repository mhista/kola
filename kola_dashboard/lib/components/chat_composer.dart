// chat_composer.dart — Chat Mode's single-row message input, matching
// Kola Bot Detail Chat.dc.html's composer. Distinct from the
// dashboard-home Composer (composer.dart) — that one has the 📎/⚡ pill
// icon row and a 2-row textarea for starting something new; this one
// is a plain single-row "reply to the bot" input, visually simpler by
// design. Inert send button — no AI conversation loop wired yet.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class ChatComposer extends StatelessComponent {
  const ChatComposer();

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:16px;padding:14px 16px;display:flex;gap:10px;align-items:flex-end',
      },
      [
        Component.element(
          tag: 'textarea',
          attributes: {
            'placeholder': 'Tell kolaa what to change...',
            'rows': '1',
            'style':
                'flex:1;border:none;outline:none;resize:none;background:transparent;'
                'color:${KolaDashboardColors.text};font-family:${KolaDashboardFonts.sans};font-size:14.5px',
          },
          children: const [],
        ),
        div(
          attributes: {
            'style':
                'width:32px;height:32px;border-radius:50%;background:${KolaDashboardColors.accent};'
                'display:flex;align-items:center;justify-content:center;flex-shrink:0;'
                'color:${KolaDashboardColors.accentText}',
          },
          [Component.text('→')],
        ),
      ],
    );
  }
}
