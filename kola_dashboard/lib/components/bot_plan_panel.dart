// bot_plan_panel.dart — Chat Mode's right pane: desktop/mobile preview
// toggle icons (inert — no separate mobile preview render exists yet,
// unlike the real dashboard's own desktop/mobile CSS switch), the bot
// summary card (name/archetype/channels + its Errand list), and the
// WhatsApp live preview. Matches Kola Bot Detail Chat.dc.html's right
// column exactly.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../models/bot_summary.dart';
import '../models/errand_chat_summary.dart';
// Needed directly for the ErrandStatusColors extension's .bg/.color
// getters used below — importing errand_chat_summary.dart (which
// itself imports this) is NOT enough, Dart requires an extension's
// declaring library to be imported into whichever file calls it.
import '../models/errand_status.dart';
import '../models/preview_message.dart';
import 'whatsapp_preview.dart';

class BotPlanPanel extends StatelessComponent {
  const BotPlanPanel({
    required this.bot,
    required this.errands,
    required this.workspaceName,
    required this.avatarInitial,
    required this.previewMessages,
  });

  final BotSummary bot;
  final List<ErrandChatSummary> errands;
  final String workspaceName;
  final String avatarInitial;
  final List<PreviewMessage> previewMessages;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'style': 'padding:24px;box-sizing:border-box;overflow-y:auto;min-height:0'},
      [
        div(
          attributes: {'style': 'display:flex;justify-content:flex-end;gap:8px;margin-bottom:18px'},
          [_previewToggleIcon('🖥️'), _previewToggleIcon('📱')],
        ),

        div(
          attributes: {
            'style':
                'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
                'border-radius:18px;padding:22px;margin-bottom:18px',
          },
          [
            div(
              attributes: {'style': 'font-size:13px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:6px'},
              [Component.text('BOT')],
            ),
            div(
              attributes: {
                'style': 'font-family:${KolaDashboardFonts.display};font-size:18px;font-weight:600;margin-bottom:4px',
              },
              [Component.text(bot.name)],
            ),
            div(
              attributes: {'style': 'font-size:13.5px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:16px'},
              [Component.text('Archetype: ${bot.archetypeLabel} · Channels: ${bot.channelsLabel}')],
            ),
            div(
              attributes: {
                'style':
                    'font-size:12.5px;letter-spacing:0.05em;text-transform:uppercase;'
                    'color:${KolaDashboardColors.muted};margin-bottom:10px',
              },
              [Component.text('Errands')],
            ),
            for (final e in errands)
              div(
                attributes: {
                  'style':
                      'display:flex;align-items:center;justify-content:space-between;padding:10px 0;'
                      'border-top:1px solid #241F1B',
                },
                [
                  div(attributes: {'style': 'font-size:14px'}, [Component.text(e.name)]),
                  div(
                    attributes: {
                      'style':
                          'font-size:11.5px;font-weight:600;padding:3px 10px;border-radius:100px;'
                          'background:${e.status.bg};color:${e.status.color}',
                    },
                    [Component.text(e.statusLabel)],
                  ),
                ],
              ),
          ],
        ),

        WhatsAppPreview(
          workspaceName: workspaceName,
          avatarInitial: avatarInitial,
          messages: previewMessages,
        ),
      ],
    );
  }

  Component _previewToggleIcon(String icon) => div(
    attributes: {
      'style':
          'width:32px;height:32px;border-radius:9px;background:${KolaDashboardColors.card};'
          'border:1px solid ${KolaDashboardColors.border};display:flex;align-items:center;justify-content:center',
    },
    [Component.text(icon)],
  );
}
