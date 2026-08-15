// create_bot_page.dart — "New agent".
//
// REBUILT. The previous version was a pre-redesign form: a Name field
// and an archetype picker, calling BotEndpoint.createBot. The redesign
// has no such screen.
//
// ── WHAT THE DESIGN ACTUALLY DOES ────────────────────────────────────
//
// There is no separate "create agent" screen in any export. An agent is
// created by DESCRIBING THE BUSINESS, and kolaa drafts the rest — that is
// step 1 of the Setup tab on Kola Bot Detail Chat.dc.html:
//
//   "Let's set up your agent. What does your business sell?"
//   → "Got it — I've drafted these Errands: …"
//
// The export's own BOTS array carries the resulting state:
// `{ name: 'Untitled agent', archetype: 'Not set up', hasSetup: false }`.
//
// So this page asks one question and hands off to the agent's Setup tab.
// It does NOT ask for a name or an archetype: the server derives both
// from the description via createBotFromDescription, and asking an owner
// to pick "archetype" before they have described their shop is the kind
// of question the redesign removed.
//
// ── WHY IT ENDS WITH A LINK RATHER THAN A REDIRECT ───────────────────
//
// kola_dashboard navigates declaratively — there is no
// `Router.of(context).push` anywhere in lib/, every transition is a
// jaspr_router `Link`. That convention is kept here rather than
// introducing the one imperative navigation call in the codebase.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/error_text.dart';
import '../theme.dart';

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
  String _description = '';
  bool _creating = false;
  String? _error;
  Bot? _created;

  Future<void> _submit() async {
    final text = _description.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Tell kolaa what your business sells first.');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final bot = await component.client.bot.createBotFromDescription(
        component.accessToken,
        component.workspaceId,
        text,
      );
      if (!mounted) return;
      setState(() {
        _created = bot;
        _creating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorText.of(e);
        _creating = false;
      });
    }
  }

  @override
  Component build(BuildContext context) => div(
        attributes: {
          'style': 'padding:${KolaSpace.lg};max-width:760px;margin:0 auto;'
              'width:100%;box-sizing:border-box',
        },
        [
          Link(
            to: '/bots',
            attributes: {
              'style': 'display:inline-flex;align-items:center;gap:6px;'
                  'font-size:${KolaType.small};font-weight:600;'
                  'color:${KolaVar.accent};text-decoration:none;'
                  'padding:6px 10px;border-radius:${KolaRadius.md};'
                  'margin-bottom:10px',
            },
            children: [
              kolaIcon(Icons.arrowRight,
                  size: 14, extraStyle: 'transform:rotate(180deg)'),
              Component.text('Agents'),
            ],
          ),
          if (_created == null) ..._form() else ..._done(_created!),
        ],
      );

  List<Component> _form() => [
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.display};'
                'font-size:${KolaType.h2};font-weight:700;'
                'color:${KolaVar.text};margin-bottom:6px',
          },
          [Component.text("Let's set up your agent")],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                'line-height:1.55;margin-bottom:18px;max-width:60ch',
          },
          [
            Component.text('Describe the business in plain language — kolaa '
                'drafts the plan as you go. You can change everything '
                'afterwards.'),
          ],
        ),
        div(
          attributes: {
            'style': 'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
                'padding:${KolaSpace.md}',
          },
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.bodyLg};font-weight:700;'
                    'color:${KolaVar.text};margin-bottom:10px',
              },
              [Component.text('What does your business sell?')],
            ),
            textarea(
              attributes: {
                'aria-label': 'Describe your business',
                'placeholder': 'e.g. Ankara fabric and ready-made outfits. '
                    'Customers should be able to check prices and stock.',
                'rows': '6',
                'style': 'width:100%;box-sizing:border-box;padding:12px 14px;'
                    'border-radius:${KolaRadius.md};'
                    'border:1px solid ${KolaVar.border};'
                    'background:${KolaVar.bg};color:${KolaVar.text};'
                    'font-family:inherit;font-size:${KolaType.body};'
                    'line-height:1.6;resize:vertical',
              },
              // Jaspr's TYPED callback. The events-map form
              // (`events: {'input': (e) => (e.target as dynamic).value}`)
              // is what the pre-redesign pages used and it does not bind
              // here — the field stayed empty however much you typed, so
              // "Draft my agent" reported an empty description over a
              // full textarea. onInput is the API the rest of the app
              // uses (18 call sites).
              //
              // Deliberately no setState: the value is echoed back as
              // this element's child, and rebuilding on every keystroke
              // resets the caret to the start.
              onInput: (v) => _description = v,
              [Component.text(_description)],
            ),
            if (_error != null)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};'
                      'color:${KolaVar.danger};line-height:1.5;'
                      'margin-top:10px',
                },
                [Component.text(_error!)],
              ),
            button(
              attributes: {
                'type': 'button',
                if (_creating) 'disabled': 'disabled',
                'style': 'margin-top:14px;padding:11px 20px;'
                    'border-radius:${KolaRadius.md};border:none;'
                    'background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};font-family:inherit;'
                    'font-size:${KolaType.body};font-weight:600;'
                    'cursor:pointer;opacity:${_creating ? '0.65' : '1'}',
              },
              events: {
                'click': (_) {
                  if (!_creating) _submit();
                },
              },
              [Component.text(_creating ? 'Drafting…' : 'Draft my agent')],
            ),
          ],
        ),
      ];

  List<Component> _done(Bot bot) => [
        div(
          attributes: {
            'style': 'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
                'padding:${KolaSpace.lg};text-align:center',
          },
          [
            div(
              attributes: {
                'style': 'color:${KolaVar.success};margin-bottom:10px',
              },
              [kolaIcon(Icons.check, size: 26, strokeWidth: 2.2)],
            ),
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.display};'
                    'font-size:${KolaType.title};font-weight:700;'
                    'color:${KolaVar.text};margin-bottom:6px',
              },
              [Component.text('${bot.name} is drafted')],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};'
                    'color:${KolaVar.muted};line-height:1.55;'
                    'margin-bottom:16px',
              },
              [
                Component.text('Next: review what it can do, teach it about '
                    'your products, and connect a channel so customers can '
                    'reach it.'),
              ],
            ),
            Link(
              to: '/bots/${bot.id}',
              attributes: {
                'class': 'kola-pressable',
                'style': 'display:inline-block;padding:11px 20px;'
                    'border-radius:${KolaRadius.md};'
                    'background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};'
                    'font-size:${KolaType.body};font-weight:600;'
                    'text-decoration:none',
              },
              children: [Component.text('Open ${bot.name}')],
            ),
          ],
        ),
      ];
}
