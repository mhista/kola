// bot_chat_header.dart — Chat Mode's top bar: "← Dashboard" back link,
// bot icon/name/archetype badge, Plan/Code mode tabs (Code is a real
// Link to Structured Mode at /bots/:id/code — the toggle SRS.md §11
// calls for), ↺/Share (inert, no undo history or sharing exists yet),
// Publish (inert, no publish pipeline yet). Matches Kola Bot Detail
// Chat.dc.html's header exactly.
//
// "Keeps the object you were editing selected" (SRS.md §11) doesn't
// apply yet — there's no editable state to lose in this static shell
// pass. Once Structured Mode's errand selection is real state (not
// mock), the Link's `extra` param or a shared bit of route state is
// where that context would be threaded through.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import '../theme.dart';
import '../models/bot_summary.dart';
import 'back_link.dart';

class BotChatHeader extends StatelessComponent {
  const BotChatHeader({required this.bot});

  final BotSummary bot;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            'display:flex;align-items:center;justify-content:space-between;padding:14px 24px;'
            'border-bottom:1px solid ${KolaDashboardColors.border}',
      },
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:12px'},
          [
            backLink(label: 'Dashboard'),
            div(
              attributes: {
                'style':
                    'width:34px;height:34px;border-radius:9px;background:${bot.iconBg};'
                    'display:flex;align-items:center;justify-content:center;font-size:16px',
              },
              [Component.text(bot.icon)],
            ),
            div(
              attributes: {
                'style': 'font-family:${KolaDashboardFonts.display};font-size:16px;font-weight:600',
              },
              [Component.text(bot.name)],
            ),
            span(
              attributes: {
                'style':
                    'background:${KolaDashboardColors.navActiveBg};color:#E9A87C;font-size:11.5px;'
                    'font-weight:600;padding:4px 10px;border-radius:100px',
              },
              [Component.text(bot.archetypeLabel)],
            ),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:20px'},
          [
            div(
              attributes: {
                'style': 'display:flex;gap:20px;font-size:14px;color:${KolaDashboardColors.mutedSecondary}',
              },
              [
                span(
                  attributes: {
                    'style':
                        'color:${KolaDashboardColors.text};border-bottom:2px solid ${KolaDashboardColors.accent};'
                        'padding-bottom:4px',
                  },
                  [Component.text('Plan')],
                ),
                Link(
                  to: '/bots/${bot.id}/code',
                  attributes: {'style': 'color:${KolaDashboardColors.mutedSecondary};text-decoration:none'},
                  children: [Component.text('Code')],
                ),
              ],
            ),
            span(attributes: {'style': 'color:${KolaDashboardColors.mutedSecondary}'}, [Component.text('↺')]),
            span(attributes: {'style': 'color:${KolaDashboardColors.mutedSecondary}'}, [Component.text('Share')]),
            div(
              attributes: {
                'style':
                    'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                    'border:none;border-radius:9px;padding:9px 18px;font-size:14px;font-weight:600',
              },
              [Component.text('Publish')],
            ),
          ],
        ),
      ],
    );
  }
}
