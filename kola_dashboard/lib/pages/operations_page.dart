// operations_page.dart — the inbox. Conversations and escalations in
// one place, rebuilt Phase 13c against `Kola Operations.dc.html` (the
// 35 KB export) per DESIGN_DELTA.md's extraction method.
//
// ── CONVERSATIONS DO NOT HAVE THEIR OWN PAGE ANY MORE ────────────────
//
// `Kola Conversations.dc.html` in the design export is a redirect stub:
// "Conversations now live inside Operations, alongside escalations — a
// conversation is shown as a customer in context, not a standalone chat
// window." That is the design decision, and this page implements it.
// The old /conversations route redirects here.
//
// ── PHASE 13C: TAB ORDER/NAMING CORRECTED, CUSTOMER CHIPS WIRED ───────
//
// The export's two tabs are "Escalations (N)" then "Conversations", in
// that order — escalations is the default. This page previously had
// them reversed and mislabeled ("Queue" for conversations, "Tickets"
// for escalations). Fixed to match: `_Tab.escalations` is first and
// default, `_Tab.conversations` second. Escalation cards now show the
// linked conversation's customer name, a waiting duration, and an
// "Act now" button that jumps straight into that conversation — none
// of that existed before; SupportTicket already carried
// `conversationId`, it just wasn't being used to cross-link.
//
// The CUSTOMER CONTEXT CHIPS (lifetime value, orders, last purchase,
// saved date) were previously gated off with the note "no customer
// endpoint at all" — that was stale. `CustomerEndpoint.getCustomerDetail`
// already existed (Gate 3b) and now backs the first three chips here;
// a new `CustomerProfileEndpoint.getForConversation` (this pass) backs
// the fourth. See `_loadCustomerContext` for the lifetime-value
// computation and why it does NOT simply sum every Sale plus every
// PaymentTransaction: Gate 13's reconciliation links a completed
// payment to the Sale it paid for via `PaymentTransaction.saleId` —
// summing both would double-count reconciled money. The rule used
// here: every 'completed' Sale, plus every 'completed' payment whose
// `saleId` is still null (money that was never a till sale at all, or
// hasn't been matched yet) — no double count, no undercount.
//
// ── THREE GAPS THAT ARE STILL REAL, RE-VERIFIED THIS PASS ─────────────
//
//   CITATIONS ("Inventory.xlsx, row 214") — re-checked: Message still
//     has no citation field. Memory retrieval records its sources
//     server-side, but nothing exposes them per message yet.
//
//   SUGGESTED REPLY — the export offers an editable AI draft. There is
//     still no endpoint that produces one — same deliberately-unfilled
//     AI-reasoning seam Phase 12 already names for Observations.
//
//   FIRED ERRANDS with outcomes, per conversation — re-checked:
//     ErrandExecutionLog is keyed by (errandId, workspaceId), with no
//     conversationId column at all, so there is no way to ask "what
//     fired on THIS thread" without a schema change. Real, separate
//     future work, not silently dropped.
//
// Each is written down rather than papered over with plausible-looking
// sample data.
//
// ── WHAT IS REAL ─────────────────────────────────────────────────────
//
//   conversation.listAll / listEscalated  → the queue
//   conversation.getMessages              → the transcript
//   conversation.sendHumanReply           → replying
//   conversation.closeConversation        → resolving
//   supportTicket.list / setStatus        → the escalations tab
//   customer.getCustomerDetail            → LTV / orders / last purchase chips
//   customerProfile.getForConversation    → saved date chip

import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../components/shell/page_help_button.dart';
import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../services/imagekit_url.dart';
import '../theme.dart';

