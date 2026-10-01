// conversations_support_page.dart — '/conversations-support'.
//
// Documents ConversationEndpoint, SupportTicketEndpoint,
// BroadcastEndpoint, and WhatsAppTemplateEndpoint — four related
// human-in-the-loop and messaging capabilities, previously undocumented
// entirely. Confirmed directly against all four endpoints' source.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class ConversationsSupportPage extends StatelessComponent {
  const ConversationsSupportPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Conversations & Support'),
      docLede(
        'Four related capabilities: the human-escalation inbox, support tickets a bot opened, '
        'broadcast messaging, and WhatsApp message templates for reaching a customer outside '
        'an open conversation window.',
      ),

      docH2('The escalation inbox'),
      docP(
        'When a bot hands a conversation to a human, it shows up here. Sending a reply does '
        'not change the conversation\'s status — it stays escalated until explicitly closed, '
        "since one reply doesn't necessarily resolve things.",
      ),
      const CodeBlock(
        title: 'ConversationEndpoint',
        dart:
            "final escalated = await client.conversation.listEscalated(accessToken, workspaceId);\n"
            "final thread = await client.conversation.getMessages(accessToken, workspaceId, c.id!);\n"
            "await client.conversation.sendHumanReply(\n"
            "  accessToken, workspaceId, c.id!, \"On it, checking now.\",\n"
            ");\n"
            "await client.conversation.closeConversation(accessToken, workspaceId, c.id!);\n"
            "// closing flips status back to normal — the bot resumes auto-replying if the\n"
            "// customer messages again",
      ),
      docNote(
        "sendHumanReply actually sends over the conversation's real channel (WhatsApp or "
        "Telegram) via the same adapter the bot itself uses — this is a real outbound send, "
        'not a dashboard-only note.',
      ),
      docP(
        'draftReply returns an AI-drafted reply for a human to edit before sending — it never '
        'sends anything itself, sendHumanReply is still a separate, explicit step.',
      ),
      const CodeBlock(
        title: 'ConversationEndpoint.draftReply',
        dart:
            "final draft = await client.conversation.draftReply(accessToken, workspaceId, c.id!);\n"
            "// edit draft, then call sendHumanReply with the edited text",
      ),

      docH2('Support tickets'),
      docP(
        "Tickets are only ever created by a bot, through the createSupportTicket built-in "
        "Errand — there's no manual-create method here, since a ticket with no conversation "
        'behind it doesn\'t fit this feature\'s shape. This endpoint reads and resolves.',
      ),
      const CodeBlock(
        title: 'SupportTicketEndpoint',
        dart:
            "final open = await client.supportTicket.list(accessToken, workspaceId, status: \"open\");\n"
            "await client.supportTicket.setStatus(\n"
            "  accessToken, workspaceId, ticket.id!, \"resolved\",\n"
            ");\n"
            "// status is one of: open, inProgress, resolved, closed",
      ),

      docH2('Broadcast messaging'),
      docP(
        'A rate-limited send to many recipients on WhatsApp or Telegram at once, gated on the '
        'broadcast feature flag. A broadcast is created as a draft with every recipient row '
        'pre-loaded (already-suppressed addresses dropped up front); nothing sends until it is '
        'explicitly started.',
      ),
      const CodeBlock(
        title: 'BroadcastEndpoint.createBroadcast / startBroadcast',
        dart:
            "final broadcast = await client.broadcast.createBroadcast(\n"
            "  accessToken, workspaceId,\n"
            '  "whatsapp", "We\'re restocked — come see the new arrivals!",\n'
            '  \'["2348012345678", "2348098765432"]\', // recipientsJson\n'
            "  20, // throughputPerMinute — a ceiling to stay beneath, not a target\n"
            ");\n"
            "await client.broadcast.startBroadcast(accessToken, workspaceId, broadcast.id!);",
      ),
      docList([
        'cancelBroadcast stops future sends only — "there is no recall," whatever already sent, '
            'sent.',
        'getBroadcastProgress reports queued/sending/sent/failed/skipped counts — delivered '
            'and read receipts are not tracked.',
        'listSuppressions / addSuppression / removeSuppression manage the opt-out list a '
            'broadcast checks before sending to each recipient.',
      ]),
      docWarning(
        'throughputPerMinute is a fixed, cautious default (20/minute, capped at 120) — neither '
        "WhatsApp's nor Telegram's real per-number throughput ceiling is read programmatically "
        'anywhere in this codebase yet.',
      ),

      docH2('WhatsApp message templates'),
      docP(
        'Templates are only required to message a customer with no open 24-hour service '
        'window — a bot replying to someone who just messaged never needs one. Meta reviews '
        "every submission and makes the final call on category regardless of what's requested "
        "here; utility is the default because it's materially cheaper than marketing on every "
        "market's rate card when the message is something a specific customer is owed or "
        'asked for.',
      ),
      const CodeBlock(
        title: 'WhatsAppTemplateEndpoint.createTemplate',
        dart:
            "final template = await client.whatsAppTemplate.createTemplate(\n"
            "  accessToken, workspaceId, channelId,\n"
            '  "Order ready", "utility", "en_US",\n'
            '  "Hi {{1}}, your order is ready for pickup.",\n'
            '  ["Aisha"], // bodyExampleValues, for Meta\'s reviewer only\n'
            ");\n"
            "final status = await client.whatsAppTemplate.refreshTemplateStatus(\n"
            "  accessToken, workspaceId, template.id!,\n"
            ");",
      ),
      docNote(
        'createProductListTemplate is a convenience wrapper over createTemplate for one '
        'specific case: proactively sending a customer their product list outside a window, '
        "framed as a reply to something they're owed rather than a cold pitch. "
        'listTemplatesForWorkspace lists every template submitted so far, newest first.',
      ),
    ]);
  }
}
