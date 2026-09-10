// invoice_payment_reminder_sweep_service.dart
//
// Phase 14L — the owner's own words, verbatim: "for the errands, it
// should not have a page of its own, thus it should auto fire." One of
// the owner's own named examples was "auto-generating payment links."
// This is the real implementation of that: a daily sweep that finds
// overdue invoices and, where the invoice's customer can actually be
// reached, sends a payment reminder — no owner action required. Same
// "sweep + act, wired into server.dart on a plain Timer" shape as
// customer_campaign_sweep_service.dart (the closest precedent, copied
// closely below) / trial_sweep_service.dart / support_ticket_sla_sweep_
// service.dart.
//
// ── WHY A REMINDER, NOT A NEW GATEWAY CHECKOUT LINK ───────────────────
//
// The obvious literal reading of "auto-generate a payment link" is
// BuiltinErrandExecutor._collectPayment — but that handler HARD-REQUIRES
// input['customerEmail'] (see that file) because PaymentCheckoutService.
// initializeCheckout needs one to hand to the gateway. Checked directly:
// Customer (customer.spy.yaml) has no email field at all, and Invoice
// (invoice.spy.yaml) doesn't either — only billToName/billToAddress/
// billToPhone. The existing "Pay now" button on the invoice UI works
// today because a human is there, at click time, to supply/confirm one;
// a scheduled background sweep has no such moment and no such data.
// Fabricating an email, or silently skipping validation, is exactly what
// this codebase's standing rule (DESIGN_DELTA.md: prefer an honest "not
// enough data" state over guessing) forbids.
//
// What IS real and reachable without inventing anything: Invoice.
// customerId points at Customer (Gate 3's identity anchor), and
// inbound_message_handler.dart already sets Conversation.customerId for
// every WhatsApp/Telegram conversation the moment identity resolves
// (Gate 3 — see that file around its "Gate 3 — resolve/create the
// Customer" comment). ConversationRepository.listByCustomer already
// exists (Gate 3b, "every conversation on a customer's unified
// timeline") and returns conversations newest-first. So: a REAL payment
// REMINDER — invoice reference, outstanding amount, due date, and the
// business's own paymentInstructions free-text field — sent over
// whichever channel that customer actually has a conversation on. Not a
// fresh checkout link (no email to build one from), but not nothing
// either: a genuine, unprompted nudge that references this business's
// own real data throughout.
//
// ── NOT EVERY OVERDUE INVOICE HAS A CUSTOMER TO MESSAGE ───────────────
//
// Plenty of invoices are created standalone from Documents (billToName/
// billToPhone typed in by hand, customerId null) or from a till sale
// rung up for a walk-in who never messaged the bot. Those invoices
// cannot honestly get an automatic reminder — there is no channel. They
// are NOT silently dropped: WorkspaceSweepService._detectInvoices
// (workspace_sweep_service.dart, FindingKinds.invoiceOverdue) surfaces
// exactly this case as a finding, so the owner sees "this one needs you
// to follow up yourself" instead of the invoice quietly going stale.
// Invoices this sweep DOES successfully remind are deliberately NOT also
// raised as a finding — they are handled, and a finding for a handled
// invoice would just be noise duplicating what already happened.
//
// ── WHATSAPP TEMPLATE PARAMS ARE INTENTIONALLY MINIMAL ─────────────────
//
// Same Meta Cloud API restriction customer_campaign_sweep_service.dart
// already documents: a business-initiated WhatsApp message needs a
// pre-approved template, get-or-create per channel exactly like that
// service. The template body here carries three parameters — invoice
// reference, outstanding amount, due date — NOT the workspace's free-
// text paymentInstructions. That field is owner-authored and arbitrary
// length/content; bolting arbitrary business copy onto an approved
// template as a "parameter" each send is the kind of thing that risks
// the template itself reading as a policy violation at review time.
// Telegram has no such restriction (free text, no template, no review),
// so ITS message includes paymentInstructions in full — the fuller,
// more useful message where the channel actually allows it.
//
// GENERIC MESSAGE TEXT — same v1 posture as the birthday sweep: not
// per-workspace customizable yet. A real "compose your own reminder"
// setting is a natural v2, not guessed at here.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/invoice_repository.dart';
import 'package:kola_server/src/services/repository/conversation_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/repository/whatsapp_message_template_repository.dart';
import 'package:kola_server/src/services/messaging/telegram/telegram_bot_registry.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_template_creation_service.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_credential.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_service.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';

