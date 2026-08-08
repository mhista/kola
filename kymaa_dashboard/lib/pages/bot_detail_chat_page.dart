// bot_detail_chat_page.dart — the "conversational surface" from
// SRS.md §11: a chat-first interface where the owner talks to Bot
// Mother to build/edit a bot, with the AI's structured summary shown
// live in the plan panel. Matches Kola Bot Detail Chat.dc.html's
// two-pane desktop layout.
//
// REAL DATA (this pass), split honestly by what actually has a backend:
//   - Header + plan panel's bot summary card: real (BotEndpoint.getBot,
//     ChannelEndpoint.listChannelsForBot for the channels label).
//   - Plan panel's Errand list: real (ErrandEndpoint.listErrandsForWorkspace
//     — workspace-scoped, not bot-scoped, same as errand_builder_page.dart).
//   - Plan panel's WhatsApp-style live preview: real, when this bot has
//     an actual Conversation (ConversationEndpoint.listAll, filtered to
//     this botId, most-recently-active one's messages via getMessages).
//     Empty state if the bot has never received a real message.
//   - The LEFT pane (talking to "Bot Mother" to build the bot
//     conversationally) has NO backend at all — no AI-chat-driven bot
//     editing endpoint exists anywhere in kola_server (the real editing
//     surfaces today are Structured Mode's tabs, Errand Builder, and the
//     Knowledge page). Phase 4c/4d's illustrative transcript was always
//     a design-file mockup of a feature that was never built server-side,
//     not real data standing in for a fetch — replacing it with fake
//     "real-looking" messages would be worse than what it replaces, so
//     this pane now honestly says so and links to the surfaces that do
//     work today, matching the same "don't build UI promising a backend
//     that doesn't exist" discipline DEVELOPMENT_PLAN.md's Phase 4e
//     applied to the Knowledge Base page.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/bot_chat_header.dart';
import '../components/bot_plan_panel.dart';
import '../models/bot_summary.dart';
import '../models/errand_chat_summary.dart';
import '../models/errand_status.dart';
import '../models/preview_message.dart';

class BotDetailChatPage extends StatefulComponent {
  const BotDetailChatPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.workspaceName,
    required this.avatarInitial,
    required this.botId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final String workspaceName;
  final String avatarInitial;

  /// The route parameter (/bots/:id) — real, unlike the illustrative
  /// content this page used to render regardless of its value.
  final String botId;

  @override
  State<BotDetailChatPage> createState() => _BotDetailChatPageState();
}

class _BotDetailChatPageState extends State<BotDetailChatPage> {
  Bot? _bot;
  List<Channel> _channels = const [];
  List<Errand> _errands = const [];
  List<PreviewMessage> _previewMessages = const [];
  String? _loadError;

