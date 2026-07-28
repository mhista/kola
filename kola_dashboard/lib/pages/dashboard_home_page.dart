// dashboard_home_page.dart — the dashboard home shell built in Phase 4c
// (desktop sidebar + home content, mobile top bar + content + tab
// bar). Moved here from app.dart in Phase 4d once app.dart became the
// jaspr_router root for multiple pages.
//
// REAL DATA (this pass): this page was the last of the original
// Phase 4c/4d static-mock trio (alongside BotDetailChatPage/
// BotDetailDevPage) still showing Kola Dashboard Shell.dc.html's fixed
// illustrative content regardless of the actual signed-in workspace —
// deliberately deferred in Phase 4e since Errand Builder/Knowledge only
// ever needed accessToken+workspaceId, not this page. Now wired to:
//   - real workspace name/plan (Workspace.name/.plan, from app.dart's
//     selected workspace — no more "Aisha's Fashion House"/"Pro plan"),
//   - real signed-in user (AuthSession.email, for the greeting name and
//     avatar initial — no more "Aisha"/"A"),
//   - a real "Recent" list built from BotEndpoint.listBotsForWorkspace
//     instead of the four hardcoded RecentItem entries.
// "Conversations"/"Integrations" now point at real routes too —
// DEVELOPMENT_PLAN.md's own noted "still pending" items for Phase 4e,
// built this pass (see pages/conversations_page.dart,
// pages/integrations_page.dart). "Bots" (the sidebar NAV item) stays
// '#' — there's still no bot-LIST page, and Recent already surfaces
// the same bots. Bot CREATION is a separate, now-real path (task #114,
// Phase 5): the "Create a new bot" quick action below and
// SidebarNav's own "+ New Bot" CTA both point at /bots/new
// (CreateBotPage) instead of a design-tool-only .dc.html reference.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/sidebar_nav.dart';
import '../components/home_content.dart';
import '../components/mobile_top_bar.dart';
import '../components/mobile_home_content.dart';
import '../components/bottom_tab_bar.dart';
import '../models/nav_item.dart';
import '../models/recent_item.dart';
import '../models/quick_action.dart';
import '../config/env.dart';

class DashboardHomePage extends StatefulComponent {
  const DashboardHomePage({
    required this.client,
    required this.accessToken,
    required this.workspace,
    required this.userEmail,
    required this.onSignOut,
    required this.workspaces,
    required this.onWorkspaceSwitch,
  });

  final Client client;
  final String accessToken;
  final Workspace workspace;
  final String? userEmail;
  final void Function() onSignOut;

  /// Every workspace the signed-in user belongs to, and the switch
  /// handler — task #131 / Phase 8d. Threaded straight through to
  /// SidebarNav/MobileTopBar, which are the only two components that
  /// actually render the switcher UI; this page doesn't otherwise touch
  /// either.
  final List<Workspace> workspaces;
  final void Function(Workspace) onWorkspaceSwitch;

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  // Mirrors navDefs. "API & Webhooks" and "Team" still have no backing
  // endpoint (no member-invite endpoint exists), so each stays '#'
  // rather than a link to a page with nothing real to show. "Bots"
  // (task #139) and "Billing" (task #139/#8d) are both now real pages —
  // BotsPage reuses the same listBotsForWorkspace call this page's own
  // Recent list already made; BillingPage reads the new
  // WorkspaceEndpoint.getBillingSummary.
  static const _navItems = [
    NavItem(icon: '🏠', label: 'Home', href: '/', active: true),
    NavItem(icon: '🤖', label: 'Bots', href: '/bots'),
    NavItem(icon: '⚡', label: 'Errands', href: '/errands'),
    NavItem(icon: '📚', label: 'Knowledge', href: '/knowledge'),
    NavItem(icon: '💬', label: 'Conversations', href: '/conversations'),
    NavItem(icon: '🔌', label: 'Integrations', href: '/integrations'),
    NavItem(icon: '🔑', label: 'API & Webhooks', href: '#'),
    NavItem(icon: '👥', label: 'Team', href: '#'),
    NavItem(icon: '💳', label: 'Billing', href: '/billing'),
    // TASK #138 — owner: "the doc page, I have not seen it, a user
    // should be able to move from the dashboard to the doc page."
    // sidebar_nav.dart's `_link` renders this as a plain target="_blank"
    // anchor (not a jaspr_router Link, since kola_docs is a separate
    // deployed app, not a route inside this one) — see Env.kolaDocsUrl.
    // Env.kolaDocsUrl is itself a const (String.fromEnvironment), so this
    // whole list stays const.
    NavItem(icon: '📖', label: 'Docs', href: Env.kolaDocsUrl),
  ];

