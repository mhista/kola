// knowledge_page.dart — Phase 4e's Knowledge Base page, deliberately
// scoped down per the project owner's own choice ("Ship a minimal
// textarea page now") after this gap was surfaced: SRS §8's full
// "Document Parsing Engine" (file upload → parsing → storage) was
// never built, and the ONLY knowledge storage that actually exists
// server-side is Bot.knowledgeSeed — a single plain-text field per bot
// (see EndpointBot.setKnowledgeSeed's doc comment). So this page is
// exactly that: pick a bot, edit its knowledgeSeed in a textarea, save.
// No file upload UI here — building one would just be a dead end
// pointing at a backend field that still only stores plain text.
//
// dev_knowledge_tab.dart's "Full Knowledge Base →" link (Bot Detail's
// Structured Mode) is what should eventually point at this page for a
// specific bot — left as '#' for now since that page still uses fully
// static mock data (Phase 4d) and isn't wired to a real bot id yet;
// not this page's job to fix.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/back_link.dart';
import '../config/env.dart';

class KnowledgePage extends StatefulComponent {
  const KnowledgePage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  List<Bot>? _bots;
  String? _loadError;

  Bot? _selected;
  String _seedText = '';
  bool _saving = false;
  String? _saveError;
  bool _saved = false;

  // COST-SAVING CHANNEL HANDOFF — see bot.spy.yaml's header. Kept as a
  // separate save action from the knowledge textarea above (own state,
  // own button), matching setCostSavingContacts being its own endpoint
  // method server-side, not folded into setKnowledgeSeed.
  String _telegramLink = '';
  String _altWhatsapp = '';
  bool _savingHandoff = false;
  String? _handoffError;
  bool _handoffSaved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bots = await component.client.bot.listBotsForWorkspace(
        component.accessToken,
        component.workspaceId,
      );
      setState(() {
        _bots = bots;
        if (bots.isNotEmpty) _select(bots.first);
      });
    } catch (_) {
      setState(() => _loadError = "Couldn't load your bots. Check your connection and try again.");
    }
  }

  void _select(Bot bot) {
    setState(() {
      _selected = bot;
      _seedText = bot.knowledgeSeed ?? '';
      _saved = false;
      _saveError = null;
      _telegramLink = bot.costSavingTelegramLink ?? '';
      _altWhatsapp = bot.costSavingAlternateWhatsapp ?? '';
      _handoffSaved = false;
      _handoffError = null;
    });
  }

  Future<void> _saveHandoff() async {
    final bot = _selected;
    if (bot == null || bot.id == null) return;
    setState(() {
      _savingHandoff = true;
      _handoffError = null;
      _handoffSaved = false;
    });
    try {
      final updated = await component.client.bot.setCostSavingContacts(
        component.accessToken,
        component.workspaceId,
        bot.id!,
        _telegramLink,
        _altWhatsapp,
      );
      setState(() {
        _selected = updated;
        _savingHandoff = false;
        _handoffSaved = true;
        final bots = _bots;
        if (bots != null) {
          final idx = bots.indexWhere((b) => b.id == updated.id);
          if (idx != -1) bots[idx] = updated;
        }
      });
    } catch (_) {
      setState(() {
        _handoffError = "Couldn't save. Check your connection and try again.";
        _savingHandoff = false;
      });
    }
  }

  Future<void> _save() async {
    final bot = _selected;
    if (bot == null || bot.id == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
      _saved = false;
    });
    try {
      final updated = await component.client.bot.setKnowledgeSeed(
        component.accessToken,
        component.workspaceId,
        bot.id!,
        _seedText,
      );
      setState(() {
        _selected = updated;
        _saving = false;
        _saved = true;
        final bots = _bots;
        if (bots != null) {
          final idx = bots.indexWhere((b) => b.id == updated.id);
          if (idx != -1) bots[idx] = updated;
        }
      });
    } catch (_) {
      setState(() {
        _saveError = "Couldn't save. Check your connection and try again.";
        _saving = false;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};"
            'color:${KolaDashboardColors.text};width:100%;height:100vh;overflow-y:auto;box-sizing:border-box;'
            'padding:40px 32px 60px;display:flex;justify-content:center',
      },
      [
        div(
          attributes: {'style': 'max-width:1100px;width:100%'},
          [
            div(attributes: {'style': 'margin-bottom:14px'}, [backLink()]),
            div(
              attributes: {'style': 'font-size:20px;font-weight:700;margin-bottom:4px'},
              [Component.text('Knowledge')],
            ),
            div(
              attributes: {'style': 'font-size:13.5px;color:${KolaDashboardColors.muted};margin-bottom:24px'},
              [
                Component.text(
                  'What your bot knows, in its own words — price lists, policies, FAQs. '
                  'Paste it in below; the bot reads this before every reply.',
                ),
              ],
            ),
            if (_loadError != null)
              div(
                attributes: {'style': 'color:${KolaDashboardColors.muted};font-size:13.5px'},
                [Component.text(_loadError!)],
              )
            else
              div(
                attributes: {'style': 'display:flex;gap:24px;flex-wrap:wrap'},
                [
                  div(attributes: {'style': 'flex:1;min-width:220px'}, [_botList()]),
                  div(attributes: {'style': 'flex:3;min-width:360px'}, [_editor()]),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Component _botList() {
    final bots = _bots;
    if (bots == null) return _placeholderCard('Loading…');
    if (bots.isEmpty) return _placeholderCard('No bots yet.');
    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:6px'},
      [
        for (final bot in bots)
          div(
            attributes: {
              'style':
                  'padding:10px 12px;border-radius:9px;cursor:pointer;font-size:13.5px;'
                  'background:${_selected?.id == bot.id ? KolaDashboardColors.navActiveBg : "transparent"};'
                  'color:${_selected?.id == bot.id ? KolaDashboardColors.accent : KolaDashboardColors.navInactiveText}',
            },
            events: {'click': (_) => _select(bot)},
            [Component.text(bot.name)],
          ),
      ],
    );
  }

  Component _editor() {
    final bot = _selected;
    if (bot == null) {
      return _placeholderCard('Select a bot to edit its knowledge.');
    }
    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:14px;padding:20px;box-sizing:border-box',
      },
      [
        div(attributes: {'style': 'font-size:14.5px;font-weight:600;margin-bottom:14px'}, [
          Component.text(bot.name),
        ]),

        if (_saveError != null)
          div(
            attributes: {
              'style':
                  'background:#2A1414;border:1px solid #4A2020;color:#E8A8A8;border-radius:8px;'
                  'padding:9px 11px;font-size:12.5px;margin-bottom:14px',
            },
            [Component.text(_saveError!)],
          ),

        textarea(
          [Component.text(_seedText)],
          rows: 16,
          onInput: (v) => setState(() {
            _seedText = v;
            _saved = false;
          }),
          attributes: {
            'style':
                'width:100%;background:#141416;border:1px solid #2C2A28;border-radius:9px;'
                'padding:14px;font-size:13.5px;color:#F3EEE7;box-sizing:border-box;'
                'font-family:${KolaDashboardFonts.mono};line-height:1.6;resize:vertical',
            'placeholder': "Price list, return policy, FAQs — anything the bot should know before it replies…",
          },
        ),

        div(
          attributes: {'style': 'display:flex;align-items:center;gap:14px;margin-top:14px'},
          [
            button(
              [Component.text(_saving ? 'Saving…' : 'Save')],
              type: ButtonType.button,
              disabled: _saving,
              onClick: _save,
              attributes: {
                'style':
                    'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                    'border:none;border-radius:10px;padding:10px 18px;font-size:13.5px;font-weight:600;'
                    'cursor:pointer;opacity:${_saving ? '0.7' : '1'}',
              },
            ),
            if (_saved)
              span(
                attributes: {'style': 'font-size:13px;color:#7ED8B0'},
                [Component.text('Saved')],
              ),
          ],
        ),

        div(attributes: {'style': 'height:1px;background:${KolaDashboardColors.border};margin:22px 0 18px'}, []),
        _handoffSection(),
      ],
    );
  }

  /// COST-SAVING CHANNEL HANDOFF — see bot.spy.yaml's header on why
  /// these two fields exist and why the bot only ever mentions what's
  /// actually filled in here, never invented. Both optional, both blank
  /// by default.
  Component _handoffSection() {
    return div([
      div(attributes: {'style': 'font-size:13.5px;font-weight:600;margin-bottom:4px'}, [
        Component.text('Cost-saving handoff (optional)'),
      ]),
      div(
        attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.muted};margin-bottom:12px;line-height:1.5'},
        [
          Component.text(
            "Meta is ending free WhatsApp replies inside the 24-hour window on Oct 1, 2026. If you'd like your "
            "bot to gently suggest moving a long conversation elsewhere, fill in either field below — it will "
            "only ever mention what you actually provide here. See ",
          ),
          a(
            href: '${Env.kolaDocsUrl}/billing/avoiding-excessive-whatsapp-billing',
            attributes: {'style': 'color:${KolaDashboardColors.accent};text-decoration:none', 'target': '_blank'},
            [Component.text('Avoiding excessive WhatsApp billing')],
          ),
          Component.text(' for the full explanation.'),
        ],
      ),
      if (_handoffError != null)
        div(
          attributes: {
            'style':
                'background:#2A1414;border:1px solid #4A2020;color:#E8A8A8;border-radius:8px;'
                'padding:9px 11px;font-size:12.5px;margin-bottom:12px',
          },
          [Component.text(_handoffError!)],
        ),
      _handoffField(
        label: 'Telegram link or @handle (no per-message fee at all)',
        value: _telegramLink,
        onInput: (v) => setState(() { _telegramLink = v; _handoffSaved = false; }),
        placeholder: 't.me/yourstorebot',
      ),
      _handoffField(
        label: 'Alternate WhatsApp number or instruction',
        value: _altWhatsapp,
        onInput: (v) => setState(() { _altWhatsapp = v; _handoffSaved = false; }),
        placeholder: '+234 801 234 5678',
      ),
      div(
        attributes: {'style': 'display:flex;align-items:center;gap:14px;margin-top:6px'},
        [
          button(
            [Component.text(_savingHandoff ? 'Saving…' : 'Save handoff settings')],
            type: ButtonType.button,
            disabled: _savingHandoff,
            onClick: _saveHandoff,
            attributes: {
              'style':
                  'background:transparent;color:${KolaDashboardColors.text};border:1px solid ${KolaDashboardColors.border};'
                  'border-radius:10px;padding:9px 16px;font-size:13px;font-weight:600;'
                  'cursor:pointer;opacity:${_savingHandoff ? '0.7' : '1'}',
            },
          ),
          if (_handoffSaved)
            span(attributes: {'style': 'font-size:13px;color:#7ED8B0'}, [Component.text('Saved')]),
        ],
      ),
    ]);
  }

  Component _handoffField({
    required String label,
    required String value,
    required void Function(String) onInput,
    String? placeholder,
  }) {
    return div(
      attributes: {'style': 'margin-bottom:10px'},
      [
        div(
          attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:4px'},
          [Component.text(label)],
        ),
        input<String>(
          type: InputType.text,
          value: value,
          onInput: (v) => onInput(v),
          attributes: {
            'style':
                'width:100%;background:#141416;border:1px solid ${KolaDashboardColors.border};border-radius:8px;'
                'padding:9px 10px;font-size:13px;color:${KolaDashboardColors.text};box-sizing:border-box',
            if (placeholder != null) 'placeholder': placeholder,
          },
        ),
      ],
    );
  }

  /// Loading/empty states used to render as bare text with no visual
  /// weight, which looked broken next to the editor's bordered card —
  /// same fix as errand_builder_page.dart's _placeholderCard.
  Component _placeholderCard(String text) => div(
    attributes: {
      'style':
          'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
          'border-radius:14px;padding:24px;box-sizing:border-box;color:${KolaDashboardColors.muted};'
          'font-size:13.5px;text-align:center',
    },
    [Component.text(text)],
  );
}
