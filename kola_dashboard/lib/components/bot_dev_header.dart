// bot_dev_header.dart — Structured Mode's top bar: bot icon/name/mono
// id, "Switch to Chat Mode" (real Link back to /bots/:id), Publish
// (inert). Deliberately no "← Dashboard" link — Kola Bot Detail
// Dev.dc.html's header doesn't have one either; going back to the
// dashboard from here means going through Chat Mode first, matching
// the design source exactly rather than adding a shortcut it didn't
// specify.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import '../theme.dart';
import '../models/bot_summary.dart';

class BotDevHeader extends StatelessComponent {
  const BotDevHeader({required this.bot});

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
                'style': 'font-family:${KolaDashboardFonts.mono};font-size:12px;color:${KolaDashboardColors.muted}',
              },
              [Component.text(bot.id)],
            ),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:16px'},
          [
            Link(
              to: '/bots/${bot.id}',
              attributes: {
                'style': 'color:${KolaDashboardColors.mutedSecondary};font-size:13.5px;text-decoration:none',
              },
              children: [Component.text('Switch to Chat Mode')],
            ),
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
