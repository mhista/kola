// chat_suggestions.dart — the row of quick-reply pills above Chat
// Mode's composer, matching Kola Bot Detail Chat.dc.html's suggestions.
// Inert in this shell pass (no click handler wired — there's no AI
// conversation loop yet to feed a suggestion into).

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class ChatSuggestions extends StatelessComponent {
  const ChatSuggestions({required this.suggestions});

  final List<String> suggestions;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'style': 'display:flex;gap:8px;flex-wrap:wrap;margin:16px 0'},
      [
        for (final s in suggestions)
          div(
            attributes: {
              'style':
                  'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
                  'border-radius:100px;padding:8px 14px;font-size:13px;color:${KolaDashboardColors.navInactiveText}',
            },
            [Component.text(s)],
          ),
      ],
    );
  }
}
