// bot_detail_chat_page.dart — the agent detail screen.
//
// REBUILT against Kola Bot Detail Chat.dc.html, structure-first: the
// export's state keys and arrays were listed before any code was
// written, and the old page was not opened until the end.
//
//   state : tab · botKey · showBotSwitcher · publishedOverride ·
//           setupStarted · extraMsgs · draftText
//   arrays: BOTS(3) · ERRANDS(4) · BASE_TRANSCRIPT(6)
//
// ── THREE TABS, ONE SCREEN ───────────────────────────────────────────
//
//   Manage  what this agent does, knows, and hands off — the default
//   Setup   Bot Mother: describe the business, it drafts the plan
//   Code    the developer view (bot_detail_dev_page.dart)
//
// The previous version showed "Talking to Bot Mother conversationally
// isn't built yet" and offered two escape hatches. That is the stub this
// replaces.
//
// ── THE HEADER IS A BOT SWITCHER ─────────────────────────────────────
//
// Per the export: avatar, name, archetype chip, and a dropdown listing
// every agent with its publish state plus "New agent". The bots list
// page stays — it is a good addition that no export contains — but from
// inside an agent you switch without going back out.
//
// ── STATS: MEASURED OR HONEST, NEVER PLAUSIBLE ───────────────────────
//
// The design shows "89% +2%", "6m −1m", "5 +1". Those are business
// facts, and inventing them is the one thing that outranks following the
// design. So:
//
//   Handled without escalation  MEASURED — conversations for this bot,
//                               minus escalated ones
//   Escalated to you            MEASURED — listEscalated for this bot
//   Avg response time           NOT MEASURED — needs per-message timing
//                               across every conversation; renders as
//                               "Not measured yet" rather than a number
//
// The deltas (+2%, −1m, +1) need a historical series nothing records
// yet. They are omitted rather than faked. Both are work items, not
// design deviations — see DESIGN_DELTA.md.
//
// ── ERRANDS ARE WORKSPACE-SCOPED, THE DESIGN IMPLIES PER-BOT ─────────
//
// Errand has no botId. Every errand in the workspace is callable by
// every bot, so listing them all under an agent is TRUE today, not a
// shortcut. If errands should ever belong to one agent, that is a schema
// change and a deliberate decision — recorded rather than assumed.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../theme.dart';

class BotDetailChatPage extends StatefulComponent {
  const BotDetailChatPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.workspaceName,
    required this.botId,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  /// The business name. The design's live preview is a WhatsApp thread
  /// headed by the BUSINESS, not the bot — that is what the customer
  /// sees on their phone.
  final String workspaceName;

  /// Parsed from the route param by the caller. Kept as an int here so
  /// every client call is type-correct at the call site rather than
  /// parsing in three places.
  final int botId;

  final FeatureGate gate;

  @override
  State<BotDetailChatPage> createState() => _BotDetailChatPageState();
}

class _BotDetailChatPageState extends State<BotDetailChatPage> {
  String _tab = 'manage';
  bool _showSwitcher = false;

  Bot? _bot;
  List<Bot> _allBots = const [];
  List<Errand> _errands = const [];
  List<Channel> _channels = const [];
  List<Conversation> _convos = const [];
  List<Conversation> _escalated = const [];
  List<KnowledgeDocument> _docs = const [];

  bool _loading = true;
  String? _loadError;

