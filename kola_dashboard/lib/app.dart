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
import 'pages/logout_page.dart';
import 'pages/settings_page.dart';
import 'pages/catalog_page.dart';
import 'pages/product_detail_page.dart';
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

  /// True when [_loadWorkspaces] threw rather than legitimately finding
  /// no workspaces. Both states route to /create-workspace today, so
  /// this changes nothing the visitor sees — it exists so that "I can't
  /// reach my workspace" is answerable without guessing.
  ///
  /// Same distinction, and same reason, as FeatureGate.loadFailed.
  bool _workspaceLoadFailed = false;

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
    _workspaceLoadFailed = false;
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
    } catch (e, stack) {
      // A failed fetch and a genuinely zero-workspace account still look
      // the same to the ROUTER — both send the visitor to
      // /create-workspace, and picking the right error UI is still an
      // open design question.
      //
      // But they must not look the same to whoever is debugging. This
      // used to be `catch (_)` with the error dropped entirely, and the
      // cost was immediate: "I can't reach my workspace any more" became
      // undiagnosable from the outside, because the one piece of
      // evidence — what actually threw — was discarded before anyone
      // could read it. The symptom is identical whether the cause is an
      // expired token, an HTTP 500, a serialisation mismatch between a
      // regenerated client and an older deployed server (BUILD_AUDIT_5
      // §2.2), or an account that genuinely has no workspace yet.
      //
      // FeatureGate already draws exactly this distinction with its
      // `loadFailed` flag, and for exactly this reason. This is the same
      // lesson applied one layer up.
      // ignore: avoid_print
      print('kola: workspace load FAILED — $e');
      // ignore: avoid_print
      print('kola: $stack');
      _workspaceLoadFailed = true;

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
    // WITHOUT THIS, A BRAND-NEW WORKSPACE HAS NO NAVIGATION.
    //
    // _gate was only ever loaded inside _loadWorkspaces, which runs at
    // boot. Arriving here from the create-workspace wizard skips it
    // entirely, so _gate stayed FeatureGate.empty() — an empty enabled
    // set with loadFailed FALSE. Every gated nav item is then hidden and
    // the shell shows no "couldn't check what's available" warning
    // either, because as far as it knows the check succeeded and the
    // answer was "nothing". The first thing a new owner saw was a
    // sidebar containing only Overview.
    //
    // Fails silently by design: see _loadGate.
    _loadGate(workspace);
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
    // _loadWorkspaces' comment claims "switching workspace has to
    // re-fetch it, and doing that from one place means a switch cannot
    // leave the previous workspace's navigation on screen." That was
    // the intent and it was never wired up — this handler set the
    // workspace and nothing re-read the feature set, so switching from
    // a full workspace to a bare one kept the full sidebar, and every
    // item on it led to a page the new workspace cannot see.
    _loadGate(workspace);
  }

  /// Applies an edit made in Settings.
  ///
  /// Replaces the entry in [_workspaces] as well as [_selectedWorkspace],
  /// because both are read: the sidebar draws the selected one's name and
  /// avatar, and the workspace switcher draws the list. Updating only the
  /// selection would leave a renamed business showing its old name in its
  /// own switcher.
  ///
  /// No gate reload — updateWorkspace cannot change plan or status, so
  /// the enabled feature set cannot have moved.
  void _handleWorkspaceUpdated(Workspace workspace) {
    setState(() {
      _workspaces = [
        for (final w in _workspaces)
          if (w.id == workspace.id) workspace else w,
      ];
      if (_selectedWorkspace?.id == workspace.id) {
        _selectedWorkspace = workspace;
      }
    });
  }

  /// Re-reads the enabled feature set for [workspace] and rebuilds.
  ///
  /// Fire-and-forget on purpose. The callers are synchronous UI
  /// handlers, and the workspace change itself has already been applied
  /// by the time this starts — so the shell renders immediately with
  /// the core navigation and fills in the gated items a moment later,
  /// rather than holding the whole transition behind a network call on
  /// a connection where that can be half a second.
  ///
  /// FeatureGate.load never throws (it fails closed and reports
  /// loadFailed), so there is nothing here to catch.
  Future<void> _loadGate(Workspace workspace) async {
    final session = _session;
    final id = workspace.id;
    if (session == null || id == null) return;

    final gate = await FeatureGate.load(
      _client,
      accessToken: session.accessToken,
      workspaceId: id,
    );
    if (!mounted) return;

    // Guards a race: two quick switches can land their responses out of
    // order, and applying a stale one would draw the wrong workspace's
    // navigation. Only the gate for the workspace still selected wins.
    if (_selectedWorkspace?.id != id) return;
    setState(() => _gate = gate);
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

  // NOTE: _avatarInitial used to live here. Its only consumers were Bot
  // Detail Chat/Dev's plan panel, and the redesign of those screens
  // replaced that panel — so the getter was left with no callers.
  // DashboardHomePage derives its own copy, and the shell components
  // that still take an `avatarInitial` are constructed elsewhere.
  // Removed rather than kept "in case", since a dead getter is exactly
  // the thing the next person assumes is load-bearing.

  String? _redirect(BuildContext context, RouteState state) {
    final loc = state.location;
    final loggedIn = _session != null;

    if (!loggedIn) {
      return loc == '/login' ? null : '/login';
    }
    // Logging out is allowed from anywhere, and is checked BEFORE the
    // workspace guard below. Without this ordering, an owner whose
    // workspace failed to load is pinned to /create-workspace and
    // cannot reach /logout at all — the one state where being able to
    // sign out and start again matters most.
    if (loc == '/logout') return null;

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
          // loadFailed is the reason _workspaceLoadFailed exists. The
          // router sends you here either way, so without it a CONNECTION
          // FAILURE is indistinguishable from having no workspace — and
          // the page would cheerfully ask a returning owner to create the
          // business they already have.
          builder: (context, state) => CreateWorkspacePage(
            client: _client,
            accessToken: _session!.accessToken,
            onCreated: _handleWorkspaceCreated,
            onSignOut: _handleSignOut,
            loadFailed: _workspaceLoadFailed,
          ),
        ),
        // The destination Sidebar's "Log out" entry has always pointed
        // at. It was never registered, so the link matched no route and
        // painted nothing while the session stayed alive — logout was
        // dead across the whole app. See logout_page.dart.
        //
        // Deliberately NOT wrapped in shellFor: this page exists for a
        // few milliseconds before the document is replaced, and drawing
        // the sidebar and workspace chrome around a screen that is
        // tearing down would flash the very navigation being left.
        Route(
          path: '/logout',
          builder: (context, state) => LogoutPage(onSignOut: _handleSignOut),
        ),
        // Registered at last. Sidebar's profile menu has pointed both
        // "Profile" and "Settings" here since it was written, and the
        // Overview's day-one card wants it for the completed workspace
        // step's Edit — three links, no route, nothing painted.
        // Commerce, first screen. Gated at the server on commerce.core
        // AND commerce.catalog; the nav item that leads here is gated on
        // the same pair, so an unlocked workspace sees neither.
        Route(
          path: '/catalog',
          builder: (context, state) => shellFor(
            state,
            CatalogPage(
              client: _client,
              accessToken: _session!.accessToken,
              workspaceId: _selectedWorkspace!.id!,
            ),
          ),
        ),
        // The destination CatalogPage's product rows already linked to.
        // Same gating as /catalog — the server checks both commerce flags
        // on every read, so a locked workspace gets the honest refusal
        // rather than an empty page.
        Route(
          path: '/catalog/:id',
          // Parsed at the boundary, as /bots/:id does: a non-numeric id
          // is a malformed URL, and tryParse falling back to 0 turns it
          // into a clean "that product isn't here" instead of an
          // exception during build.
          builder: (context, state) => shellFor(
            state,
            ProductDetailPage(
              client: _client,
              accessToken: _session!.accessToken,
              workspaceId: _selectedWorkspace!.id!,
              productId: int.tryParse(state.params['id'] ?? '') ?? 0,
            ),
          ),
        ),
        Route(
          path: '/settings',
          builder: (context, state) => shellFor(
            state,
            SettingsPage(
              client: _client,
              accessToken: _session!.accessToken,
              workspace: _selectedWorkspace!,
              workspaces: _workspaces,
              onWorkspaceSwitch: _handleWorkspaceSwitch,
              onWorkspaceUpdated: _handleWorkspaceUpdated,
              gate: _gate,
            ),
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
          // Rebuilt on the new design system — wears AppShell.
          //
          // `workspaces` is no longer passed: the cross-workspace
          // billing list was a workaround for having no workspace
          // switcher. The shell's profile menu owns that now, so this
          // page shows the SELECTED workspace only — which is the one
          // whose money it is talking about.
          builder: (context, state) => shellFor(
            state,
            BillingPage(
              client: _client,
              accessToken: _session!.accessToken,
              workspaceId: _selectedWorkspace!.id!,
              userEmail: _session!.email,
              gate: _gate,
            ),
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
          // botId is parsed HERE rather than inside the page: the route
          // param is the only place it arrives as a string, and parsing
          // once at the boundary keeps every client call type-correct.
          // A non-numeric id is a malformed URL, and int.tryParse
          // falling back to 0 makes that a clean "not found" rather than
          // an exception during build.
          builder: (context, state) => BotDetailChatPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
            workspaceName: _selectedWorkspace!.name,
            botId: int.tryParse(state.params['id'] ?? '') ?? 0,
            gate: _gate,
          ),
        ),
        Route(
          path: '/bots/:id/code',
          // Parsed at the boundary, same as /bots/:id above.
          builder: (context, state) => BotDetailDevPage(
            client: _client,
            accessToken: _session!.accessToken,
            workspaceId: _selectedWorkspace!.id!,
            botId: int.tryParse(state.params['id'] ?? '') ?? 0,
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
