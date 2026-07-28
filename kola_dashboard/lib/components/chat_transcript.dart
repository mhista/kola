// chat_transcript.dart — the scrolling bot/user message list on Chat
// Mode's left pane, matching Kola Bot Detail Chat.dc.html's transcript
// exactly, including its three bubble variants (plain, checklist,
// imageCard). Bot messages use a fixed '✳' avatar on
// KolaDashboardColors.navActiveBg-adjacent green (#1F6F54, the design's
// own literal — distinct from any existing token, so kept as a literal
// here rather than forcing it into an unrelated shared token); user
// messages reuse the accent/accentText pair already used everywhere
// else for the business's own voice.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../models/chat_message.dart';

class ChatTranscript extends StatelessComponent {
  const ChatTranscript({required this.messages});

  final List<ChatMessage> messages;

  static const _botAvatarBg = '#1F6F54';

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'flex:1;min-height:0;display:flex;flex-direction:column;gap:14px;overflow-y:auto',
      },
      [for (final msg in messages) _bubble(msg)],
    );
  }

  Component _bubble(ChatMessage msg) {
    final avatarBg = msg.fromUser ? KolaDashboardColors.avatarBg : _botAvatarBg;
    final avatar = msg.fromUser ? 'A' : '✳';
    final bubbleBg = msg.fromUser ? KolaDashboardColors.accent : KolaDashboardColors.card;
    final bubbleColor = msg.fromUser ? KolaDashboardColors.accentText : KolaDashboardColors.text;

    return div(
      attributes: {
        'style':
            'display:flex;gap:10px;align-self:${msg.fromUser ? "flex-end" : "flex-start"};'
            'max-width:88%;flex-direction:${msg.fromUser ? "row-reverse" : "row"}',
      },
      [
        div(
          attributes: {
            'style':
                'width:28px;height:28px;border-radius:8px;background:$avatarBg;display:flex;'
                'align-items:center;justify-content:center;font-size:13px;flex-shrink:0;'
                'color:${KolaDashboardColors.text}',
          },
          [Component.text(avatar)],
        ),
        div(
          attributes: {
            'style':
                'background:$bubbleBg;color:$bubbleColor;padding:12px 15px;border-radius:14px;'
                'font-size:14.5px;line-height:1.55',
          },
          [_content(msg)],
        ),
      ],
    );
  }

  Component _content(ChatMessage msg) {
    switch (msg.variant) {
      case ChatMessageVariant.plain:
        return Component.text(msg.text);

      case ChatMessageVariant.checklist:
        return div(
          [
            div(
              attributes: {'style': 'font-size:14px;font-weight:600;margin-bottom:8px'},
              [Component.text(msg.text)],
            ),
            for (final item in msg.items)
              div(
                attributes: {'style': 'display:flex;align-items:center;gap:8px;padding:5px 0'},
                [
                  div(
                    attributes: {
                      'style':
                          'width:16px;height:16px;border-radius:4px;background:#2F8F6D;display:flex;'
                          'align-items:center;justify-content:center;font-size:10px;flex-shrink:0',
                    },
                    [Component.text('✓')],
                  ),
                  span(attributes: {'style': 'font-size:13.5px'}, [Component.text(item)]),
                ],
              ),
          ],
        );

      case ChatMessageVariant.imageCard:
        return div(
          [
            div(
              attributes: {'style': 'font-size:14px;margin-bottom:10px'},
              [Component.text(msg.text)],
            ),
            div(
              attributes: {
                'style':
                    'background:#0000002e;border:1px dashed #4A443F;border-radius:10px;padding:14px;'
                    'display:flex;align-items:center;gap:10px',
              },
              [
                div(
                  attributes: {
                    'style':
                        'width:36px;height:36px;border-radius:8px;background:#2A2622;display:flex;'
                        'align-items:center;justify-content:center;font-size:15px',
                  },
                  [Component.text('🖼')],
                ),
                span(
                  attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.mutedStrong}'},
                  [Component.text(msg.imageLabel ?? '')],
                ),
              ],
            ),
          ],
        );
    }
  }
}
