// operations_page.dart — the inbox. Conversations and support tickets
// in one place.
//
// ── CONVERSATIONS DO NOT HAVE THEIR OWN PAGE ANY MORE ────────────────
//
// `Kola Conversations.dc.html` in the design export is a redirect stub:
// "Conversations now live inside Operations, alongside escalations — a
// conversation is shown as a customer in context, not a standalone chat
// window." That is the design decision, and this page implements it.
// The old /conversations route redirects here.
//
// ── WHAT THE DESIGN SHOWS THAT THE BACKEND CANNOT YET FILL ───────────
//
// The export's detail pane carries four things there is no endpoint
// for. None of them are faked here:
//
//   CUSTOMER CONTEXT CHIPS (lifetime value, orders, last purchase,
//     saved date) — customers.core is a locked feature and there is no
//     customer endpoint at all. Gated.
//
//   CITATIONS ("Inventory.xlsx, row 214") — the Message model has no
//     citation field. Memory retrieval records its sources server-side,
//     but nothing exposes them per message yet.
//
//   SUGGESTED REPLY — the export offers an editable AI draft. There is
//     no endpoint that produces one.
//
//   FIRED ERRANDS with outcomes — errand_execution_log exists as a
//     model, but EndpointErrand has no method to list executions.
//
// Each is a real gap, written down rather than papered over with
// plausible-looking sample data. A support inbox that invents a
// customer's lifetime value is worse than one that omits it.
//
// ── WHAT IS REAL ─────────────────────────────────────────────────────
//
//   conversation.listAll / listEscalated  → the queue
//   conversation.getMessages              → the transcript
//   conversation.sendHumanReply           → replying
//   conversation.closeConversation        → resolving
//   supportTicket.list / setStatus        → the tickets tab

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../services/imagekit_url.dart';
import '../theme.dart';

enum _Tab { queue, tickets }