class InvoicePaymentReminderSweepService {
  InvoicePaymentReminderSweepService({
    required InvoiceRepository invoices,
    required ConversationRepository conversations,
    required WorkspaceRepository workspaces,
    required ChannelRepository channels,
    required WhatsAppMessageTemplateRepository whatsAppTemplateRepo,
    required WhatsAppTemplateCreationService whatsAppTemplates,
  }) : _invoices = invoices,
       _conversations = conversations,
       _workspaces = workspaces,
       _channels = channels,
       _whatsAppTemplateRepo = whatsAppTemplateRepo,
       _whatsAppTemplates = whatsAppTemplates;

  final InvoiceRepository _invoices;
  final ConversationRepository _conversations;
  final WorkspaceRepository _workspaces;
  final ChannelRepository _channels;
  final WhatsAppMessageTemplateRepository _whatsAppTemplateRepo;
  final WhatsAppTemplateCreationService _whatsAppTemplates;

  /// An unpaid invoice does not get messaged forever — three reminders,
  /// ever, then this sweep leaves it alone (it still shows up as overdue
  /// everywhere else; only the automatic nudging stops).
  static const _maxReminders = 3;

  /// Minimum time between reminders for the same invoice. Sized to the
  /// daily sweep interval the same way the birthday sweep's "once per
  /// calendar year" dedupe is sized to ITS daily interval — a few days,
  /// not every single day, or a customer who simply hasn't paid yet gets
  /// nagged every morning.
  static const _minGap = Duration(days: 3);

  /// Checks every unpaid invoice across every workspace and reminds
  /// whichever ones are overdue, past [_minGap] since their last
  /// reminder (or never reminded), under [_maxReminders], AND have a
  /// resolvable customer channel. Per-invoice try/catch: one bad row
  /// must never stop the rest of the sweep. Returns how many reminders
  /// actually went out this run.
  Future<int> sweepOnce({DateTime? now}) async {
    final n = (now ?? DateTime.now()).toUtc();
    final unpaid = await _invoices.listUnpaid();

    var sent = 0;
    for (final invoice in unpaid) {
      try {
        if (await _maybeRemind(invoice, now: n)) sent++;
      } catch (e) {
        Log.error('InvoicePaymentReminderSweepService: failed for invoice ${invoice.id}', error: e);
      }
    }
    return sent;
  }

  Future<bool> _maybeRemind(Invoice invoice, {required DateTime now}) async {
    if (invoice.id == null) return false;
    if (invoice.dueAt == null || !invoice.dueAt!.isBefore(now)) return false; // not overdue
    if (invoice.paymentRemindersSent >= _maxReminders) return false;
    final lastSent = invoice.lastPaymentReminderSentAt;
    if (lastSent != null && now.difference(lastSent) < _minGap) return false;
    if (invoice.customerId == null) return false; // no identity to resolve a channel from

    final customerConversations = await _conversations.listByCustomer(invoice.customerId!);
    Conversation? channel;
    for (final c in customerConversations) {
      if (c.workspaceId != invoice.workspaceId) continue; // belt-and-braces; should already match
      if (c.platformType == 'whatsapp' || c.platformType == 'telegram') {
        channel = c;
        break;
      }
    }
    if (channel == null) return false; // WorkspaceSweepService._detectInvoices surfaces this instead

    final workspace = await _workspaces.findById(invoice.workspaceId);
    final businessName = (workspace?.name.isNotEmpty ?? false) ? workspace!.name : 'us';
    final outstandingMinor = invoice.totalMinor - invoice.paidMinor;

    final bool ok;
    if (channel.platformType == 'telegram') {
      ok = await _sendTelegramReminder(
        conversation: channel,
        invoice: invoice,
        businessName: businessName,
        outstandingMinor: outstandingMinor,
      );
    } else {
      ok = await _sendWhatsAppReminder(
        conversation: channel,
        invoice: invoice,
        businessName: businessName,
        outstandingMinor: outstandingMinor,
      );
    }
    if (!ok) return false;

    await _invoices.markReminderSent(
      invoice.workspaceId,
      invoice.id!,
      remindersSentNow: invoice.paymentRemindersSent + 1,
    );
    Log.info(
      'InvoicePaymentReminderSweepService: sent reminder for invoice ${invoice.id} '
      '(${channel.platformType}, reminder #${invoice.paymentRemindersSent + 1})',
    );
    return true;
  }

