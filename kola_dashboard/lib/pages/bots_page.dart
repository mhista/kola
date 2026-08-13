// bots_page.dart — the bots that answer customers.
//
// REBUILT on the new design system. The previous version used
// KolaDashboardColors throughout; nothing here does.
//
// ── THIS IS NOT THE DESIGN'S "AGENTS" SCREEN ─────────────────────────
//
// `Kola Agents.dc.html` shows specialised agents — Sales, Support,
// Finance, Inventory — each with its own stats and an on/off toggle.
// None of that exists: there are no agent endpoints, no per-agent
// config in the schema, no per-agent stats, and `agents.core` is a
// locked feature.
//
// Building that screen would mean inventing the data contract for a
// backend that does not exist, and then rebuilding it when the real one
// lands. So this page is the REAL thing the nav's "Agents" entry points
// at: bots, which have a working backend today.
//
// When the agent layer is built, this page becomes its detail view —
// an agent is a bot with a specialisation, not a separate object.
//
// ── WHAT IS REAL ─────────────────────────────────────────────────────
//
//   bot.listBotsForWorkspace   → the list
//
// THAT IS ALL OF IT. Two actions the design implies are NOT possible:
//
//   PAUSE / RESUME — there is no endpoint that changes a bot's status.
//     updateBot(token, wsId, botId, name, ARCHETYPE) takes an archetype
//     as its fifth argument, not a status. A first version of this page
//     called it with 'paused' in that position, which would have
//     silently overwritten the bot's archetype with the word "paused"
//     and broken how it answers. Caught by checking the generated
//     client's signature rather than assuming it.
//
//   DELETE — EndpointBot has no delete method.
//
// Both are shown as status, read-only. A page offering an action the
// server cannot perform is worse than one that does not offer it —
// especially when the call silently succeeds against the wrong field.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../theme.dart';

class BotsPage extends StatefulComponent {
  const BotsPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final FeatureGate gate;

  @override
  State<BotsPage> createState() => _BotsPageState();
}