class OperationsPage extends StatefulComponent {
  const OperationsPage({
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
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  _Tab _tab = _Tab.queue;

  bool _loading = true;
  String? _error;

  List<Conversation> _conversations = const [];
  Set<int> _escalatedIds = const {};
  List<SupportTicket> _tickets = const [];

  Conversation? _selected;
  List<Message> _messages = const [];
  bool _messagesLoading = false;

  String _reply = '';
  bool _sending = false;

  /// Mobile only. Desktop shows both panes at once, so this is ignored
  /// above the breakpoint — see build().
  bool _showDetailOnMobile = false;

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

    final c = component.client;
    final t = component.accessToken;
    final w = component.workspaceId;

    try {
      final results = await Future.wait<List<dynamic>>([
        c.conversation.listAll(t, w),
        component.gate.isEnabled(Features.escalation)
            ? c.conversation.listEscalated(t, w)
            : Future.value(const <Conversation>[]),
        component.gate.isEnabled(Features.operations)
            ? c.supportTicket.list(t, w)
            : Future.value(const <SupportTicket>[]),
      ]);

      if (!mounted) return;
      final convos = results[0].cast<Conversation>();
      final escalated = results[1].cast<Conversation>();

      setState(() {
        _conversations = convos;
        // A set of ids rather than a second list: the queue renders one
        // list and marks the escalated ones, so membership is the only
        // question ever asked.
        _escalatedIds = {
          for (final e in escalated)
            if (e.id != null) e.id!,
        };
        _tickets = results[2].cast<SupportTicket>();
        _loading = false;
      });

      // Open the first escalated conversation if there is one, else the
      // first overall. Escalations are why someone opens this page.
      //
      // Written as a loop rather than with `firstOrNull`, which lives in
      // package:collection — not a direct dependency of this package,
      // and not worth adding one for a two-line search.
      Conversation? first;
      for (final c in convos) {
        if (_escalatedIds.contains(c.id)) {
          first = c;
          break;
        }
      }
      first ??= convos.isEmpty ? null : convos.first;
      if (first != null) _select(first, showDetail: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  Future<void> _select(Conversation convo, {bool showDetail = true}) async {
    setState(() {
      _selected = convo;
      _messages = const [];
      _messagesLoading = true;
      _reply = '';
      if (showDetail) _showDetailOnMobile = true;
    });

    try {
      final msgs = await component.client.conversation.getMessages(
        component.accessToken,
        component.workspaceId,
        convo.id!,
      );
      // A slow fetch that resolves after the user has moved on must not
      // paint the wrong transcript into the wrong conversation.
      if (!mounted || _selected?.id != convo.id) return;
      setState(() {
        _messages = msgs;
        _messagesLoading = false;
      });
    } catch (_) {
      if (!mounted || _selected?.id != convo.id) return;
      setState(() => _messagesLoading = false);
    }
  }

  Future<void> _send() async {
    final body = _reply.trim();
    final convo = _selected;
    if (body.isEmpty || convo == null || _sending) return;

    setState(() => _sending = true);
    try {
      final msg = await component.client.conversation.sendHumanReply(
        component.accessToken,
        component.workspaceId,
        convo.id!,
        body,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, msg];
        _reply = '';
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not send that reply: $e';
      });
    }
  }

  Future<void> _close() async {
    final convo = _selected;
    if (convo == null) return;
    try {
      final updated = await component.client.conversation.closeConversation(
        component.accessToken,
        component.workspaceId,
        convo.id!,
      );
      if (!mounted) return;
      setState(() {
        _selected = updated;
        _conversations = [
          for (final c in _conversations) if (c.id == updated.id) updated else c,
        ];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not close that conversation: $e');
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;height:100%;min-height:0',
      },
      [
        _header(),
        if (_error != null) _errorBanner(),
        if (_loading)
          _skeleton()
        else
          div(
            attributes: {'style': 'flex:1;display:flex;min-height:0'},
            [
              // Desktop: both panes. Mobile: whichever is active.
              div(
                classes: _showDetailOnMobile ? 'kola-shell-desktop' : '',
                attributes: {
                  'style': 'width:100%;max-width:380px;flex:none;'
                      'border-right:1px solid ${KolaVar.border};'
                      'overflow-y:auto;min-height:0',
                },
                [_list()],
              ),
              div(
                classes: _showDetailOnMobile ? '' : 'kola-shell-desktop',
                attributes: {
                  'style': 'flex:1;min-width:0;display:flex;'
                      'flex-direction:column;min-height:0',
                },
                [_detail()],
              ),
            ],
          ),
      ],
    );
  }

  Component _header() {
    final escalatedCount = _escalatedIds.length;
    final openTickets = _tickets
        .where((t) => t.status != 'resolved' && t.status != 'closed')
        .length;

    return div(
      attributes: {
        'style': 'flex:none;padding:20px 20px 0;'
            'border-bottom:1px solid ${KolaVar.border}',
      },
      [
        h1(
          attributes: {
            'style': 'font-family:${KolaFonts.display};font-size:${KolaType.h2};'
                'font-weight:700;color:${KolaVar.text};margin:0 0 4px',
          },
          [Component.text('Operations')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'margin-bottom:14px',
          },
          [
            Component.text(escalatedCount == 0
                ? 'Everything is being handled automatically.'
                : escalatedCount == 1
                    ? '1 conversation needs a person.'
                    : '$escalatedCount conversations need a person.'),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;gap:4px'},
          [
            _tabButton(_Tab.queue, 'Queue', _conversations.length),
            if (component.gate.isEnabled(Features.operations))
              _tabButton(_Tab.tickets, 'Tickets', openTickets),
          ],
        ),
      ],
    );
  }

  Component _tabButton(_Tab tab, String label, int count) {
    final active = _tab == tab;
    return button(
      attributes: {
        'class': 'kola-pressable',
        'type': 'button',
        'style': 'background:transparent;border:none;font-family:inherit;'
            'padding:9px 14px;font-size:${KolaType.body};font-weight:600;'
            'border-bottom:2px solid ${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accent : KolaVar.muted}',
        'aria-selected': active ? 'true' : 'false',
      },
      events: {'click': (_) => setState(() => _tab = tab)},
      [Component.text(count > 0 ? '$label ($count)' : label)],
    );
  }

  // ── List pane ───────────────────────────────────────────────────────

  Component _list() {
    if (_tab == _Tab.tickets) return _ticketList();

    if (_conversations.isEmpty) {
      return _emptyPane(
        'No conversations yet',
        'When a customer messages one of your channels, the conversation '
            'appears here.',
      );
    }

    return div(
      attributes: {'style': 'display:flex;flex-direction:column'},
      [for (final c in _conversations) _listRow(c)],
    );
  }

  Component _listRow(Conversation convo) {
    final selected = _selected?.id == convo.id;
    final escalated = _escalatedIds.contains(convo.id);
    final closed = convo.status == 'closed';

    return button(
      attributes: {
        'class': 'kola-nav-row',
        'type': 'button',
        'style': 'display:flex;flex-direction:column;align-items:stretch;gap:4px;'
            'width:100%;text-align:left;font-family:inherit;'
            'padding:13px 16px;border:none;'
            'border-bottom:1px solid ${KolaVar.border};'
            'background:${selected ? KolaVar.tintSurface(0) : 'transparent'};'
            'cursor:pointer',
      },
      events: {'click': (_) => _select(convo)},
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:8px'},
          [
            if (escalated)
              span(
                attributes: {
                  'style': 'width:7px;height:7px;flex:none;'
                      'border-radius:${KolaRadius.circle};'
                      'background:${KolaVar.danger}',
                },
                [],
              ),
            span(
              attributes: {
                'style': 'flex:1;min-width:0;font-size:${KolaType.body};'
                    'font-weight:600;overflow:hidden;text-overflow:ellipsis;'
                    'white-space:nowrap;'
                    'color:${selected ? KolaVar.accent : KolaVar.text}',
              },
              [Component.text(_displayName(convo))],
            ),
            span(
              attributes: {
                'style': 'font-size:${KolaType.micro};color:${KolaVar.muted};'
                    'flex:none',
              },
              [Component.text(_ago(convo.lastMessageAt))],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:8px;'
                'font-size:${KolaType.tiny};color:${KolaVar.muted}',
          },
          [
            span([Component.text(convo.platformType)]),
            if (escalated)
              span(
                attributes: {'style': KolaTone.negative.badgeCss},
                [Component.text('Needs you')],
              ),
            if (closed)
              span(
                attributes: {'style': KolaTone.neutral.badgeCss},
                [Component.text('Closed')],
              ),
          ],
        ),
      ],
    );
  }

  Component _ticketList() {
    final open = _tickets
        .where((t) => t.status != 'resolved' && t.status != 'closed')
        .toList();

    if (open.isEmpty) {
      return _emptyPane(
        'No open tickets',
        'Tickets are raised when a conversation needs tracked follow-up.',
      );
    }

    final now = DateTime.now();
    return div(
      attributes: {'style': 'display:flex;flex-direction:column'},
      [
        for (final t in open)
          div(
            attributes: {
              'style': 'padding:14px 16px;'
                  'border-bottom:1px solid ${KolaVar.border}',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.body};font-weight:600;'
                      'color:${KolaVar.text};margin-bottom:6px',
                },
                [Component.text(t.subject)],
              ),
              div(
                attributes: {'style': 'display:flex;gap:8px;align-items:center'},
                [
                  span(
                    attributes: {'style': _slaTone(t, now).badgeCss},
                    [Component.text(_slaLabel(t, now))],
                  ),
                  span(
                    attributes: {
                      'style': 'font-size:${KolaType.micro};'
                          'color:${KolaVar.muted}',
                    },
                    [Component.text(t.priority)],
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  // ── Detail pane ─────────────────────────────────────────────────────

  Component _detail() {
    final convo = _selected;
    if (convo == null) {
      return _emptyPane('Nothing selected',
          'Pick a conversation on the left to see the full exchange.');
    }

    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;height:100%;min-height:0',
      },
      [
        _detailHeader(convo),
        div(
          attributes: {
            'style': 'flex:1;overflow-y:auto;min-height:0;padding:16px 20px;'
                'display:flex;flex-direction:column;gap:10px',
          },
          [
            if (_messagesLoading)
              for (var i = 0; i < 3; i++)
                div(
                  classes: 'kola-skel',
                  attributes: {
                    'style': 'height:44px;border-radius:${KolaRadius.md};'
                        'max-width:70%;'
                        '${i.isOdd ? 'align-self:flex-end' : ''}',
                  },
                  [],
                )
            else if (_messages.isEmpty)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
                },
                [Component.text('No messages in this conversation yet.')],
              )
            else
              for (final m in _messages) _bubble(m),
          ],
        ),
        _composer(convo),
      ],
    );
  }

  Component _detailHeader(Conversation convo) => div(
        attributes: {
          'style': 'flex:none;padding:14px 20px;'
              'border-bottom:1px solid ${KolaVar.border};'
              'display:flex;align-items:center;gap:12px',
        },
        [
          // Back, mobile only — on desktop both panes are visible and a
          // back button would have nothing to go back from.
          button(
            classes: 'kola-shell-mobile kola-pressable',
            attributes: {
              'type': 'button',
              'style': 'background:transparent;border:none;flex:none;'
                  'color:${KolaVar.muted};align-items:center',
              'aria-label': 'Back to the list',
            },
            events: {'click': (_) => setState(() => _showDetailOnMobile = false)},
            [kolaIcon(Icons.arrowRight, size: 16, extraStyle: 'transform:rotate(180deg)')],
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
                [Component.text(_displayName(convo))],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.micro};color:${KolaVar.muted}',
                },
                [Component.text('${convo.platformType} · ${convo.status}')],
              ),
            ],
          ),
          if (convo.status != 'closed')
            button(
              attributes: {
                'class': 'kola-pressable',
                'type': 'button',
                'style': 'flex:none;background:transparent;'
                    'border:1px solid ${KolaVar.border};color:${KolaVar.muted};'
                    'border-radius:${KolaRadius.pill};padding:6px 14px;'
                    'font-size:${KolaType.micro};font-weight:600;'
                    'font-family:inherit',
              },
              events: {'click': (_) => _close()},
              [Component.text('Mark resolved')],
            ),
        ],
      );