  int? get _botId => int.tryParse(component.botId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final botId = _botId;
    if (botId == null) {
      setState(() => _loadError = 'Invalid bot id.');
      return;
    }
    try {
      final results = await Future.wait([
        component.client.bot.getBot(component.accessToken, component.workspaceId, botId),
        component.client.channel.listChannelsForBot(component.accessToken, component.workspaceId, botId),
        component.client.errand.listErrandsForWorkspace(component.accessToken, component.workspaceId),
      ]);
      final bot = results[0] as Bot;
      final channels = results[1] as List<Channel>;
      final errands = results[2] as List<Errand>;

      // Most recently active real conversation for this bot, if any —
      // the plan panel's "live preview" shows its actual last few
      // messages instead of Phase 4c's fixed mock thread.
      List<PreviewMessage> preview = const [];
      try {
        final conversations = await component.client.conversation.listAll(
          component.accessToken,
          component.workspaceId,
        );
        final botConversations = [...conversations.where((c) => c.botId == botId)]
          ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        if (botConversations.isNotEmpty) {
          final messages = await component.client.conversation.getMessages(
            component.accessToken,
            component.workspaceId,
            botConversations.first.id!,
          );
          preview = [
            for (final m in messages.reversed.take(6).toList().reversed)
              PreviewMessage(text: m.body, mine: m.direction == 'outbound', time: _formatTime(m.createdAt)),
          ];
        }
      } catch (_) {
        // A bot with no conversations yet is the common case, not an
        // error — leave preview empty rather than surfacing _loadError
        // for something that isn't actually a failure.
      }

      if (mounted) {
        setState(() {
          _bot = bot;
          _channels = channels;
          _errands = errands;
          _previewMessages = preview;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadError = "Couldn't load this bot. Check your connection and try again.");
    }
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _archetypeLabel(String archetype) {
    switch (archetype) {
      case 'catalog':
        return 'Catalog';
      case 'customerCare':
        return 'Customer Care';
      default:
        return 'Custom';
    }
  }

  static String _archetypeIcon(String archetype) {
    switch (archetype) {
      case 'catalog':
        return '📦';
      case 'customerCare':
        return '🤖';
      default:
        return '⚙️';
    }
  }

  String _channelsLabel(List<Channel> channels) {
    final connected = channels.where((c) => c.status == 'connected').toList();
    if (connected.isEmpty) return 'No channel connected';
    return connected
        .map((c) => c.platformType == 'telegram' ? 'Telegram' : 'WhatsApp')
        .toSet()
        .join(', ');
  }

  ErrandChatSummary _toChatSummary(Errand errand) {
    final isActive = errand.status == 'active';
    return ErrandChatSummary(
      name: errand.name,
      statusLabel: isActive ? 'Live' : 'Disabled',
      status: isActive ? ErrandStatus.live : ErrandStatus.draft,
    );
  }

  @override
  Component build(BuildContext context) {
    final bot = _bot;

    if (bot == null) {
      return div(
        attributes: {
          'style':
              "font-family:${KolaDashboardFonts.sans};background:#121214;color:#F3EEE7;"
              'width:100%;height:100vh;display:flex;align-items:center;justify-content:center;'
              'font-size:14px;color:${KolaDashboardColors.muted}',
        },
        [Component.text(_loadError ?? 'Loading bot…')],
      );
    }

    final summary = BotSummary(
      id: component.botId,
      name: bot.name,
      icon: _archetypeIcon(bot.archetype),
      iconBg: '#1F6F54',
      archetypeLabel: _archetypeLabel(bot.archetype),
      channelsLabel: _channelsLabel(_channels),
    );

    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:#121214;color:#F3EEE7;"
            'width:100%;height:100vh;overflow:hidden;box-sizing:border-box;display:flex;flex-direction:column;'
            'background-image:radial-gradient(circle, rgba(255,255,255,0.06) 1.4px, transparent 1.4px);'
            'background-size:24px 24px',
      },
      [
        BotChatHeader(bot: summary),
        div(
          attributes: {
            'style': 'flex:1;display:grid;grid-template-columns:1fr 1fr;min-height:0',
          },
          [
            _botMotherPlaceholder(),
            BotPlanPanel(
              bot: summary,
              errands: [for (final e in _errands) _toChatSummary(e)],
              workspaceName: component.workspaceName,
              avatarInitial: component.avatarInitial,
              previewMessages: _previewMessages,
            ),
          ],
        ),
      ],
    );
  }

  /// Honest stand-in for Chat Mode's original design intent — talking to
  /// "Bot Mother" to build/edit this bot conversationally. See this
  /// file's header for why: no such endpoint exists in kola_server, so
  /// rendering a fake illustrative transcript here would misrepresent a
  /// feature that was never built, not real data this page fetched.
  Component _botMotherPlaceholder() {
    return div(
      attributes: {
        'style':
            'border-right:1px solid #1F1D1B;display:flex;flex-direction:column;'
            'align-items:center;justify-content:center;text-align:center;padding:32px;'
            'box-sizing:border-box;min-height:0;gap:14px',
      },
      [
        div(attributes: {'style': 'font-size:32px'}, [Component.text('✳')]),
        div(
          attributes: {'style': 'font-size:15px;font-weight:600;max-width:320px'},
          [Component.text("Talking to Bot Mother to edit this bot conversationally isn't built yet.")],
        ),
        div(
          attributes: {
            'style': 'font-size:13.5px;color:${KolaDashboardColors.muted};max-width:320px;line-height:1.6',
          },
          [
            Component.text(
              'Edit this bot today from Structured Mode, or from the Errand Builder and Knowledge pages.',
            ),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;gap:10px;margin-top:6px'},
          [
            Link(
              to: '/bots/${component.botId}/code',
              attributes: {
                'style':
                    'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                    'border-radius:9px;padding:9px 16px;font-size:13.5px;font-weight:600;text-decoration:none',
              },
              children: [Component.text('Open Structured Mode')],
            ),
            Link(
              to: '/errands',
              attributes: {
                'style':
                    'border:1px solid ${KolaDashboardColors.border};color:${KolaDashboardColors.text};'
                    'border-radius:9px;padding:9px 16px;font-size:13.5px;font-weight:600;text-decoration:none',
              },
              children: [Component.text('Open Errands')],
            ),
          ],
        ),
      ],
    );
  }
}
