// integrations_page.dart — the channels customers actually message.
//
// REBUILT on the new design system. The previous version used
// KolaDashboardColors throughout; nothing here does.
//
// ── CHANNELS BELONG TO BOTS, NOT TO THE WORKSPACE ────────────────────
//
// There is no "list every channel in this workspace" endpoint —
// `listChannelsForBot(token, workspaceId, botId)` is bot-scoped. That is
// not an oversight in the API; it is the real ownership model. A
// WhatsApp number is connected to one bot, and the same number cannot
// answer as two different bots.
//
// So this page loads the bots, then fans out one channel request per
// bot, and groups by bot. Grouping is not decoration: "connect a
// channel" is meaningless without saying WHICH bot will answer on it,
// and a flat list would hide exactly that.
//
// ── WHAT IS REAL ─────────────────────────────────────────────────────
//
//   bot.listBotsForWorkspace          → the groups
//   channel.listChannelsForBot        → what is connected
//   channel.connectTelegramChannel    → connect, inline, one token
//
// ── WHAT IS NOT ──────────────────────────────────────────────────────
//
//   DISCONNECT — no endpoint exists. Not offered.
//
//   WHATSAPP — connectWhatsAppChannelManual takes FIVE credentials
//     (access token, phone number id, WABA id, app id, app secret),
//     each obtained from Meta's Business Manager through a multi-step
//     process. Cramming that into five inputs with no guidance produces
//     a form people fail at silently and blame the product for. It
//     links to the written walkthrough instead — which is what that
//     document exists for.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../config/env.dart';
import '../services/feature_gate.dart';
import '../theme.dart';