  Future<bool> _sendTelegramReminder({
    required Conversation conversation,
    required Invoice invoice,
    required String businessName,
    required int outstandingMinor,
  }) async {
    final adapter = TelegramBotRegistry.instance.messagingFor(conversation.channelId);
    if (adapter == null) return false;

    final message = _reminderText(
      businessName: businessName,
      invoice: invoice,
      outstandingMinor: outstandingMinor,
      includePaymentInstructions: true,
    );
    final result = await adapter.sendText(recipient: conversation.externalUserId, text: message);
    if (!result.success) {
      Log.warning(
        'InvoicePaymentReminderSweepService: Telegram send failed for conversation ${conversation.id}: ${result.errorMessage}',
      );
      return false;
    }
    return true;
  }

  /// Same get-or-create-then-send flow as CustomerCampaignSweepService.
  /// _sendWhatsAppGreeting — see this file's header for why the template
  /// carries only reference/amount/due-date, not paymentInstructions.
  Future<bool> _sendWhatsAppReminder({
    required Conversation conversation,
    required Invoice invoice,
    required String businessName,
    required int outstandingMinor,
  }) async {
    final channel = await _channels.findById(conversation.channelId);
    if (channel == null || channel.status != 'connected' || channel.encryptedCredential == null) {
      Log.info(
        'InvoicePaymentReminderSweepService: WhatsApp channel ${conversation.channelId} not connected — skipping reminder',
      );
      return false;
    }

    const label = 'payment_reminder';
    final existing = await _whatsAppTemplateRepo.listByChannel(channel.id!);
    final matches = existing.where((t) => t.metaTemplateName.startsWith(label)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    WhatsAppMessageTemplate? approved;
    for (final t in matches) {
      if (t.status == 'approved') {
        approved = t;
        break;
      }
    }

    if (approved == null) {
      if (matches.isNotEmpty) {
        Log.info(
          'InvoicePaymentReminderSweepService: ${matches.first.status} $label template already exists '
          'for channel ${channel.id} — waiting (or needs manual attention if rejected)',
        );
        return false;
      }

      try {
        final submitted = await _whatsAppTemplates.createTemplate(
          workspaceId: invoice.workspaceId,
          channelId: channel.id!,
          label: label,
          category: 'utility',
          language: 'en_US',
          bodyText: 'Hi! This is a reminder from {{1}} that invoice {{2}} for {{3}} '
              'is now overdue (was due {{4}}). Please reach out if you have already paid.',
          bodyExampleValues: [
            businessName,
            invoice.reference,
            _money(outstandingMinor, invoice.currency),
            _formatDate(invoice.dueAt!),
          ],
        );
        Log.info(
          'InvoicePaymentReminderSweepService: submitted $label template '
          '(${submitted.metaTemplateName}) for channel ${channel.id} — awaiting Meta review',
        );
      } on InvalidWhatsAppChannelException catch (e) {
        Log.warning('InvoicePaymentReminderSweepService: could not submit $label template: $e');
      }
      return false;
    }

    final credential = WhatsAppCredential.decode(
      ChannelCredentialEncryptionService.decrypt(channel.encryptedCredential!),
    );
    try {
      await WhatsAppService(
        accessToken: credential.accessToken,
        phoneNumberId: credential.phoneNumberId,
      ).sendTemplate(
        to: conversation.externalUserId,
        templateName: approved.metaTemplateName,
        language: approved.language,
        bodyParams: [
          businessName,
          invoice.reference,
          _money(outstandingMinor, invoice.currency),
          _formatDate(invoice.dueAt!),
        ],
      );
    } catch (e) {
      Log.warning('InvoicePaymentReminderSweepService: WhatsApp template send failed for conversation ${conversation.id}: $e');
      return false;
    }
    return true;
  }

  String _reminderText({
    required String businessName,
    required Invoice invoice,
    required int outstandingMinor,
    required bool includePaymentInstructions,
  }) {
    final buffer = StringBuffer(
      'Hi! This is a reminder from $businessName that invoice ${invoice.reference} '
      'for ${_money(outstandingMinor, invoice.currency)} is now overdue '
      '(was due ${_formatDate(invoice.dueAt!)}).',
    );
    if (includePaymentInstructions &&
        invoice.paymentInstructions != null &&
        invoice.paymentInstructions!.trim().isNotEmpty) {
      buffer.write(' ${invoice.paymentInstructions!.trim()}');
    }
    buffer.write(' Please reach out if you have already paid.');
    return buffer.toString();
  }

  /// Same "₦" + two-decimal convention as workspace_sweep_service.dart's
  /// own _money helper (ReportEndpoint's formatter) — kept as a separate
  /// copy rather than a shared import since both are small, private, and
  /// this file has no other dependency on that one.
  static String _money(int minor, String currency) {
    final amount = (minor / 100).toStringAsFixed(2);
    return currency == 'NGN' ? '₦$amount' : '$amount $currency';
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
