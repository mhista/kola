// tasks_page.dart — Phase 13b. `/tasks`, the third of the previously-404ing
// sidebar routes (see observations_page.dart's header for the shared
// backstory: nav_model.dart always pointed here correctly, app.dart never
// registered the route, no page file existed, and — unlike 13a — no
// backend existed either).
//
// Built against Kola Tasks.dc.html (state extracted before writing any
// Dart, per DESIGN_DELTA.md's method): a 3-column kanban board (To do /
// In progress / Done), each card showing title, source (which subsystem
// generated it), a due label, a priority-colored left border, an
// assignee initial, and an "Overdue" pill when applicable. The export's
// `view: 'populated'|'empty'` toggle is a design-tool preview control,
// not a real feature — handled here as an ordinary empty state per
// column, same treatment 13a gave Observations/Recommendations.
//
// ── WHAT'S NEW HERE, VS. 13A: A REAL BACKEND HAD TO BE BUILT ──────────
//
// Unlike Observations/Recommendations (which reused FindingEndpoint
// unchanged), Tasks needed a new model, migration, repository and
// endpoint — see task.spy.yaml's header for the two named
// simplifications (assignee is free text, not a member link;
// sourceType is a label, not a strict polymorphic reference).
//
// ── ONE SMALL ADDITION ON TOP OF THE EXPORT: "+ Add task" ─────────────
//
// The export shows no way to add a card — every sample task is
// pre-populated. A board nobody can add to defeats its own purpose, so
// this page adds a minimal inline "+ Add task" affordance (title only,
// defaults to 'todo'/'medium', no source). This is an addition, not a
// subtraction — see task_endpoint.dart's own header on the same point.
//
// ── OVERDUE IS COMPUTED HERE, NOT STORED ───────────────────────────────
//
// Same choice task.spy.yaml's header explains server-side: `overdue` is
// derived at render time from `dueAt` vs `DateTime.now()`, never a
// stored column, so it can never go stale between reads.
//
// ── DRAG-AND-DROP IS OUT OF SCOPE FOR THIS PASS ────────────────────────
//
// The export's board is presentational — no drag interaction is
// specified in its script. Moving a card between columns here uses a
// small "Move to…" control instead of drag-and-drop, calling the same
// TaskEndpoint.setStatus a future drag implementation would call. Named
// here rather than silently omitted.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../theme.dart';

