// customer_service_page.dart — ADMIN_APP_SPEC.md §3.3, build-order step
// 5, built this pass. Backed by AdminDiagnosticsEndpoint — see that
// file's header for exactly what each diagnostic check does and doesn't
// know (several are honestly UNKNOWN rather than guessed).
//
// FLOW: enter a workspace id, run diagnostics, see six labeled checks,
// then optionally drill into recent conversations or failed knowledge
// documents for that same workspace and act (re-index, resend a
// notification) — all audited server-side.
//
// WORKSPACE INSPECTION (added this pass — the honest substitute for
// literal impersonation, see docs/ADMIN_CONTROL_PLANE_STATUS.md):
// clicking a conversation row expands it into the real message thread
// (AdminDiagnosticsEndpoint.getConversationMessages), and a new
// "Bot configuration" section lists the workspace's configured errands
// (listErrandsForWorkspace) — both read-only. This is deliberately NOT
// a way to send messages as the bot or issue any customer-facing
// session; it's a way to see what the customer and bot actually said
// and what the bot was told to do, which is the real diagnostic need
// behind "why isn't my bot replying."

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../services/admin_error.dart';
import '../theme.dart';

class CustomerServicePage extends StatefulComponent {
  const CustomerServicePage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  String _workspaceIdInput = '';
  int? _workspaceId;

  bool _loading = false;
  String? _error;
  List<String> _checks = const [];
  List<Conversation> _conversations = const [];
  List<KnowledgeDocument> _failedDocs = const [];
  List<Errand> _errands = const [];

  int? _expandedConversationId;
  bool _messagesLoading = false;
  List<Message> _threadMessages = const [];
  String? _threadError;

  bool _busy = false;
  String? _banner;
  bool _bannerIsError = false;

