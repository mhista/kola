// whatsapp_preview.dart — the WhatsApp-look phone mockup on Chat Mode's
// plan panel, matching Kola Bot Detail Chat.dc.html's preview pane
// exactly (colors are WhatsApp's own dark-theme palette, deliberately
// NOT pulled from KolaDashboardColors — this widget is impersonating a
// different app's UI on purpose, so its colors are kept as literals
// local to this file rather than forced into our own design tokens).
//
// Purely illustrative in this shell pass — [messages] is a fixed
// example conversation, not a real one. Once this reads an actual
// recent conversation (Phase 4e+, via kola_client), the component
// itself doesn't need to change — only what's passed into [messages].

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../models/preview_message.dart';

class WhatsAppPreview extends StatelessComponent {
  const WhatsAppPreview({
    required this.workspaceName,
    required this.avatarInitial,
    required this.messages,
  });

  final String workspaceName;
  final String avatarInitial;
  final List<PreviewMessage> messages;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'style': 'background:#1C1815;border-radius:20px;padding:16px'},
      [
        div(
          attributes: {
            'style':
                'background:#0B141A;border-radius:14px;overflow:hidden;'
                'background-image:radial-gradient(circle,rgba(255,255,255,0.035) 1px,transparent 1px);'
                'background-size:14px 14px',
          },
          [
            // ── Chat header ──────────────────────────────────────────
            div(
              attributes: {
                'style': 'background:#1F2C33;padding:11px 14px;display:flex;align-items:center;gap:9px',
              },
              [
                span(attributes: {'style': 'color:#8696A0;font-size:16px'}, [Component.text('‹')]),
                div(
                  attributes: {
                    'style':
                        'width:30px;height:30px;border-radius:50%;background:#2F8F6D;display:flex;'
                        'align-items:center;justify-content:center;color:#F3EEE7;font-size:13px;'
                        'font-weight:600;flex-shrink:0',
                  },
                  [Component.text(avatarInitial)],
                ),
                div(
                  attributes: {'style': 'flex:1;min-width:0'},
                  [
                    div(
                      attributes: {'style': 'font-size:13.5px;color:#F3EEE7;font-weight:600'},
                      [Component.text(workspaceName)],
                    ),
                    div(
                      attributes: {'style': 'font-size:11px;color:#8696A0'},
                      [Component.text('online')],
                    ),
                  ],
                ),
                span(attributes: {'style': 'color:#8696A0;font-size:14px'}, [Component.text('⋮')]),
              ],
            ),

            // ── Messages ──────────────────────────────────────────────
            div(
              attributes: {
                'style': 'padding:14px;display:flex;flex-direction:column;gap:8px;min-height:220px',
              },
              [for (final pm in messages) _bubble(pm)],
            ),

            // ── Input bar ─────────────────────────────────────────────
            div(
              attributes: {
                'style': 'background:#1F2C33;padding:9px 12px;display:flex;align-items:center;gap:9px',
              },
              [
                span(attributes: {'style': 'color:#8696A0;font-size:15px'}, [Component.text('😊')]),
                div(
                  attributes: {
                    'style':
                        'flex:1;background:#2A3942;border-radius:100px;padding:8px 13px;'
                        'font-size:12.5px;color:#8696A0',
                  },
                  [Component.text('Message')],
                ),
                div(
                  attributes: {
                    'style':
                        'width:30px;height:30px;border-radius:50%;background:#00A884;display:flex;'
                        'align-items:center;justify-content:center;color:#0B141A;font-size:13px;'
                        'flex-shrink:0',
                  },
                  [Component.text('🎤')],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Component _bubble(PreviewMessage pm) {
    final bg = pm.mine ? '#005C4B' : '#202C33';
    final radius = pm.mine ? '14px 14px 4px 14px' : '14px 14px 14px 4px';

    return div(
      attributes: {'style': 'align-self:${pm.mine ? "flex-end" : "flex-start"};max-width:82%'},
      [
        div(
          attributes: {
            'style': 'background:$bg;color:#E9EDEF;padding:8px 12px;border-radius:$radius;'
                'font-size:13px;line-height:1.4',
          },
          [
            Component.text(pm.text),
            div(
              attributes: {
                'style': 'display:flex;justify-content:flex-end;align-items:center;gap:4px;margin-top:3px',
              },
              [
                span(attributes: {'style': 'font-size:10px;color:#8696A0'}, [Component.text(pm.time)]),
                if (pm.mine)
                  span(attributes: {'style': 'font-size:10.5px;color:#53BDEB'}, [Component.text('✓✓')]),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
