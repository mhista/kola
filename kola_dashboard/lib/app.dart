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
import 'services/feature_gate.dart';
import 'services/local_storage.dart';
import 'models/auth_session.dart';
import 'theme.dart';
import 'components/shell/app_shell.dart';
import 'components/shell/splash_screen.dart';

import 'pages/overview_page.dart';
import 'pages/operations_page.dart';
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

  /// Which features this workspace can see. Loaded once per workspace,
  /// read synchronously by the shell and every page after that.
  ///
  /// Starts empty, which hides everything gated. That is the right
  /// default for the moment before the first fetch resolves: showing
  /// nav items and then removing the ones that turn out to be locked
  /// would be a visible flicker advertising exactly what the gating
  /// exists to keep quiet.
  FeatureGate _gate = FeatureGate.empty();

  // True only while restoreSession()/listMyWorkspaces() are resolving on
  // first load — kept separate from "not logged in" so the redirect
  // guard below never fires against a still-unknown auth state (which
  // would flash /login even for a visitor who turns out to have a
  // valid persisted session).
  bool _bootstrapping = true;

  /// Whether the splash has finished playing and faded out.
  ///
  /// SEPARATE FROM [_bootstrapping] on purpose. Boot finishing and the
  /// splash leaving are two different events: a warm cache can finish
  /// boot in under 100ms, and swapping the splash out that fast reads
  /// as a glitch rather than as speed. SplashScreen owns the timing and
  /// flips this when it is genuinely done.
  bool _splashDone = false;

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

      // Feature set is per-workspace, so it loads here rather than in
      // _bootstrap — switching workspace has to re-fetch it, and doing
      // that from one place means a switch cannot leave the previous
      // workspace's navigation on screen.
      final selected = _selectedWorkspace;
      if (selected?.id != null) {
        _gate = await FeatureGate.load(
          _client,
          accessToken: session.accessToken,
          workspaceId: selected!.id!,
        );
      } else {
        _gate = FeatureGate.empty();
      }
    } catch (_) {
      // A failed fetch and a genuinely zero-workspace account look the
      // same from here — both send the visitor to /create-workspace.
      // Not distinguishing them yet is a real gap, not an oversight;
      // flagged rather than silently "fixed" with a guess at the right
      // error UI.
      _workspaces = const [];
      _selectedWorkspace = null;
      // Reset with the rest. A gate left over from a previous workspace
      // would decide what this one can see, which is the one mistake in
      // this whole mechanism that actually leaks something.
      _gate = FeatureGate.empty();
    }
  }

  /// A first name to greet, best-effort, from the email local part.
  ///
  /// 'aisha@shop.com' → 'Aisha'. 'aisha.bello@…' and 'aisha_bello@…' →
  /// 'Aisha', because a greeting reading "Evening, Aisha.bello" is worse
  /// than one reading just "Evening".
  ///
  /// Returns empty rather than a placeholder when there is nothing
  /// usable — 'info@', 'sales@' and 'hello@' are real signup addresses,
  /// and "Evening, Info" is worse than "Evening". The caller drops the
  /// name entirely in that case.
  ///
  /// Takes a nullable email because [AuthSession.email] IS nullable —
  /// Supabase's user object does not guarantee one (a phone-only or
  /// anonymous sign-in has no email at all). Null returns empty, and
  /// the greeting falls back to just "Evening", which is exactly the
  /// same handling the generic-address case already gets.
  ///
  /// This is a stand-in. It goes away the moment there is a real user
  /// profile with a name on it.
  static String _greetingName(String? email) {
    if (email == null) return '';

    final local = email.split('@').first;
    final first = local.split(RegExp(r'[._\-+]')).first.trim();
    if (first.isEmpty) return '';

    const generic = {
      'info', 'sales', 'hello', 'admin', 'contact', 'support',
      'team', 'office', 'mail', 'me', 'shop', 'store',
    };
    if (generic.contains(first.toLowerCase())) return '';

    // Digits usually mean a handle rather than a name ('user123').
    if (RegExp(r'\d').hasMatch(first)) return '';

    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  /// Wraps a page in the redesigned [AppShell].
  ///
  /// NOT APPLIED TO ANY ROUTE YET, AND THAT IS DELIBERATE. Every page
  /// below is still on the previous design and draws its own sidebar —
  /// putting one of them inside AppShell right now would render two
  /// sidebars side by side.
  ///
  /// Each page adopts this as it is rebuilt, and drops its own chrome in
  /// the same commit. That keeps the app working at every step instead
  /// of going dark for the length of a 44-screen migration.
  Component shellFor(RouteState state, Component page) => AppShell(
        gate: _gate,
        currentRoute: state.location,
        workspaceName: _selectedWorkspace?.name ?? '',
        workspaceSubtitle: _session?.email ?? '',
        child: page,
      );

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

    // Conversations were folded into Operations by the redesign — see
    // operations_page.dart. Redirected rather than removed because the
    // old path is in bookmarks, in the legacy dashboard's own links, and
    // in anything already shared; a 404 there would look like the
    // feature was taken away rather than moved.
    if (loc == '/conversations' || loc.startsWith('/conversations/')) {
      return '/operations';
    }

    return null;
  }

  @override
  Component build(BuildContext context) {
    // The splash owns the screen until it has both played and been
    // released by a finished boot. It fades out over the same
    // background colour the app uses, so the handover is a dissolve
    // rather than a flash of empty page.
    if (!_splashDone) {
      return SplashScreen(
        isReady: !_bootstrapping,
        onDone: () => setState(() => _splashDone = true),
      );
    }

    // Reachable only when boot outran the splash's own ceiling — see
    // SplashScreen._maxVisible. Rare, and deliberately not left as a
    // blank screen: something visible has to say the app is still
    // trying.
    if (_bootstrapping) {
      return div(
        attributes: {
          'style': 'font-family:${KolaFonts.sans};'
              'background:${KolaVar.bg};color:${KolaVar.text};'
              'width:100%;height:100vh;display:flex;'
              'align-items:center;justify-content:center;'
              'font-size:${KolaType.body}',
        },
        [Component.text('Still loading — this is taking longer than usual.')],
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
        // FIRST PAGE ON THE REDESIGN. Wrapped in AppShell, which now
        // provides the navigation, the workspace menu and sign-out that
        // DashboardHomePage used to draw itself — so this page renders
        // only its own content and no chrome.
        //
        // DashboardHomePage is still imported and still routable at
        // /home-legacy below, deliberately: it is the reference for
        // behaviour not yet ported (the workspace switcher), and
        // deleting it before that is ported would lose the only working
        // version of it.
        Route(
          path: '/',
          builder: (context, state) => shellFor(
            state,
            OverviewPage(
              client: _client,
              accessToken: _session!.accessToken,
              workspaceId: _selectedWorkspace!.id!,
              greetingName: _greetingName(_session!.email),
              gate: _gate,
            ),
          ),
        ),
        // Operations — the inbox. Absorbs what used to be the
        // Conversations page; see operations_page.dart's header and the
        // redirect stub in `Kola Conversations.dc.html`.
        Route(
          path: '/operations',
          builder: (context, state) => shellFor(
            state,
            OperationsPage(
              client: _client,
              accessToken: _session!.accessToken,
              workspaceId: _selectedWorkspace!.id!,
              gate: _gate,
            ),
          ),
        ),
        Route(
          path: '/home-legacy',
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
          // Rebuilt on the new design system — wears AppShell, draws no
          // chrome of its own.
          builder: (context, state) => shellFor(
            state,
            BotsPage(
              client: _client,
              accessToken: _session!.accessToken,
              workspaceId: _selectedWorkspace!.id!,
              gate: _gate,
            ),
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
          // Rebuilt on the new design system, so it now wears AppShell
          // and no longer draws its own chrome.
          builder: (context, state) => shellFor(
            state,
            KnowledgePage(
              client: _client,
              accessToken: _session!.accessToken,
              workspaceId: _selectedWorkspace!.id!,
              gate: _gate,
            ),
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
          // Rebuilt on the new design system — wears AppShell.
          builder: (context, state) => shellFor(
            state,
            IntegrationsPage(
              client: _client,
              accessToken: _session!.accessToken,
              workspaceId: _selectedWorkspace!.id!,
              gate: _gate,
            ),
          ),
        ),
      ],
    );
  }
}
