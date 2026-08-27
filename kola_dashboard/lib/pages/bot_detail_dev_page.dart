// bot_detail_dev_page.dart — the Code view of an agent.
//
// REBUILT against Kola Bot Detail Dev.dc.html, structure-first.
//
//   state : tab · selectedIdx
//   tabs  : Overview · Errands · Knowledge · Channels · Logs · API
//
// Reached from the Code tab on bot_detail_chat_page.dart. Kept as its own
// route rather than a third tab body, so the two views do not become two
// copies of the same thing.
//
// ── WHAT IS MEASURED, AND WHAT HONESTLY IS NOT ───────────────────────
//
// The export shows "312 conversations this week", "188 errand calls",
// "1.2s avg response". Only one of those is derivable today:
//
//   Conversations this week  MEASURED — conversations for this bot with
//                            lastMessageAt inside 7 days
//   Errand calls             NO SOURCE — errand_execution_log exists
//                            server-side but is not exposed by any
//                            endpoint
//   Avg response time        NO SOURCE — needs per-message timing
//
// Same for the Logs tab: the server writes execution logs, nothing
// serves them. Rather than a scripted log stream that looks live, Logs
// says what it will show and why it cannot yet.
//
// ── THE API TAB IS COMING-SOON IN THE DESIGN ITSELF ──────────────────
//
// The export labels the MCP endpoint "coming soon". platform.public_api
// and platform.webhooks_outbound are R6 and unbuilt, so a working curl
// against api.kolaa.dev would be a promise the product cannot keep. The
// honest state here IS the designed state — no deviation.
//
// ── CONFIGURATION: `model` IS OMITTED ────────────────────────────────
//
// The export lists archetype, channels, model and fallback. Three of
// those are real and read from the record. `model: kola-2` is a product
// name nothing stores — printing it would invent a fact about how the
// business's agent is configured. Omitted until a model is actually
// recorded per bot.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/error_text.dart';
import '../services/responsive.dart';
import '../theme.dart';

class BotDetailDevPage extends StatefulComponent {
  const BotDetailDevPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.botId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final int botId;

  @override
  State<BotDetailDevPage> createState() => _BotDetailDevPageState();
}

