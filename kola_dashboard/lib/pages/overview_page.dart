// overview_page.dart — the morning briefing. The app's front door.
//
// ── THE DESIGN'S Day 1 / Week 1 / Month 6 BUTTONS ARE NOT HERE ───────
//
// Those are a design-tool control for previewing the same screen with
// different amounts of data. In production nobody chooses how much data
// they have. So they become what they were always describing — real
// states, driven by what actually comes back:
//
//     loading  → skeletons in the shape of the content
//     error    → say so, offer a retry
//     empty    → the three setup steps ("Day 1")
//     ready    → the briefing ("Week 1" / "Month 6")
//
// ── NO INVENTED NUMBERS ──────────────────────────────────────────────
//
// The export shows ₦340,000 of revenue, stock levels and a delivery
// recommendation. None of that is reachable at launch scope: commerce
// and intelligence are locked features, and there is no endpoint behind
// any of it. Rendering those cards with plausible figures would produce
// a dashboard that lies — and it would lie most convincingly to the
// person deciding whether to trust it with their business.
//
// So every section here is backed by a real call, and the sections that
// are not are gated off rather than mocked. This page grows as the
// features unlock, which is exactly what the release phases are for.
//
// ── WHAT IS REAL RIGHT NOW ───────────────────────────────────────────
//
//   conversation.listAll        → conversations handled
//   conversation.listEscalated  → what needs a human, with rows
//   supportTicket.list          → open tickets, SLA deadlines
//   knowledge.listDocuments     → what kolaa has been taught
//   bot.listBotsForWorkspace    → whether setup is actually finished

import 'dart:convert';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';
import 'package:web/web.dart' as web;

import '../components/ask_kola.dart';
import '../components/next_step_hint.dart';
import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../components/shell/page_help_button.dart';
import '../services/feature_gate.dart';
import '../services/local_storage.dart';
import '../services/error_text.dart';
import '../services/money_format.dart';
import '../theme.dart';

class OverviewPage extends StatefulComponent {
  const OverviewPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.greetingName,
    required this.gate,
    this.sellsCatalogItems,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  /// Gate 7 (migration 045). Passed in rather than fetched here — the
  /// caller (app.dart) already holds the selected Workspace in full;
  /// this page otherwise only ever asked the server for workspaceId's
  /// child data (bots, documents, products...), never the Workspace
  /// record itself, and fetching it a second time just for this one
  /// field would be a new round-trip for something the caller already
  /// has in hand.
  final bool? sellsCatalogItems;

  /// Who to greet. A PERSON, not the business.
  ///
  /// The design reads "Evening, Aisha". Passing the workspace name here
  /// would produce "Evening, Aisha's Fashion House", which is nobody's
  /// name and lands badly on the most prominent line of the app. The
  /// workspace name belongs in the sidebar, where it already is.
  final String greetingName;

  final FeatureGate gate;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

enum _Phase { loading, error, ready }

class _OverviewPageState extends State<OverviewPage> {
  _Phase _phase = _Phase.loading;
  String? _errorMessage;

  List<Conversation> _conversations = const [];
  List<Conversation> _escalated = const [];
  List<SupportTicket> _tickets = const [];
  List<KnowledgeDocument> _documents = const [];
  List<Product> _products = const [];
  List<Sale> _recentSales = const [];

  /// What the server's sweep noticed. See WorkspaceSweepService.
  List<WorkspaceFinding> _findings = const [];

  /// Findings currently being dismissed, so the row can say so.
  Set<int> _dismissing = {};
  List<Bot> _bots = const [];
  List<Errand> _errands = const [];
  List<ConnectorStatus> _connectors = const [];

  /// Phase 14/174 — "Changed today"'s own small preview read. Capped at
  /// [_timelinePreviewCap] server-side (the `limit` argument), not
  /// client-truncated from a bigger list — no point fetching more than
  /// this section will ever show.
  List<Event> _timelineEvents = const [];
  static const _timelinePreviewCap = 5;

  /// Every Operations-category event, read wide (not the 5-row preview
  /// cap above) so "Automations running" can count today's real
  /// `errand_executed` rows per errand — see [_todayErrandCounts]. Same
  /// catchError-to-empty posture as the other additive reads: a hiccup
  /// here loses the count, not the page.
  List<Event> _operationsEvents = const [];

  /// Whether a messaging channel is live, for the day-one card's step 2.
  ///
  /// Restricted to the two connectors that ARE channels rather than
  /// "any connector is connected" — a workspace with Paystack wired up
  /// and no WhatsApp has not connected a channel, and ticking the step
  /// for it would be the same false fact in a subtler form.
  bool get _channelConnected => _connectors.any(
        (c) =>
            (c.key == 'whatsapp' || c.key == 'telegram') &&
            c.status == 'connected',
      );

  /// Hints the owner has waved away. Persisted, because a suggestion
  /// that returns on every page load is nagging, and people stop reading
  /// the whole area it appears in.
  Set<String> _dismissed = const {};

  static const _dismissedKey = 'kola_dismissed_hints';

  /// The moon/sun toggle in the design's top bar (Kola Dashboard
  /// Shell.dc.html lines 35-42). The light/dark mechanism itself is not
  /// new — settings_page.dart's `_applyTheme` already writes
  /// `data-theme` on `<html>` and reads/writes this exact localStorage
  /// key; this is a second, page-local caller of the same real
  /// mechanism, not a second implementation of it. 'system' has no
  /// dedicated glyph in the design's two-button toggle, so pressing
  /// either button here always lands on an explicit 'dark' or 'light' —
  /// a workspace that wants to follow the OS still sets that from
  /// Settings, same as today.
  static const _themeKey = 'kola_theme';
  String _theme = 'system';

  // 14b. 'Needs your attention' and 'Automations running' used to render
  // every row the query returned, unbounded — confirmed during the
  // owner's live review as the source of a 10+ row list during the
  // knowledge-upload-failure incident. Capped at [_listCap] with an
  // inline "Show N more" toggle rather than a link to a real full-list
  // page: Recommendations/Observations exist as destinations but a
  // capped attention row mixes both kinds, and there is no full-list
  // page for Automations at all yet (see PHASE_14_HANDOFF.pdf's 14b).
  static const _listCap = 5;
  bool _attentionExpanded = false;
  bool _automationsExpanded = false;

  @override
  void initState() {
    super.initState();
    final raw = LocalStorage.getItem(_dismissedKey) ?? '';
    _dismissed = raw.split(',').where((s) => s.isNotEmpty).toSet();
    _theme = LocalStorage.getItem(_themeKey) ?? 'system';
    _load();
  }

  void _dismissHint(String id) {
    final next = {..._dismissed, id};
    LocalStorage.setItem(_dismissedKey, next.join(','));
    setState(() => _dismissed = next);
  }

  /// Same write settings_page.dart's `_applyTheme` performs — see this
  /// class's own `_theme` field comment for why this page has its own
  /// copy of the call rather than a shared widget: the design puts this
  /// toggle in the shell's top bar, reachable from Overview specifically.
  void _applyTheme(String value) {
    LocalStorage.setItem(_themeKey, value);
    final root = web.document.documentElement;
    if (root != null) root.setAttribute(KolaTheme.attribute, value);
    setState(() => _theme = value);
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _errorMessage = null;
    });

    final token = component.accessToken;
    final id = component.workspaceId;
    final gate = component.gate;