class TasksPage extends StatefulComponent {
  const TasksPage({
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
  State<TasksPage> createState() => _TasksPageState();
}

class _Col {
  const _Col(this.status, this.label);
  final String status;
  final String label;
}

const _columns = [
  _Col('todo', 'To do'),
  _Col('in_progress', 'In progress'),
  _Col('done', 'Done'),
];

const _priorityColor = {
  'high': KolaVar.danger,
  'medium': KolaVar.warning,
  'low': KolaVar.success,
};

const _priorityLabel = {
  'high': 'High',
  'medium': 'Medium',
  'low': 'Low',
};

const _sourceLabel = {
  'recommendation': 'Recommendations',
  'observation': 'Observations',
  'operation': 'Operations',
};

class _TasksPageState extends State<TasksPage> {
  bool _loading = true;
  String? _error;
  List<Task> _tasks = const [];
  Set<int> _busy = const {};
  bool _addingOpen = false;
  String _newTitle = '';
  bool _creating = false;

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
    try {
      final tasks = await component.client.task.list(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  Future<void> _move(Task t, String status) async {
    final id = t.id;
    if (id == null) return;
    setState(() => _busy = {..._busy, id});
    try {
      final updated = await component.client.task.setStatus(
        component.accessToken,
        component.workspaceId,
        id,
        status,
      );
      if (!mounted) return;
      setState(() {
        _tasks = [for (final x in _tasks) if (x.id == id) updated else x];
        _busy = {..._busy}..remove(id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = {..._busy}..remove(id));
    }
  }

  Future<void> _create() async {
    final title = _newTitle.trim();
    if (title.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      final created = await component.client.task.create(
        component.accessToken,
        component.workspaceId,
        title,
      );
      if (!mounted) return;
      setState(() {
        _tasks = [created, ..._tasks];
        _newTitle = '';
        _addingOpen = false;
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

  bool _isOverdue(Task t) {
    if (t.status == 'done') return false;
    final due = t.dueAt;
    if (due == null) return false;
    return due.isBefore(DateTime.now());
  }

  String _dueLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff == -1) return 'yesterday';
    if (diff > 1) return 'in $diff days';
    return '${-diff} days ago';
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:1180px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        _header(),
        if (_error != null) _errorBanner(),
        if (_loading) _skeleton() else _board(),
      ],
    );
  }

  Component _header() => div(
        attributes: {
          'style': 'display:flex;align-items:flex-start;'
              'justify-content:space-between;gap:12px;'
              'margin-bottom:${KolaSpace.lg};flex-wrap:wrap',
        },
        [
          div(
            [],
            [
              h1(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};'
                      'font-size:${KolaType.h2};font-weight:700;'
                      'color:${KolaVar.text};margin:0 0 4px',
                },
                [Component.text('Tasks')],
              ),
              div(
                attributes: {
                  'style':
                      'font-size:${KolaType.small};color:${KolaVar.muted}',
                },
                [
                  Component.text(
                    'Things a recommendation, escalation, or observation turned into a real commitment.',
                  ),
                ],
              ),
            ],
          ),
          _addButton(),
        ],
      );

  Component _addButton() {
    if (_addingOpen) {
      return div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:8px',
        },
        [
          input<String>(
            type: InputType.text,
            attributes: {
              'placeholder': 'Task title…',
              'style': 'padding:8px 12px;border-radius:${KolaRadius.sm};'
                  'border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.bg};color:${KolaVar.text};'
                  'font-size:${KolaType.small};font-family:inherit;'
                  'min-width:220px',
            },
            value: _newTitle,
            onInput: (v) => setState(() => _newTitle = v),
          ),
          button(
            attributes: {
              'type': 'button',
              if (_creating) 'disabled': '',
              'style': 'background:${KolaVar.accent};border:none;'
                  'color:${KolaVar.accentText};'
                  'border-radius:${KolaRadius.sm};padding:8px 14px;'
                  'font-size:${KolaType.small};font-family:inherit;'
                  'font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => _create()},
            [Component.text(_creating ? 'Adding…' : 'Add')],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'background:transparent;'
                  'border:1px solid ${KolaVar.border};'
                  'color:${KolaVar.mutedStrong};'
                  'border-radius:${KolaRadius.sm};padding:8px 14px;'
                  'font-size:${KolaType.small};font-family:inherit;'
                  'cursor:pointer',
            },
            events: {
              'click': (_) => setState(() {
                    _addingOpen = false;
                    _newTitle = '';
                  }),
            },
            [Component.text('Cancel')],
          ),
        ],
      );
    }
    return button(
      attributes: {
        'type': 'button',
        'style': 'background:${KolaVar.accent};border:none;'
            'color:${KolaVar.accentText};border-radius:${KolaRadius.sm};'
            'padding:9px 16px;font-size:${KolaType.small};'
            'font-family:inherit;font-weight:600;cursor:pointer',
      },
      events: {'click': (_) => setState(() => _addingOpen = true)},
      [Component.text('+ Add task')],
    );
  }

  Component _errorBanner() => div(
        attributes: {
          'style': 'background:${KolaVar.dangerBg};'
              'border:1px solid ${KolaVar.danger};'
              'border-radius:${KolaRadius.md};padding:${KolaSpace.sm};'
              'color:${KolaVar.danger};font-size:${KolaType.small};'
              'margin-bottom:${KolaSpace.md}',
        },
        [Component.text(_error!)],
      );

  Component _skeleton() => div(
        attributes: {
          'style': 'display:grid;'
              'grid-template-columns:repeat(3,1fr);gap:${KolaSpace.lg}',
        },
        [
          for (var i = 0; i < 3; i++)
            div(
              attributes: {
                'style': 'height:260px;border-radius:${KolaRadius.lg};'
                    'background:${KolaVar.card};'
                    'border:1px solid ${KolaVar.border};opacity:0.6',
              },
              [],
            ),
        ],
      );

  Component _board() => div(
        attributes: {
          'style': 'display:grid;'
              'grid-template-columns:repeat(3,minmax(240px,1fr));'
              'gap:${KolaSpace.lg};overflow-x:auto',
        },
        [for (final col in _columns) _column(col)],
      );

  Component _column(_Col col) {
    final items = [for (final t in _tasks) if (t.status == col.status) t];
    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;gap:${KolaSpace.sm};'
            'min-width:0',
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};font-weight:700;'
                'color:${KolaVar.mutedStrong};padding:0 2px;'
                'display:flex;align-items:center;gap:6px',
          },
          [
            Component.text(col.label),
            span(
              attributes: {
                'style': 'font-weight:400;color:${KolaVar.muted}',
              },
              [Component.text('— ${items.length}')],
            ),
          ],
        ),
        if (items.isEmpty)
          div(
            attributes: {
              'style': 'border:1px dashed ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};padding:24px 12px;'
                  'text-align:center;color:${KolaVar.muted};'
                  'font-size:${KolaType.small}',
            },
            [Component.text('Nothing here right now')],
          )
        else
          for (final t in items) _card(t, col.status),
      ],
    );
  }

  Component _card(Task t, String currentStatus) {
    final id = t.id;
    final busy = id != null && _busy.contains(id);
    final overdue = _isOverdue(t);
    final done = t.status == 'done';
    final priorityColor = _priorityColor[t.priority] ?? KolaVar.muted;
    final source = t.sourceType == null ? null : _sourceLabel[t.sourceType];

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};'
            'border:1px solid ${overdue ? '#3A2622' : KolaVar.border};'
            'border-left:3px solid $priorityColor;'
            'border-radius:${KolaRadius.md};padding:12px 14px;'
            'opacity:${busy ? '0.5' : '1'}',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:flex-start;'
                'justify-content:space-between;gap:8px',
          },
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};font-weight:600;'
                    'color:${done ? KolaVar.muted : KolaVar.text};'
                    'text-decoration:${done ? 'line-through' : 'none'};'
                    'line-height:1.4',
              },
              [Component.text(t.title)],
            ),
            if (t.assignee != null && t.assignee!.isNotEmpty)
              span(
                attributes: {
                  'title': t.assignee!,
                  'style': 'width:22px;height:22px;flex-shrink:0;'
                      'border-radius:${KolaRadius.circle};'
                      'background:${KolaVar.pill};display:flex;'
                      'align-items:center;justify-content:center;'
                      'font-size:${KolaType.tiny};font-weight:700;'
                      'color:${KolaVar.mutedStrong}',
                },
                [Component.text(t.assignee!.substring(0, 1).toUpperCase())],
              ),
          ],
        ),
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:6px;'
                'margin-top:6px;font-size:${KolaType.tiny};'
                'color:${KolaVar.muted}',
          },
          [
            if (source != null) Component.text(source),
            if (source != null && t.dueAt != null) Component.text(' · '),
            if (t.dueAt != null)
              span(
                attributes: {
                  'style': overdue
                      ? 'color:${KolaVar.danger};font-weight:700'
                      : '',
                },
                [Component.text('due ${_dueLabel(t.dueAt!)}')],
              ),
          ],
        ),
        if (overdue)
          div(
            attributes: {
              'style': 'display:inline-block;margin-top:8px;'
                  'background:${KolaVar.dangerBg};color:${KolaVar.danger};'
                  'font-size:${KolaType.tiny};font-weight:700;'
                  'border-radius:${KolaRadius.pill};padding:2px 8px',
            },
            [Component.text('Overdue')],
          ),
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:6px;'
                'margin-top:10px',
          },
          [
            span(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:$priorityColor',
              },
              [Component.text(_priorityLabel[t.priority] ?? t.priority)],
            ),
            div(attributes: {'style': 'flex:1'}, []),
            for (final col in _columns)
              if (col.status != currentStatus)
                button(
                  attributes: {
                    'type': 'button',
                    if (busy || id == null) 'disabled': '',
                    'style': 'background:transparent;'
                        'border:1px solid ${KolaVar.border};'
                        'color:${KolaVar.mutedStrong};'
                        'border-radius:${KolaRadius.sm};padding:3px 8px;'
                        'font-size:${KolaType.tiny};font-family:inherit;'
                        'cursor:${busy ? 'default' : 'pointer'}',
                  },
                  events: {
                    'click': (_) {
                      if (!busy) _move(t, col.status);
                    },
                  },
                  [Component.text('→ ${col.label}')],
                ),
          ],
        ),
      ],
    );
  }
}
