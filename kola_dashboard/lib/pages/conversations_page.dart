// conversations_page.dart — Phase 4e's own remaining scope item
// (DEVELOPMENT_PLAN.md line 133: "Still pending: Conversations inbox").
// No .dc.html design export exists for this page — unlike every other
// page in this shell, there's no approved mock to match pixel-for-pixel,
// so this is a functional build using the same theme tokens/visual
// language as the rest of kola_dashboard, not a from-scratch design.
//
// Backed entirely by kola_server's real ConversationEndpoint (built in
// the Escalation feature pass — see conversation_endpoint.dart's own
// header: "left rail = listEscalated, center thread = getMessages,
// reply box = sendHumanReply"). This page is exactly that shape:
//   - Left rail: escalated conversations by default (the actual queue a
//     human needs to act on), with a toggle to see every conversation
//     regardless of status.
//   - Center: the selected conversation's real message thread.
//   - Reply box: ConversationEndpoint.sendHumanReply — actually sends
//     over the real Telegram/WhatsApp channel, not a local-only echo.
//   - "Close" button: ConversationEndpoint.closeConversation.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/back_link.dart';

class ConversationsPage extends StatefulComponent {
  const ConversationsPage({required this.client, required this.accessToken, required this.workspaceId});

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  List<Conversation>? _conversations;
  String? _loadError;
  bool _showAll = false;

  Conversation? _selected;
  List<Message>? _messages;
  String? _threadError;

