// bot_detail_dev_page.dart — the "structured/dev surface" from
// SRS.md §11: a table/form/JSON-schema view of the same bot object
// Chat Mode edits conversationally. Matches Kola Bot Detail Dev.dc.html's
// tabbed layout (Overview/Errands/Knowledge/Channels/Logs/API).
//
// REAL DATA (this pass), tab by tab — each wired only as far as an
// actual kola_server endpoint supports, per this project's own "don't
// build UI promising a backend that doesn't exist" discipline:
//   - Overview: real conversation/errand/channel counts (BotEndpoint,
//     ErrandEndpoint, ChannelEndpoint, ConversationEndpoint). No
//     "avg response time" stat — no latency-aggregation endpoint exists
//     (ErrandExecutionLog is written but nothing lists it), so that
//     stat is dropped rather than shown with a fabricated number.
//   - Errands: real Errand rows (name/source/status/schema/scope come
//     straight off the Errand record). "Last called" is honestly '—'
//     for every row — no execution-log listing endpoint exists to back
//     it (see errand_endpoint.dart: nothing exposes ErrandExecutionLog).
//   - Knowledge: real — a single card reflecting Bot.knowledgeSeed's
//     actual state, since that's genuinely the only knowledge storage
//     that exists (no multi-document upload system — same scope line
//     knowledge_page.dart already drew). Links to the real /knowledge
//     page.
//   - Channels: fully real (ChannelEndpoint.listChannelsForBot).
//   - Logs: real recent message activity from this bot's actual
//     Conversations (ConversationEndpoint), reformatted as log lines —
//     not ErrandExecutionLog specifically (no listing endpoint for
//     that), but genuine activity, not mock text.
//   - API: unchanged — dev_api_tab.dart already only used the real
//     botId and an honestly-labeled placeholder bearer token.

import 'dart:convert';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/bot_dev_header.dart';
import '../components/dev_tab_bar.dart';
import '../components/dev_overview_tab.dart';
import '../components/dev_errands_tab.dart';
import '../components/dev_knowledge_tab.dart';
import '../components/dev_channels_tab.dart';
import '../components/dev_logs_tab.dart';
import '../components/dev_api_tab.dart';
import '../models/bot_summary.dart';
import '../models/overview_stat.dart';
import '../models/errand_row.dart';
import '../models/errand_status.dart';
import '../models/knowledge_doc_summary.dart';
import '../models/channel_card_summary.dart';
import '../models/log_entry.dart';

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
  final String botId;

  @override
  State<BotDetailDevPage> createState() => _BotDetailDevPageState();
}

class _BotDetailDevPageState extends State<BotDetailDevPage> {
  String _tab = 'errands';
  int? _selectedErrandIndex;

