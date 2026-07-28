// bots_page.dart — task #139 (dashboard polish pass): the sidebar's
// "Bots" nav item has been a '#' placeholder since Phase 4c because
// there was no dedicated bot-LIST page — DashboardHomePage's "Recent"
// list only ever showed the newest 6, and existed to link somewhere
// useful, not to be a full inventory. This is that missing page: every
// bot in the workspace, one row each, with its lifecycle status and a
// direct link into both of its detail views.
//
// NOTHING NEW SERVER-SIDE: BotEndpoint.listBotsForWorkspace already
// exists (dashboard_home_page.dart's own _load already calls it) — this
// page is a pure UI gap-fill, not new backend work. Deliberately NOT
// touching Team/Billing/API & Webhooks in this same pass — those three
// have no backing endpoint at all yet (no member-invite endpoint, no
// billing/subscription-summary endpoint), so building a page for them
// now would be "UI with no real backend behind it," the exact mistake
// this project has caught and fixed before. They stay '#' until that
// backend work happens; flagged to the owner rather than silently
// stubbed.
//
// STANDALONE PAGE, NO SIDEBAR: matches every other page reachable from
// a real nav link (errand_builder_page.dart, knowledge_page.dart,
// conversations_page.dart, integrations_page.dart) — full-width content
// with a "← Home" link, not a second copy of SidebarNav. DashboardHomePage
// is the only page that renders the sidebar itself.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/back_link.dart';

class BotsPage extends StatefulComponent {
  const BotsPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<BotsPage> createState() => _BotsPageState();
}

class _BotsPageState extends State<BotsPage> {
  List<Bot>? _bots;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bots = await component.client.bot.listBotsForWorkspace(
        component.accessToken,
        component.workspaceId,
      );
      if (mounted) setState(() => _bots = bots);
    } catch (_) {
      if (mounted) setState(() => _loadError = "Couldn't load your bots. Check your connection and try again.");
    }
  }

  static String _archetypeIcon(String archetype) {
    switch (archetype) {
      case 'catalog':
        return '📦';
      case 'customerCare':
        return '🤖';
      default:
        return '⚙️';
    }
  }

  static String _archetypeLabel(String archetype) {
    switch (archetype) {
      case 'catalog':
        return 'Catalog';
      case 'customerCare':
        return 'Customer care';
      default:
        return 'Custom';
    }
  }

  static (String, String, String) _statusChip(String status) {
    // (dot color, text color, label) — mirrors errand_builder_page.dart's
    // Live/Disabled chip styling, extended with a third state since a
    // Bot has one more lifecycle stage (draft) than an Errand does.
    switch (status) {
      case 'live':
        return ('#7ED8B0', '#7ED8B0', 'Live');
      case 'paused':
        return ('#E0B168', '#E0B168', 'Paused');
      default:
        return (KolaDashboardColors.muted, KolaDashboardColors.mutedSecondary, 'Draft');
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};"
            'color:${KolaDashboardColors.text};width:100%;height:100vh;overflow-y:auto;box-sizing:border-box;'
            'padding:40px 32px 60px;display:flex;justify-content:center',
      },
      [
        div(
          attributes: {'style': 'max-width:900px;width:100%'},
          [
            div(
              attributes: {'style': 'margin-bottom:20px'},
              [backLink()],
            ),
            div(
              attributes: {
                'style': 'display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:24px;gap:16px',
              },
              [
                div([
                  div(
                    attributes: {
                      'style': "font-family:${KolaDashboardFonts.display};font-size:22px;font-weight:700;margin-bottom:6px",
                    },
                    [Component.text('Bots')],
                  ),
                  div(
                    attributes: {
                      'style': 'font-size:14px;color:${KolaDashboardColors.mutedSecondary};line-height:1.5;max-width:520px',
                    },
                    [Component.text('Every bot in this workspace, in one place.')],
                  ),
                ]),
                Link(
                  to: '/bots/new',
                  attributes: {
                    'style':
                        'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                        'border:none;border-radius:100px;padding:10px 18px;font-size:13.5px;font-weight:600;'
                        'text-decoration:none;white-space:nowrap',
                  },
                  child: Component.text('+ New Bot'),
                ),
              ],
            ),
            div(
              attributes: {
                'style':
                    'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
                    'border-radius:18px;overflow:hidden',
              },
              [_content()],
            ),
          ],
        ),
      ],
    );
  }

  Component _content() {
    if (_loadError != null) return _emptyState(_loadError!);
    final bots = _bots;
    if (bots == null) return _emptyState('Loading…');
    if (bots.isEmpty) {
      return _emptyState("No bots yet — create your first one to get started.");
    }
    final sorted = [...bots]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return div(
      attributes: {'style': 'display:flex;flex-direction:column'},
      [for (final bot in sorted) _botRow(bot)],
    );
  }

  Component _emptyState(String text) => div(
    attributes: {
      'style': 'padding:40px 20px;text-align:center;color:${KolaDashboardColors.muted};font-size:13.5px',
    },
    [Component.text(text)],
  );

  Component _botRow(Bot bot) {
    final (dotColor, textColor, label) = _statusChip(bot.status);
    return div(
      attributes: {
        'style':
            'display:flex;align-items:center;gap:14px;padding:16px 20px;border-bottom:1px solid ${KolaDashboardColors.pill}',
      },
      [
        div(
          attributes: {
            'style':
                'width:38px;height:38px;border-radius:10px;background:${KolaDashboardColors.pill};'
                'display:flex;align-items:center;justify-content:center;font-size:18px;flex:none',
          },
          [Component.text(_archetypeIcon(bot.archetype))],
        ),
        div(
          attributes: {'style': 'min-width:0;flex:1'},
          [
            div(attributes: {'style': 'font-size:14.5px;font-weight:600;margin-bottom:2px'}, [Component.text(bot.name)]),
            div(
              attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary}'},
              [Component.text(_archetypeLabel(bot.archetype))],
            ),
          ],
        ),
        div(
          attributes: {
            'style':
                'display:flex;align-items:center;gap:6px;background:${KolaDashboardColors.pill};'
                'border:1px solid ${KolaDashboardColors.border};border-radius:100px;padding:5px 11px;flex:none',
          },
          [
            span(attributes: {'style': 'width:6px;height:6px;border-radius:50%;background:$dotColor'}, []),
            span(
              attributes: {'style': 'font-size:11.5px;color:$textColor;font-weight:600'},
              [Component.text(label)],
            ),
          ],
        ),
        Link(
          to: '/bots/${bot.id}',
          attributes: {
            'style':
                'background:transparent;border:1px solid ${KolaDashboardColors.border};'
                'color:${KolaDashboardColors.navInactiveText};border-radius:100px;padding:6px 13px;'
                'font-size:12.5px;text-decoration:none;flex:none',
          },
          child: Component.text('Open chat'),
        ),
        Link(
          to: '/bots/${bot.id}/code',
          attributes: {
            'style':
                'background:transparent;border:1px solid ${KolaDashboardColors.border};'
                'color:${KolaDashboardColors.navInactiveText};border-radius:100px;padding:6px 13px;'
                'font-size:12.5px;text-decoration:none;flex:none',
          },
          child: Component.text('Dev view'),
        ),
      ],
    );
  }
}