  String _replyText = '';
  bool _sending = false;
  String? _sendError;

  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loadError = null);
    try {
      final conversations = _showAll
          ? await component.client.conversation.listAll(component.accessToken, component.workspaceId)
          : await component.client.conversation.listEscalated(component.accessToken, component.workspaceId);
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        // Keep the current selection if it's still in the new list;
        // otherwise fall back to nothing selected rather than a stale
        // thread for a conversation no longer in view.
        if (_selected != null && !conversations.any((c) => c.id == _selected!.id)) {
          _selected = null;
          _messages = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadError = "Couldn't load conversations. Check your connection and try again.");
    }
  }

  Future<void> _selectConversation(Conversation c) async {
    setState(() {
      _selected = c;
      _messages = null;
      _threadError = null;
      _replyText = '';
      _sendError = null;
    });
    try {
      final messages = await component.client.conversation.getMessages(
        component.accessToken,
        component.workspaceId,
        c.id!,
      );
      if (mounted) setState(() => _messages = messages);
    } catch (_) {
      if (mounted) setState(() => _threadError = "Couldn't load this conversation's messages.");
    }
  }

  Future<void> _sendReply() async {
    final selected = _selected;
    if (selected == null || _replyText.trim().isEmpty) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final message = await component.client.conversation.sendHumanReply(
        component.accessToken,
        component.workspaceId,
        selected.id!,
        _replyText.trim(),
      );
      if (mounted) {
        setState(() {
          _messages = [...(_messages ?? const []), message];
          _replyText = '';
          _sending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sendError = "Couldn't send that reply — the channel may be disconnected.";
          _sending = false;
        });
      }
    }
  }

  Future<void> _closeConversation() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() => _closing = true);
    try {
      await component.client.conversation.closeConversation(
        component.accessToken,
        component.workspaceId,
        selected.id!,
      );
      if (mounted) {
        setState(() => _closing = false);
        await _loadConversations();
      }
    } catch (_) {
      if (mounted) setState(() => _closing = false);
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'escalated':
        return 'Escalated';
      case 'closed':
        return 'Closed';
      default:
        return 'Bot handling';
    }
  }

  static String _statusColor(String status) {
    switch (status) {
      case 'escalated':
        return '#F0B08C';
      case 'closed':
        return '#6B655E';
      default:
        return '#7ED8B0';
    }
  }

  static String _platformIcon(String platform) => platform == 'telegram' ? '✈️' : '💬';

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};"
            'color:${KolaDashboardColors.text};width:100%;height:100vh;overflow:hidden;'
            'box-sizing:border-box;display:flex;flex-direction:column',
      },
      [
        div(
          attributes: {
            'style':
                'display:flex;align-items:center;justify-content:space-between;'
                'padding:20px 24px;border-bottom:1px solid ${KolaDashboardColors.border};flex-shrink:0',
          },
          [
            div(
              attributes: {'style': 'display:flex;align-items:center;gap:16px'},
              [
                backLink(),
                div(attributes: {'style': 'font-size:16px;font-weight:700'}, [Component.text('Conversations')]),
              ],
            ),
            div(
              attributes: {'style': 'display:flex;gap:8px'},
              [
                _toggleButton('Escalated', !_showAll, () => _setShowAll(false)),
                _toggleButton('All', _showAll, () => _setShowAll(true)),
              ],
            ),
          ],
        ),
        div(
          attributes: {'style': 'flex:1;min-height:0;display:flex'},
          [_leftRail(), _threadPane()],
        ),
      ],
    );
  }

  void _setShowAll(bool showAll) {
    if (showAll == _showAll) return;
    setState(() => _showAll = showAll);
    _loadConversations();
  }

  Component _toggleButton(String label, bool active, void Function() onClick) {
    return span(
      attributes: {
        'style':
            'font-size:12.5px;font-weight:600;padding:6px 14px;border-radius:100px;cursor:pointer;'
            'background:${active ? KolaDashboardColors.navActiveBg : "transparent"};'
            'color:${active ? KolaDashboardColors.accent : KolaDashboardColors.mutedSecondary};'
            'border:1px solid ${active ? KolaDashboardColors.navActiveBg : KolaDashboardColors.border}',
      },
      events: {'click': (_) => onClick()},
      [Component.text(label)],
    );
  }

  Component _leftRail() {
    final conversations = _conversations;
    return div(
      attributes: {
        'style':
            'width:320px;flex-shrink:0;border-right:1px solid ${KolaDashboardColors.border};'
            'overflow-y:auto;box-sizing:border-box',
      },
      [
        if (conversations == null && _loadError == null)
          _emptyNote('Loading…'),
        if (_loadError != null) _emptyNote(_loadError!),
        if (conversations != null && conversations.isEmpty)
          _emptyNote(_showAll ? 'No conversations yet.' : 'Nothing escalated right now.'),
        if (conversations != null)
          for (final c in conversations) _conversationRow(c),
      ],
    );
  }

  Component _conversationRow(Conversation c) {
    final isSelected = _selected?.id == c.id;
    return div(
      attributes: {
        'style':
            'padding:14px 18px;border-bottom:1px solid ${KolaDashboardColors.border};cursor:pointer;'
            'background:${isSelected ? KolaDashboardColors.card : "transparent"}',
      },
      events: {'click': (_) => _selectConversation(c)},
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:8px;margin-bottom:4px'},
          [
            span(attributes: {'style': 'font-size:13px'}, [Component.text(_platformIcon(c.platformType))]),
            div(
              attributes: {'style': 'font-size:13.5px;font-weight:600;flex:1;min-width:0'},
              [Component.text(c.displayName?.trim().isNotEmpty == true ? c.displayName! : c.externalUserId)],
            ),
          ],
        ),
        span(
          attributes: {
            'style':
                'font-size:11px;font-weight:600;padding:2px 8px;border-radius:100px;'
                'background:#00000030;color:${_statusColor(c.status)}',
          },
          [Component.text(_statusLabel(c.status))],
        ),
      ],
    );
  }

  Component _threadPane() {
    final selected = _selected;
    if (selected == null) {
      return div(
        attributes: {
          'style':
              'flex:1;display:flex;align-items:center;justify-content:center;'
              'color:${KolaDashboardColors.muted};font-size:13.5px',
        },
        [Component.text('Select a conversation to view the thread.')],
      );
    }

    return div(
      attributes: {'style': 'flex:1;display:flex;flex-direction:column;min-height:0'},
      [
        div(
          attributes: {
            'style':
                'display:flex;align-items:center;justify-content:space-between;padding:16px 22px;'
                'border-bottom:1px solid ${KolaDashboardColors.border};flex-shrink:0',
          },
          [
            div(
              attributes: {'style': 'font-size:14.5px;font-weight:600'},
              [
                Component.text(
                  selected.displayName?.trim().isNotEmpty == true ? selected.displayName! : selected.externalUserId,
                ),
              ],
            ),
            if (selected.status != 'closed')
              button(
                [Component.text(_closing ? 'Closing…' : 'Close conversation')],
                onClick: _closeConversation,
                disabled: _closing,
                attributes: {
                  'style':
                      'background:transparent;border:1px solid ${KolaDashboardColors.border};'
                      'color:${KolaDashboardColors.mutedStrong};border-radius:9px;padding:7px 14px;'
                      'font-size:12.5px;cursor:pointer',
                },
              ),
          ],
        ),
        div(
          attributes: {'style': 'flex:1;min-height:0;overflow-y:auto;padding:20px 22px;display:flex;flex-direction:column;gap:10px'},
          [
            if (_threadError != null) _emptyNote(_threadError!),
            if (_messages == null && _threadError == null) _emptyNote('Loading…'),
            if (_messages != null)
              for (final m in _messages!) _messageBubble(m),
          ],
        ),
        _replyBox(selected),
      ],
    );
  }

  Component _messageBubble(Message m) {
    final mine = m.direction == 'outbound';
    return div(
      attributes: {'style': 'display:flex;justify-content:${mine ? "flex-end" : "flex-start"}'},
      [
        div(
          attributes: {
            'style':
                'max-width:60%;padding:10px 14px;border-radius:14px;font-size:13.5px;line-height:1.5;'
                'background:${mine ? KolaDashboardColors.accent : KolaDashboardColors.card};'
                'color:${mine ? KolaDashboardColors.accentText : KolaDashboardColors.text};',
          },
          [
            div([Component.text(m.body)]),
            div(
              attributes: {
                'style':
                    'font-size:10.5px;opacity:0.7;margin-top:4px;text-align:${mine ? "right" : "left"}',
              },
              [Component.text('${m.senderType} · ${_formatTime(m.createdAt)}')],
            ),
          ],
        ),
      ],
    );
  }

  Component _replyBox(Conversation selected) {
    final disabled = selected.status == 'closed';
    return div(
      attributes: {
        'style': 'padding:16px 22px;border-top:1px solid ${KolaDashboardColors.border};flex-shrink:0',
      },
      [
        if (_sendError != null)
          div(attributes: {'style': 'font-size:12.5px;color:#E8A8A8;margin-bottom:8px'}, [Component.text(_sendError!)]),
        div(
          attributes: {'style': 'display:flex;gap:10px'},
          [
            input<String>(
              type: InputType.text,
              value: _replyText,
              onInput: (v) => setState(() => _replyText = v),
              disabled: disabled,
              attributes: {
                'style':
                    'flex:1;background:#141416;border:1px solid ${KolaDashboardColors.border};border-radius:9px;'
                    'padding:11px 12px;font-size:14px;color:${KolaDashboardColors.text};box-sizing:border-box',
                'placeholder': disabled ? 'This conversation is closed.' : 'Type a reply…',
              },
            ),
            button(
              [Component.text(_sending ? 'Sending…' : 'Send')],
              onClick: _sendReply,
              disabled: disabled || _sending || _replyText.trim().isEmpty,
              attributes: {
                'style':
                    'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                    'border:none;border-radius:9px;padding:11px 20px;font-size:14px;font-weight:600;'
                    'cursor:pointer;opacity:${(disabled || _sending) ? "0.6" : "1"}',
              },
            ),
          ],
        ),
      ],
    );
  }

  Component _emptyNote(String text) => div(
    attributes: {'style': 'padding:18px;font-size:13px;color:${KolaDashboardColors.muted}'},
    [Component.text(text)],
  );
}