  // Setup (Bot Mother)
  String _draftText = '';
  bool _drafting = false;
  String? _setupError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final c = component.client;
    final t = component.accessToken;
    final w = component.workspaceId;
    try {
      // Parallel: six sequential round trips would be most of a second
      // before anything draws.
      final results = await Future.wait([
        c.bot.getBot(t, w, component.botId),
        c.bot.listBotsForWorkspace(t, w),
        c.errand.listErrandsForWorkspace(t, w),
        c.channel.listChannelsForBot(t, w, component.botId),
        c.conversation.listAll(t, w),
        c.conversation.listEscalated(t, w),
        c.knowledge.listDocuments(t, w),
      ]);
      if (!mounted) return;
      setState(() {
        _bot = results[0] as Bot;
        _allBots = results[1] as List<Bot>;
        _errands = results[2] as List<Errand>;
        _channels = results[3] as List<Channel>;
        _convos = results[4] as List<Conversation>;
        _escalated = results[5] as List<Conversation>;
        _docs = results[6] as List<KnowledgeDocument>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = ErrorText.of(e);
        _loading = false;
      });
    }
  }


  // ── Measured stats ─────────────────────────────────────────────────

  List<Conversation> get _mine =>
      [for (final c in _convos) if (c.botId == component.botId) c];

  List<Conversation> get _mineEscalated =>
      [for (final c in _escalated) if (c.botId == component.botId) c];

  /// Null when there is nothing to measure — a workspace with no
  /// conversations has no handling rate, and 0% would be a lie.
  int? get _handledPct {
    final total = _mine.length;
    if (total == 0) return null;
    return (((total - _mineEscalated.length) / total) * 100).round();
  }

  /// Conversations for this bot whose last message landed inside 7 days.
  int get _convosThisWeek {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 7));
    return _mine.where((c) => c.lastMessageAt.isAfter(cutoff)).length;
  }

  bool get _isPublished => (_bot?.status ?? '') == 'published';

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    if (_loading) return _shell([_skeleton()]);
    if (_loadError != null) return _shell([_errorState()]);
    return _shell([
      if (_tab == 'manage') _manageTab() else _setupTab(),
    ]);
  }

  Component _shell(List<Component> body) => div(
        attributes: {'style': 'padding:${KolaSpace.lg};max-width:1240px;margin:0 auto;width:100%;box-sizing:border-box'},
        [_header(), ...body],
      );

  // ── Header + bot switcher ──────────────────────────────────────────

  Component _header() {
    final bot = _bot;
    return div(
      attributes: {
        'style': 'display:flex;flex-wrap:wrap;gap:12px;align-items:center;'
            'margin-bottom:${KolaSpace.md};position:relative',
      },
      [
        // Back to the agents list. Reads as an ACTION — accent colour,
        // semibold, with a real chevron. A muted "‹ Dashboard" in body
        // weight looked like a caption, which is what it was reported as.
        //
        // There is no chevron-left in Icons, so arrowRight is rotated
        // via kolaIcon's extraStyle rather than adding a near-duplicate
        // path to the icon set.
        Link(
          to: '/bots',
          attributes: {
            'style': 'display:inline-flex;align-items:center;gap:6px;'
                'font-size:${KolaType.small};font-weight:600;'
                'color:${KolaVar.accent};text-decoration:none;'
                'white-space:nowrap;padding:6px 10px;'
                'border-radius:${KolaRadius.md}',
          },
          children: [
            kolaIcon(Icons.arrowRight,
                size: 14, extraStyle: 'transform:rotate(180deg)'),
            Component.text('Dashboard'),
          ],
        ),
        // The whole identity block is ONE control, not a label with a
        // glyph beside it. Border + background + a real chevron are what
        // make it read as openable; a bare '⌄' next to text does not.
        button(
          attributes: {
            'type': 'button',
            'aria-label': 'Switch agent',
            'aria-haspopup': 'menu',
            'aria-expanded': _showSwitcher ? 'true' : 'false',
            'style': 'display:inline-flex;align-items:center;gap:10px;'
                'padding:6px 12px 6px 6px;cursor:pointer;'
                'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.pill};'
                'background:${_showSwitcher ? KolaVar.pill : 'transparent'};'
                'font-family:inherit',
          },
          events: {
            'click': (e) {
              e.stopPropagation();
              setState(() => _showSwitcher = !_showSwitcher);
            },
          },
          [
            div(
              attributes: {
                'style': 'width:30px;height:30px;flex:none;'
                    'border-radius:${KolaRadius.md};'
                    'background:${KolaVar.tintSurface(1)};'
                    'color:${KolaVar.tintIcon(1)};display:flex;'
                    'align-items:center;justify-content:center',
              },
              [kolaIcon(Icons.bot, size: 17)],
            ),
            span(
              attributes: {
                'style': 'font-family:${KolaFonts.display};'
                    'font-size:${KolaType.subhead};font-weight:700;'
                    'color:${KolaVar.text}',
              },
              [Component.text(bot?.name ?? 'Agent')],
            ),
            span(
              attributes: {
                'style': 'padding:3px 10px;border-radius:${KolaRadius.pill};'
                    'background:${KolaVar.pill};'
                    'color:${KolaVar.mutedStrong};'
                    'font-size:${KolaType.micro};font-weight:600',
              },
              [Component.text(_archetypeLabel(bot?.archetype ?? ''))],
            ),
            span(
              attributes: {
                'style': 'color:${KolaVar.muted};display:flex;'
                    'transition:transform ${KolaMotion.fast};'
                    'transform:rotate(${_showSwitcher ? '180' : '0'}deg)',
              },
              [kolaIcon(Icons.chevronDown, size: 15)],
            ),
          ],
        ),
        div(attributes: {'style': 'flex:1'}, const []),
        _topTabs(),
        span(
          attributes: {
            'style': '${(_isPublished ? KolaTone.positive : KolaTone.neutral).badgeCss};'
                'white-space:nowrap',
          },
          [Component.text(_isPublished ? 'Published' : 'Draft')],
        ),
        if (_showSwitcher) _switcherMenu(),
      ],
    );
  }

  Component _switcherMenu() => div(
        attributes: {
          'style': 'position:absolute;top:44px;left:60px;z-index:40;'
              'min-width:300px;background:${KolaVar.card};'
              'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:6px;'
              'box-shadow:0 18px 44px rgba(0,0,0,.45)',
        },
        [
          for (final b in _allBots)
            Link(
          to: '/bots/${b.id}',
              attributes: {
                'style': 'display:flex;gap:10px;align-items:center;'
                    'padding:10px 12px;border-radius:${KolaRadius.md};'
                    'text-decoration:none;'
                    'background:${b.id == component.botId ? KolaVar.pill : 'transparent'}',
              },
          children: [
                div(
                  attributes: {
                    'style': 'width:28px;height:28px;flex:none;'
                        'border-radius:${KolaRadius.sm};'
                        'background:${KolaVar.tintSurface(1)};'
                        'color:${KolaVar.tintIcon(1)};display:flex;'
                        'align-items:center;justify-content:center',
                  },
                  [kolaIcon(Icons.bot, size: 15)],
                ),
                div(attributes: {'style': 'flex:1;min-width:0'}, [
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.small};font-weight:600;'
                          'color:${KolaVar.text}',
                    },
                    [Component.text(b.name)],
                  ),
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.tiny};'
                          'color:${KolaVar.muted}',
                    },
                    [
                      Component.text(b.status == 'published'
                          ? 'Published'
                          : ((b.knowledgeSeed ?? '').isEmpty
                              ? 'Not set up'
                              : 'Draft')),
                    ],
                  ),
                ]),
              ],
            ),
          div(
            attributes: {
              'style': 'height:1px;background:${KolaVar.border};margin:6px 0',
            },
            const [],
          ),
          Link(
          to: '/bots/new',
            attributes: {
              'style': 'display:flex;gap:10px;align-items:center;'
                  'padding:10px 12px;text-decoration:none;'
                  'color:${KolaVar.accent};font-size:${KolaType.small};'
                  'font-weight:600;gap:10px',
            },
          children: [kolaIcon(Icons.plus, size: 15), Component.text('New agent')],
          ),
        ],
      );

  Component _topTabs() => div(
        attributes: {
          'style': 'display:inline-flex;gap:4px;padding:4px;'
              'border-radius:${KolaRadius.pill};background:${KolaVar.pill}',
        },
        [
          _topTab('manage', 'Manage'),
          _topTab('setup', 'Setup'),
          _codeTab(),
        ],
      );

  Component _topTab(String id, String label) {
    final active = _tab == id;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:7px 16px;border-radius:${KolaRadius.pill};'
            'border:none;font-family:inherit;font-size:${KolaType.small};'
            'font-weight:600;cursor:pointer;'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.mutedStrong}',
      },
      events: {'click': (_) => setState(() => _tab = id)},
      [Component.text(label)],
    );
  }

  /// Code is a separate route, not a tab body — the developer view is
  /// its own page (bot_detail_dev_page.dart), and duplicating it here
  /// would give two copies to keep in step.
  Component _codeTab() => Link(
          to: '/bots/${component.botId}/code',
        attributes: {
          'style': 'padding:7px 16px;border-radius:${KolaRadius.pill};'
              'font-size:${KolaType.small};font-weight:600;'
              'color:${KolaVar.mutedStrong};text-decoration:none',
        },
          children: [Component.text('Code')],
      );

  // ── Manage ─────────────────────────────────────────────────────────

  Component _manageTab() => div([
        _statRow(),
        div(
          attributes: {
            'style': 'display:grid;gap:${KolaSpace.smd};'
                'grid-template-columns:repeat(auto-fit,minmax(330px,1fr));'
                'align-items:start',
          },
          [
            div([_whatItCanDo(), _whatItKnows(), _whereItHandsOff()]),
            div([_handles(), _livePreview()]),
          ],
        ),
      ]);

  Component _statRow() => div(
        attributes: {
          'style': 'display:grid;gap:${KolaSpace.smd};'
              'grid-template-columns:repeat(auto-fit,minmax(210px,1fr));'
              'margin-bottom:${KolaSpace.smd}',
        },
        [
          // NO ZEROES. A business that has not started yet should be told
          // what will appear here, not shown a wall of 0s — "0 conversations,
          // 0 handled, 0 escalated" reads as failure rather than as
          // not-started, and it is the first thing a new owner sees.
          //
          // Note "Escalated to you" is inverted: zero there is GOOD news,
          // so it says so rather than staying silent.
          _statCard(
            'Conversations this week',
            _convosThisWeek == 0 ? null : '$_convosThisWeek',
            'Once customers start messaging, this fills in',
          ),
          _statCard(
            'Handled without escalation',
            _handledPct == null ? null : '$_handledPct%',
            'Shows how much kolaa handles on its own',
          ),
          _statCard(
            'Escalated to you',
            _mineEscalated.isEmpty ? null : '${_mineEscalated.length}',
            'Nothing waiting on you',
          ),
          _statCard('Avg. response time', null, 'Not measured yet'),
        ],
      );

  /// [value] when it is measured; [note] when it is not.
  ///
  /// Never both, and never a number sourced from anywhere but the data.
  Component _statCard(String label, String? value, String? note) => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:${KolaSpace.md}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'margin-bottom:8px',
            },
            [Component.text(label)],
          ),
          if (value != null)
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.display};'
                    'font-size:${KolaType.h2};font-weight:700;'
                    'color:${KolaVar.text}',
              },
              [Component.text(value)],
            )
          else
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                    'font-style:italic;padding:6px 0',
              },
              [Component.text(note ?? 'Not measured yet')],
            ),
        ],
      );

  Component _whatItCanDo() => _card([
        _cardHead('What it can do', '${_errands.length} errands'),
        if (_errands.isEmpty)
          _emptyLine('No errands yet. Errands are the actions kolaa can take '
              'mid-conversation — checking stock, holding an item, escalating '
              'to you.')
        else
          for (final e in _errands) _errandRow(e),
        Link(
          to: '/errands',
          attributes: {
            'style': 'display:block;text-align:center;padding:11px;'
                'margin-top:8px;border:1px dashed ${KolaVar.border};'
                'border-radius:${KolaRadius.md};text-decoration:none;'
                'color:${KolaVar.mutedStrong};font-size:${KolaType.small};'
                'font-weight:600',
          },
          children: [
            span(
              attributes: {
                'style': 'display:inline-flex;align-items:center;gap:7px',
              },
              [kolaIcon(Icons.plus, size: 14), Component.text('Add an errand')],
            ),
          ],
        ),
      ]);

  Component _errandRow(Errand e) {
    final live = e.status == 'live' || e.status == 'active';
    return div(
      attributes: {
        'style': 'display:flex;gap:10px;align-items:center;padding:11px 0;'
            'border-bottom:1px solid ${KolaVar.border}',
      },
      [
        div(
          attributes: {
            'style': 'flex:1;min-width:0;font-size:${KolaType.body};'
                'color:${KolaVar.text}',
          },
          [Component.text(e.name)],
        ),
        span(
          attributes: {
            'style': '${(live ? KolaTone.positive : KolaTone.caution).badgeCss};'
                'white-space:nowrap',
          },
          [Component.text(live ? 'Live' : 'Needs your input')],
        ),
      ],
    );
  }

  Component _whatItKnows() => _card([
        _cardHead('What it knows', null),
        if (_docs.isEmpty)
          _emptyLine('Nothing yet. Until kolaa is taught something it can only '
              'fall back on general answers.')
        else
          for (final d in _docs.take(6))
            div(
              attributes: {
                'style': 'display:flex;gap:10px;align-items:center;'
                    'padding:10px 0;'
                    'border-bottom:1px solid ${KolaVar.border}',
              },
              [
                div(
                  attributes: {
                    'style': 'flex:1;min-width:0;font-size:${KolaType.body};'
                        'color:${KolaVar.text};word-break:break-word',
                  },
                  [Component.text(d.title)],
                ),
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.small};'
                        'color:${KolaVar.muted};white-space:nowrap',
                  },
                  [Component.text('${d.chunkCount} sections')],
                ),
              ],
            ),
        Link(
          to: '/knowledge',
          attributes: {
            'style': 'display:block;text-align:center;padding:11px;'
                'margin-top:8px;border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};text-decoration:none;'
                'color:${KolaVar.text};font-size:${KolaType.small};'
                'font-weight:600',
          },
          children: [Component.text('Open Knowledge Center')],
        ),
      ]);

  Component _whereItHandsOff() => _card([
        _cardHead('Where it hands off', null),
        div(
          attributes: {
            'style': 'font-size:${KolaType.body};color:${KolaVar.mutedStrong};'
                'line-height:1.65',
          },
          [
            Component.text(_escalationProse()),
          ],
        ),
      ]);

  /// Describes the real escalation behaviour in the design's voice.
  ///
  /// The export's version names an amount and a wait ("refund over
  /// ₦20,000 … waits up to 4 hours"). Those are configured thresholds,
  /// and none of them are stored yet, so this describes what actually
  /// happens rather than quoting numbers nothing enforces.
  String _escalationProse() {
    final channel = _channels.isEmpty
        ? 'your notification channel'
        : _channels.first.platformType == 'whatsapp'
            ? 'WhatsApp'
            : _channels.first.platformType;
    return 'Escalates to you when a customer asks for a person, when the '
        'request looks like a complaint, or when nothing in your knowledge '
        'matches with confidence. Sends an alert on $channel and waits for '
        'you to reply before the customer hears anything further.';
  }

  Component _handles() => _card([
        _cardHead('Handles', null),
        if (_channels.isEmpty)
          _emptyLine('No channel connected. Customers cannot reach this agent '
              'until one is.')
        else
          for (final ch in _channels)
            div(
              attributes: {
                'style': 'display:flex;gap:10px;align-items:center;'
                    'padding:11px 0;'
                    'border-bottom:1px solid ${KolaVar.border}',
              },
              [
                div(
                  attributes: {'style': 'color:${KolaVar.muted}'},
                  [kolaIcon(Icons.whatsapp, size: 16)],
                ),
                div(
                  attributes: {
                    'style': 'flex:1;font-size:${KolaType.body};'
                        'color:${KolaVar.text};text-transform:capitalize',
                  },
                  [Component.text(ch.platformType)],
                ),
                span(
                  attributes: {
                    'style': '${(ch.status == 'connected' ? KolaTone.positive : KolaTone.caution).badgeCss}',
                  },
                  [
                    Component.text(
                        ch.status == 'connected' ? 'Connected' : ch.status),
                  ],
                ),
              ],
            ),
        Link(
          to: '/integrations',
          attributes: {
            'style': 'display:block;text-align:center;padding:11px;'
                'margin-top:8px;border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};text-decoration:none;'
                'color:${KolaVar.text};font-size:${KolaType.small};'
                'font-weight:600',
          },
          children: [Component.text('Manage channels')],
        ),
      ]);

  /// The design's live WhatsApp preview. Shows the most recent real
  /// conversation for this agent — not a scripted sample, because a
  /// staged transcript on a live dashboard reads as real activity.
  Component _livePreview() {
    final recent = _mine.isEmpty ? null : _mine.first;
    return _card([
      _cardHead('Live preview', null),
      if (recent == null)
        _emptyLine('No conversations yet. When a customer messages this '
            'agent, the exchange appears here.')
      else ...[
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};font-weight:600;'
                'color:${KolaVar.text};margin-bottom:2px',
          },
          [Component.text(component.workspaceName)],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin-bottom:2px',
          },
          [
            Component.text('with '
                '${recent.displayName ?? recent.externalUserId}'),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin-bottom:12px;text-transform:capitalize',
          },
          [Component.text('${recent.platformType} · ${recent.status}')],
        ),
        Link(
          to: '/operations',
          attributes: {
            'style': 'display:block;text-align:center;padding:11px;'
                'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};text-decoration:none;'
                'color:${KolaVar.text};font-size:${KolaType.small};'
                'font-weight:600',
          },
          children: [Component.text('Open in Operations')],
        ),
      ],
    ]);
  }

  // ── Setup (Bot Mother) ─────────────────────────────────────────────

  Component _setupTab() => div([
        div(
          attributes: {
            'style': 'font-size:${KolaType.bodyLg};font-weight:700;'
                'color:${KolaVar.text};margin-bottom:4px',
          },
          [Component.text('Setting up ${_bot?.name ?? 'this agent'}')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.55;margin-bottom:14px',
          },
          [
            Component.text('Describe the business in plain language — kolaa '
                'drafts the plan as you go.'),
          ],
        ),
        _stepper(),
        div(
          attributes: {
            'style': 'display:grid;gap:${KolaSpace.smd};'
                'grid-template-columns:repeat(auto-fit,minmax(320px,1fr));'
                'align-items:start',
          },
          [_describeCard(), _livePlanCard()],
        ),
      ]);

  Component _stepper() {
    final steps = <(String, bool)>[
      ('Describe', (_bot?.knowledgeSeed ?? '').isNotEmpty),
      ('Errands drafted', _errands.isNotEmpty),
      ('Media', false),
      ('Review', false),
    ];
    return div(
      attributes: {
        'style': 'display:flex;flex-wrap:wrap;gap:14px;align-items:center;'
            'margin-bottom:${KolaSpace.md}',
      },
      [
        for (var i = 0; i < steps.length; i++) ...[
          div(
            attributes: {'style': 'display:flex;gap:7px;align-items:center'},
            [
              div(
                attributes: {
                  'style': 'width:20px;height:20px;border-radius:50%;'
                      'display:flex;align-items:center;'
                      'justify-content:center;font-size:11px;'
                      'font-weight:700;'
                      'background:${steps[i].$2 ? KolaVar.success : KolaVar.pill};'
                      'color:${steps[i].$2 ? KolaVar.accentText : KolaVar.muted}',
                },
                steps[i].$2
                    ? [kolaIcon(Icons.check, size: 12, strokeWidth: 2.4)]
                    : [Component.text('${i + 1}')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};'
                      'color:${steps[i].$2 ? KolaVar.text : KolaVar.muted}',
                },
                [Component.text(steps[i].$1)],
              ),
            ],
          ),
          if (i < steps.length - 1)
            div(
              attributes: {
                'style': 'width:22px;height:1px;background:${KolaVar.border}',
              },
              const [],
            ),
        ],
      ],
    );
  }

  Component _describeCard() => _card([
        _cardHead('What does your business sell?', null),
        textarea(
          attributes: {
            'aria-label': 'Describe your business',
            'placeholder': 'e.g. Ankara fabric and ready-made outfits. '
                'Customers should be able to check prices and stock.',
            'rows': '5',
            'style': 'width:100%;box-sizing:border-box;padding:12px 14px;'
                'border-radius:${KolaRadius.md};'
                'border:1px solid ${KolaVar.border};'
                'background:${KolaVar.bg};color:${KolaVar.text};'
                'font-family:inherit;font-size:${KolaType.body};'
                'line-height:1.6;resize:vertical',
          },
          // Typed callback — see create_bot_page.dart on why the
          // events-map form does not bind.
          onInput: (v) => _draftText = v,
          [Component.text(_draftText)],
        ),
        if (_setupError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                  'line-height:1.5;margin-top:10px',
            },
            [Component.text(_setupError!)],
          ),
        button(
          attributes: {
            'type': 'button',
            if (_drafting) 'disabled': 'disabled',
            'style': 'margin-top:14px;padding:11px 18px;'
                'border-radius:${KolaRadius.md};border:none;'
                'background:${KolaVar.accentFill};'
                'color:${KolaVar.accentText};font-family:inherit;'
                'font-size:${KolaType.body};font-weight:600;'
                'cursor:pointer;opacity:${_drafting ? '0.65' : '1'}',
          },
          events: {
            'click': (_) {
              if (!_drafting) _saveDescription();
            },
          },
          [Component.text(_drafting ? 'Drafting…' : 'Draft the plan')],
        ),
      ]);

  /// Saves the description as the agent's knowledge seed.
  ///
  /// setKnowledgeSeed is the real, existing path. The export also shows
  /// kolaa drafting errands from the same description — that is
  /// createBotFromDescription, which only exists for NEW agents, so
  /// drafting errands into an EXISTING one has no endpoint yet. Recorded
  /// rather than faked with a hardcoded errand list.
  Future<void> _saveDescription() async {
    final text = _draftText.trim();
    if (text.isEmpty) {
      setState(() => _setupError = 'Describe the business first.');
      return;
    }
    setState(() {
      _drafting = true;
      _setupError = null;
    });
    try {
      final updated = await component.client.bot.setKnowledgeSeed(
        component.accessToken,
        component.workspaceId,
        component.botId,
        text,
      );
      if (!mounted) return;
      setState(() {
        _bot = updated;
        _drafting = false;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _drafting = false;
        _setupError = ErrorText.of(e);
      });
    }
  }

  Component _livePlanCard() => _card([
        div(
          attributes: {
            'style': 'font-size:${KolaType.micro};font-weight:700;'
                'letter-spacing:.08em;color:${KolaVar.muted};'
                'margin-bottom:6px',
          },
          [Component.text('LIVE PLAN')],
        ),
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.display};'
                'font-size:${KolaType.title};font-weight:700;'
                'color:${KolaVar.text};margin-bottom:10px',
          },
          [Component.text(_bot?.name ?? 'This agent')],
        ),
        div(
          attributes: {
            'style': 'display:flex;flex-wrap:wrap;gap:6px;margin-bottom:14px',
          },
          [
            span(
              attributes: {
                'style': 'padding:4px 11px;'
                    'border-radius:${KolaRadius.pill};'
                    'background:${KolaVar.pill};'
                    'color:${KolaVar.mutedStrong};'
                    'font-size:${KolaType.micro};font-weight:600',
              },
              [Component.text(_archetypeLabel(_bot?.archetype ?? ''))],
            ),
            for (final ch in _channels)
              span(
                attributes: {
                  'style': 'padding:4px 11px;'
                      'border-radius:${KolaRadius.pill};'
                      'background:${KolaVar.pill};'
                      'color:${KolaVar.mutedStrong};'
                      'font-size:${KolaType.micro};font-weight:600;'
                      'text-transform:capitalize',
                },
                [Component.text(ch.platformType)],
              ),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.micro};font-weight:700;'
                'letter-spacing:.08em;color:${KolaVar.muted};'
                'margin-bottom:8px',
          },
          [Component.text('ERRANDS DRAFTED · ${_errands.length}')],
        ),
        if (_errands.isEmpty)
          _emptyLine('None yet. Describe the business and kolaa will suggest '
              'the actions it should be able to take.')
        else
          for (final e in _errands) _errandRow(e),
      ]);

  // ── Shared ─────────────────────────────────────────────────────────

  // Phase A of the agent architecture correction — mirrors
  // AgentArchetypes.all server-side (kola_server/lib/src/services/
  // agents/agent_archetypes.dart). 'escalations' was never a valid
  // stored value (kept as a defensive case, not a real archetype).
  String _archetypeLabel(String raw) => switch (raw) {
        'customerCare' => 'Customer Care',
        'catalog' => 'Catalog',
        'payment' => 'Payment agent',
        'support' => 'Support agent',
        'finance' => 'Finance agent',
        'inventory' => 'Inventory agent',
        'marketing' => 'Marketing agent',
        'sales' => 'Sales agent',
        'custom' => 'Custom',
        'escalations' => 'Escalations',
        '' => 'Not set up',
        _ => raw,
      };

  Component _card(List<Component> children) => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:${KolaSpace.md};margin-bottom:${KolaSpace.smd}',
        },
        children,
      );

  Component _cardHead(String title, String? trailing) => div(
        attributes: {
          'style': 'display:flex;gap:10px;align-items:baseline;'
              'margin-bottom:10px',
        },
        [
          div(
            attributes: {
              'style': 'flex:1;font-size:${KolaType.bodyLg};'
                  'font-weight:700;color:${KolaVar.text}',
            },
            [Component.text(title)],
          ),
          if (trailing != null)
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
              },
              [Component.text(trailing)],
            ),
        ],
      );

  Component _emptyLine(String text) => div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'line-height:1.55;padding:6px 0',
        },
        [Component.text(text)],
      );

  Component _skeleton() => div(
        attributes: {
          'style': 'height:280px;border-radius:${KolaRadius.lg};'
              'border:1px solid ${KolaVar.border};background:${KolaVar.card}',
        },
        const [],
      );

  Component _errorState() => _card([
        _cardHead('Could not load this agent', null),
        _emptyLine('This is a connection problem — nothing about the agent '
            'has changed.'),
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.mono};'
                'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin:10px 0;word-break:break-word',
          },
          [Component.text(_loadError ?? '')],
        ),
        button(
          attributes: {
            'type': 'button',
            'style': 'padding:9px 15px;border-radius:${KolaRadius.md};'
                'border:none;background:${KolaVar.accentFill};'
                'color:${KolaVar.accentText};font-family:inherit;'
                'font-size:${KolaType.body};font-weight:600;cursor:pointer',
          },
          events: {'click': (_) => _load()},
          [Component.text('Try again')],
        ),
      ]);
}