    try {
      // Issued together rather than awaited one after another. These are
      // five independent reads; serially they cost five round trips,
      // which on a slow connection is the difference between a page that
      // appears and a page that unrolls.
      //
      // Each gated call is replaced by an immediately-completed empty
      // list when its feature is off, so the shape of this list never
      // changes and the indices below stay honest.
      //
      // ── WHICH FAILURES ARE ALLOWED TO KILL THE PAGE ─────────────────
      //
      // Future.wait fails FAST: the first future to throw rejects the
      // whole thing, and this page turns into "Couldn't load your
      // briefing". That is right for the reads this screen cannot exist
      // without, and wrong for the ones that only ADD a section.
      //
      // I got this wrong by dropping listFindings straight into the list
      // with everything else. A brand-new workspace — no products, no
      // channel, nothing taught — hit one failing call on an endpoint
      // that had just been added, and the entire Overview went red. The
      // owner's first ever screen, blanked by an optional section.
      //
      // So the additive reads catch their own errors and degrade to an
      // empty list. A missing findings section is invisible; a missing
      // briefing is alarming.
      final results = await Future.wait<List<dynamic>>([
        component.client.conversation.listAll(token, id),
        gate.isEnabled(Features.escalation)
            ? component.client.conversation.listEscalated(token, id)
            : Future.value(const <Conversation>[]),
        gate.isEnabled(Features.operations)
            ? component.client.supportTicket.list(token, id)
            : Future.value(const <SupportTicket>[]),
        gate.isEnabled(Features.memoryDocuments)
            ? component.client.knowledge.listDocuments(token, id)
            : Future.value(const <KnowledgeDocument>[]),
        component.client.bot.listBotsForWorkspace(token, id),
        gate.isEnabled(Features.errandsBuiltin)
            ? component.client.errand.listErrandsForWorkspace(token, id)
            : Future.value(const <Errand>[]),
        // Sixth read, added for the day-one card's step 2.
        //
        // The setup card previously hardcoded "Connect a channel" as
        // NOT done — copied from the design export, where it is a
        // rendering sample. Shipped literally it tells an owner who has
        // just connected WhatsApp that they have not, which is the
        // false-fact case. There is no workspace-level channel list on
        // the client (ChannelEndpoint.listChannelsForBot is per-bot), so
        // the connector catalogue is the honest source: it already
        // merges stored channels per workspace.
        gate.isEnabled(Features.channelWhatsapp)
            ? component.client.connector.listConnectors(token, id)
            : Future.value(const <ConnectorStatus>[]),

        // Eighth read: the catalog.
        //
        // The Overview used to carry a "Products —" placeholder whose
        // only job was to say "available once you can add a catalog". It
        // was gated on the catalog being LOCKED, so releasing the
        // catalog made the card vanish and nothing took its place — the
        // header silently went from four cards to three. The placeholder
        // was written; the real thing never was.
        //
        // This also feeds NextSteps.hasProducts, which has been hardcoded
        // false since the day it was wired.
        gate.isEnabled(Features.commerceCatalog)
            ? component.client.product
                .listProducts(
                  token,
                  id,
                  // Explicit: Serverpod drops defaults when generating the
                  // client, so this is `required` there even though the
                  // endpoint declares it optional.
                  includeArchived: false,
                )
                .catchError((_) => const <Product>[])
            : Future.value(const <Product>[]),

        // Ninth read: what needs the owner's attention.
        //
        // This endpoint SWEEPS and then returns — see FindingEndpoint on
        // why, and on what changes when a scheduler exists. It is in the
        // same Future.wait as everything else because it does not depend
        // on any of them.
        component.client.finding
            .listFindings(token, id)
            .catchError((_) => const <WorkspaceFinding>[]),

        // Tenth read: the sales counter, migration 046's release.
        //
        // "Sales this week" was a hardcoded em-dash placeholder gated on
        // commerce.core — which migration 030 already released to
        // everyone, so the placeholder was never actually reachable
        // (nothing checked commerce.pos, the flag that actually decides
        // whether a sales counter exists). Fixed here rather than left:
        // 50 is a generous cap for "this week" on a single till: this
        // section computes a sum, not a paginated list, so more than 50
        // sales in seven days would need a real aggregation endpoint,
        // not a client-side fold — worth revisiting once a shop is
        // actually ringing up that many.
        gate.isEnabled(Features.commercePos)
            ? component.client.sale
                .listSales(token, id, limit: 50, offset: 0)
                .catchError((_) => const <Sale>[])
            : Future.value(const <Sale>[]),

        // Eleventh read: "Changed today"'s preview (Phase 14/174).
        // Additive — same catchError-to-empty posture as findings/
        // products above, so a hiccup on this one read cannot blank the
        // whole briefing.
        gate.isEnabled(Features.timeline)
            ? component.client.event
                .listTimeline(token, id, limit: _timelinePreviewCap)
                .catchError((_) => const <Event>[])
            : Future.value(const <Event>[]),

        // Twelfth read: the wide Operations feed "Automations running"
        // counts today's real errand_executed rows from — see
        // [_operationsEvents]'s own comment on why this is separate from
        // the 5-row "Changed today" preview above. Same feature gate:
        // there is nothing to read if the Timeline feature itself is
        // off.
        gate.isEnabled(Features.timeline)
            ? component.client.event
                .listTimeline(token, id, category: 'Operations', limit: 200)
                .catchError((_) => const <Event>[])
            : Future.value(const <Event>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _conversations = results[0].cast<Conversation>();
        _escalated = results[1].cast<Conversation>();
        _tickets = results[2].cast<SupportTicket>();
        _documents = results[3].cast<KnowledgeDocument>();
        _bots = results[4].cast<Bot>();
        _errands = results[5].cast<Errand>();
        _connectors = results[6].cast<ConnectorStatus>();
        _products = results[7].cast<Product>();
        _findings = results[8].cast<WorkspaceFinding>();
        _recentSales = results[9].cast<Sale>();
        _timelineEvents = results[10].cast<Event>();
        _operationsEvents = results[11].cast<Event>();
        _phase = _Phase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = ErrorText.of(e);
      });
    }
  }

  /// A workspace that has not started yet.
  ///
  /// Judged on bots AND knowledge, not on conversations. A business can
  /// have set everything up correctly and simply not been messaged yet
  /// — showing them "get started" in that situation tells them their
  /// work did not take.
  bool get _isEmpty => _bots.isEmpty && _documents.isEmpty;

  /// Sum of every completed sale rung up in the last 7 days. `_recentSales`
  /// is already capped at 50 rows and sorted newest-first by the server
  /// (SaleRepository.listByWorkspace orders on sold_at descending), so
  /// this filters rather than re-sorts.
  int get _salesThisWeekMinor {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _recentSales
        .where((s) => s.status == 'completed' && s.soldAt.isAfter(cutoff))
        .fold(0, (sum, s) => sum + s.totalMinor);
  }

  @override
  Component build(BuildContext context) {
    return div(
      // THE GLOW. A warm wash bleeding down from above the fold, per
      // Kola Dashboard Shell.dc.html, where it is a theme token rather
      // than a page style — hence KolaVar.glow and not a literal.
      //
      // It sits on an outer wrapper, not on the 1040px column: the
      // ellipse is 900px wide and anchored at 50% -10%, so constraining
      // it to the content column would clip it and centre it on the
      // wrong axis at wide viewports.
      //
      // `background-image` rather than `background`, so it composes over
      // --kola-bg instead of replacing it.
      attributes: {
        'style': 'background-image:${KolaVar.glow};'
            'background-repeat:no-repeat;width:100%',
      },
      [
        div(
          attributes: {
            'style': 'max-width:1040px;margin:0 auto;width:100%;'
                'padding:28px 20px 40px;display:flex;'
                'flex-direction:column;gap:22px',
          },
          [
            _greeting(),
            ...switch (_phase) {
              _Phase.loading => _skeletons(),
              _Phase.error => [_errorCard()],
              _Phase.ready => _isEmpty ? _setup() : _briefing(),
            },
          ],
        ),
      ],
    );
  }

  // ── Greeting ────────────────────────────────────────────────────────