  /// One message.
  ///
  /// Direction decides the side. 'inbound' is the customer (left);
  /// anything else came from this side (right) — which covers both the
  /// bot and a human reply, deliberately: to the customer they arrived
  /// identically, and the transcript is a record of what the customer
  /// actually saw.
  Component _bubble(Message m) {
    final inbound = m.direction == 'inbound';
    final human = m.senderType == 'human';

    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;max-width:78%;'
            '${inbound ? 'align-self:flex-start' : 'align-self:flex-end'}',
      },
      [
        div(
          attributes: {
            'style': 'padding:10px 14px;border-radius:${KolaRadius.md};'
                'font-size:${KolaType.body};line-height:1.5;'
                'white-space:pre-wrap;overflow-wrap:anywhere;'
                '${inbound ? 'background:${KolaVar.card};color:${KolaVar.text}' : 'background:${KolaVar.successBg};color:${KolaVar.text}'}',
          },
          [
            // ── THE PHOTO, WHEN THERE IS ONE ──────────────────────────
            //
            // Above the text, because the picture IS the message when a
            // customer sends one — the caption, if any, explains it.
            //
            // Three states, and the third is the one worth getting
            // right:
            //   url present   the photo, rendered
            //   kind, no url  it arrived and could not be stored, said
            //                 plainly rather than shown as nothing
            //   neither       an ordinary text message
            if (m.mediaUrl != null)
              div(
                attributes: {
                  'style': 'margin:-2px 0 8px;border-radius:'
                      '${KolaRadius.md};overflow:hidden;max-width:260px;'
                      'border:1px solid ${KolaVar.border}',
                },
                [
                  img(
                    // Width-capped through the same helper the catalog
                    // uses — a phone camera original is several MB and
                    // this bubble is 260px wide.
                    src: ImageKitUrl.wide(m.mediaUrl!, width: 520),
                    alt: m.mediaKind == 'video'
                        ? 'Video from the customer'
                        : 'Photo from the customer',
                    attributes: {
                      'loading': 'lazy',
                      'style': 'width:100%;display:block',
                    },
                  ),
                ],
              )
            else if (m.mediaKind != null)
              // NOT silently dropped. The owner needs to know a picture
              // was sent even when kolaa could not keep it, because the
              // customer is about to refer to it.
              div(
                attributes: {
                  'style': 'margin-bottom:6px;padding:8px 10px;'
                      'border-radius:${KolaRadius.sm};'
                      'border:1px dashed ${KolaVar.border};'
                      'font-size:${KolaType.tiny};color:${KolaVar.muted}',
                },
                [
                  Component.text(
                    m.mediaKind == 'video'
                        ? 'Sent a video — it could not be saved'
                        : 'Sent a photo — it could not be saved',
                  ),
                ],
              ),

            Component.text(m.body),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:9.5px;color:${KolaVar.muted};margin-top:3px;'
                '${inbound ? '' : 'text-align:right'}',
          },
          [
            // Says who sent it. Without this a shop owner cannot tell
            // their own reply from the bot's, which matters when they
            // are deciding whether to step in.
            Component.text(inbound
                ? _time(m.createdAt)
                : '${human ? 'You' : 'kolaa'} · ${_time(m.createdAt)}'),
          ],
        ),
      ],
    );
  }

  Component _composer(Conversation convo) {
    if (convo.status == 'closed') {
      return div(
        attributes: {
          'style': 'flex:none;padding:14px 20px;'
              'border-top:1px solid ${KolaVar.border};'
              'font-size:${KolaType.small};color:${KolaVar.muted}',
        },
        [Component.text('This conversation is closed.')],
      );
    }

    return div(
      attributes: {
        'style': 'flex:none;padding:12px 16px;'
            'border-top:1px solid ${KolaVar.border};'
            'display:flex;gap:8px;align-items:center',
      },
      [
        input<String>(
          type: InputType.text,
          attributes: {
            'placeholder': 'Reply as yourself…',
            'aria-label': 'Your reply',
            'style': 'flex:1;min-width:0;background:${KolaVar.card};'
                'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.pill};padding:10px 16px;'
                'color:${KolaVar.text};font-family:inherit;'
                'font-size:${KolaType.body};outline:none',
          },
          onInput: (v) => _reply = v,
          events: {
            'keydown': (e) {
              // Was `(e as dynamic).key`, which throws — so pressing
              // Enter to send a reply did nothing at all. See
              // command_palette.dart and dom_files.dart.
              if ((e as web.KeyboardEvent).key == 'Enter') _send();
            },
          },
        ),
        button(
          attributes: {
            'class': 'kola-pressable',
            'type': 'button',
            'style': 'flex:none;width:38px;height:38px;'
                'border-radius:${KolaRadius.circle};border:none;'
                'background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                'display:flex;align-items:center;justify-content:center;'
                '${_sending ? 'opacity:0.6' : ''}',
            'aria-label': 'Send reply',
          },
          events: {'click': (_) => _send()},
          [kolaIcon(Icons.arrowRight, size: 16, strokeWidth: 2)],
        ),
      ],
    );
  }

  // ── Shared bits ─────────────────────────────────────────────────────

  Component _skeleton() => div(
        attributes: {
          'style': 'flex:1;padding:20px;display:flex;flex-direction:column;gap:10px',
        },
        [
          for (var i = 0; i < 6; i++)
            div(
              classes: 'kola-skel',
              attributes: {'style': 'height:58px;border-radius:${KolaRadius.md}'},
              [],
            ),
        ],
      );

  Component _emptyPane(String title, String body) => div(
        attributes: {
          'style': 'padding:40px 24px;text-align:center;'
              'display:flex;flex-direction:column;align-items:center;gap:8px',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text}',
            },
            [Component.text(title)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.5;max-width:320px',
            },
            [Component.text(body)],
          ),
        ],
      );

  Component _errorBanner() => div(
        attributes: {
          'role': 'alert',
          'style': 'flex:none;margin:12px 20px 0;padding:10px 14px;'
              'background:${KolaVar.dangerBg};color:${KolaVar.danger};'
              'border:1px solid ${KolaVar.danger};'
              'border-radius:${KolaRadius.md};font-size:${KolaType.small}',
        },
        [Component.text(_error!)],
      );

  /// The customer's name, or their handle, or their number.
  ///
  /// displayName is nullable and frequently absent — a WhatsApp contact
  /// who has not set a profile name arrives as a bare phone number.
  /// Falling through to externalUserId keeps every row identifiable.
  static String _displayName(Conversation c) {
    final n = c.displayName?.trim();
    return (n == null || n.isEmpty) ? c.externalUserId : n;
  }

  static String _time(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  static KolaTone _slaTone(SupportTicket t, DateTime now) {
    if (t.slaDeadline.isBefore(now)) return KolaTone.negative;
    if (t.slaDeadline.difference(now) < const Duration(hours: 2)) {
      return KolaTone.caution;
    }
    return KolaTone.neutral;
  }

  static String _slaLabel(SupportTicket t, DateTime now) {
    if (t.slaDeadline.isBefore(now)) {
      final over = now.difference(t.slaDeadline);
      return over.inHours >= 1
          ? '${over.inHours}h overdue'
          : '${over.inMinutes}m overdue';
    }
    final left = t.slaDeadline.difference(now);
    return left.inHours >= 1 ? '${left.inHours}h left' : '${left.inMinutes}m left';
  }
}
