// dev_overview_tab.dart — Structured Mode's Overview tab: stats grid +
// configuration summary row, matching Kola Bot Detail Dev.dc.html
// exactly. Static text for the config line in this shell pass — real
// data (actual archetype/channels/model/fallback) comes from the
// Bot record itself once kola_client wiring exists.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../models/overview_stat.dart';

class DevOverviewTab extends StatelessComponent {
  const DevOverviewTab({required this.stats, required this.configSummary});

  final List<OverviewStat> stats;
  final String configSummary;

  @override
  Component build(BuildContext context) {
    return div(
      [
        div(
          attributes: {
            'style':
                'display:grid;grid-template-columns:repeat(3,1fr);gap:16px;max-width:900px;'
                'margin-bottom:24px',
          },
          [
            for (final s in stats)
              div(
                attributes: {
                  'style':
                      'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
                      'border-radius:14px;padding:18px',
                },
                [
                  div(
                    attributes: {'style': 'font-size:13px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:8px'},
                    [Component.text(s.label)],
                  ),
                  div(
                    attributes: {
                      'style': 'font-family:${KolaDashboardFonts.display};font-size:24px;font-weight:600',
                    },
                    [Component.text(s.value)],
                  ),
                ],
              ),
          ],
        ),
        div(
          attributes: {
            'style':
                'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
                'border-radius:14px;padding:20px;max-width:900px',
          },
          [
            div(
              attributes: {
                'style':
                    'font-size:13px;color:${KolaDashboardColors.muted};text-transform:uppercase;'
                    'letter-spacing:0.04em;margin-bottom:12px',
              },
              [Component.text('Configuration')],
            ),
            div(
              attributes: {
                'style': 'font-size:14px;color:${KolaDashboardColors.navInactiveText};line-height:2',
              },
              [Component.text(configSummary)],
            ),
          ],
        ),
      ],
    );
  }
}