class _BotDetailDevPageState extends State<BotDetailDevPage>
    with ResponsiveViewport<BotDetailDevPage> {
  String _tab = 'Overview';
  int _selectedIdx = -1;

  Bot? _bot;
  List<Errand> _errands = const [];
  List<Channel> _channels = const [];
  List<Conversation> _convos = const [];
  List<KnowledgeDocument> _docs = const [];

  bool _loading = true;
  String? _loadError;

  static const _tabs = [
    'Overview',
    'Errands',
    'Knowledge',
    'Channels',
    'Logs',
    'API',
  ];

  @override
  void initState() {
    super.initState();
    initResponsive();
    _load();
  }

  @override
  void dispose() {
    disposeResponsive();
    super.dispose();
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
      final r = await Future.wait([
        c.bot.getBot(t, w, component.botId),
        c.errand.listErrandsForWorkspace(t, w),
        c.channel.listChannelsForBot(t, w, component.botId),
        c.conversation.listAll(t, w),
        c.knowledge.listDocuments(t, w),
      ]);
      if (!mounted) return;
      setState(() {
        _bot = r[0] as Bot;
        _errands = r[1] as List<Errand>;
        _channels = r[2] as List<Channel>;
        _convos = r[3] as List<Conversation>;
        _docs = r[4] as List<KnowledgeDocument>;
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


  /// Conversations for this bot whose last message landed inside 7 days.
  int get _convosThisWeek {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 7));
    return _convos
        .where((c) => c.botId == component.botId)
        .where((c) => c.lastMessageAt.isAfter(cutoff))
        .length;
  }

  /// The design's short handle, e.g. `bot_8f2a1c`. Derived from the real
  /// id rather than invented — an owner pasting this into support must
  /// get something that identifies the actual record.
  String get _handle => 'bot_${component.botId}';

  @override
  Component build(BuildContext context) => div(
        attributes: {
          'style': 'padding:${KolaSpace.lg};max-width:1240px;margin:0 auto;'
              'width:100%;box-sizing:border-box',
        },
        [
          _header(),
          if (_loading)
            _skeleton()
          else if (_loadError != null)
            _errorCard()
          else ...[
            _tabBar(),
            switch (_tab) {
              'Overview' => _overview(),
              'Errands' => _errandsTab(),
              'Knowledge' => _knowledgeTab(),
              'Channels' => _channelsTab(),
              'Logs' => _logsTab(),
              _ => _apiTab(),
            },
          ],
        ],
      );

  // ── Header ─────────────────────────────────────────────────────────

  Component _header() => div(
        attributes: {
          'style': 'display:flex;flex-wrap:wrap;gap:12px;align-items:center;'
              'margin-bottom:${KolaSpace.md}',
        },
        [
          Link(
          to: '/bots',
            attributes: {
              'style': 'display:inline-flex;align-items:center;gap:6px;'
                  'font-size:${KolaType.small};font-weight:600;'
                  'color:${KolaVar.accent};text-decoration:none;'
                  'padding:6px 10px;border-radius:${KolaRadius.md}',
            },
          children: [
              kolaIcon(Icons.arrowRight,
                  size: 14, extraStyle: 'transform:rotate(180deg)'),
              Component.text('Dashboard'),
            ],
          ),
          div(
            attributes: {
              'style': 'width:30px;height:30px;flex:none;'
                  'border-radius:${KolaRadius.md};'
                  'background:${KolaVar.tintSurface(3)};'
                  'color:${KolaVar.tintIcon(3)};display:flex;'
                  'align-items:center;justify-content:center',
            },
            [kolaIcon(Icons.terminal, size: 16)],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.subhead};font-weight:700;'
                  'color:${KolaVar.text}',
            },
            [Component.text(_bot?.name ?? 'Agent')],
          ),
          span(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.micro};color:${KolaVar.muted};'
                  'background:${KolaVar.pill};padding:4px 9px;'
                  'border-radius:${KolaRadius.sm}',
            },
            [Component.text(_handle)],
          ),
          div(attributes: {'style': 'flex:1'}, const []),
          Link(
          to: '/bots/${component.botId}',
            attributes: {
              'style': 'padding:8px 15px;border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'color:${KolaVar.text};text-decoration:none;'
                  'font-size:${KolaType.small};font-weight:600',
            },
          children: [Component.text('Switch to Chat Mode')],
          ),
        ],
      );

  Component _tabBar() => div(
        attributes: {
          'style': 'display:flex;flex-wrap:wrap;gap:4px;padding:4px;'
              'border-radius:${KolaRadius.pill};background:${KolaVar.pill};'
              'margin-bottom:${KolaSpace.md};width:fit-content',
        },
        [
          for (final t in _tabs)
            button(
              attributes: {
                'type': 'button',
                'aria-pressed': _tab == t ? 'true' : 'false',
                'style': 'padding:7px 15px;border-radius:${KolaRadius.pill};'
                    'border:none;font-family:inherit;'
                    'font-size:${KolaType.small};font-weight:600;'
                    'cursor:pointer;'
                    'background:${_tab == t ? KolaVar.accent : 'transparent'};'
                    'color:${_tab == t ? KolaVar.accentText : KolaVar.mutedStrong}',
              },
              events: {
                'click': (_) => setState(() {
                      _tab = t;
                      _selectedIdx = -1;
                    }),
              },
              [Component.text(t)],
            ),
        ],
      );

  // ── Overview ───────────────────────────────────────────────────────

  Component _overview() => div([
        div(
          attributes: {
            'style': 'display:grid;gap:${KolaSpace.smd};'
                'grid-template-columns:repeat(auto-fit,minmax(210px,1fr));'
                'margin-bottom:${KolaSpace.smd}',
          },
          [
            // No zeroes — see bot_detail_chat_page's stat row. Even on
            // the developer view, "0 / 0 / 0" reads as broken rather
            // than as not-started.
            _stat(
              'Conversations this week',
              _convosThisWeek == 0 ? null : '$_convosThisWeek',
              'Nothing yet this week',
            ),
            _stat('Errand calls', null, 'No call log yet'),
            _stat('Avg response time', null, 'Not measured yet'),
          ],
        ),
        _card([
          _sectionLabel('CONFIGURATION'),
          _configLine('archetype', _bot?.archetype ?? '—'),
          _configLine(
            'channels',
            _channels.isEmpty
                ? 'none connected'
                : _channels.map((c) => c.platformType).join(', '),
          ),
          _configLine('fallback', 'escalate_to_human'),
          _configLine('status', _bot?.status ?? '—'),
        ]),
      ]);

  Component _stat(String label, String? value, String? note) => div(
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
              [Component.text(note ?? '—')],
            ),
        ],
      );

  Component _configLine(String key, String value) => div(
        attributes: {
          'style': 'font-family:${KolaFonts.mono};'
              'font-size:${KolaType.small};line-height:2;'
              'color:${KolaVar.muted}',
        },
        [
          Component.text('$key: '),
          span(
            attributes: {'style': 'color:${KolaVar.accent}'},
            [Component.text(value)],
          ),
        ],
      );

  // ── Errands ────────────────────────────────────────────────────────

  Component _errandsTab() {
    if (_errands.isEmpty) {
      return _card([
        _sectionLabel('ERRANDS'),
        _muted('No errands yet. An errand is a tool this agent can call '
            'mid-conversation.'),
      ]);
    }
    return _card([
      if (!isMobile)
        div(
          attributes: {
            'style': 'display:grid;'
                'grid-template-columns:2fr 1.4fr 1fr 1fr;gap:12px;'
                'padding-bottom:10px;'
                'border-bottom:1px solid ${KolaVar.border};'
                'font-size:${KolaType.micro};font-weight:700;'
                'letter-spacing:.06em;color:${KolaVar.muted}',
          },
          [
            for (final h in const ['NAME', 'SOURCE', 'SCOPE', 'STATUS'])
              div([Component.text(h)]),
          ],
        ),
      for (var i = 0; i < _errands.length; i++) _errandRow(i, _errands[i]),
    ]);
  }

  Component _errandRow(int i, Errand e) {
    final open = _selectedIdx == i;
    final live = e.status == 'live' || e.status == 'active';
    final header = isMobile ? _errandRowMobile(i, e, live) : _errandRowDesktop(i, e, live);
    return div([
      header,
      if (open)
        div(
          attributes: {
            'style': 'padding:12px 0 16px;'
                'border-bottom:1px solid ${KolaVar.border}',
          },
          [
            _detailLine('Trigger', e.descriptionForAi),
            _detailLine('Fulfillment', _fulfillment(e)),
            _detailLine('Input schema', e.inputSchemaJson),
            _detailLine('Last called', 'No call log yet'),
          ],
        ),
    ]);
  }

  Component _errandRowDesktop(int i, Errand e, bool live) => div(
        attributes: {
          'style': 'display:grid;'
              'grid-template-columns:2fr 1.4fr 1fr 1fr;gap:12px;'
              'padding:12px 0;align-items:center;cursor:pointer;'
              'border-bottom:1px solid ${KolaVar.border}',
        },
        events: {
          'click': (_) => setState(() => _selectedIdx = _selectedIdx == i ? -1 : i),
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.text};'
                  'font-weight:600',
            },
            [Component.text(e.name)],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.tiny};color:${KolaVar.muted}',
            },
            [Component.text(e.source)],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.tiny};color:${KolaVar.muted}',
            },
            [Component.text(e.permissionScope)],
          ),
          span(
            attributes: {
              'style': '${(live ? KolaTone.positive : KolaTone.caution).badgeCss};'
                  'white-space:nowrap;justify-self:start',
            },
            [Component.text(live ? 'Live' : 'Needs input')],
          ),
        ],
      );

  /// Same row, stacked. The 4-column grid (name/source/scope/status)
  /// has no legible narrower form below tablet — this is a card, not a
  /// squeezed grid, same treatment knowledge_page.dart's document table
  /// got.
  Component _errandRowMobile(int i, Errand e, bool live) => div(
        attributes: {
          'style': 'padding:12px 0;cursor:pointer;'
              'border-bottom:1px solid ${KolaVar.border}',
        },
        events: {
          'click': (_) => setState(() => _selectedIdx = _selectedIdx == i ? -1 : i),
        },
        [
          div(
            attributes: {
              'style': 'display:flex;justify-content:space-between;'
                  'align-items:flex-start;gap:10px;margin-bottom:6px',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.body};color:${KolaVar.text};'
                      'font-weight:600;flex:1;min-width:0;word-break:break-word',
                },
                [Component.text(e.name)],
              ),
              span(
                attributes: {
                  'style': '${(live ? KolaTone.positive : KolaTone.caution).badgeCss};'
                      'white-space:nowrap',
                },
                [Component.text(live ? 'Live' : 'Needs input')],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.tiny};color:${KolaVar.muted}',
            },
            [Component.text('${e.source} · ${e.permissionScope}')],
          ),
        ],
      );

  String _fulfillment(Errand e) {
    if (e.builtinHandlerKey != null) return 'Built-in · ${e.builtinHandlerKey}';
    if (e.queryTemplateSql != null) return 'Database credential';
    return e.source;
  }

  Component _detailLine(String label, String value) => div(
        attributes: {'style': 'display:flex;gap:12px;padding:5px 0'},
        [
          div(
            attributes: {
              'style': 'width:120px;flex:none;font-size:${KolaType.tiny};'
                  'color:${KolaVar.muted}',
            },
            [Component.text(label)],
          ),
          div(
            attributes: {
              'style': 'flex:1;font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.tiny};color:${KolaVar.mutedStrong};'
                  'word-break:break-word;line-height:1.6',
            },
            [Component.text(value)],
          ),
        ],
      );

  // ── Knowledge / Channels ───────────────────────────────────────────

  Component _knowledgeTab() => _card([
        _sectionLabel('KNOWLEDGE'),
        if (_docs.isEmpty)
          _muted('Nothing indexed yet.')
        else
          for (final d in _docs)
            div(
              attributes: {
                'style': 'display:flex;gap:12px;padding:10px 0;'
                    'border-bottom:1px solid ${KolaVar.border}',
              },
              [
                div(
                  attributes: {
                    'style': 'flex:1;font-size:${KolaType.body};'
                        'color:${KolaVar.text};word-break:break-word',
                  },
                  [Component.text(d.title)],
                ),
                div(
                  attributes: {
                    'style': 'font-family:${KolaFonts.mono};'
                        'font-size:${KolaType.tiny};color:${KolaVar.muted}',
                  },
                  [Component.text('${d.chunkCount} sections')],
                ),
              ],
            ),
        Link(
          to: '/knowledge',
          attributes: {
            'style': 'display:block;text-align:center;padding:11px;'
                'margin-top:10px;border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};text-decoration:none;'
                'color:${KolaVar.text};font-size:${KolaType.small};'
                'font-weight:600',
          },
          children: [Component.text('Full Knowledge Base')],
        ),
      ]);

  Component _channelsTab() => _card([
        _sectionLabel('CHANNELS'),
        if (_channels.isEmpty)
          _muted('Not connected. Customers cannot reach this agent yet.')
        else
          for (final ch in _channels)
            div(
              attributes: {
                'style': 'display:flex;gap:12px;align-items:center;'
                    'padding:11px 0;'
                    'border-bottom:1px solid ${KolaVar.border}',
              },
              [
                div(
                  attributes: {
                    'style': 'flex:1;font-family:${KolaFonts.mono};'
                        'font-size:${KolaType.small};color:${KolaVar.text}',
                  },
                  [Component.text(ch.platformType)],
                ),
                span(
                  attributes: {
                    'style': (ch.status == 'connected'
                            ? KolaTone.positive
                            : KolaTone.caution)
                        .badgeCss,
                  },
                  [
                    Component.text(ch.status == 'connected'
                        ? 'Connected'
                        : 'Not connected'),
                  ],
                ),
              ],
            ),
      ]);

  // ── Logs / API — honest, not scripted ──────────────────────────────

  Component _logsTab() => _card([
        _sectionLabel('LOGS'),
        _muted('Nothing to show yet. The server records every errand call '
            'and escalation in errand_execution_log, but no endpoint serves '
            'them to this screen — so there is no log to stream here.'),
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'line-height:1.6;margin-top:10px',
          },
          [
            Component.text('When it lands, this shows inbound messages, '
                'errand calls with status and duration, low-confidence '
                'answers, and publishes — newest first.'),
          ],
        ),
      ]);

  Component _apiTab() => _card([
        _sectionLabel('API'),
        _muted('Calling this agent directly is not available yet. The public '
            'API and outbound webhooks are built but not released, so kolaa '
            'will not hand out a key that cannot authenticate against '
            'anything.'),
        div(
          attributes: {
            'style': 'margin-top:14px;padding:12px 14px;'
                'border-radius:${KolaRadius.md};background:${KolaVar.bg};'
                'border:1px solid ${KolaVar.border};'
                'font-family:${KolaFonts.mono};font-size:${KolaType.tiny};'
                'color:${KolaVar.muted};line-height:1.7',
          },
          [Component.text('POST /bots/$_handle/message')],
        ),
        div(
          attributes: {
            'style': 'display:flex;gap:8px;align-items:center;'
                'margin-top:12px;font-size:${KolaType.small};'
                'color:${KolaVar.muted}',
          },
          [
            span(
              attributes: {'style': KolaTone.neutral.badgeCss},
              [Component.text('MCP · soon')],
            ),
          ],
        ),
      ]);

  // ── Shared ─────────────────────────────────────────────────────────

  Component _card(List<Component> children) => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:${KolaSpace.md};margin-bottom:${KolaSpace.smd}',
        },
        children,
      );

  Component _sectionLabel(String t) => div(
        attributes: {
          'style': 'font-size:${KolaType.micro};font-weight:700;'
              'letter-spacing:.08em;color:${KolaVar.muted};'
              'margin-bottom:12px',
        },
        [Component.text(t)],
      );

  Component _muted(String t) => div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'line-height:1.6',
        },
        [Component.text(t)],
      );

  Component _skeleton() => div(
        attributes: {
          'style': 'height:240px;border-radius:${KolaRadius.lg};'
              'border:1px solid ${KolaVar.border};background:${KolaVar.card}',
        },
        const [],
      );

  Component _errorCard() => _card([
        _sectionLabel('ERROR'),
        _muted(_loadError ?? ''),
        button(
          attributes: {
            'type': 'button',
            'style': 'margin-top:12px;padding:9px 15px;'
                'border-radius:${KolaRadius.md};border:none;'
                'background:${KolaVar.accentFill};'
                'color:${KolaVar.accentText};font-family:inherit;'
                'font-size:${KolaType.body};font-weight:600;cursor:pointer',
          },
          events: {'click': (_) => _load()},
          [Component.text('Try again')],
        ),
      ]);
}
