// create_bot_page.dart — Phase 5's bot creation flow (task #114). Until
// now, sidebar_nav.dart's "+ New Bot" CTA was a plain inert `href:'#'`
// anchor and nothing in kola_dashboard ever called BotEndpoint.createBot
// — every other page (Errand Builder, Knowledge, Integrations, the Chat/
// Dev detail pages) assumed a Bot already existed, with no way to get
// the first one short of the server's own test-seeding.
//
// SCOPED TO WHAT BotEndpoint.createBot ACTUALLY TAKES: name + archetype
// only (confirmed directly against bot_endpoint.dart — see its
// `_validArchetypes` check). status/knowledgeSeed/createdAt/updatedAt
// are all server-set, not caller-supplied, so there's nothing else this
// form could meaningfully ask for. knowledgeSeed is filled in
// afterward, on the Knowledge page — this form doesn't try to front-load
// it.
//
// NO IMPERATIVE NAVIGATION EXISTS ANYWHERE IN THIS CODEBASE (confirmed —
// no `Router.of(context)`/`.push(`/`.go(` call in kola_dashboard/lib):
// every page navigates only via jaspr_router's declarative `Link`. So on
// success this page doesn't try to redirect itself — it swaps the form
// for a small "Bot created" confirmation with real `Link`s to that bot's
// Chat Mode and Dev Mode pages, plus a way to create another. That's the
// same shape create_workspace_page.dart's `onCreated` callback achieves
// via a parent-level state change; Bot has no equivalent app.dart-level
// state to hand back to, so this page owns its own post-create state
// instead.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/back_link.dart';

class CreateBotPage extends StatefulComponent {
  const CreateBotPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<CreateBotPage> createState() => _CreateBotPageState();
}

class _CreateBotPageState extends State<CreateBotPage> {
  String _name = '';
  // Must be one of 'customerCare' | 'catalog' | 'custom' — the exact set
  // BotEndpoint.createBot validates against server-side. No shared
  // constants module defines this anywhere yet (checked); hardcoded here
  // the same way errand_builder_page.dart hardcodes its permission-scope
  // options.
  String _archetype = 'customerCare';
  bool _creating = false;
  String? _error;
  Bot? _created;

  Future<void> _submit() async {
    if (_name.trim().isEmpty) {
      setState(() => _error = 'Give this bot a name.');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final bot = await component.client.bot.createBot(
        component.accessToken,
        component.workspaceId,
        _name.trim(),
        _archetype,
      );
      setState(() {
        _created = bot;
        _creating = false;
      });
    } catch (_) {
      setState(() {
        _error = "Couldn't create this bot. Check your connection and try again.";
        _creating = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _created = null;
      _name = '';
      _archetype = 'customerCare';
      _error = null;
    });
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};"
            'color:${KolaDashboardColors.text};width:100%;height:100vh;overflow-y:auto;'
            'box-sizing:border-box;padding:40px 32px 60px;display:flex;justify-content:center',
      },
      [
        div(
          attributes: {'style': 'max-width:440px;width:100%'},
          [
            div(
              attributes: {'style': 'margin-bottom:22px'},
              [backLink()],
            ),
            div(
              attributes: {'style': 'font-size:20px;font-weight:700;margin-bottom:4px'},
              [Component.text('New bot')],
            ),
            div(
              attributes: {'style': 'font-size:13.5px;color:${KolaDashboardColors.muted};margin-bottom:24px'},
              [Component.text('Give it a name and a purpose — you can teach it knowledge and errands after.')],
            ),
            _created != null ? _successCard(_created!) : _createForm(),
          ],
        ),
      ],
    );
  }

  Component _createForm() {
    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:14px;padding:20px;box-sizing:border-box',
      },
      [
        if (_error != null)
          div(
            attributes: {
              'style':
                  'background:#2A1414;border:1px solid #4A2020;color:#E8A8A8;border-radius:8px;'
                  'padding:9px 11px;font-size:12.5px;margin-bottom:14px',
            },
            [Component.text(_error!)],
          ),

        _field(
          labelText: 'Bot name',
          child: input<String>(
            type: InputType.text,
            value: _name,
            onInput: (v) => setState(() => _name = v),
            attributes: {'style': _inputStyle, 'placeholder': 'Aisha Assistant'},
          ),
        ),
        _field(
          labelText: 'What will it mainly do?',
          child: select(
            [
              option(
                [Component.text('Customer care — answer questions, escalate when stuck')],
                value: 'customerCare',
                selected: _archetype == 'customerCare',
              ),
              option(
                [Component.text('Catalog — prices, stock, product Q&A')],
                value: 'catalog',
                selected: _archetype == 'catalog',
              ),
              option(
                [Component.text('Custom — something else')],
                value: 'custom',
                selected: _archetype == 'custom',
              ),
            ],
            value: _archetype,
            onChange: (values) => setState(() => _archetype = values.first),
            attributes: {'style': _inputStyle},
          ),
        ),

        button(
          [Component.text(_creating ? 'Creating…' : 'Create bot')],
          type: ButtonType.button,
          disabled: _creating,
          onClick: _submit,
          attributes: {
            'style':
                'width:100%;background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                'border:none;border-radius:10px;padding:12px;font-size:14.5px;font-weight:600;'
                'margin-top:8px;cursor:pointer;opacity:${_creating ? '0.7' : '1'}',
          },
        ),
      ],
    );
  }

  Component _successCard(Bot bot) {
    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:14px;padding:20px;box-sizing:border-box',
      },
      [
        div(attributes: {'style': 'font-size:14.5px;font-weight:600;margin-bottom:6px'}, [
          Component.text('${bot.name} is ready'),
        ]),
        div(
          attributes: {'style': 'font-size:13px;color:${KolaDashboardColors.muted};margin-bottom:18px'},
          [Component.text('It has no knowledge or errands yet — add those next.')],
        ),
        div(
          attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
          [
            Link(
              to: '/bots/${bot.id}',
              attributes: {
                'style':
                    'display:block;text-align:center;background:${KolaDashboardColors.accent};'
                    'color:${KolaDashboardColors.accentText};border-radius:10px;padding:11px;'
                    'font-size:14px;font-weight:600;text-decoration:none',
              },
              child: Component.text('Open bot'),
            ),
            Link(
              to: '/knowledge',
              attributes: {
                'style':
                    'display:block;text-align:center;border:1px solid ${KolaDashboardColors.border};'
                    'color:${KolaDashboardColors.text};border-radius:10px;padding:11px;'
                    'font-size:14px;font-weight:600;text-decoration:none',
              },
              child: Component.text('Add knowledge'),
            ),
            button(
              [Component.text('Create another bot')],
              type: ButtonType.button,
              onClick: _reset,
              attributes: {
                'style':
                    'width:100%;background:transparent;border:none;color:${KolaDashboardColors.mutedStrong};'
                    'font-size:13px;padding:6px;cursor:pointer;margin-top:2px',
              },
            ),
          ],
        ),
      ],
    );
  }

  static const _inputStyle =
      'width:100%;background:#141416;border:1px solid #2C2A28;border-radius:9px;'
      'padding:11px 12px;font-size:14px;color:#F3EEE7;box-sizing:border-box;font-family:inherit';

  Component _field({required String labelText, required Component child}) => div(
    attributes: {'style': 'margin-bottom:14px'},
    [
      label(
        [Component.text(labelText)],
        attributes: {
          'style': 'display:block;font-size:12.5px;color:${KolaDashboardColors.mutedStrong};margin-bottom:6px',
        },
      ),
      child,
    ],
  );
}