  Bot? _bot;
  List<Channel> _channels = const [];
  List<Errand> _errands = const [];
  List<Conversation> _conversations = const [];
  List<Message> _recentMessages = const [];
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
        component.client.conversation.listAll(component.accessToken, component.workspaceId),
      ]);
      final bot = results[0] as Bot;
      final channels = results[1] as List<Channel>;
      final errands = results[2] as List<Errand>;
      final conversations = [
        ...(results[3] as List<Conversation>).where((c) => c.botId == botId),
      ]..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

      List<Message> recentMessages = const [];
      if (conversations.isNotEmpty) {
        try {
          recentMessages = await component.client.conversation.getMessages(
            component.accessToken,
            component.workspaceId,
            conversations.first.id!,
          );
        } catch (_) {
          // Non-fatal — Logs tab just shows less activity.
        }
      }

      if (mounted) {
        setState(() {
          _bot = bot;
          _channels = channels;
          _errands = errands;
          _conversations = conversations;
          _recentMessages = recentMessages;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = "Couldn't load this bot. Check your connection and try again.");
      }
    }
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

  String _channelsLabel() {
    final connected = _channels.where((c) => c.status == 'connected').toList();
    if (connected.isEmpty) return 'No channel connected';
    return connected.map((c) => c.platformType == 'telegram' ? 'Telegram' : 'WhatsApp').toSet().join(', ');
  }

  List<OverviewStat> get _overviewStats => [
    OverviewStat(label: 'Conversations', value: _conversations.length.toString()),
    OverviewStat(
      label: 'Active errands',
      value: _errands.where((e) => e.status == 'active').length.toString(),
    ),
    OverviewStat(
      label: 'Channels connected',
      value: _channels.where((c) => c.status == 'connected').length.toString(),
    ),
  ];

  String get _configSummary {
    final bot = _bot;
    if (bot == null) return '';
    final parts = ['Archetype: ${_archetypeLabel(bot.archetype)}', 'Channels: ${_channelsLabel()}'];
    final hasEscalation = _errands.any(
      (e) => e.source == 'builtin' && e.builtinHandlerKey == 'escalateToHuman' && e.status == 'active',
    );
    if (hasEscalation) parts.add('Fallback: escalate to human');
    return parts.join(' · ');
  }

  List<ErrandRow> get _errandRows => [
    for (final e in _errands)
      ErrandRow(
        name: e.name,
        trigger: e.descriptionForAi,
        source: e.source,
        status: e.status == 'active' ? ErrandStatus.live : ErrandStatus.draft,
        statusLabel: e.status == 'active' ? 'Live' : 'Disabled',
        // No execution-log listing endpoint exists server-side yet
        // (errand_endpoint.dart never exposes ErrandExecutionLog) — '—'
        // is honest, not a guess dressed up as data.
        lastCalled: '—',
        schema: _prettyJson(e.inputSchemaJson),
        fulfillment: _fulfillmentText(e),
        scope: e.permissionScope == 'readWrite' ? 'Read/write' : 'Read-only',
      ),
  ];

  static String _fulfillmentText(Errand e) {
    switch (e.source) {
      case 'builtin':
        return 'Built-in: ${e.builtinHandlerKey ?? 'handler'}';
      case 'webhook':
        return 'Webhook-based fulfillment';
      case 'dbCredential':
        return 'Database query fulfillment';
      case 'mcp':
        return 'MCP endpoint fulfillment';
      default:
        return e.source;
    }
  }

  static String _prettyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  List<KnowledgeDocSummary> get _knowledgeDocs {
    final seed = _bot?.knowledgeSeed;
    final hasSeed = seed != null && seed.trim().isNotEmpty;
    return [
      KnowledgeDocSummary(
        icon: '📝',
        name: 'Knowledge seed text',
        status: hasSeed ? 'Set — ${seed!.trim().length} chars' : 'Not set yet',
      ),
    ];
  }

  List<ChannelCardSummary> get _channelCards {
    const platforms = ['telegram', 'whatsapp'];
    return [
      for (final platform in platforms)
        _channelCardFor(platform, _channels.where((c) => c.platformType == platform).toList()),
    ];
  }

  ChannelCardSummary _channelCardFor(String platform, List<Channel> matches) {
    final label = platform == 'telegram' ? 'Telegram' : 'WhatsApp';
    final icon = platform == 'telegram' ? '✈️' : '💬';
    final connected = matches.where((c) => c.status == 'connected').toList();
    if (connected.isNotEmpty) {
      final display = connected.first.displayName;
      return ChannelCardSummary(
        icon: icon,
        name: label,
        status: display != null && display.isNotEmpty ? '● Connected — $display' : '● Connected',
        statusColor: '#7ED8B0',
      );
    }
    return ChannelCardSummary(icon: icon, name: label, status: 'Not connected', statusColor: '#6B655E');
  }

  List<LogEntry> get _logs {
    if (_recentMessages.isEmpty) {
      return const [LogEntry(time: '', text: 'No activity yet.')];
    }
    final sorted = [..._recentMessages]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [for (final m in sorted.take(20)) LogEntry(time: _formatTime(m.createdAt), text: _describeMessage(m))];
  }

  static String _describeMessage(Message m) {
    switch (m.senderType) {
      case 'customer':
        return 'Inbound message received from customer';
      case 'bot':
        return 'Bot replied automatically';
      case 'human':
        return 'Human agent replied';
      default:
        return m.direction == 'inbound' ? 'Inbound message received' : 'Outbound message sent';
    }
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
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
      channelsLabel: _channelsLabel(),
    );

    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:#121214;color:#F3EEE7;"
            'width:100%;height:100vh;overflow:hidden;box-sizing:border-box;'
            'display:flex;flex-direction:column;'
            'background-image:radial-gradient(circle, rgba(255,255,255,0.06) 1.4px, transparent 1.4px);'
            'background-size:24px 24px',
      },
      [
        BotDevHeader(bot: summary),
        DevTabBar(currentTab: _tab, onTabChange: (t) => setState(() => _tab = t)),
        div(
          attributes: {'style': 'flex:1;min-height:0;overflow-y:auto;padding:28px 24px'},
          [_currentTabContent()],
        ),
      ],
    );
  }

  Component _currentTabContent() {
    switch (_tab) {
      case 'overview':
        return DevOverviewTab(stats: _overviewStats, configSummary: _configSummary);
      case 'knowledge':
        return DevKnowledgeTab(docs: _knowledgeDocs);
      case 'channels':
        return DevChannelsTab(cards: _channelCards);
      case 'logs':
        return DevLogsTab(logs: _logs);
      case 'api':
        return DevApiTab(botId: component.botId);
      case 'errands':
      default:
        final rows = _errandRows;
        return DevErrandsTab(
          rows: rows,
          selectedIndex: _selectedErrandIndex,
          onRowClick: (i) => setState(() => _selectedErrandIndex = i),
          onClose: () => setState(() => _selectedErrandIndex = null),
        );
    }
  }
}