  Future<void> _run() async {
    final id = int.tryParse(_workspaceIdInput.trim());
    if (id == null) {
      setState(() => _error = 'Enter a numeric workspace id.');
      return;
    }
    setState(() {
      _workspaceId = id;
      _loading = true;
      _error = null;
    });
    try {
      final checks = await component.client.adminDiagnostics.diagnoseWorkspace(component.adminToken, id);
      final convos = await component.client.adminDiagnostics.listRecentConversations(component.adminToken, id, limit: 20);
      final docs = await component.client.adminDiagnostics.listFailedKnowledgeDocuments(component.adminToken, id);
      final errands = await component.client.adminDiagnostics.listErrandsForWorkspace(component.adminToken, id);
      if (!mounted) return;
      setState(() {
        _checks = checks;
        _conversations = convos;
        _failedDocs = docs;
        _errands = errands;
        _expandedConversationId = null;
        _threadMessages = const [];
        _threadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (isAdminSessionError(e)) {
        component.onSignOut();
        return;
      }
      setState(() {
        _error = describeAdminError(e);
        _loading = false;
      });
    }
  }

  Future<void> _reindex(KnowledgeDocument doc) async {
    if (_workspaceId == null) return;
    setState(() => _busy = true);
    try {
      final status = await component.client.adminDiagnostics.reindexDocument(
        component.adminToken,
        _workspaceId!,
        doc.id!,
        'Re-index from admin customer service page',
      );
      if (!mounted) return;
      setState(() {
        _banner = 'Re-index result: $status';
        _bannerIsError = status != 'indexed';
        _busy = false;
      });
      await _run();
    } catch (e) {
      if (!mounted) return;
      if (isAdminSessionError(e)) {
        component.onSignOut();
        return;
      }
      setState(() {
        _banner = 'Re-index failed: ${describeAdminError(e)}';
        _bannerIsError = true;
        _busy = false;
      });
    }
  }

  /// Click a conversation row to expand/collapse its real message
  /// thread — see this file's header on why this replaces literal
  /// impersonation. Clicking an already-expanded row just collapses it
  /// without a re-fetch.
  Future<void> _toggleConversation(Conversation c) async {
    if (_workspaceId == null || c.id == null) return;
    if (_expandedConversationId == c.id) {
      setState(() => _expandedConversationId = null);
      return;
    }
    setState(() {
      _expandedConversationId = c.id;
      _messagesLoading = true;
      _threadMessages = const [];
      _threadError = null;
    });
    try {
      final messages = await component.client.adminDiagnostics.getConversationMessages(
        component.adminToken,
        _workspaceId!,
        c.id!,
      );
      if (!mounted) return;
      setState(() {
        _threadMessages = messages;
        _messagesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (isAdminSessionError(e)) {
        component.onSignOut();
        return;
      }
      setState(() {
        _threadError = describeAdminError(e);
        _messagesLoading = false;
      });
    }
  }

  String _statusColor(String status) => switch (status) {
        'OK' => AdminColors.releasedFg,
        'FAIL' => AdminColors.danger,
        'WARN' => AdminColors.betaFg,
        _ => AdminColors.muted,
      };

  @override
  Component build(BuildContext context) => AdminShell(
        activeLabel: 'Customer service',
        onUnbuiltNav: (_) {},
        onSignOut: component.onSignOut,
        child: div(attributes: {'style': 'max-width:900px'}, [
          div(
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:20px;font-weight:700;"
                  'color:${AdminColors.heading};margin-bottom:4px',
            },
            [Component.text('Customer service diagnostics')],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:16px'},
            [
              Component.text(
                'Not every check below is a live signal today — see AdminDiagnosticsEndpoint\'s '
                'header for what UNKNOWN means per check.',
              ),
            ],
          ),
          if (_banner != null) _bannerBox(),
          div(
            attributes: {'style': 'display:flex;gap:8px;margin-bottom:18px'},
            [
              input<String>(
                type: InputType.text,
                value: _workspaceIdInput,
                onInput: (v) => _workspaceIdInput = v,
                attributes: {
                  'placeholder': 'Workspace id',
                  'style': 'padding:9px 12px;border-radius:6px;border:1px solid ${AdminColors.border};'
                      "background:${AdminColors.card};color:${AdminColors.text};width:160px;"
                      "font-family:${AdminFonts.mono};font-size:13px",
                },
              ),
              button(
                [Component.text(_loading ? 'Running…' : 'Run diagnostics')],
                events: {'click': (_) => _run()},
                attributes: {
                  'style': 'padding:9px 16px;border-radius:6px;border:none;background:${AdminColors.accent};'
                      'color:${AdminColors.accentText};font-weight:600;cursor:pointer',
                },
              ),
            ],
          ),
          if (_error != null)
            div(attributes: {'style': 'color:${AdminColors.danger};margin-bottom:12px;font-size:13px'}, [Component.text(_error!)]),
          if (_checks.isNotEmpty) ..._checksSection(),
          if (_workspaceId != null) ..._conversationsSection(),
          if (_workspaceId != null) ..._failedDocsSection(),
          if (_workspaceId != null) ..._errandsSection(),
        ]),
      );

  Component _bannerBox() => div(
        attributes: {
          'style': 'padding:10px 14px;border-radius:8px;margin-bottom:14px;font-size:13px;'
              'background:${_bannerIsError ? AdminColors.dangerBg : AdminColors.releasedBg};'
              'color:${_bannerIsError ? AdminColors.danger : AdminColors.releasedFg};'
              'border:1px solid ${_bannerIsError ? AdminColors.dangerBorder : AdminColors.border}',
        },
        [Component.text(_banner!)],
      );

  List<Component> _checksSection() => [
        div(
          attributes: {'style': 'font-size:13px;font-weight:700;color:${AdminColors.heading};margin:18px 0 8px'},
          [Component.text('Diagnostic checks')],
        ),
        div(
          attributes: {
            'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden;margin-bottom:18px',
          },
          [
            for (final line in _checks) _checkRow(line),
          ],
        ),
      ];

  Component _checkRow(String line) {
    final parts = line.split('|');
    final name = parts.isNotEmpty ? parts[0] : line;
    final status = parts.length > 1 ? parts[1] : '';
    final detail = parts.length > 2 ? parts.sublist(2).join('|') : '';
    return div(
      attributes: {
        'style': 'display:flex;gap:12px;padding:10px 14px;border-bottom:1px solid ${AdminColors.rowBorder};'
            'font-size:12.5px;align-items:baseline',
      },
      [
        span([Component.text(status)], attributes: {
          'style': "font-family:${AdminFonts.mono};font-weight:700;color:${_statusColor(status)};width:56px;flex:none",
        }),
        span([Component.text(name)], attributes: {'style': 'width:180px;flex:none;color:${AdminColors.text}'}),
        span([Component.text(detail)], attributes: {'style': 'color:${AdminColors.muted}'}),
      ],
    );
  }

  List<Component> _conversationsSection() => [
        div(
          attributes: {'style': 'font-size:13px;font-weight:700;color:${AdminColors.heading};margin:18px 0 8px'},
          [Component.text('Recent conversations (${_conversations.length})')],
        ),
        div(
          attributes: {'style': 'font-size:11.5px;color:${AdminColors.faint};margin:-4px 0 8px'},
          [Component.text('Click a conversation to read its message thread — read-only, audited.')],
        ),
        div(
          attributes: {
            'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden;margin-bottom:18px',
          },
          _conversations.isEmpty
              ? [
                  div(attributes: {'style': 'padding:14px;font-size:12.5px;color:${AdminColors.faint}'}, [
                    Component.text('No conversations found for this workspace.'),
                  ]),
                ]
              : [
                  for (final c in _conversations) ..._conversationRow(c),
                ],
        ),
      ];

  List<Component> _conversationRow(Conversation c) {
    final expanded = _expandedConversationId == c.id;
    return [
      div(
        events: {'click': (_) => _toggleConversation(c)},
        attributes: {
          'style': 'padding:9px 14px;border-bottom:1px solid ${AdminColors.rowBorder};'
              'font-size:12.5px;color:${AdminColors.text};display:flex;justify-content:space-between;'
              'cursor:pointer;background:${expanded ? AdminColors.sidebarItemActiveBg : 'transparent'}',
        },
        [
          Component.text('${expanded ? '▾' : '▸'} #${c.id} · customer ${c.customerId ?? "-"}'),
          span([Component.text(c.status)], attributes: {'style': 'color:${AdminColors.muted}'}),
        ],
      ),
      if (expanded) _threadPanel(),
    ];
  }

  Component _threadPanel() => div(
        attributes: {
          'style': 'padding:12px 14px;border-bottom:1px solid ${AdminColors.rowBorder};'
              'background:${AdminColors.bg}',
        },
        [
          if (_messagesLoading) div([Component.text('Loading thread…')], attributes: {'style': 'color:${AdminColors.muted};font-size:12px'}),
          if (_threadError != null)
            div(attributes: {'style': 'color:${AdminColors.danger};font-size:12px'}, [Component.text(_threadError!)]),
          if (!_messagesLoading && _threadError == null && _threadMessages.isEmpty)
            div([Component.text('No messages in this conversation.')], attributes: {'style': 'color:${AdminColors.faint};font-size:12px'}),
          if (!_messagesLoading && _threadError == null && _threadMessages.isNotEmpty)
            div(
              attributes: {'style': 'display:flex;flex-direction:column;gap:6px;max-height:340px;overflow-y:auto'},
              [for (final m in _threadMessages) _messageRow(m)],
            ),
        ],
      );

  Component _messageRow(Message m) {
    final fromCustomer = m.direction == 'inbound';
    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;gap:2px;padding:7px 10px;border-radius:6px;'
            'max-width:80%;align-self:${fromCustomer ? 'flex-start' : 'flex-end'};'
            'background:${fromCustomer ? AdminColors.card : AdminColors.sidebarItemActiveBg}',
      },
      [
        div(
          attributes: {'style': 'font-size:10px;color:${AdminColors.faint}'},
          [Component.text('${fromCustomer ? "Customer" : "Bot"} · ${m.senderType} · ${m.createdAt}')],
        ),
        div(
          attributes: {'style': 'font-size:12.5px;color:${AdminColors.text};white-space:pre-wrap'},
          [Component.text(m.body.isEmpty ? '(no text — media or empty body)' : m.body)],
        ),
      ],
    );
  }

  List<Component> _errandsSection() => [
        div(
          attributes: {'style': 'font-size:13px;font-weight:700;color:${AdminColors.heading};margin:18px 0 8px'},
          [Component.text('Bot configuration — errands (${_errands.length})')],
        ),
        div(
          attributes: {'style': 'font-size:11.5px;color:${AdminColors.faint};margin:-4px 0 8px'},
          [Component.text('Read-only: what this workspace\'s bot is configured to do.')],
        ),
        div(
          attributes: {
            'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden',
          },
          _errands.isEmpty
              ? [
                  div(attributes: {'style': 'padding:14px;font-size:12.5px;color:${AdminColors.faint}'}, [
                    Component.text('No errands configured for this workspace.'),
                  ]),
                ]
              : [
                  for (final e in _errands)
                    div(
                      attributes: {
                        'style': 'padding:9px 14px;border-bottom:1px solid ${AdminColors.rowBorder};'
                            'font-size:12.5px;color:${AdminColors.text};display:flex;justify-content:space-between;'
                            'gap:12px;align-items:baseline',
                      },
                      [
                        span([Component.text(e.name)], attributes: {'style': 'flex:1'}),
                        span([Component.text(e.status)], attributes: {'style': 'color:${AdminColors.muted};flex:none'}),
                        span([Component.text(e.source)], attributes: {'style': 'color:${AdminColors.faint};flex:none'}),
                      ],
                    ),
                ],
        ),
      ];

  List<Component> _failedDocsSection() => [
        div(
          attributes: {'style': 'font-size:13px;font-weight:700;color:${AdminColors.heading};margin:18px 0 8px'},
          [Component.text('Failed knowledge documents (${_failedDocs.length})')],
        ),
        div(
          attributes: {
            'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden',
          },
          _failedDocs.isEmpty
              ? [
                  div(attributes: {'style': 'padding:14px;font-size:12.5px;color:${AdminColors.faint}'}, [
                    Component.text('None — nothing failed to index for this workspace.'),
                  ]),
                ]
              : [
                  for (final d in _failedDocs)
                    div(
                      attributes: {
                        'style': 'padding:9px 14px;border-bottom:1px solid ${AdminColors.rowBorder};'
                            'font-size:12.5px;display:flex;justify-content:space-between;align-items:center',
                      },
                      [
                        span([Component.text('${d.title} — ${d.errorMessage ?? "no error message stored"}')],
                            attributes: {'style': 'color:${AdminColors.text}'}),
                        button(
                          [Component.text(_busy ? '…' : 'Re-index')],
                          events: {'click': (_) => _busy ? null : _reindex(d)},
                          attributes: {
                            'style': 'padding:5px 10px;border-radius:6px;border:1px solid ${AdminColors.border};'
                                "background:transparent;color:${AdminColors.accent};font-size:11.5px;cursor:pointer",
                          },
                        ),
                      ],
                    ),
                ],
        ),
      ];
}