  static const _quickActions = [
    // Added task #114 — mirrors SidebarNav's own "+ New Bot" CTA so
    // mobile (which has no sidebar) has an equally direct path to
    // CreateBotPage, not just desktop.
    QuickAction(
      icon: '🤖',
      label: 'Create a new bot',
      sub: 'Give it a name and a purpose',
      href: '/bots/new',
      colorIndex: 0,
    ),
    QuickAction(
      icon: '⚡',
      label: 'Create a new Errand',
      sub: 'Teach kola a new task',
      href: '/errands',
      colorIndex: 0,
    ),
    QuickAction(
      icon: '📚',
      label: 'Upload knowledge',
      sub: 'Price lists, FAQs, docs',
      href: '/knowledge',
      colorIndex: 1,
    ),
    QuickAction(
      icon: '🔌',
      label: 'Connect a channel',
      sub: 'WhatsApp or Telegram',
      href: '/integrations',
      colorIndex: 2,
    ),
    QuickAction(
      icon: '💬',
      label: "This week's conversations",
      sub: 'See what customers are asking',
      href: '/conversations',
      colorIndex: 3,
    ),
  ];

  List<Bot>? _bots;
  bool get _loading => _bots == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bots = await component.client.bot.listBotsForWorkspace(
        component.accessToken,
        component.workspace.id!,
      );
      if (mounted) setState(() => _bots = bots);
    } catch (_) {
      // A failed fetch and a genuinely bot-less workspace look the same
      // from here — both render the empty state below. Not distinguishing
      // them is a real gap, flagged rather than silently guessed at, same
      // posture as app.dart's own _loadWorkspaces.
      if (mounted) setState(() => _bots = const []);
    }
  }

  /// Real "Recent" entries, built from this workspace's actual bots
  /// (newest first) — replaces Phase 4c/4d's four hardcoded RecentItem
  /// mock rows. Each links to that bot's real Chat Mode page.
  List<RecentItem> get _recentItems {
    final bots = _bots ?? const <Bot>[];
    final sorted = [...bots]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [
      for (final bot in sorted.take(6))
        RecentItem(icon: _archetypeIcon(bot.archetype), label: bot.name, href: '/bots/${bot.id}'),
    ];
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

  String get _greetingName {
    final email = component.userEmail;
    if (email == null || email.isEmpty) return 'there';
    final local = email.split('@').first;
    if (local.isEmpty) return 'there';
    return local[0].toUpperCase() + local.substring(1);
  }

  String get _avatarInitial {
    final name = _greetingName;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get _workspacePlanLabel {
    final plan = component.workspace.plan;
    if (plan.isEmpty) return 'Free plan';
    return '${plan[0].toUpperCase()}${plan.substring(1)} plan';
  }

  @override
  Component build(BuildContext context) {
    final recentItems = _recentItems;

    return div(
      [
        // ── Desktop layout ────────────────────────────────────────────
        div(
          classes: 'kola-dash-desktop',
          attributes: {'style': 'position:relative;width:100%;height:100vh;overflow:hidden'},
          [
            SidebarNav(
              navItems: _navItems,
              recentItems: recentItems,
              workspaceName: component.workspace.name,
              workspacePlan: _workspacePlanLabel,
              avatarInitial: _avatarInitial,
              onSignOut: component.onSignOut,
              workspaces: component.workspaces,
              selectedWorkspaceId: component.workspace.id,
              onWorkspaceSwitch: component.onWorkspaceSwitch,
              recentEmptyLabel: _loading ? 'Loading bots…' : 'No bots yet',
            ),
            HomeContent(
              greetingName: _greetingName,
              quickActions: _quickActions,
              client: component.client,
              accessToken: component.accessToken,
              workspaceId: component.workspace.id!,
            ),
          ],
        ),

        // ── Mobile layout ─────────────────────────────────────────────
        div(
          classes: 'kola-dash-mobile',
          attributes: {
            'style': 'flex-direction:column;height:100vh;overflow:hidden;box-sizing:border-box',
          },
          [
            MobileTopBar(
              avatarInitial: _avatarInitial,
              onSignOut: component.onSignOut,
              workspaces: component.workspaces,
              selectedWorkspaceId: component.workspace.id,
              onWorkspaceSwitch: component.onWorkspaceSwitch,
            ),
            MobileHomeContent(
              greetingName: _greetingName,
              quickActions: _quickActions,
              client: component.client,
              accessToken: component.accessToken,
              workspaceId: component.workspace.id!,
            ),
            const BottomTabBar(),
          ],
        ),
      ],
    );
  }
}
