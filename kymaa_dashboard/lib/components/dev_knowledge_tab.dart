// dev_knowledge_tab.dart — Structured Mode's Knowledge tab: a document
// grid + a link out to the full Knowledge Base page. Matches Kola Bot
// Detail Dev.dc.html's layout, but [docs] now reflects real data: the
// real backend has exactly one knowledge field per bot
// (Bot.knowledgeSeed — see knowledge_page.dart's header for why there's
// no real multi-document upload system), so BotDetailDevPage passes a
// single real entry describing that field's actual state rather than
// Phase 4c/4d's illustrative multi-document grid. "Full Knowledge Base →"
// is now a real router Link — /knowledge exists as of Phase 4e.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import '../theme.dart';
import '../models/knowledge_doc_summary.dart';

class DevKnowledgeTab extends StatelessComponent {
  const DevKnowledgeTab({required this.docs});

  final List<KnowledgeDocSummary> docs;

  @override
  Component build(BuildContext context) {
    return div(
      [
        Link(
          to: '/knowledge',
          attributes: {
            'style':
                'color:${KolaDashboardColors.mutedSecondary};text-decoration:none;font-size:13.5px;'
                'display:inline-block;margin-bottom:16px',
          },
          children: [Component.text('Full Knowledge Base →')],
        ),
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:repeat(3,1fr);gap:14px;max-width:900px',
          },
          [
            for (final d in docs)
              div(
                attributes: {
                  'style':
                      'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
                      'border-radius:12px;padding:16px',
                },
                [
                  div(attributes: {'style': 'font-size:20px;margin-bottom:8px'}, [Component.text(d.icon)]),
                  div(attributes: {'style': 'font-size:13.5px;font-weight:600'}, [Component.text(d.name)]),
                  div(
                    attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.muted};margin-top:4px'},
                    [Component.text(d.status)],
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
