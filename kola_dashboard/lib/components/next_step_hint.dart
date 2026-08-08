// next_step_hint.dart — one suggested next action, chosen from what the
// workspace is actually missing.
//
// ── WHY NOT A MARQUEE, A TOAST, OR A NOTIFICATION ────────────────────
//
// A marquee moves text the reader is trying to read, and is unusable for
// anyone with a reading or vestibular difficulty. A toast disappears
// before a distracted shop owner has finished the sentence, and cannot
// be recovered. A notification competes with real notifications —
// escalations, overdue invoices — and teaches people to dismiss the
// channel that matters most.
//
// So: a quiet inline card, in the flow of the page, dismissible, and
// gone for good once the thing it suggests is done. It cannot be missed
// and it cannot nag.
//
// ── IT SUGGESTS ONE THING, NOT A CHECKLIST ───────────────────────────
//
// Rules are evaluated in order and the FIRST unmet one wins. A list of
// five things to do is a list nobody starts; one clear next action is
// one somebody finishes. The order below is dependency order — teaching
// kola nothing is worse than having no channel connected, because
// without knowledge even a connected bot answers badly.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../theme.dart';
import 'shell/icons.dart';
import 'shell/kola_icon.dart';

class NextStep {
  const NextStep({
    required this.id,
    required this.title,
    required this.body,
    required this.cta,
    required this.route,
    required this.icon,
  });

  /// Stable key, used to remember a dismissal. Deliberately not the
  /// title — copy gets edited, and an edit should not resurrect a hint
  /// somebody already dismissed.
  final String id;

  final String title;
  final String body;
  final String cta;
  final String route;
  final String icon;
}

abstract class NextSteps {
  /// Picks the highest-priority unmet step, or null when there is
  /// nothing useful to suggest.
  ///
  /// Every argument is a fact about the workspace, not a guess. A hint
  /// that suggests something already done is worse than no hint — it
  /// says the product is not paying attention.
  static NextStep? choose({
    required bool hasBot,
    required bool hasDocuments,
    required bool hasConversations,
    required bool commerceEnabled,
    required bool hasProducts,
    required Set<String> dismissed,
  }) {
    final candidates = <NextStep>[
      if (!hasBot)
        const NextStep(
          id: 'create-bot',
          title: 'Create your first bot',
          body: 'Nothing can answer customers until one exists. It takes a '
              'sentence describing what you sell.',
          cta: 'Create a bot',
          route: '/bots/new',
          icon: Icons.bot,
        ),
      if (!hasDocuments)
        const NextStep(
          id: 'teach-kola',
          title: 'Teach kola about the business',
          body: 'Right now it has nothing of yours to cite, so it can only '
              'give general answers. One price list or returns policy '
              'changes that immediately.',
          cta: 'Add knowledge',
          route: '/knowledge',
          icon: Icons.book,
        ),
      if (commerceEnabled && !hasProducts)
        const NextStep(
          id: 'add-products',
          title: 'Add what you sell',
          body: 'With a catalog, kola can quote prices and check stock in a '
              'conversation instead of passing every question to you.',
          cta: 'Open catalog',
          route: '/catalog',
          icon: Icons.catalog,
        ),
      if (hasBot && hasDocuments && !hasConversations)
        const NextStep(
          id: 'test-memory',
          title: 'Check what kola would say',
          body: 'Before a customer asks, ask it yourself. The memory '
              'inspector shows the exact passage it would answer from.',
          cta: 'Open the inspector',
          route: '/knowledge',
          icon: Icons.sparkles,
        ),
    ];

    for (final c in candidates) {
      if (!dismissed.contains(c.id)) return c;
    }
    return null;
  }
}

class NextStepHint extends StatelessComponent {
  const NextStepHint({required this.step, required this.onDismiss});

  final NextStep step;
  final void Function(String id) onDismiss;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        // role=note, not alert. An alert interrupts a screen reader
        // mid-sentence, and this is a suggestion — it is never urgent
        // enough to talk over something the user is already reading.
        'role': 'note',
        'style': 'display:flex;gap:12px;align-items:flex-start;'
            'background:${KolaVar.tintSurface(0)};'
            'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:14px 16px',
      },
      [
        div(
          attributes: {
            'style': 'flex:none;width:30px;height:30px;'
                'border-radius:${KolaRadius.circle};'
                'background:${KolaVar.tintIcon(0)};color:${KolaVar.accent};'
                'display:flex;align-items:center;justify-content:center',
          },
          [kolaIcon(step.icon, size: 15)],
        ),
        div(
          attributes: {'style': 'flex:1;min-width:0'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                    'color:${KolaVar.text};margin-bottom:3px',
              },
              [Component.text(step.title)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.mutedStrong};'
                    'line-height:1.5;margin-bottom:10px',
              },
              [Component.text(step.body)],
            ),
            div(
              attributes: {
                'style': 'display:flex;gap:8px;align-items:center;flex-wrap:wrap',
              },
              [
                Link(
                  to: step.route,
                  attributes: {
                    'class': 'kola-pressable',
                    'style': 'background:${KolaVar.accentFill};'
                        'color:${KolaVar.accentText};'
                        'border-radius:${KolaRadius.pill};padding:7px 15px;'
                        'font-size:${KolaType.micro};font-weight:600;'
                        'text-decoration:none',
                  },
                  children: [Component.text(step.cta)],
                ),
                button(
                  attributes: {
                    'class': 'kola-pressable',
                    'type': 'button',
                    'style': 'background:transparent;border:none;'
                        'color:${KolaVar.muted};font-family:inherit;'
                        'font-size:${KolaType.micro};font-weight:600',
                  },
                  events: {'click': (_) => onDismiss(step.id)},
                  [Component.text('Not now')],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
