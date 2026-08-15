// composer.dart — the "what do you want kolaa to help with" textarea
// card, shared between desktop and mobile home content (sizing only
// differs via [compact], per Kola Dashboard Shell.dc.html).
//
// TASK #139 — NO LONGER A STATIC SHELL. This was purely decorative
// until now (no state, no click handler on the send button, no wiring
// to kola_client at all — see this file's own prior header, which said
// exactly that). It now does ONE real thing: submitting a description
// calls BotEndpoint.createBotFromDescription (Bot Mother v1 — see that
// method's own doc comment in bot_endpoint.dart for how narrow "v1" is)
// and creates a real Bot from it.
//
// WHY BOT CREATION SPECIFICALLY, NOT A GENERAL-PURPOSE COMMAND BOX: the
// 📎/⚡ pill icons next to the textarea (Upload knowledge / New Errand)
// stay exactly as inert as they were — this composer sits directly
// above a "Create a new bot" quick action and its own placeholder asks
// "what do you want kolaa to help with," which together read as "describe
// the bot you want," not "do anything." Wiring the other two icons to
// their own real actions is separate, additional scope, not something
// this pass silently expanded into.
//
// NO IMPERATIVE NAVIGATION: this app has never used jaspr_router's
// programmatic navigation (see bot_detail_dev_page.dart's header) —
// every transition is a real declarative `Link`. So a successful create
// doesn't redirect itself; it swaps the composer for a small inline
// "<name> is ready" confirmation with a real Link into the new bot,
// same shape create_bot_page.dart's own `_successCard` already uses for
// the plain-form path.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';
import '../theme.dart';

class Composer extends StatefulComponent {
  const Composer({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    this.compact = false,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final bool compact;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  String _description = '';
  bool _submitting = false;
  String? _error;
  Bot? _created;

  Future<void> _submit() async {
    if (_description.trim().isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final bot = await component.client.bot.createBotFromDescription(
        component.accessToken,
        component.workspaceId,
        _description.trim(),
      );
      setState(() {
        _created = bot;
        _submitting = false;
      });
    } catch (_) {
      setState(() {
        _error = "Couldn't create a bot from that. Check your connection and try again.";
        _submitting = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _created = null;
      _description = '';
      _error = null;
    });
  }

  @override
  Component build(BuildContext context) {
    final compact = component.compact;
    final radius = compact ? 20 : 22;
    final padding = compact ? '16px' : '18px 20px';

    return div(
      attributes: {
        'style':
            'width:100%;box-sizing:border-box;background:${KolaDashboardColors.card};'
            'border:1px solid ${KolaDashboardColors.border};border-radius:${radius}px;padding:$padding'
            '${compact ? "" : ";max-width:680px"}',
      },
      [_created != null ? _successRow(_created!) : _form(compact)],
    );
  }

  Component _form(bool compact) {
    final pillSize = compact ? 30 : 34;
    final sendSize = compact ? 32 : 36;
    final fontSize = compact ? 15 : 16;
    final placeholder = compact
        ? 'Describe the bot you want…'
        : 'Describe the bot you want kolaa to create…';

    return div([
      if (_error != null)
        div(
          attributes: {
            'style':
                'background:#2A1414;border:1px solid #4A2020;color:#E8A8A8;border-radius:8px;'
                'padding:8px 10px;font-size:12.5px;margin-bottom:10px',
          },
          [Component.text(_error!)],
        ),
      textarea(
        [Component.text(_description)],
        rows: 2,
        onInput: (v) => setState(() => _description = v),
        attributes: {
          'placeholder': placeholder,
          'style':
              'width:100%;box-sizing:border-box;border:none;outline:none;resize:none;'
              'background:transparent;color:${KolaDashboardColors.text};'
              'font-family:${KolaDashboardFonts.sans};font-size:${fontSize}px',
        },
      ),
      div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;align-items:center;margin-top:6px',
        },
        [
          div(
            attributes: {'style': 'display:flex;gap:8px'},
            [
              a(
                attributes: {
                  'style':
                      'width:${pillSize}px;height:${pillSize}px;border-radius:50%;'
                      'background:${KolaDashboardColors.pill};display:flex;align-items:center;'
                      'justify-content:center;text-decoration:none;font-size:${compact ? 13 : 15}px',
                  'title': 'Upload knowledge',
                },
                [Component.text('📎')],
                href: '#',
              ),
              div(
                attributes: {
                  'style':
                      'width:${pillSize}px;height:${pillSize}px;border-radius:50%;'
                      'background:${KolaDashboardColors.pill};display:flex;align-items:center;'
                      'justify-content:center;font-size:${compact ? 13 : 15}px',
                  'title': 'New Errand',
                },
                [Component.text('⚡')],
              ),
            ],
          ),
          button(
            [Component.text(_submitting ? '…' : '→')],
            type: ButtonType.button,
            disabled: _submitting || _description.trim().isEmpty,
            onClick: _submit,
            attributes: {
              'style':
                  'width:${sendSize}px;height:${sendSize}px;border-radius:50%;border:none;'
                  'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                  'display:flex;align-items:center;justify-content:center;font-size:${compact ? 14 : 16}px;'
                  'cursor:pointer;padding:0;'
                  'opacity:${(_submitting || _description.trim().isEmpty) ? '0.5' : '1'}',
            },
          ),
        ],
      ),
    ]);
  }

  Component _successRow(Bot bot) => div(
    attributes: {'style': 'display:flex;align-items:center;justify-content:space-between;gap:14px;flex-wrap:wrap'},
    [
      div([
        div(attributes: {'style': 'font-size:14.5px;font-weight:600'}, [Component.text('${bot.name} is ready')]),
        div(
          attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.muted};margin-top:2px'},
          [Component.text('It has no knowledge or channels connected yet.')],
        ),
      ]),
      div(
        attributes: {'style': 'display:flex;gap:8px;flex-shrink:0'},
        [
          Link(
            to: '/bots/${bot.id}',
            attributes: {
              'style':
                  'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                  'border-radius:100px;padding:8px 16px;font-size:13px;font-weight:600;text-decoration:none',
            },
            child: Component.text('Open bot'),
          ),
          button(
            [Component.text('Create another')],
            type: ButtonType.button,
            onClick: _reset,
            attributes: {
              'style':
                  'background:transparent;border:1px solid ${KolaDashboardColors.border};'
                  'color:${KolaDashboardColors.navInactiveText};border-radius:100px;padding:8px 16px;'
                  'font-size:13px;font-family:inherit;cursor:pointer',
            },
          ),
        ],
      ),
    ],
  );
}