  Component _greeting() {
    final now = DateTime.now();
    final part = now.hour < 12
        ? 'Morning'
        : now.hour < 17
            ? 'Afternoon'
            : 'Evening';

    return div(
      attributes: {
        'style': 'display:flex;align-items:baseline;justify-content:space-between;'
            'gap:12px;flex-wrap:wrap',
      },
      [
        h1(
          attributes: {
            'style': 'font-family:${KolaFonts.display};font-size:${KolaType.display};'
                'font-weight:700;color:${KolaVar.text};margin:0;'
                'letter-spacing:-0.02em',
          },
          [
            Component.text(component.greetingName.isEmpty
                ? part
                : '$part, ${component.greetingName}'),
          ],
        ),
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:10px',
          },
          [
            _themeToggle(),
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                    'white-space:nowrap',
              },
              [Component.text(_formatDate(now))],
            ),
            const PageHelpButton(
              pageKey: 'overview',
              body: [
                "Your morning briefing. What needs you right now, one "
                    "recommendation worth acting on, and what changed "
                    "today — kola pulls this from every conversation, "
                    "sale and escalation happening across the business, "
                    "so you're never hunting for it.",
                "The four cards up top are your always-visible vitals. "
                    "Below them, 'Needs your attention' surfaces the "
                    "things kola thinks you should look at, 'What kola "
                    "learned' shows what it's learned recently, "
                    "'Automations running' lists what's active right "
                    "now, and 'Changed today' previews the most recent "
                    "real activity — open the full Timeline for "
                    "everything, filterable by category.",
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// The moon/sun pill from `Kola Dashboard Shell.dc.html` lines 35-42 —
  /// a 2-button toggle in a bordered pill, active button on a tinted
  /// background. Values and colours copied from the export's own
  /// `darkBg`/`lightBg` (the dark button highlights on [KolaVar.border],
  /// the light one on [KolaVar.pill] — an asymmetric pair in the
  /// original, not a typo introduced here).
  Component _themeToggle() {
    final isDark = _theme == 'dark';
    final isLight = _theme == 'light';
    return div(
      attributes: {
        'style': 'display:flex;background:${KolaVar.card};'
            'border:1px solid ${KolaVar.border};border-radius:${KolaRadius.pill};'
            'padding:3px',
      },
      [
        button(
          attributes: {
            'type': 'button',
            'aria-label': 'Dark mode',
            'aria-pressed': '$isDark',
            'style': 'border:none;width:30px;height:30px;'
                'border-radius:${KolaRadius.circle};cursor:pointer;'
                'background:${isDark ? KolaVar.border : 'transparent'};'
                'color:${isDark ? KolaVar.text : KolaVar.muted};'
                'display:flex;align-items:center;justify-content:center',
          },
          events: {'click': (_) => _applyTheme('dark')},
          [kolaIcon(Icons.moon, size: 15)],
        ),
        button(
          attributes: {
            'type': 'button',
            'aria-label': 'Light mode',
            'aria-pressed': '$isLight',
            'style': 'border:none;width:30px;height:30px;'
                'border-radius:${KolaRadius.circle};cursor:pointer;'
                'background:${isLight ? KolaVar.pill : 'transparent'};'
                'color:${isLight ? KolaVar.text : KolaVar.muted};'
                'display:flex;align-items:center;justify-content:center',
          },
          events: {'click': (_) => _applyTheme('light')},
          [kolaIcon(Icons.sun, size: 15)],
        ),
      ],
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────

  /// Shaped like the briefing it replaces, so nothing jumps when the
  /// real content lands.
  List<Component> _skeletons() => [
        div(
          attributes: {
            'style': 'display:grid;gap:14px;'
                'grid-template-columns:repeat(auto-fit,minmax(160px,1fr))',
          },
          [
            for (var i = 0; i < 3; i++)
              div(
                classes: 'kola-skel',
                attributes: {'style': 'height:78px;border-radius:${KolaRadius.lg}'},
                [],
              ),
          ],
        ),
        div(
          classes: 'kola-skel',
          attributes: {'style': 'height:140px;border-radius:${KolaRadius.lg}'},
          [],
        ),
      ];

  // ── Error ───────────────────────────────────────────────────────────

  Component _errorCard() => div(
        attributes: {
          'role': 'alert',
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.danger};'
              'border-radius:${KolaRadius.lg};padding:20px',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text("Couldn't load your briefing")],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.5;margin-bottom:14px',
            },
            [
              Component.text(
                'Your data is fine — this is a problem reaching the server. '
                'Nothing has been lost.',
              ),
            ],
          ),
          if (_errorMessage != null)
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.mono};font-size:${KolaType.micro};'
                    'color:${KolaVar.muted};background:${KolaVar.pill};'
                    'border-radius:${KolaRadius.sm};padding:8px 10px;'
                    'margin-bottom:14px;overflow-wrap:anywhere',
              },
              // The raw message is shown rather than swallowed. When a
              // shop owner reports "it won't load", this is the one
              // thing that makes the report actionable.
              [Component.text(_errorMessage!)],
            ),
          button(
            attributes: {
              'class': 'kola-pressable',
              'type': 'button',
              'style': 'background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                  'border:none;border-radius:${KolaRadius.pill};'
                  'padding:9px 18px;font-size:${KolaType.small};'
                  'font-weight:600;font-family:inherit',
            },
            events: {'click': (_) => _load()},
            [Component.text('Try again')],
          ),
        ],
      );

  // ── Empty / setup ───────────────────────────────────────────────────

  /// The day-one card, rebuilt against `Kola Dashboard Shell.dc.html`.
  ///
  /// ── WHAT THE EXPORT ACTUALLY SPECIFIES ─────────────────────────────
  ///
  /// The export's `setupSteps` are, verbatim:
  ///
  ///   1. Create your workspace  — done: TRUE
  ///   2. Connect a channel      — done: false
  ///   3. Teach kolaa about the business — done: false
  ///
  /// The previous build's step 1 was "Create a bot", which appears in no
  /// export. It also asked a first-time owner to do something they had
  /// just implicitly done: you cannot reach this screen without a
  /// workspace, so step 1 opens already ticked. That tick is the point —
  /// the card starts with a win rather than three chores.
  ///
  /// The card is centred, dashed, and led by a 🌱, per the export. The
  /// step list is capped at 480px and left-aligned inside the centred
  /// card, which is why the two alignments differ here.
  ///
  /// ── ONE DELIBERATE DEVIATION: WHERE "EDIT" GOES ────────────────────
  ///
  /// The export points step 1 at `Kola Create Workspace.dc.html`,
  /// because in a static export that is the only file where workspace
  /// fields exist. Wiring "Edit" to /create-workspace in the running app
  /// would hand an owner a form that CREATES A SECOND BUSINESS — the
  /// data-corruption exception, not a style preference. It goes to
  /// /settings, which is where those fields are editable.
  ///
  /// ── THE SUBTITLE COUNTS, IT DOES NOT ASSERT ────────────────────────
  ///
  /// The export's copy ends "Step one's done — two to go." That is a
  /// fixed string in a design sample. Shipped as-is it would still say
  /// "two to go" to someone who had finished a second step, so the tail
  /// is computed from the real step states.
  List<Component> _setup() {
    final steps = <({
      String title,
      String body,
      String cta,
      String? route,
      String icon,
      bool done,
    })>[
      (
        title: 'Create your workspace',
        body: 'Your business name, what you sell, and who owns the account.',
        cta: 'Edit',
        // NOT /create-workspace, which is where the export points.
        //
        // In a static export that file is the only place workspace
        // fields exist, but in the running app it is a form that CREATES
        // A SECOND BUSINESS. /settings edits the one you already have —
        // it opens on the Workspaces section, which holds exactly the
        // three fields this step collected.
        route: '/settings',
        icon: Icons.workspaceSetup,
        done: true,
      ),
      (
        title: 'Connect a channel',
        body: 'WhatsApp or Telegram — wherever customers actually message you.',
        cta: 'Connect a channel',
        route: '/integrations',
        icon: Icons.whatsapp,
        done: _channelConnected,
      ),
      (
        title: 'Teach kolaa about the business',
        // Rewritten. The export's line — "Paste a price list, FAQ or
        // policy — its first answers cite this, not a guess" — names
        // three document types and leaves the owner to infer why it
        // matters. Most shop owners do not have a "policy" document,
        // and the ones who do will not think of it as the thing kolaa
        // needs. So this names the FACTS a customer actually asks
        // about, then states the consequence of skipping it plainly.
        body: 'Your prices, what you have in stock, where you deliver, '
            'your refund rules, your opening hours. kolaa answers from '
            'whatever you give it — and cites it. Give it nothing and it '
            'has to guess.',
        // "Teach kolaa something" described the intent but not the
        // action, so it was unclear what pressing it would do.
        cta: 'Add knowledge',
        route: '/knowledge',
        icon: Icons.book,
        done: _documents.isNotEmpty,
      ),
    ];

    final remaining = steps.where((s) => !s.done).length;
    final tail = remaining == 0
        ? " That's all three done — kolaa is working with real answers now."
        : remaining == 1
            ? " One left."
            : " Step one's done — $remaining to go.";

    return [
      div(
        attributes: {
          'style': 'background:${KolaVar.card};'
              'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.xl};padding:36px 28px;'
              'text-align:center',
        },
        [
          div(
            attributes: {'style': 'font-size:26px;margin-bottom:10px'},
            [Component.text('🌱')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('kolaa is still learning your business')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.5;max-width:440px;margin:0 auto 22px',
            },
            [
              Component.text(
                'Three steps get it grounded in real answers instead of '
                'guesses.$tail',
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'display:flex;flex-direction:column;gap:10px;'
                  'max-width:480px;margin:0 auto;text-align:left',
            },
            [for (var i = 0; i < steps.length; i++) _setupStep(i + 1, steps[i])],
          ),
        ],
      ),
    ];
  }

  Component _setupStep(
    int number,
    ({
      String title,
      String body,
      String cta,
      String? route,
      String icon,
      bool done,
    }) step,
  ) {
    return div(
      attributes: {
        'style': 'background:${KolaVar.bg};'
            'border:1px solid ${step.done ? KolaVar.success : KolaVar.border};'
            'border-radius:${KolaRadius.md};padding:14px 16px;'
            'display:flex;align-items:center;gap:14px;flex-wrap:wrap;'
            'opacity:${step.done ? '0.7' : '1'}',
      },
      [
        div(
          attributes: {
            'style': 'width:24px;height:24px;border-radius:${KolaRadius.circle};'
                'flex:none;display:flex;align-items:center;justify-content:center;'
                'font-size:${KolaType.tiny};font-weight:700;'
                'background:${step.done ? KolaVar.successBg : KolaVar.pill};'
                'color:${step.done ? KolaVar.successBright : KolaVar.muted}',
          },
          [Component.text(step.done ? '✓' : '$number')],
        ),
        // The export gives every step its own glyph, tinted green once
        // the step is done. It carries no information the number does
        // not — it is there so the row reads as a thing rather than a
        // list entry, which is most of why the designed card feels
        // finished and a bare numbered list does not.
        div(
          attributes: {
            'style': 'width:30px;height:30px;border-radius:${KolaRadius.sm};'
                'flex:none;display:flex;align-items:center;'
                'justify-content:center;'
                'background:${step.done ? KolaVar.successBg : KolaVar.pill};'
                'color:${step.done ? KolaVar.successBright : KolaVar.accent}',
          },
          [kolaIcon(step.icon, size: 15)],
        ),
        div(
          attributes: {'style': 'flex:1;min-width:180px'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                    'color:${KolaVar.text};margin-bottom:2px',
              },
              [Component.text(step.title)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                    'line-height:1.45',
              },
              [Component.text(step.body)],
            ),
          ],
        ),
        // A step with no route renders a static "Done" tag rather than
        // a button. See the workspace step's `route: null` comment —
        // the destination does not exist yet, and a button that goes
        // nowhere reads as broken rather than unfinished.
        if (step.route == null)
          div(
            attributes: {
              'style': 'flex:none;border-radius:${KolaRadius.pill};'
                  'padding:8px 16px;font-size:${KolaType.tiny};'
                  'font-weight:600;background:${KolaVar.successBg};'
                  'color:${KolaVar.successBright}',
            },
            [Component.text('Done')],
          )
        else
          Link(
            to: step.route!,
            attributes: {
              'class': 'kola-pressable',
              'style': 'flex:none;border-radius:${KolaRadius.pill};'
                  'padding:8px 16px;font-size:${KolaType.tiny};font-weight:600;'
                  'text-decoration:none;'
                  '${step.done ? 'background:transparent;border:1px solid ${KolaVar.border};color:${KolaVar.muted}' : 'background:${KolaVar.accentFill};color:${KolaVar.accentText}'}',
            },
            children: [Component.text(step.done ? 'Edit' : step.cta)],
          ),
      ],
    );
  }

  // ── Ready ───────────────────────────────────────────────────────────

  /// True when the workspace is set up but nothing has happened yet.
  ///
  /// A REAL AND COMMON STATE, and distinct from both the others. Someone
  /// who finished setup ten minutes ago has bots and documents, so they
  /// are not "empty" — but they have no conversations either, so the
  /// briefing has nothing to brief. Showing them "Nothing needs you
  /// right now" would be technically true and completely useless: they
  /// cannot tell whether kolaa is working or silently broken.
  bool get _noActivityYet =>
      _conversations.isEmpty && _escalated.isEmpty && _tickets.isEmpty;

  List<Component> _briefing() {
    // Findings come from the SERVER now, ranked by severity and carrying
    // how long each has been true. _attentionItems() used to compute a
    // list here from whatever the page happened to have loaded — see the
    // note where it used to live.
    final attention = _findings;

    final hint = NextSteps.choose(
      hasBot: _bots.isNotEmpty,
      hasDocuments: _documents.isNotEmpty,
      hasConversations: _conversations.isNotEmpty,
      commerceEnabled: component.gate.isEnabled(Features.commerceCatalog),
      // Was hardcoded false with a note saying it would start working
      // when the catalog shipped. The catalog shipped and this was not
      // revisited, which is what that kind of note is for and exactly
      // how it fails.
      hasProducts: _products.isNotEmpty,
      sellsCatalogItems: component.sellsCatalogItems,
      dismissed: _dismissed,
    );

    return [
      if (hint != null) NextStepHint(step: hint, onDismiss: _dismissHint),
      _stats(),
      // ── TOP RECOMMENDATION ────────────────────────────────────────
      //
      // The design's own card. It is the WORST open finding, promoted
      // out of the list — not a separate computation, because two
      // sources ranking the same facts differently is how a dashboard
      // starts contradicting itself.
      //
      // Rendered with its real confidence. Today that is always 1.0
      // because every detector is deterministic, and the card says so
      // rather than implying a judgement was made.
      if (attention.isNotEmpty) _topRecommendation(attention.first),

      if (_noActivityYet && attention.isEmpty)
        _waitingCard()
      else if (attention.length > 1)
        _section(
          'Needs your attention',
          // .skip(1) — the first one is the card above. Repeating it
          // immediately underneath would read as two different problems.
          _cappedList(
            items: attention.skip(1).toList(),
            expanded: _attentionExpanded,
            onExpand: () => setState(() => _attentionExpanded = true),
            builder: _findingsList,
          ),
        )
      else if (attention.isEmpty)
        _allClear(),
      // Header copy matches the design's own "What kola learned" exactly
      // (was "What kolaa knows") — see _knowledgeLines()'s own comment
      // on why the CONTENT stays the honest document-count summary
      // rather than the export's two illustrative insight lines.
      _section('What kola learned', _knowledgeLines()),
      if (_errands.isNotEmpty) _section('Automations running', _automations()),
      // Phase 14/174. Only rendered when there is something real to
      // show — an empty "Changed today" heading over blank space reads
      // as a failure to load, same reasoning _allClear() already uses
      // for "Needs your attention".
      if (component.gate.isEnabled(Features.timeline) && _timelineEvents.isNotEmpty)
        _changedToday(),

      // The composer. Sticky, so it stays reachable however far the
      // briefing scrolls — it is the primary action on this screen.
      AskKola(
        client: component.client,
        accessToken: component.accessToken,
        workspaceId: component.workspaceId,
        hasDocuments: _documents.isNotEmpty,
      ),
    ];
  }

  /// Errands kolaa can call mid-conversation.
  ///
  /// `active` is what the design means by "running" — an errand exists
  /// but disabled is not running, and showing it as such would tell an
  /// owner a thing is happening that is not.
  Component _automations() {
    final active = _errands.where((e) => e.status == 'active').toList();

    return _cappedList(
      items: active,
      expanded: _automationsExpanded,
      onExpand: () => setState(() => _automationsExpanded = true),
      builder: _automationsList,
    );
  }

  /// Today's real `errand_executed` count per errand, from
  /// [_operationsEvents] (a wide, unfiltered-by-date Operations read —
  /// see that field's own comment). Payload carries `errandId`, set at
  /// emit time by errand_dispatch_service.dart's own `dispatch()`.
  Map<int, int> _todayErrandCounts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = <int, int>{};
    for (final e in _operationsEvents) {
      if (e.eventType != 'errand_executed') continue;
      final local = e.occurredAt.toLocal();
      if (DateTime(local.year, local.month, local.day) != today) continue;
      Map<String, dynamic> payload;
      try {
        final decoded = jsonDecode(e.payloadJson);
        payload = decoded is Map<String, dynamic> ? decoded : const {};
      } catch (_) {
        payload = const {};
      }
      final errandId = payload['errandId'];
      if (errandId is int) counts.update(errandId, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  /// The design's own copy shape is "{name} — {N} handled today"
  /// (`Order status replies — 22 handled today`) alongside one workflow
  /// line with no count (`Payment confirmation → stock update`). This
  /// build has real per-errand names and, via [_todayErrandCounts], a
  /// real count of today's runs — so every ACTIVE errand renders the
  /// design's counted template with its own real name and count, rather
  /// than literally reusing the export's two fixed sample lines (which
  /// name specific automations this workspace may not even have). A
  /// count of zero falls back to the plain name, never "0 handled
  /// today" — same never-show-a-zero rule this file applies everywhere
  /// else.
  Component _automationsList(List<Errand> active) {
    final counts = _todayErrandCounts();
    return div(
      attributes: {
        'style': 'background:${KolaVar.card};'
            'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:4px 0',
      },
      [
        if (active.isEmpty)
          div(
            attributes: {
              'style': 'padding:12px 16px;font-size:${KolaType.small};'
                  'color:${KolaVar.muted}',
            },
            [Component.text('No automations are switched on right now.')],
          )
        else
          for (var i = 0; i < active.length; i++)
            div(
              attributes: {
                'style': 'display:flex;align-items:center;gap:10px;'
                    'padding:11px 16px;font-size:${KolaType.body};'
                    'color:${KolaVar.text};'
                    '${i > 0 ? 'border-top:1px solid ${KolaVar.border}' : ''}',
              },
              [
                span(
                  attributes: {
                    'style': 'width:6px;height:6px;flex:none;'
                        'border-radius:${KolaRadius.circle};'
                        'background:${KolaVar.success}',
                  },
                  [],
                ),
                span(
                  attributes: {'style': 'flex:1;min-width:0'},
                  [
                    Component.text(
                      switch (counts[active[i].id]) {
                        final n? when n > 0 => '${active[i].name} — $n handled today',
                        _ => active[i].name,
                      },
                    ),
                  ],
                ),
              ],
            ),
      ],
    );
  }

  /// Set up, connected, nothing has come in yet.
  ///
  /// The job of this card is to answer the question the person is
  /// actually asking — "is this thing working?" — rather than to fill
  /// space. So it states plainly that kolaa is watching, and gives the
  /// one action that proves it: message the bot yourself.
  Component _waitingCard() => div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:20px',
        },
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:center;gap:8px;margin-bottom:8px',
            },
            [
              div(
                attributes: {'style': 'color:${KolaVar.successBright};display:flex'},
                [kolaIcon(Icons.checkSquare, size: 16)],
              ),
              span(
                attributes: {
                  'style': 'font-size:${KolaType.lead};font-weight:600;'
                      'color:${KolaVar.text}',
                },
                [Component.text('kolaa is set up and listening')],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.55;margin-bottom:14px;max-width:520px',
            },
            [
              Component.text(
                'No customer messages yet. When one arrives it appears here, '
                'and anything kolaa cannot answer confidently is passed to you '
                'rather than guessed at.',
              ),
            ],
          ),
          Link(
            to: '/conversations',
            attributes: {
              'class': 'kola-pressable',
              'style': 'display:inline-block;background:transparent;'
                  'border:1px solid ${KolaVar.border};color:${KolaVar.text};'
                  'border-radius:${KolaRadius.pill};padding:8px 16px;'
                  'font-size:${KolaType.tiny};font-weight:600;text-decoration:none',
            },
            children: [Component.text('Open conversations')],
          ),
        ],
      );

  /// The stat row.
  ///
  /// ── WHY SOME CARDS SHOW AN EM DASH AND NOT 0 ───────────────────────
  ///
  /// Two different situations look similar and must not read the same:
  ///
  ///   MEASURED, AND THE ANSWER IS ZERO — 0 conversations means kolaa
  ///   watched and nothing came in. That is a fact about the business,
  ///   and 0 is the correct way to say it.
  ///
  ///   NOT MEASURED YET — the sales counter has not launched, so nothing
  ///   is counting money. Printing "Revenue: 0" there states something
  ///   false about the business: they may have had their best week ever.
  ///   A dashboard is scanned, not read, and the number is what gets
  ///   scanned — the explanation underneath does not undo it.
  ///
  /// So unmeasured cards carry an em dash plus a plain sentence about
  /// when the number starts. The card is present, visible and explained,
  /// which is what makes the product feel staged rather than broken —
  /// it just does not claim a figure it has not measured.
  ///
  /// ── WHICH LOCKED FEATURES GET A CARD AT ALL ────────────────────────
  ///
  /// Only ones already announced publicly. The sales counter and catalog
  /// are on the landing page, so naming them here tells nobody anything
  /// new. Observations, recommendations and analytics are NOT announced,
  /// so they stay absent — a placeholder card is a roadmap announcement
  /// wearing a different hat.
  /// A counted stat, or an em-dash and an explanation when the count is
  /// zero. See the NEVER A ZERO note below for why.
  ({String label, String value, String? note}) _stat(
    String label,
    int count,
    String zeroNote,
  ) =>
      count == 0
          ? (label: label, value: '—', note: zeroNote)
          : (label: label, value: '$count', note: null);

  Component _stats() {
    final gate = component.gate;

    final stats = <({String label, String value, String? note})>[
      // ── ORDER MATCHES THE DESIGN'S FIRST SLOT ──────────────────────────
      //
      // Kola Dashboard Shell.dc.html's healthStats leads with "Revenue
      // this week". There is no revenue metric in this build (see this
      // file's header — commerce and intelligence are locked at launch
      // scope), but "Sales this week" is the same real-money concept
      // this codebase CAN measure honestly, so it takes the design's
      // first position rather than trailing behind Conversations.
      //
      // Sales this week — real once commerce.pos is released (migration
      // 046). Previously gated on commerce.core, which migration 030
      // released to every workspace years before a till existed; that
      // meant this branch could never actually show, and the placeholder
      // silently never appeared for anyone. Fixed to check the flag that
      // actually gates the sales counter, and to show a real number
      // instead of a permanent em-dash once it's on.
      if (gate.isEnabled(Features.commercePos))
        _salesThisWeekMinor == 0
            ? (
                label: 'Sales this week',
                value: '—',
                note: 'Starts counting once you ring up a sale.',
              )
            : (label: 'Sales this week', value: formatMinor(_salesThisWeekMinor), note: null)
      else
        (
          label: 'Sales this week',
          value: '—',
          note: 'Starts counting when the sales counter arrives.',
        ),

      // ── NEVER A ZERO ─────────────────────────────────────────────────
      //
      // "Conversations 0 / Waiting on you 0 / Documents learned 0" was
      // three zeros across the top of the first screen a new owner sees.
      // A zero is a measurement, and it reads as a verdict: it says the
      // product ran and found nothing, when the truth is that nothing
      // has happened YET. Those are different facts and the second one
      // is encouraging.
      //
      // So a count of zero becomes an em-dash plus the condition that
      // starts it counting — the same treatment the commerce
      // placeholders below already use, which is why they read fine and
      // these did not.
      //
      // Second slot — the design's own second card is "Conversations",
      // unchanged here.
      _stat('Conversations', _conversations.length,
          'Starts counting when a customer first messages you.'),
      if (gate.isEnabled(Features.memoryDocuments))
        _stat('Documents learned', _documents.length,
            'Add a price list or FAQ and it appears here.'),

      // "Waiting on you" DELIBERATELY REMOVED.
      //
      // It was the fourth of five cards and the least load-bearing. When
      // it is zero it says nothing; when it is not, the "Needs your
      // attention" section directly below lists the same items with far
      // more detail — who is waiting and for how long — so the card was
      // a worse duplicate of something already on screen. The design's
      // own header carries three cards, not five.
      //
      // "Avg. response time" — the design's own third card — IS NOT
      // shown. Named gap, not a silent cut: grepped for any existing
      // average-response-time computation anywhere in this codebase
      // (responseTime/response_time/avgResponse/firstResponse) — zero
      // matches, confirmed independently by intelligence_endpoint.dart's
      // own header for the same reason. Computing it is a real
      // aggregation over Message.createdAt pairs, genuinely separate
      // work from a presentation-layer pass — printing a number with
      // nothing behind it is the one thing DESIGN_DELTA.md forbids
      // outright.

      // Products, in BOTH states.
      //
      // Only the locked branch existed, so releasing the catalog deleted
      // the card instead of filling it in. A placeholder written without
      // its counterpart is a card that disappears the moment the feature
      // it was waiting for arrives — the opposite of what it was for.
      //
      // Gate 7 (migration 045): commerceCatalog is a release/plan flag,
      // on for every workspace once shipped — not a statement that THIS
      // business sells anything. A workspace that has explicitly said
      // "no" (sellsCatalogItems == false) drops the card entirely rather
      // than show a permanent zero. Unanswered (null) keeps today's
      // behavior so nothing changes for a workspace nobody has asked yet.
      if (component.sellsCatalogItems != false) ...[
        if (gate.isEnabled(Features.commerceCatalog))
          _stat('Products', _products.length,
              'Add or import your first product and it appears here.')
        else
          (
            label: 'Products',
            value: '—',
            note: 'Available once you can add a catalog.',
          ),
      ],
    ];

    return div(
      attributes: {
        'style': 'display:grid;gap:14px;'
            'grid-template-columns:repeat(auto-fit,minmax(150px,1fr))',
      },
      [for (final s in stats) _statCard(s)],
    );
  }

  Component _statCard(({String label, String value, String? note}) s) {
    final pending = s.note != null;

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:16px;'
            // Pending cards sit back a little so the row reads as
            // "these three are live, these two are coming" at a glance,
            // without needing to read any of it.
            '${pending ? 'opacity:0.75' : ''}',
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin-bottom:6px',
          },
          [Component.text(s.label)],
        ),
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.display};font-size:${KolaType.h1};'
                'font-weight:700;font-variant-numeric:tabular-nums;'
                'color:${pending ? KolaVar.muted : KolaVar.text}',
          },
          [Component.text(s.value)],
        ),
        if (s.note != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.micro};color:${KolaVar.muted};'
                  'line-height:1.4;margin-top:6px',
            },
            [Component.text(s.note!)],
          ),
      ],
    );
  }

  /// Escalations and SLA-risk tickets, most urgent first.
  // _attentionItems() AND _attentionList() USED TO LIVE HERE.
  //
  // They computed the attention list inline from whatever this page had
  // already fetched, which meant it could only ever mention escalated
  // conversations and SLA tickets. A product out of stock, a document
  // that failed to index, a workspace with no channel connected — none
  // of it was noticed, because nothing was looking.
  //
  // It also could not say HOW LONG anything had been true, and a
  // dismissal could not stick, because there was no row to write it on.
  //
  // WorkspaceSweepService does the detecting now. Its ticket detector is
  // a direct port of the SLA logic that lived here — including the
  // overdue / due-soon split, which was right and would have been the
  // easiest thing to lose in a rewrite.

  /// The single worst thing, as the design's own card
  /// (`Kola Dashboard Shell.dc.html` lines 219-233): a 3-dot confidence
  /// meter + label, a bold title, a "Reason: …" line, then "Not useful"
  /// (outline) beside the filled action button — in that order, that
  /// button chrome (8px corners, not this app's usual pill — copied
  /// faithfully from the export rather than "corrected" to match every
  /// other button here).
  Component _topRecommendation(WorkspaceFinding f) => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:16px;margin-bottom:18px',
        },
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:center;gap:8px;'
                  'margin-bottom:8px',
            },
            [
              _confidenceDots(f.confidence),
              span(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
                },
                [Component.text(_confidenceLabel(f.confidence))],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                  'color:${KolaVar.text};line-height:1.4;margin-bottom:4px',
            },
            [Component.text(f.title)],
          ),
          if (f.detail != null)
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                    'line-height:1.55;max-width:64ch',
              },
              [
                Component.text('Reason: '),
                Component.text(f.detail!),
              ],
            ),
          div(
            attributes: {
              'style': 'display:flex;gap:8px;flex-wrap:wrap;margin-top:14px',
            },
            [
              _notUsefulButton(f),
              if (_routeFor(f) case final route?)
                Link(
                  to: route,
                  attributes: {
                    'class': 'kola-pressable',
                    'style': 'padding:8px 16px;'
                        'border-radius:${KolaRadius.sm};border:none;'
                        'background:${KolaVar.accentFill};'
                        'color:${KolaVar.accentText};text-decoration:none;'
                        'font-size:${KolaType.small};font-weight:600',
                  },
                  children: [Component.text(_actionLabelFor(f))],
                ),
            ],
          ),
        ],
      );

  /// 3 dots, matching recommendations_page.dart's identical helper
  /// (kept as a private copy rather than shared — see that file's own
  /// comment on why: two private State methods, not worth a components/
  /// file yet). Colour thresholds are that page's, not
  /// [KolaConfidenceStyle.fromScore]'s slightly different ones — this
  /// card and the Recommendations list read the same underlying
  /// WorkspaceFinding data and must tier it identically, or the same
  /// 0.62 would render "medium" in one place and "high" in the other.
  Component _confidenceDots(double confidence) {
    final List<String> colors;
    if (confidence >= 0.8) {
      colors = [KolaVar.success, KolaVar.success, KolaVar.success];
    } else if (confidence >= 0.5) {
      colors = [KolaVar.warning, KolaVar.warning, KolaVar.border];
    } else {
      colors = [KolaVar.danger, KolaVar.border, KolaVar.border];
    }
    return div(
      attributes: {'style': 'display:flex;gap:3px'},
      [
        for (final c in colors)
          span(
            attributes: {
              'style': 'width:6px;height:6px;'
                  'border-radius:${KolaRadius.circle};background:$c',
            },
            [],
          ),
      ],
    );
  }

  /// The design's own copy shape is "{tier} confidence · {score}" (e.g.
  /// "Medium confidence · 0.62"). Every finding this codebase detects
  /// today is counted rather than judged — confidence is always exactly
  /// 1.0 — and printing a tier name over a manufactured-looking score
  /// for a deterministic count is the "dressing certainty up" this
  /// codebase has already decided against elsewhere (see
  /// recommendations_page.dart's identical reasoning). So 1.0 keeps the
  /// honest "Counted, not guessed" wording; anything less (a future,
  /// genuinely probabilistic detector) renders the design's own
  /// tier-plus-score shape, which is accurate once confidence is real.
  String _confidenceLabel(double confidence) {
    if (confidence >= 1.0) return 'Counted, not guessed';
    final tier = confidence >= 0.8
        ? 'High'
        : confidence >= 0.5
            ? 'Medium'
            : 'Low';
    return '$tier confidence · ${confidence.toStringAsFixed(2)}';
  }

  /// The design's "Not useful" button — same dismiss call
  /// [_dismissButton] makes for the plain list rows below, under the
  /// export's own label and chrome (outline, 8px corners) rather than
  /// this app's usual pill, since this card copies the export's button
  /// shapes literally — see this method's caller's own comment.
  Component _notUsefulButton(WorkspaceFinding f) {
    final busy = f.id != null && _dismissing.contains(f.id);
    return button(
      attributes: {
        'type': 'button',
        if (busy || f.id == null) 'disabled': '',
        'style': 'background:transparent;'
            'border:1px solid ${KolaVar.border};color:${KolaVar.mutedStrong};'
            'border-radius:${KolaRadius.sm};padding:8px 14px;'
            'font-size:${KolaType.small};font-family:inherit;'
            'cursor:${busy ? 'default' : 'pointer'}',
      },
      events: {
        'click': (_) {
          if (!busy) _dismissFinding(f);
        },
      },
      [Component.text(busy ? 'Hiding…' : 'Not useful')],
    );
  }

  /// 14b. Renders [builder] against at most [_listCap] of [items] (or all
  /// of them, once [onExpand] has fired), plus a "Show N more" toggle
  /// when there is more than the built list. Generic over the row type
  /// so it works for both the findings list (`_findingsList`) and the
  /// automations list (`_automations`'s own row-builder) without a
  /// second copy of the same cap/expand logic.
  Component _cappedList<T>({
    required List<T> items,
    required bool expanded,
    required void Function() onExpand,
    required Component Function(List<T>) builder,
  }) {
    final overflow = items.length - _listCap;
    final visible = expanded || overflow <= 0
        ? items
        : items.take(_listCap).toList();

    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
      [
        builder(visible),
        if (!expanded && overflow > 0)
          button(
            attributes: {
              'type': 'button',
              'style': 'align-self:flex-start;background:transparent;'
                  'border:none;color:${KolaVar.accent};'
                  'font-size:${KolaType.small};font-weight:600;'
                  'font-family:inherit;cursor:pointer;padding:4px 2px',
            },
            events: {'click': (_) => onExpand()},
            [
              Component.text(
                overflow == 1 ? 'Show 1 more' : 'Show $overflow more',
              ),
            ],
          ),
      ],
    );
  }

  /// Everything else, as rows.
  Component _findingsList(List<WorkspaceFinding> items) => div(
        attributes: {
          'style': 'display:flex;flex-direction:column;'
              'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};overflow:hidden;'
              'background:${KolaVar.card}',
        },
        [
          for (var i = 0; i < items.length; i++) _findingRow(items[i], i),
        ],
      );

  Component _findingRow(WorkspaceFinding f, int index) {
    final route = _routeFor(f);
    final busy = f.id != null && _dismissing.contains(f.id);

    final body = <Component>[
      _severityDot(f.severity),
      div(
        attributes: {'style': 'flex:1;min-width:0'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.text};'
                  'line-height:1.4',
            },
            [Component.text(f.title)],
          ),
          if (f.detail != null)
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                    'line-height:1.45;margin-top:2px;overflow:hidden;'
                    'text-overflow:ellipsis;white-space:nowrap',
              },
              [Component.text(f.detail!)],
            ),
        ],
      ),
      span(
        attributes: {
          'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
              'white-space:nowrap',
        },
        [Component.text(_age(f))],
      ),
    ];

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:10px;padding:12px 14px;'
            'opacity:${busy ? '0.5' : '1'};'
            '${index > 0 ? 'border-top:1px solid ${KolaVar.border}' : ''}',
      },
      [
        // A Link ONLY when there is somewhere real to go. A row that
        // looks clickable and does nothing is the dead-link problem in
        // miniature, and half these findings are about the workspace
        // rather than one row.
        if (route != null)
          Link(
            to: route,
            attributes: {
              'class': 'kola-nav-row',
              'style': 'display:flex;align-items:center;gap:10px;flex:1;'
                  'min-width:0;text-decoration:none;color:inherit',
            },
            children: body,
          )
        else
          div(
            attributes: {
              'style': 'display:flex;align-items:center;gap:10px;flex:1;'
                  'min-width:0',
            },
            body,
          ),
        _dismissButton(f),
      ],
    );
  }

  Component _dismissButton(WorkspaceFinding f) {
    final busy = f.id != null && _dismissing.contains(f.id);
    return button(
      attributes: {
        'type': 'button',
        'aria-label': 'Dismiss: ${f.title}',
        if (busy) 'disabled': '',
        'style': 'flex:none;padding:7px 12px;'
            'border-radius:${KolaRadius.pill};border:1px solid transparent;'
            'background:transparent;color:${KolaVar.muted};'
            'font-family:inherit;font-size:${KolaType.tiny};font-weight:600;'
            'cursor:${busy ? 'default' : 'pointer'}',
      },
      events: {
        'click': (_) {
          if (!busy) _dismissFinding(f);
        },
      },
      // "I know" rather than "Dismiss": it is what the owner is actually
      // saying, and it makes clear this is an acknowledgement rather than
      // a claim to have fixed anything.
      [Component.text(busy ? 'Hiding…' : 'I know')],
    );
  }

  Component _severityDot(int severity) => span(
        attributes: {
          'style': 'width:7px;height:7px;flex:none;'
              'border-radius:${KolaRadius.circle};'
              'background:${severity <= 1 ? KolaVar.danger : severity == 2 ? KolaVar.warning : KolaVar.muted}',
          'aria-hidden': 'true',
        },
        [],
      );

  /// "6 days" — the whole reason these are stored rather than computed.
  String _age(WorkspaceFinding f) {
    final d = DateTime.now().toUtc().difference(f.firstSeenAt);
    if (d.inMinutes < 60) return 'just now';
    if (d.inHours < 24) {
      return d.inHours == 1 ? 'for an hour' : 'for ${d.inHours} hours';
    }
    final days = d.inDays;
    if (days == 1) return 'for a day';
    if (days < 14) return 'for $days days';
    final weeks = days ~/ 7;
    return weeks == 1 ? 'for a week' : 'for $weeks weeks';
  }

  /// Where a finding leads, or null when there is nowhere honest.
  ///
  /// Driven by subjectType rather than kind, so a new detector on an
  /// existing subject gets its link for free — and a detector about the
  /// workspace itself correctly gets none.
  String? _routeFor(WorkspaceFinding f) => switch (f.subjectType) {
        'product' when f.subjectId != null => '/catalog/${f.subjectId}',
        'conversation' => '/conversations',
        'ticket' => '/operations',
        'document' => '/knowledge',
        _ => switch (f.kind) {
            'product_out_of_stock' || 'product_low_stock' ||
            'product_missing_price' =>
              '/catalog',
            'knowledge_empty' => '/knowledge',
            'no_channel_connected' => '/integrations',
            'ticket_due_soon' => '/operations',
            _ => null,
          },
      };

  String _actionLabelFor(WorkspaceFinding f) => switch (f.subjectType) {
        'product' => 'Open this product',
        'conversation' => 'Reply now',
        'ticket' => 'Open the ticket',
        'document' => 'Open Knowledge',
        _ => switch (f.kind) {
            'no_channel_connected' => 'Connect a channel',
            'knowledge_empty' => 'Teach kolaa something',
            'ticket_due_soon' => 'Open Operations',
            _ => 'Take a look',
          },
      };

  Future<void> _dismissFinding(WorkspaceFinding f) async {
    final id = f.id;
    if (id == null) return;
    setState(() => _dismissing = {..._dismissing, id});
    try {
      await component.client.finding.dismissFinding(
        component.accessToken,
        component.workspaceId,
        id,
      );
      if (!mounted) return;
      // Removed locally rather than by reloading. A full reload would
      // re-run the sweep, which is several queries, to learn one thing
      // this already knows.
      setState(() {
        _findings = [for (final x in _findings) if (x.id != id) x];
        _dismissing = {..._dismissing}..remove(id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dismissing = {..._dismissing}..remove(id));
    }
  }

  /// Shown when nothing needs attention.
  ///
  /// An empty "Needs your attention" heading over blank space reads as
  /// a failure to load. Saying nothing needs them is the actual news,
  /// and it is good news.
  Component _allClear() => div(
        attributes: {
          'style': 'background:${KolaVar.successBg};'
              'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:16px;'
              'display:flex;align-items:center;gap:10px',
        },
        [
          div(
            attributes: {'style': 'color:${KolaVar.successBright};display:flex'},
            [kolaIcon(Icons.checkSquare, size: 17)],
          ),
          span(
            attributes: {
              'style': 'font-size:${KolaType.bodyLg};color:${KolaVar.text}',
            },
            [Component.text('Nothing needs you right now.')],
          ),
        ],
      );

  /// "What kola learned" — `Kola Dashboard Shell.dc.html`'s own
  /// `learnedItems` are two specific insight lines ("Customers most
  /// often ask about delivery time to Ikeja and Lekki.", "Ankara fabric
  /// restocks sell out within 48 hours on average."). Those are
  /// TOPIC-EXTRACTION output — what customers ask about most, which
  /// products restock fastest — and nothing in this codebase computes
  /// that: grepped kola_server for any topic/most-asked/FAQ-pattern
  /// aggregation and found none (bot_knowledge_service.dart's "topic"
  /// hits are about knowledge-base indexing, not conversation-content
  /// analysis). Copying the export's literal sentences would be exactly
  /// the fabricated-fact case DESIGN_DELTA.md forbids — they would be
  /// false, or at best a stale demo generalised to every workspace.
  ///
  /// So the SHAPE matches (a card, a short list of plain-text lines, no
  /// bullets) but the CONTENT is the honest thing this build can say
  /// about what kolaa has learned: how much it has to cite, and what
  /// part of that is still processing. Named here rather than silently
  /// swapped, per this file's own header on "no invented numbers".
  Component _knowledgeLines() {
    final indexed = _documents.where((d) => d.status == 'indexed').length;
    final pending = _documents.length - indexed;

    final lines = <String>[
      indexed == 0
          ? 'kolaa has nothing to cite yet — anything you add becomes '
              'searchable within a few seconds.'
          : indexed == 1
              ? 'kolaa is answering customers from 1 document you taught it.'
              : 'kolaa is answering customers from $indexed documents you taught it.',
      if (pending > 0)
        pending == 1
            ? '1 document is still being processed — not searchable yet.'
            : '$pending documents are still being processed — not searchable yet.',
    ];

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};padding:14px 16px;'
            'display:flex;flex-direction:column;gap:10px',
      },
      [
        for (final l in lines)
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.text}',
            },
            [Component.text(l)],
          ),
      ],
    );
  }

  /// Phase 14/174. A small preview of the real Timeline (event_endpoint
  /// .dart's listTimeline, capped at [_timelinePreviewCap]) — time +
  /// title only, per the design: "no dots/tags needed at this small
  /// scale" (those live on the full /timeline page). The section
  /// header carries the "View full timeline →" link the design shows.
  Component _changedToday() => div(
        attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:baseline;'
                  'justify-content:space-between;gap:10px',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.body};font-weight:700;'
                      'color:${KolaVar.muted};letter-spacing:0.02em',
                },
                [Component.text('Changed today')],
              ),
              Link(
                to: '/timeline',
                attributes: {
                  'style': 'font-size:${KolaType.small};font-weight:600;'
                      'color:${KolaVar.accent};text-decoration:none',
                },
                children: [Component.text('View full timeline →')],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'display:flex;flex-direction:column;'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};overflow:hidden;'
                  'background:${KolaVar.card}',
            },
            [
              for (var i = 0; i < _timelineEvents.length; i++)
                _changedTodayRow(_timelineEvents[i], i),
            ],
          ),
        ],
      );

  Component _changedTodayRow(Event e, int index) => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:10px;'
              'padding:10px 14px;font-size:${KolaType.small};'
              'color:${KolaVar.text};'
              '${index > 0 ? 'border-top:1px solid ${KolaVar.border}' : ''}',
        },
        [
          span(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                  'width:44px;flex:none;font-variant-numeric:tabular-nums',
            },
            [Component.text(_shortTime(e.occurredAt))],
          ),
          span(
            attributes: {'style': 'flex:1;min-width:0'},
            [Component.text(_timelineTitle(e))],
          ),
        ],
      );

  static String _shortTime(DateTime utc) {
    final local = utc.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute$period';
  }

  /// A small, deliberately plainer copy of timeline_page.dart's own
  /// [_describe] title logic — this preview only needs the title, not
  /// the category/dot/amount the full page also renders, and the two
  /// switches are short enough that sharing them isn't worth a new
  /// shared file for two call sites (same "copy at two, extract at
  /// three" call intelligence_page.dart's own header already makes).
  static String _timelineTitle(Event e) {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(e.payloadJson);
      payload = decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      payload = const {};
    }
    return switch (e.eventType) {
      'sale_completed' => 'Sale completed',
      'payment_confirmed' => 'Payment confirmed',
      'new_conversation' => 'New conversation started',
      'agent_drafted' => '${payload['name'] ?? 'An agent'} was drafted',
      'agent_published' => '${payload['name'] ?? 'An agent'} went live',
      'agent_paused' => '${payload['name'] ?? 'An agent'} was paused',
      'errand_executed' => 'An errand ran',
      'errand_rows_mapped_to_customers' => 'Customers matched from an import',
      _ => e.eventType.replaceAll('_', ' '),
    };
  }

  Component _section(String title, Component body) => div(
        attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};font-weight:700;'
                  'color:${KolaVar.muted};letter-spacing:0.02em',
            },
            [Component.text(title)],
          ),
          body,
        ],
      );

  static String _formatDate(DateTime d) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}
