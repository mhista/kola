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
  List<Bot> _bots = const [];
  List<Errand> _errands = const [];

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
      ]);

      if (!mounted) return;
      setState(() {
        _conversations = results[0].cast<Conversation>();
        _escalated = results[1].cast<Conversation>();
        _tickets = results[2].cast<SupportTicket>();
        _documents = results[3].cast<KnowledgeDocument>();
        _bots = results[4].cast<Bot>();
        _errands = results[5].cast<Errand>();
        _phase = _Phase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = e.toString();
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
      attributes: {
        'style': 'max-width:1040px;margin:0 auto;width:100%;'
            'padding:28px 20px 40px;display:flex;flex-direction:column;gap:22px',
      },
      [
        _greeting(),
        ...switch (_phase) {
          _Phase.loading => _skeletons(),
          _Phase.error => [_errorCard()],
          _Phase.ready => _isEmpty ? _setup() : _briefing(),
        },
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

  List<Component> _setup() {
    final steps = <({String title, String body, String cta, String route, bool done})>[
      (
        title: 'Create a bot',
        body: 'The thing that answers your customers. One is enough to start.',
        cta: 'Create a bot',
        route: '/bots/new',
        done: _bots.isNotEmpty,
      ),
      (
        title: 'Connect a channel',
        body: 'WhatsApp or Telegram — wherever your customers already message you.',
        cta: 'Connect a channel',
        route: '/integrations',
        done: false,
      ),
      (
        title: 'Teach kola about the business',
        body: 'Paste a price list, FAQ or returns policy. Its first answers cite '
            'this instead of guessing.',
        cta: 'Add knowledge',
        route: '/knowledge',
        done: _documents.isNotEmpty,
      ),
    ];

    return [
      div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.xl};padding:28px 22px',
        },
        [
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
                  'line-height:1.5;margin-bottom:20px;max-width:460px',
            },
            [
              Component.text(
                'Three steps ground it in real answers instead of guesses.',
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'display:flex;flex-direction:column;gap:10px',
            },
            [for (var i = 0; i < steps.length; i++) _setupStep(i + 1, steps[i])],
          ),
        ],
      ),
    ];
  }

  Component _setupStep(
    int number,
    ({String title, String body, String cta, String route, bool done}) step,
  ) {
    return div(
      attributes: {
        'style': 'background:${KolaVar.bg};'
            'border:1px solid ${step.done ? KolaVar.success : KolaVar.border};'
            'border-radius:${KolaRadius.md};padding:14px;'
            'display:flex;align-items:center;gap:12px;flex-wrap:wrap;'
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
        Link(
          to: step.route,
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
    final attention = _attentionItems();

    final hint = NextSteps.choose(
      hasBot: _bots.isNotEmpty,
      hasDocuments: _documents.isNotEmpty,
      hasConversations: _conversations.isNotEmpty,
      commerceEnabled: component.gate.isEnabled(Features.commerceCatalog),
      // No catalog endpoint exists yet, so this is always false and the
      // products hint never fires. Wired now rather than later so it
      // starts working the moment the catalog does, instead of being
      // forgotten.
      hasProducts: false,
      dismissed: _dismissed,
    );

    return [
      if (hint != null) NextStepHint(step: hint, onDismiss: _dismissHint),
      _stats(),
      if (_noActivityYet)
        _waitingCard()
      else if (attention.isNotEmpty)
        _section('Needs your attention', _attentionList(attention))
      else
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
  Component _stats() {
    final gate = component.gate;

    final stats = <({String label, String value, String? note})>[
      (label: 'Conversations', value: '${_conversations.length}', note: null),
      if (gate.isEnabled(Features.escalation))
        (label: 'Waiting on you', value: '${_escalated.length}', note: null),
      if (gate.isEnabled(Features.memoryDocuments))
        (label: 'Documents learned', value: '${_documents.length}', note: null),

      // Announced on the landing page, not shipped yet.
      if (!gate.isEnabled(Features.commerceCore))
        (
          label: 'Sales this week',
          value: '—',
          note: 'Starts counting when the sales counter arrives.',
        ),
      if (!gate.isEnabled(Features.commerceCatalog))
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
  List<({String label, String meta, String tone, String route})> _attentionItems() {
    final items = <({String label, String meta, String tone, String route})>[];
    final now = DateTime.now();

    if (_escalated.isNotEmpty) {
      items.add((
        label: _escalated.length == 1
            ? '1 conversation is waiting for a human'
            : '${_escalated.length} conversations are waiting for a human',
        meta: 'Escalated',
        tone: KolaVar.danger,
        route: '/conversations',
      ));
    }

    final breaching = _tickets
        .where((t) => t.status != 'resolved' && t.status != 'closed')
        .where((t) => t.slaDeadline.isAfter(now))
        .where((t) => t.slaDeadline.difference(now) < const Duration(hours: 2))
        .length;

    if (breaching > 0) {
      items.add((
        label: breaching == 1
            ? '1 support ticket is close to its deadline'
            : '$breaching support tickets are close to their deadline',
        meta: 'Within 2 hours',
        tone: KolaVar.warning,
        route: '/operations',
      ));
    }

    // Already past deadline is a separate, worse case — collapsing it
    // into "close to deadline" would let the most urgent thing on the
    // page read as the least.
    final overdue = _tickets
        .where((t) => t.status != 'resolved' && t.status != 'closed')
        .where((t) => t.slaDeadline.isBefore(now))
        .length;

    if (overdue > 0) {
      items.insert(0, (
        label: overdue == 1
            ? '1 support ticket is past its deadline'
            : '$overdue support tickets are past their deadline',
        meta: 'Overdue',
        tone: KolaVar.danger,
        route: '/operations',
      ));
    }

    return items;
  }

  Component _attentionList(
    List<({String label, String meta, String tone, String route})> items,
  ) =>
      div(
        attributes: {
          'style': 'display:flex;flex-direction:column;'
              'border:1px solid ${KolaVar.border};border-radius:${KolaRadius.lg};'
              'overflow:hidden;background:${KolaVar.card}',
        },
        [
          for (var i = 0; i < items.length; i++)
            Link(
              to: items[i].route,
              attributes: {
                'class': 'kola-nav-row',
                'style': 'display:flex;align-items:center;gap:12px;'
                    'padding:13px 16px;text-decoration:none;'
                    'color:${KolaVar.text};font-size:${KolaType.bodyLg};'
                    '${i > 0 ? 'border-top:1px solid ${KolaVar.border}' : ''}',
              },
              children: [
                span(
                  attributes: {
                    'style': 'width:7px;height:7px;flex:none;'
                        'border-radius:${KolaRadius.circle};'
                        'background:${items[i].tone}',
                  },
                  [],
                ),
                span(attributes: {'style': 'flex:1'}, [Component.text(items[i].label)]),
                span(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                        'white-space:nowrap',
                  },
                  [Component.text(items[i].meta)],
                ),
              ],
            ),
        ],
      );

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
