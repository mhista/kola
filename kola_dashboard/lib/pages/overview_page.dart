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
//   knowledge.listDocuments     → what kola has been taught
//   bot.listBotsForWorkspace    → whether setup is actually finished

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/ask_kola.dart';
import '../components/next_step_hint.dart';
import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/feature_gate.dart';
import '../services/local_storage.dart';
import '../services/error_text.dart';
import '../theme.dart';

class OverviewPage extends StatefulComponent {
  const OverviewPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.greetingName,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

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

  /// What the server's sweep noticed. See WorkspaceSweepService.
  List<WorkspaceFinding> _findings = const [];

  /// Findings currently being dismissed, so the row can say so.
  Set<int> _dismissing = {};
  List<Bot> _bots = const [];
  List<Errand> _errands = const [];
  List<ConnectorStatus> _connectors = const [];

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

  @override
  void initState() {
    super.initState();
    final raw = LocalStorage.getItem(_dismissedKey) ?? '';
    _dismissed = raw.split(',').where((s) => s.isNotEmpty).toSet();
    _load();
  }

  void _dismissHint(String id) {
    final next = {..._dismissed, id};
    LocalStorage.setItem(_dismissedKey, next.join(','));
    setState(() => _dismissed = next);
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
            ? component.client.product.listProducts(
                token,
                id,
                // Explicit: Serverpod drops defaults when generating the
                // client, so this is `required` there even though the
                // endpoint declares it optional.
                includeArchived: false,
              )
            : Future.value(const <Product>[]),

        // Ninth read: what needs the owner's attention.
        //
        // This endpoint SWEEPS and then returns — see FindingEndpoint on
        // why, and on what changes when a scheduler exists. It is in the
        // same Future.wait as everything else because it does not depend
        // on any of them.
        component.client.finding.listFindings(token, id),
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
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'white-space:nowrap',
          },
          [Component.text(_formatDate(now))],
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
  ///   3. Teach kola about the business — done: false
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
        title: 'Teach kola about the business',
        // Rewritten. The export's line — "Paste a price list, FAQ or
        // policy — its first answers cite this, not a guess" — names
        // three document types and leaves the owner to infer why it
        // matters. Most shop owners do not have a "policy" document,
        // and the ones who do will not think of it as the thing kola
        // needs. So this names the FACTS a customer actually asks
        // about, then states the consequence of skipping it plainly.
        body: 'Your prices, what you have in stock, where you deliver, '
            'your refund rules, your opening hours. kola answers from '
            'whatever you give it — and cites it. Give it nothing and it '
            'has to guess.',
        // "Teach kola something" described the intent but not the
        // action, so it was unclear what pressing it would do.
        cta: 'Add knowledge',
        route: '/knowledge',
        icon: Icons.book,
        done: _documents.isNotEmpty,
      ),
    ];

    final remaining = steps.where((s) => !s.done).length;
    final tail = remaining == 0
        ? " That's all three done — kola is working with real answers now."
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
            [Component.text('kola is still learning your business')],
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
  /// cannot tell whether kola is working or silently broken.
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
          _findingsList(attention.skip(1).toList()),
        )
      else if (attention.isEmpty)
        _allClear(),
      _section('What kola knows', _knowledgeSummary()),
      if (_errands.isNotEmpty) _section('Automations running', _automations()),

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

  /// Errands kola can call mid-conversation.
  ///
  /// `active` is what the design means by "running" — an errand exists
  /// but disabled is not running, and showing it as such would tell an
  /// owner a thing is happening that is not.
  Component _automations() {
    final active = _errands.where((e) => e.status == 'active').toList();

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
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
                span(attributes: {'style': 'flex:1;min-width:0'},
                    [Component.text(active[i].name)]),
              ],
            ),
      ],
    );
  }

  /// Set up, connected, nothing has come in yet.
  ///
  /// The job of this card is to answer the question the person is
  /// actually asking — "is this thing working?" — rather than to fill
  /// space. So it states plainly that kola is watching, and gives the
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
                [Component.text('kola is set up and listening')],
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
                'and anything kola cannot answer confidently is passed to you '
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
  ///   MEASURED, AND THE ANSWER IS ZERO — 0 conversations means kola
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

      // Announced on the landing page, not shipped yet.
      if (!gate.isEnabled(Features.commerceCore))
        (
          label: 'Sales this week',
          value: '—',
          note: 'Starts counting when the sales counter arrives.',
        ),

      // Products, in BOTH states.
      //
      // Only the locked branch existed, so releasing the catalog deleted
      // the card instead of filling it in. A placeholder written without
      // its counterpart is a card that disappears the moment the feature
      // it was waiting for arrives — the opposite of what it was for.
      if (gate.isEnabled(Features.commerceCatalog))
        _stat('Products', _products.length,
            'Add or import your first product and it appears here.')
      else
        (
          label: 'Products',
          value: '—',
          note: 'Available once you can add a catalog.',
        ),
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

  /// The single worst thing, as the design's own card.
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
              _severityDot(f.severity),
              span(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};font-weight:600;'
                      'color:${KolaVar.muted}',
                },
                [
                  // The design shows "Medium confidence · 0.62". Every
                  // finding here is counted rather than judged, so it
                  // says so plainly instead of dressing certainty up as
                  // a score.
                  Component.text(
                    f.confidence >= 1.0
                        ? 'Counted, not guessed'
                        : '${(f.confidence * 100).round()}% confident',
                  ),
                ],
              ),
              span(
                attributes: {
                  'style': 'flex:1;text-align:right;'
                      'font-size:${KolaType.tiny};color:${KolaVar.muted}',
                },
                [Component.text(_age(f))],
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
              [Component.text(f.detail!)],
            ),
          div(
            attributes: {
              'style': 'display:flex;gap:8px;flex-wrap:wrap;margin-top:14px',
            },
            [
              if (_routeFor(f) case final route?)
                Link(
                  to: route,
                  attributes: {
                    'class': 'kola-pressable',
                    'style': 'padding:9px 16px;'
                        'border-radius:${KolaRadius.pill};border:none;'
                        'background:${KolaVar.accentFill};'
                        'color:${KolaVar.accentText};text-decoration:none;'
                        'font-size:${KolaType.tiny};font-weight:600',
                  },
                  children: [Component.text(_actionLabelFor(f))],
                ),
              _dismissButton(f),
            ],
          ),
        ],
      );

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
            'knowledge_empty' => 'Teach kola something',
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

  Component _knowledgeSummary() {
    final indexed = _documents.where((d) => d.status == 'indexed').length;
    final pending = _documents.length - indexed;

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:16px;'
            'font-size:${KolaType.body};color:${KolaVar.mutedStrong};'
            'line-height:1.6',
      },
      [
        Component.text(
          indexed == 0
              ? 'kola has nothing to cite yet. Anything you add becomes '
                  'searchable within a few seconds.'
              : indexed == 1
                  ? 'kola is answering from 1 document.'
                  : 'kola is answering from $indexed documents.',
        ),
        if (pending > 0)
          div(
            attributes: {
              'style': 'margin-top:8px;font-size:${KolaType.tiny};'
                  'color:${KolaVar.warning}',
            },
            [
              Component.text(
                pending == 1
                    ? '1 document is still being processed.'
                    : '$pending documents are still being processed.',
              ),
            ],
          ),
      ],
    );
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