enum _Tab { escalations, conversations }

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
  _Tab _tab = _Tab.escalations;

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

  // 14e. A real AI-drafted reply, fetched on request rather than
  // automatically on every conversation open — an unconfigured/rate-
  // limited provider cascade means this can be slow or fall back to a
  // template, and firing it silently for every conversation the owner
  // merely glances at would be wasted latency and provider calls for
  // drafts nobody asked for.
  bool _draftLoading = false;

  // ── Customer context chips (Phase 13c) ────────────────────────────
  //
  // Keyed by customerId, not conversationId — two conversations can
  // point at the same customer, and there is no reason to fetch twice.
  // Populated lazily by _loadCustomerContext, called from _select.
  final Map<int, CustomerDetail> _customerDetailCache = {};
  final Map<int, CustomerProfile?> _customerProfileCache = {};
  bool _customerContextLoading = false;

  /// Mobile only. Desktop shows both panes at once, so this is ignored
  /// above the breakpoint — see build().
  bool _showDetailOnMobile = false;

  @override
  void initState() {
    super.initState();
    // The escalations tab doesn't exist at all when Features.operations
    // is off — defaulting to it in that case would land on a tab whose
    // button is never rendered. See _header's own gate check.
    if (!component.gate.isEnabled(Features.operations)) {
      _tab = _Tab.conversations;
    }
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
      _draftFailed = false;
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

    unawaited(_loadCustomerContext(convo));
  }

  /// Backs the four customer-context chips. Gated on `customers.core`
  /// (same gate `CustomerEndpoint` enforces server-side — checking it
  /// here too just avoids a request that would fail anyway) and on the
  /// conversation actually having a resolved `customerId` — a brand new
  /// conversation with no purchase/identity history yet has none, and
  /// that's a normal state, not an error.
  Future<void> _loadCustomerContext(Conversation convo) async {
    final customerId = convo.customerId;
    if (customerId == null || !component.gate.isEnabled(Features.customers)) {
      return;
    }
    if (_customerDetailCache.containsKey(customerId)) return;

    setState(() => _customerContextLoading = true);
    try {
      final results = await Future.wait([
        component.client.customer.getCustomerDetail(
          component.accessToken,
          component.workspaceId,
          customerId,
        ),
        component.client.customerProfile.getForConversation(
          component.accessToken,
          component.workspaceId,
          convo.id!,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _customerDetailCache[customerId] = results[0] as CustomerDetail;
        _customerProfileCache[customerId] = results[1] as CustomerProfile?;
        _customerContextLoading = false;
      });
    } catch (_) {
      // A failed context fetch should not block the conversation itself
      // from being usable — the chips just don't render.
      if (!mounted) return;
      setState(() => _customerContextLoading = false);
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

  /// 14e. Fetches ConversationEndpoint.draftReply and drops the result
  /// straight into the (now controlled) reply field — editable, not
  /// sent. A failure here is non-fatal to the page: the owner can still
  /// type a reply by hand, same as before this feature existed, so it
  /// surfaces as a small inline note rather than the page's main error
  /// banner (which would read as "Operations is broken").
  bool _draftFailed = false;

  Future<void> _suggestReply() async {
    final convo = _selected;
    if (convo == null || _draftLoading || _sending) return;
    setState(() {
      _draftLoading = true;
      _draftFailed = false;
    });
    try {
      final draft = await component.client.conversation.draftReply(
        component.accessToken,
        component.workspaceId,
        convo.id!,
      );
      if (!mounted || _selected?.id != convo.id) return;
      setState(() {
        _reply = draft;
        _draftLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _draftLoading = false;
        _draftFailed = true;
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
        else if (_tab == _Tab.escalations)
          // Single full-width column, matching the export — Escalations
          // is a queue, not a conversation view, so there is no detail
          // pane here at all. "Act now" on a card switches to the
          // Conversations tab and opens the linked thread instead.
          div(
            attributes: {'style': 'flex:1;overflow-y:auto;min-height:0'},
            [_escalationList()],
          )
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
                [_conversationList()],
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
        div(
          attributes: {
            'style': 'display:flex;align-items:flex-start;'
                'justify-content:space-between;gap:12px',
          },
          [
            h1(
              attributes: {
                'style': 'font-family:${KolaFonts.display};'
                    'font-size:${KolaType.h2};font-weight:700;'
                    'color:${KolaVar.text};margin:0 0 4px',
              },
              [Component.text('Operations')],
            ),
            const PageHelpButton(
              pageKey: 'operations',
              body: [
                "Escalations are conversations kola couldn't handle on "
                    "its own and handed to a person — Conversations is "
                    "every conversation, handled or not, in case you "
                    "want to check in on one kola is still running.",
                "Tap 'Suggest a reply' and kola drafts one from the "
                    "conversation so far — it lands in the box below for "
                    "you to edit or replace before sending, never sent "
                    "automatically. Same composer on both tabs.",
              ],
            ),
          ],
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
            // Escalations first, matching the export's own tab order
            // and default ('queue' in the export's state is this tab).
            if (component.gate.isEnabled(Features.operations))
              _tabButton(_Tab.escalations, 'Escalations', openTickets),
            _tabButton(_Tab.conversations, 'Conversations', _conversations.length),
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

  // ── List panes ──────────────────────────────────────────────────────

  Component _conversationList() {
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

  /// The export's escalation card: a urgency-colored left bar, title,
  /// "customer · waiting Xh", a right-aligned deadline countdown +
  /// priority label, and an "Act now" button. One field from the export
  /// is deliberately not rendered: `tried` ("offered replacement,
  /// customer declined") has no home on SupportTicket — there is no
  /// running log of what's been attempted on a ticket, just its current
  /// status. Named here rather than invented.
  Component _escalationList() {
    final open = _tickets
        .where((t) => t.status != 'resolved' && t.status != 'closed')
        .toList();

    if (open.isEmpty) {
      return _emptyPane(
        'All clear',
        'No escalations waiting and nothing needs you right now.',
      );
    }

    final now = DateTime.now();
    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;gap:10px;padding:14px 16px',
      },
      [for (final t in open) _escalationCard(t, now)],
    );
  }

  Component _escalationCard(SupportTicket t, DateTime now) {
    final tone = _slaTone(t, now);
    final barColor = tone == KolaTone.negative
        ? KolaVar.danger
        : tone == KolaTone.caution
            ? KolaVar.warning
            : KolaVar.success;
    final linked = _conversationFor(t);
    final customerName = linked != null ? _displayName(linked) : 'Customer';

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};'
            'border:1px solid ${tone == KolaTone.negative ? KolaVar.danger : KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:14px 16px;'
            'display:flex;align-items:center;gap:14px;flex-wrap:wrap',
      },
      [
        span(
          attributes: {
            'style': 'width:4px;height:34px;border-radius:4px;'
                'background:$barColor;flex:none',
          },
          [],
        ),
        div(
          attributes: {'style': 'flex:1;min-width:160px'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:600;'
                    'color:${KolaVar.text};margin-bottom:3px',
              },
              [Component.text(t.subject)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
              },
              [Component.text('$customerName · waiting ${_ago(t.createdAt)}')],
            ),
          ],
        ),
        div(
          attributes: {'style': 'text-align:right;flex:none'},
          [
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.mono};'
                    'font-size:${KolaType.body};font-weight:600;'
                    'color:$barColor',
              },
              [Component.text(_slaLabel(t, now))],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.micro};color:${KolaVar.muted}',
              },
              [Component.text('${t.priority} priority')],
            ),
          ],
        ),
        button(
          attributes: {
            'class': 'kola-pressable',
            'type': 'button',
            'style': 'background:${KolaVar.accentFill};'
                'color:${KolaVar.accentText};border:none;'
                'border-radius:${KolaRadius.sm};padding:9px 16px;'
                'font-size:${KolaType.small};font-weight:600;flex:none;'
                'min-height:44px;font-family:inherit;cursor:pointer',
          },
          events: {
            'click': (_) {
              setState(() => _tab = _Tab.conversations);
              if (linked != null) _select(linked);
            },
          },
          [Component.text('Act now')],
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

    final chipsRow = _customerChipsRow(convo);

    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;height:100%;min-height:0',
      },
      [
        _detailHeader(convo),
        if (chipsRow != null)
          div(
            attributes: {
              'style': 'flex:none;padding:12px 20px 0',
            },
            [chipsRow],
          ),
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
        'style': 'flex:none;border-top:1px solid ${KolaVar.border}',
      },
      [
        // 14e. "kola suggests" — a real AI-drafted reply the owner edits
        // before sending, fetched on request via
        // ConversationEndpoint.draftReply. Shown above the input rather
        // than auto-filling it silently, so it's visible that the text
        // came from a suggestion, not that the owner typed it.
        div(
          attributes: {
            'style': 'padding:10px 16px 0;display:flex;'
                'align-items:center;gap:8px',
          },
          [
            button(
              attributes: {
                'type': 'button',
                if (_draftLoading || _sending) 'disabled': '',
                'style': 'background:transparent;'
                    'border:1px solid ${KolaVar.border};'
                    'color:${KolaVar.mutedStrong};'
                    'border-radius:${KolaRadius.pill};padding:6px 12px;'
                    'font-size:${KolaType.tiny};font-family:inherit;'
                    'display:inline-flex;align-items:center;gap:6px;'
                    'cursor:${_draftLoading ? 'default' : 'pointer'}',
              },
              events: {'click': (_) => _suggestReply()},
              [
                kolaIcon(Icons.sparkles, size: 12),
                Component.text(
                  _draftLoading ? 'kola is drafting…' : 'Suggest a reply',
                ),
              ],
            ),
            if (_draftFailed)
              span(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
                },
                [Component.text("Couldn't draft one — reply below by hand.")],
              ),
          ],
        ),
        div(
          attributes: {
            'style': 'padding:10px 16px 12px;'
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
              value: _reply,
              onInput: (v) => setState(() => _reply = v),
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
        ),
      ],
    );
  }

  // ── Customer context (Phase 13c) ───────────────────────────────────

  /// The SupportTicket ↔ Conversation link the escalation cards use for
  /// "Act now" — a linear scan of an already-loaded list, not a second
  /// fetch. `null` means the linked conversation hasn't loaded (or the
  /// ticket predates a schema where this always resolves) — callers
  /// treat that as "switch tabs, but don't try to select anything."
  Conversation? _conversationFor(SupportTicket t) {
    for (final c in _conversations) {
      if (c.id == t.conversationId) return c;
    }
    return null;
  }

  /// The four chips from the export — lifetime value, orders, last
  /// purchase, saved date — or `null` when there's nothing to show
  /// (customers.core off, no resolved customerId yet, or the context
  /// fetch hasn't completed). Returning `null` rather than an empty row
  /// is what keeps this out of the layout entirely when there's nothing
  /// real to say, per the same "never show a hollow chip" instinct
  /// DESIGN_DELTA.md applies to zero states elsewhere.
  Component? _customerChipsRow(Conversation convo) {
    final customerId = convo.customerId;
    if (customerId == null) return null;
    final detail = _customerDetailCache[customerId];
    if (detail == null) return null; // still loading, or fetch failed

    final profile = _customerProfileCache[customerId];

    // ── Lifetime value / orders, de-duplicated ──────────────────────
    //
    // See this file's header: a completed Sale and a completed
    // PaymentTransaction can be the SAME money (Gate 13 reconciliation
    // links them via PaymentTransaction.saleId). Counting both would
    // overstate what this customer has actually paid.
    var minor = 0;
    var orders = 0;
    DateTime? lastPurchase;
    var currency = 'NGN';
    for (final s in detail.sales) {
      if (s.status != 'completed') continue;
      minor += s.totalMinor;
      orders++;
      currency = s.currency;
      if (lastPurchase == null || s.soldAt.isAfter(lastPurchase)) {
        lastPurchase = s.soldAt;
      }
    }
    for (final p in detail.payments) {
      if (p.status != 'completed' || p.saleId != null) continue;
      minor += p.amountKobo;
      orders++;
      currency = p.currency;
      final when = p.paidAt ?? p.createdAt;
      if (lastPurchase == null || when.isAfter(lastPurchase)) {
        lastPurchase = when;
      }
    }

    final chips = <MapEntry<String, String>>[
      MapEntry('Lifetime value', _naira(minor, currency)),
      MapEntry('Orders', '$orders'),
      MapEntry(
        'Last purchase',
        lastPurchase == null ? '—' : _dateAgo(lastPurchase),
      ),
      MapEntry(
        'Saved date',
        profile?.birthday == null ? '—' : _monthDay(profile!.birthday!),
      ),
    ];

    return div(
      attributes: {
        'style': 'display:flex;gap:10px;flex-wrap:wrap',
      },
      [
        for (final c in chips)
          div(
            attributes: {
              'style': 'background:${KolaVar.bg};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:9px;padding:8px 12px;min-width:110px',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.micro};color:${KolaVar.muted};'
                      'margin-bottom:2px;text-transform:uppercase;'
                      'letter-spacing:0.03em',
                },
                [Component.text(c.key)],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};font-weight:600;'
                      'color:${KolaVar.text}',
                },
                [Component.text(c.value)],
              ),
            ],
          ),
      ],
    );
  }

  /// Same minor-unit-divided-by-100 approach as till_display_page.dart's
  /// own `_money` and PublicCatalogPage's `_priceLabel` — including the
  /// same named gap: zero-decimal currencies aren't handled specially.
  static String _naira(int minor, String currency) {
    final major = minor / 100;
    return '$currency ${major.toStringAsFixed(2)}';
  }

  static String _dateAgo(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  static String _monthDay(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
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