class IntegrationsPage extends StatefulComponent {
  const IntegrationsPage({
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
  State<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  bool _loading = true;
  String? _error;

  List<Bot> _bots = const [];

  /// botId → its channels.
  Map<int, List<Channel>> _channels = const {};

  /// Which bot's Telegram form is open. Only ever one — two open forms
  /// invite pasting the token into the wrong bot's box, and a token
  /// connected to the wrong bot is silent, not an error.
  int? _connecting;
  String _token = '';
  bool _saving = false;

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

      // One request per bot, all at once. Sequentially this is N round
      // trips, and on a slow connection the page would fill in one bot
      // at a time.
      final lists = await Future.wait([
        for (final b in bots)
          component.client.channel.listChannelsForBot(
            component.accessToken,
            component.workspaceId,
            b.id!,
          ),
      ]);

      if (!mounted) return;
      setState(() {
        _bots = bots;
        _channels = {
          for (var i = 0; i < bots.length; i++)
            if (bots[i].id != null) bots[i].id!: lists[i],
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _connectTelegram(Bot bot) async {
    final token = _token.trim();
    if (token.isEmpty || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await component.client.channel.connectTelegramChannel(
        component.accessToken,
        component.workspaceId,
        bot.id!,
        token,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _connecting = null;
        _token = '';
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        // Named, because the usual cause is a token pasted with the
        // "bot" prefix or an extra space, and a generic failure gives
        // no hint of that.
        _error = 'Telegram would not accept that token: $e';
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
          _noBots()
        else
          for (final b in _bots) _botGroup(b),
      ],
    );
  }

  Component _header() {
    final total = _channels.values.fold<int>(0, (n, c) => n + c.length);

    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:4px'},
      [
        h1(
          attributes: {
            'style': 'font-family:${KolaFonts.display};font-size:${KolaType.h2};'
                'font-weight:700;color:${KolaVar.text};margin:0',
          },
          [Component.text('Integrations')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.5;max-width:560px',
          },
          [
            Component.text(total == 0
                ? 'Where customers reach you. Nothing is connected yet, so '
                    'nothing can arrive.'
                : total == 1
                    ? '1 channel connected.'
                    : '$total channels connected.'),
          ],
        ),
      ],
    );
  }

  Component _botGroup(Bot bot) {
    final channels = _channels[bot.id] ?? const <Channel>[];
    final isOpen = _connecting == bot.id;

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
                'style': 'flex:none;color:${KolaVar.muted};display:flex',
              },
              [kolaIcon(Icons.bot, size: 16)],
            ),
            div(
              attributes: {
                'style': 'flex:1;min-width:0;font-size:${KolaType.bodyLg};'
                    'font-weight:600;color:${KolaVar.text};overflow:hidden;'
                    'text-overflow:ellipsis;white-space:nowrap',
              },
              [Component.text(bot.name)],
            ),
          ],
        ),

        if (channels.isEmpty)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.5',
            },
            [
              Component.text(
                'No channel connected. This bot cannot be reached by anyone '
                'yet.',
              ),
            ],
          )
        else
          for (final c in channels) _channelRow(c),

        _connectRow(bot, isOpen),
        if (isOpen) _telegramForm(bot),
      ],
    );
  }

  Component _channelRow(Channel c) {
    final live = c.status == 'active';

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:10px;'
            'padding:10px 12px;background:${KolaVar.bg};'
            'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};flex-wrap:wrap',
      },
      [
        div(
          attributes: {
            'style': 'color:${KolaVar.accent};display:flex;flex:none',
          },
          [kolaIcon(_platformIcon(c.platformType), size: 15)],
        ),
        div(
          attributes: {'style': 'flex:1;min-width:0'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:600;'
                    'color:${KolaVar.text}',
              },
              [Component.text(_platformLabel(c.platformType))],
            ),
            if (c.displayName != null && c.displayName!.isNotEmpty)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.micro};color:${KolaVar.muted};'
                      'overflow:hidden;text-overflow:ellipsis;'
                      'white-space:nowrap',
                },
                [Component.text(c.displayName!)],
              ),
          ],
        ),
        span(
          attributes: {
            'style': (live ? KolaTone.positive : KolaTone.caution).badgeCss,
          },
          [Component.text(live ? 'Live' : c.status)],
        ),
      ],
    );
  }

  Component _connectRow(Bot bot, bool isOpen) => div(
        attributes: {
          'style': 'display:flex;gap:8px;flex-wrap:wrap;align-items:center',
        },
        [
          button(
            attributes: {
              'class': 'kola-pressable',
              'type': 'button',
              'style': 'background:transparent;'
                  'border:1px solid ${KolaVar.border};color:${KolaVar.text};'
                  'border-radius:${KolaRadius.pill};padding:8px 16px;'
                  'font-size:${KolaType.micro};font-weight:600;'
                  'font-family:inherit',
            },
            events: {
              'click': (_) => setState(() {
                    _connecting = isOpen ? null : bot.id;
                    _token = '';
                  }),
            },
            [Component.text(isOpen ? 'Cancel' : 'Connect Telegram')],
          ),

          // WhatsApp needs five credentials from Meta's Business
          // Manager. A five-input form with no guidance is a form people
          // fail at silently — the walkthrough is the honest route.
          a(
            attributes: {
              'class': 'kola-pressable',
              'style': 'border:1px solid ${KolaVar.border};'
                  'color:${KolaVar.muted};border-radius:${KolaRadius.pill};'
                  'padding:8px 16px;font-size:${KolaType.micro};'
                  'font-weight:600;text-decoration:none',
              'target': '_blank',
              'rel': 'noopener noreferrer',
            },
            [Component.text('Connect WhatsApp →')],
            href: '${Env.kolaDocsUrl}/whatsapp-setup',
          ),
        ],
      );

  Component _telegramForm(Bot bot) => div(
        attributes: {
          'style': 'background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:14px;'
              'display:flex;flex-direction:column;gap:10px',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.micro};color:${KolaVar.muted};'
                  'line-height:1.5',
            },
            [
              Component.text(
                'Message @BotFather on Telegram, send /newbot, and paste the '
                'token it gives you. It looks like 123456789:AA…',
              ),
            ],
          ),
          input(
            type: InputType.text,
            attributes: {
              'aria-label': 'Telegram bot token',
              'placeholder': '123456789:AAExample-Token',
              'autocomplete': 'off',
              'spellcheck': 'false',
              'style': 'width:100%;box-sizing:border-box;'
                  'background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.sm};padding:10px 12px;'
                  'color:${KolaVar.text};font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.small};outline:none',
            },
            events: {
              'input': (e) => _token = (e.target as dynamic).value as String? ?? '',
              'keydown': (e) {
                if ((e as dynamic).key == 'Enter') _connectTelegram(bot);
              },
            },
          ),
          div(
            attributes: {'style': 'display:flex;gap:8px'},
            [
              button(
                attributes: {
                  'class': 'kola-pressable',
                  'type': 'button',
                  'style': 'background:${KolaVar.accentFill};'
                      'color:${KolaVar.accentText};border:none;'
                      'border-radius:${KolaRadius.pill};padding:8px 18px;'
                      'font-size:${KolaType.micro};font-weight:600;'
                      'font-family:inherit;${_saving ? 'opacity:0.6' : ''}',
                },
                events: {'click': (_) => _connectTelegram(bot)},
                [Component.text(_saving ? 'Connecting…' : 'Connect')],
              ),
            ],
          ),
        ],
      );

  Component _noBots() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.xl};padding:32px 24px;'
              'text-align:center',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('Create an agent first')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.6;max-width:400px;margin:0 auto 16px',
            },
            [
              // Explains the dependency rather than just blocking. A
              // channel connects TO something, and without a bot there
              // is nothing on the other end of the number.
              Component.text(
                'A channel connects a phone number or Telegram account to an '
                'agent. Without an agent there is nothing to answer on it.',
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
            children: [Component.text('Create an agent')],
          ),
        ],
      );

  Component _skeleton() => div(
        attributes: {'style': 'display:flex;flex-direction:column;gap:14px'},
        [
          for (var i = 0; i < 2; i++)
            div(
              classes: 'kola-skel',
              attributes: {'style': 'height:120px;border-radius:${KolaRadius.lg}'},
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

  static String _platformLabel(String p) => switch (p) {
        'whatsapp' => 'WhatsApp',
        'telegram' => 'Telegram',
        _ => p,
      };

  static String _platformIcon(String p) => switch (p) {
        'whatsapp' => Icons.whatsapp,
        _ => Icons.plug,
      };
}
