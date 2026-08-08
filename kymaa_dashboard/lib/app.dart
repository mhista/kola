// app.dart — root component. Rewritten in Phase 4e from a StatelessComponent
// into a StatefulComponent: this is now where the real Supabase session,
// the kola_client Client, and the caller's selected Workspace all live,
// since jaspr_router's Route builders need live access to them (closures
// over `this`), not just static route params.
//
// AUTH/WORKSPACE GUARD: [_redirect] is the single place that decides
// "is this visitor allowed to see the page they asked for" — sends an
// unauthenticated visitor to /login, and an authenticated-but-
// workspace-less one to /create-workspace (the real first-write path,
// see WorkspaceEndpoint.createWorkspace's own doc comment). Everything
// past that gate assumes _session and _selectedWorkspace are non-null,
// which is why route builders below can safely use `!`.
//
// Routes (all real data as of this pass — see each page's own header
// for exactly what's wired vs. honestly placeholder where no backend
// exists yet):
//   /login             → LoginPage
//   /create-workspace  → CreateWorkspacePage
//   /                  → DashboardHomePage
//   /bots              → BotsPage               (task #139 — closes the
//                          sidebar's last-remaining bot-related '#' gap)
//   /billing           → BillingPage             (task #139/#8d — plan/
//                          trial/usage summary, cross-workspace when the
//                          caller belongs to more than one. Team/API &
//                          Webhooks stay '#', no backing endpoint exists
//                          for those yet)
//   /bots/new          → CreateBotPage
//   /bots/:id          → BotDetailChatPage
//   /bots/:id/code     → BotDetailDevPage
//   /errands           → ErrandBuilderPage
//   /knowledge         → KnowledgePage
//   /conversations     → ConversationsPage      (DEVELOPMENT_PLAN.md's
//                          own "still pending" Phase 4e item)
//   /integrations      → IntegrationsPage        (same)

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import 'config/env.dart';
import 'services/auth_service.dart';
import 'services/local_storage.dart';
import 'models/auth_session.dart';
import 'theme.dart';

import 'pages/dashboard_home_page.dart';
import 'pages/bots_page.dart';
import 'pages/billing_page.dart';
import 'pages/create_bot_page.dart';
import 'pages/bot_detail_chat_page.dart';
import 'pages/bot_detail_dev_page.dart';
import 'pages/login_page.dart';
import 'pages/create_workspace_page.dart';
import 'pages/errand_builder_page.dart';
import 'pages/knowledge_page.dart';
import 'pages/conversations_page.dart';
import 'pages/integrations_page.dart';

class DashboardApp extends StatefulComponent {
  const DashboardApp();

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  late final Client _client;
  late final AuthService _authService;

  AuthSession? _session;
  List<Workspace> _workspaces = const [];
  Workspace? _selectedWorkspace;

