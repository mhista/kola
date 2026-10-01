// tasks_timeline_page.dart — '/tasks-timeline'.
//
// Documents TaskEndpoint and EventEndpoint — previously undocumented
// entirely. Confirmed directly against both endpoints' source,
// including event_endpoint.dart's own honest count: nine real event
// types have an actual emit() call site in this codebase, two design-
// named categories (Inventory, Knowledge) have zero and return an
// empty list rather than a fabricated entry.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class TasksTimelinePage extends StatelessComponent {
  const TasksTimelinePage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Tasks & Timeline'),
      docLede(
        'Two lightweight tracking surfaces: a kanban task board, and a read-only feed over '
        "kolaa's own event bus for a human to scan what happened recently.",
      ),

      docH2('Tasks'),
      docP(
        'A task can come from a human creating one by hand, or from another subsystem — '
        'sourceType is one of recommendation, observation, or operation when a task was '
        'generated rather than typed, with sourceFindingId pointing back at the finding that '
        'produced it.',
      ),
      const CodeBlock(
        title: 'TaskEndpoint',
        dart:
            "final tasks = await client.task.list(accessToken, workspaceId);\n"
            "final task = await client.task.create(\n"
            "  accessToken, workspaceId, \"Call supplier about late delivery\",\n"
            "  priority: \"high\", // high | medium | low\n"
            "  dueAt: DateTime.now().add(const Duration(days: 1)),\n"
            ");\n"
            "await client.task.setStatus(accessToken, workspaceId, task.id!, \"in_progress\");\n"
            "// status is one of: todo, in_progress, done\n"
            "await client.task.delete(accessToken, workspaceId, task.id!);",
      ),

      docH2('Timeline'),
      docP(
        'A read-only view over the same event bus that drives outbound webhooks (see '
        'Webhooks) — newest first, optionally filtered to one category.',
      ),
      const CodeBlock(
        title: 'EventEndpoint.listTimeline',
        dart:
            "final recent = await client.event.listTimeline(accessToken, workspaceId, limit: 100);\n"
            "final payments = await client.event.listTimeline(\n"
            "  accessToken, workspaceId,\n"
            '  category: "Payments",\n'
            ");",
      ),
      docP('Categories map from real event types as follows:'),
      docList([
        'Payments — sale_completed, payment_confirmed',
        'Conversations — new_conversation, message_sent',
        'Integrations — agent_drafted, agent_published, agent_paused',
        'Operations — errand_executed',
        'Customers — errand_rows_mapped_to_customers',
      ]),
      docWarning(
        'Inventory and Knowledge are offered as filter categories but currently return an '
        'empty list always — no code path in this codebase emits an event when stock changes '
        'or a document is taught. Not simulated with a plausible-looking entry; an unmatched '
        'category is the honest state for now.',
      ),
      docNote(
        'An unrecognized or empty category returns an empty list rather than throwing — the '
        "same posture as a workspace with genuinely nothing in a category yet.",
      ),
    ]);
  }
}