class _BotsPageState extends State<BotsPage> {
  bool _loading = true;
  String? _error;
  List<Bot> _bots = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bots = await component.client.bot.listBotsForWorkspace(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _bots = bots;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'max-width:1040px;margin:0 auto;width:100%;'
            'padding:28px 20px 40px;display:flex;flex-direction:column;gap:18px',
      },
      [
        _header(),
        if (_error != null) _errorBanner(),
        if (_loading)
          _skeleton()
        else if (_bots.isEmpty)
          _empty()
        else
          div(
            attributes: {
              'style': 'display:grid;gap:14px;'
                  'grid-template-columns:repeat(auto-fill,minmax(300px,1fr))',
            },
            [for (final b in _bots) _card(b)],
          ),
      ],
    );
  }

  Component _header() {
    final active = _bots.where((b) => b.status == 'active').length;

    return div(
      attributes: {
        'style': 'display:flex;align-items:flex-start;justify-content:space-between;'
            'gap:14px;flex-wrap:wrap',
      },
      [
        div(
          attributes: {'style': 'min-width:0'},
          [
            h1(
              attributes: {
                'style': 'font-family:${KolaFonts.display};font-size:${KolaType.h2};'
                    'font-weight:700;color:${KolaVar.text};margin:0 0 4px',
              },
              [Component.text('Agents')],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                    'line-height:1.5;max-width:520px',
              },
              [
                Component.text(_bots.isEmpty
                    ? 'An agent is what answers your customers. You need at '
                        'least one.'
                    : active == _bots.length
                        ? 'All ${_bots.length} answering customers.'
                        : '$active of ${_bots.length} answering customers.'),
              ],
            ),
          ],
        ),
        Link(
          to: '/bots/new',
          attributes: {
            'class': 'kola-pressable',
            'style': 'flex:none;background:${KolaVar.accentFill};'
                'color:${KolaVar.accentText};border-radius:${KolaRadius.pill};'
                'padding:9px 18px;font-size:${KolaType.small};'
                'font-weight:600;text-decoration:none',
          },
          children: [Component.text('New agent')],
        ),
      ],
    );
  }

  Component _card(Bot bot) {
    final paused = bot.status != 'active';

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:16px;'
            'display:flex;flex-direction:column;gap:12px',
      },
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:10px'},
          [
            div(
              attributes: {
                'style': 'flex:none;width:34px;height:34px;'
                    'border-radius:${KolaRadius.circle};'
                    'background:${KolaVar.tintIcon(0)};color:${KolaVar.accent};'
                    'display:flex;align-items:center;justify-content:center',
              },
              [kolaIcon(Icons.bot, size: 17)],
            ),
            div(
              attributes: {'style': 'flex:1;min-width:0'},
              [
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                        'color:${KolaVar.text};overflow:hidden;'
                        'text-overflow:ellipsis;white-space:nowrap',
                  },
                  [Component.text(bot.name)],
                ),
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.micro};color:${KolaVar.muted}',
                  },
                  [Component.text(bot.archetype)],
                ),
              ],
            ),
            span(
              attributes: {
                'style': (paused ? KolaTone.neutral : KolaTone.positive).badgeCss,
              },
              [Component.text(paused ? 'Paused' : 'Answering')],
            ),
          ],
        ),

        // Says what the state MEANS, not just what it is. "Paused" alone
        // does not tell an owner that messages still arrive and simply
        // go unanswered — which is the thing they need to know before
        // leaving it paused overnight.
        if (paused)
          div(
            attributes: {
              'style': 'font-size:${KolaType.micro};color:${KolaVar.warning};'
                  'line-height:1.5',
            },
            [
              Component.text(
                'Customers can still message this channel. Nothing replies '
                'until you resume it.',
              ),
            ],
          ),

        div(
          attributes: {
            'style': 'display:flex;gap:8px;align-items:center;'
                'flex-wrap:wrap;margin-top:auto',
          },
          [
            Link(
              to: '/bots/${bot.id}',
              attributes: {
                'class': 'kola-pressable',
                'style': 'border:1px solid ${KolaVar.border};'
                    'color:${KolaVar.text};border-radius:${KolaRadius.pill};'
                    'padding:7px 15px;font-size:${KolaType.micro};'
                    'font-weight:600;text-decoration:none',
              },
              children: [Component.text('Open')],
            ),
            // No pause/resume control. There is no endpoint for it —
            // see this file's header. A button that appears to work and
            // corrupts the archetype instead is the worst outcome
            // available here.
            Link(
              to: '/bots/${bot.id}/code',
              attributes: {
                'class': 'kola-pressable',
                'style': 'border:1px solid ${KolaVar.border};'
                    'color:${KolaVar.muted};border-radius:${KolaRadius.pill};'
                    'padding:7px 15px;font-size:${KolaType.micro};'
                    'font-weight:600;text-decoration:none',
              },
              children: [Component.text('Settings')],
            ),
          ],
        ),
      ],
    );
  }

  Component _empty() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.xl};padding:36px 24px;'
              'text-align:center',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('No agents yet')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.6;max-width:420px;margin:0 auto 18px',
            },
            [
              Component.text(
                'Describe what you sell and how you want customers spoken to. '
                'kola builds the agent from that.',
              ),
            ],
          ),
          Link(
            to: '/bots/new',
            attributes: {
              'class': 'kola-pressable',
              'style': 'display:inline-block;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};'
                  'border-radius:${KolaRadius.pill};padding:9px 20px;'
                  'font-size:${KolaType.small};font-weight:600;'
                  'text-decoration:none',
            },
            children: [Component.text('Create your first agent')],
          ),
        ],
      );

  Component _skeleton() => div(
        attributes: {
          'style': 'display:grid;gap:14px;'
              'grid-template-columns:repeat(auto-fill,minmax(300px,1fr))',
        },
        [
          for (var i = 0; i < 3; i++)
            div(
              classes: 'kola-skel',
              attributes: {'style': 'height:132px;border-radius:${KolaRadius.lg}'},
              [],
            ),
        ],
      );

  Component _errorBanner() => div(
        attributes: {
          'role': 'alert',
          'style': 'padding:10px 14px;background:${KolaVar.dangerBg};'
              'color:${KolaVar.danger};border:1px solid ${KolaVar.danger};'
              'border-radius:${KolaRadius.md};font-size:${KolaType.small}',
        },
        [Component.text(_error!)],
      );
}