  // True only while restoreSession()/listMyWorkspaces() are resolving on
  // first load — kept separate from "not logged in" so the redirect
  // guard below never fires against a still-unknown auth state (which
  // would flash /login even for a visitor who turns out to have a
  // valid persisted session).
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _client = Client(Env.kolaServerUrl);
    _authService = AuthService();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final session = await _authService.restoreSession();
    if (session != null) {
      await _loadWorkspaces(session);
    }
    setState(() {
      _session = session;
      _bootstrapping = false;
    });
  }

  // Task #131 / Phase 8d — persists which workspace was last selected,
  // so a manual switch survives a page reload instead of _loadWorkspaces
  // always re-picking workspaces.first. Deliberately just an id, not the
  // full Workspace object — the fetched list is always the source of
  // truth for the object's own fields (name/plan/etc.); this is purely
  // "which one," same division of responsibility AuthSession/LocalStorage
  // already have for the session itself.
  static const _selectedWorkspaceIdKey = 'kola_selected_workspace_id';

  /// Populates [_workspaces]/[_selectedWorkspace] for a given session.
  /// If a workspace id was persisted from a prior manual switch (see
  /// [_handleWorkspaceSwitch]) AND it's still in the freshly-fetched
  /// list, that one wins; otherwise falls back to the original "just
  /// auto-select the first one" behavior — still correct for the
  /// zero-or-one-workspace case EndpointWorkspace.listMyWorkspaces' own
  /// doc comment describes, and now also correct for a returning
  /// multi-workspace user.
  Future<void> _loadWorkspaces(AuthSession session) async {
    try {
      final workspaces = await _client.workspace.listMyWorkspaces(session.accessToken);
      _workspaces = workspaces;

      final persistedId = int.tryParse(LocalStorage.getItem(_selectedWorkspaceIdKey) ?? '');
      Workspace? restored;
      if (persistedId != null) {
        for (final w in workspaces) {
          if (w.id == persistedId) {
            restored = w;
            break;
          }
        }
      }
      _selectedWorkspace = restored ?? (workspaces.isNotEmpty ? workspaces.first : null);
    } catch (_) {
      // A failed fetch and a genuinely zero-workspace account look the
      // same from here — both send the visitor to /create-workspace.
      // Not distinguishing them yet is a real gap, not an oversight;
      // flagged rather than silently "fixed" with a guess at the right
      // error UI.
      _workspaces = const [];
      _selectedWorkspace = null;
    }
  }

  void _handleAuthenticated(AuthSession session) {
    _loadWorkspaces(session).then((_) {
      if (mounted) setState(() => _session = session);
    });
  }

  void _handleWorkspaceCreated(Workspace workspace) {
    _persistSelectedWorkspaceId(workspace.id);
    setState(() {
      _workspaces = [..._workspaces, workspace];
      _selectedWorkspace = workspace;
    });
  }

  /// The one real handler behind the switcher UI in SidebarNav/
  /// MobileTopBar (task #131 / Phase 8d) — same shape as
  /// [_handleWorkspaceCreated]: persist, then setState so every route
  /// builder in [build] picks up the new `_selectedWorkspace!.id!`
  /// closure on next render. No server call needed — [workspace] is
  /// always one of the entries [_loadWorkspaces] already fetched (the
  /// dropdown can't offer anything else), so there's nothing left to
  /// verify.
  void _handleWorkspaceSwitch(Workspace workspace) {
    _persistSelectedWorkspaceId(workspace.id);
    setState(() => _selectedWorkspace = workspace);
  }

  void _persistSelectedWorkspaceId(int? id) {
    if (id == null) {
      LocalStorage.removeItem(_selectedWorkspaceIdKey);
    } else {
      LocalStorage.setItem(_selectedWorkspaceIdKey, id.toString());
    }
  }

  /// Clears the local session (AuthService.signOut() drops the persisted
  /// LocalStorage entry — see auth_service.dart) and resets workspace
  /// state, then relies on [_redirect] to send the now-unauthenticated
  /// visitor to /login on the next build. No call to kola_server is
  /// needed here — Supabase sessions aren't revoked server-side by this
  /// dashboard, only forgotten locally, same as any client that just
  /// stops sending a token.
  void _handleSignOut() {
    _authService.signOut();
    LocalStorage.removeItem(_selectedWorkspaceIdKey);
    setState(() {
      _session = null;
      _workspaces = const [];
      _selectedWorkspace = null;
    });
  }

  /// Shared by every route below that needs an avatar initial (Bot
  /// Detail Chat/Dev's plan panel today; DashboardHomePage derives its
  /// own copy the same way rather than importing this, since it's a
  /// three-line getter, not worth threading a shared util module for).
  String get _avatarInitial {
    final email = _session?.email;
    if (email == null || email.isEmpty) return '?';
    final local = email.split('@').first;
    return local.isNotEmpty ? local[0].toUpperCase() : '?';
  }

  String? _redirect(BuildContext context, RouteState state) {
    final loc = state.location;
    final loggedIn = _session != null;

    if (!loggedIn) {
      return loc == '/login' ? null : '/login';
    }
    if (_selectedWorkspace == null) {
      return loc == '/create-workspace' ? null : '/create-workspace';
    }
    if (loc == '/login' || loc == '/create-workspace') {
      return '/';
    }
    return null;
  }

  @override
  Component build(BuildContext context) {
    if (_bootstrapping) {
      return div(
        attributes: {
          'style':
              "font-family:${KolaDashboardFonts.sans};background:#121214;color:#F3EEE7;"
              'width:100%;height:100vh;display:flex;align-items:center;justify-content:center',
        },
        [Component.text('Loading…')],
      );
    }

    return Router(
      redirect: _redirect,
      routes: [
        Route(
          path: '/login',
          builder: (context, state) => LoginPage(
            authService: _authService,
            onAuthenticated: _handleAuthenticated,
          ),
        ),
        Route(
          path: '/create-workspace',
          builder: (context, state) => CreateWorkspacePage(
            client: _client,
            accessToken: _session!.accessToken,
            onCreated: _handleWorkspaceCreated,
            onSignOut: _handleSignOut,
          ),
        ),
        Route(
          path: '/',
          builder: (context, state) => DashboardHomePage(
            client: _client,
            accessToken: _session!.accessToken,
            workspace: _selectedWorkspace!,
            userEmail: _session!.email,
            onSignOut: _handleSignOut,
            workspaces: _workspaces,
            onWorkspaceSwitch: _handleWorkspaceSwitch,
          ),
        ),
        Route(
          path: '/bots',
          builder: (context, state) => BotsPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
          ),
        ),
        Route(
          path: '/billing',
          builder: (context, state) => BillingPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
            workspaces: _workspaces,
            userEmail: _session!.email,
          ),
        ),
        Route(
          // Must come before '/bots/:id' — jaspr_router otherwise
          // matches 'new' as the :id param and hands it to
          // BotDetailChatPage instead of routing here.
          path: '/bots/new',
          builder: (context, state) => CreateBotPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
          ),
        ),
        Route(
          path: '/bots/:id',
          builder: (context, state) => BotDetailChatPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
            workspaceName: _selectedWorkspace!.name,
            avatarInitial: _avatarInitial,
            botId: state.params['id']!,
          ),
        ),
        Route(
          path: '/bots/:id/code',
          builder: (context, state) => BotDetailDevPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
            botId: state.params['id']!,
          ),
        ),
        Route(
          path: '/errands',
          builder: (context, state) => ErrandBuilderPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
          ),
        ),
        Route(
          path: '/knowledge',
          builder: (context, state) => KnowledgePage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
          ),
        ),
        Route(
          path: '/conversations',
          builder: (context, state) => ConversationsPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
          ),
        ),
        Route(
          path: '/integrations',
          builder: (context, state) => IntegrationsPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
          ),
        ),
      ],
    );
  }
}
