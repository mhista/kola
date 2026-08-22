// builtin_errand_executor.dart
//
// Phase 3b's "built-in Errand type working first (no external call)"
// (DEVELOPMENT_PLAN.md Phase 3b, SRS.md §7.2). Every built-in fulfillment
// Kola ships lives in [_handlers] below, keyed by Errand.builtinHandlerKey
// — adding a new one is adding one more registry entry, not touching any
// calling code (ErrandEndpoint, and eventually the AI orchestrator's
// tool-calling once that exists — see ai_provider.dart's header).
//
// ONE REAL HANDLER AT FIRST, DELIBERATELY (this comment is now stale
// about the count — corrected as of task #130 — but the reasoning below
// for why 'escalateToHuman' shipped first still holds): SRS.md §7.2
// lists three built-in examples ("send a message, escalate to human,
// look up a knowledge answer"). 'escalateToHuman' was the first one
// built because it's genuinely self-contained (no dependency on anything
// unbuilt) and directly matches PRD.md §6's customer-care bot
// requirement to "escalate what it can't answer." 'collectPayment'
// (task #128) and 'createSupportTicket' (task #130) followed once their
// own dependencies (a real payment gateway connection; the Conversation
// model) existed as real features. "Look up a knowledge answer" still
// deliberately isn't built as a *built-in Errand* at all — it's
// bot_knowledge_service.dart's job, called directly by the grounded-Q&A
// path today (see docs/DEVELOPMENT_PLAN.md Phase 3's "done when" bar),
// not through this executor.
//
// EVERY INVOCATION IS LOGGED, ALWAYS — success or failure — via
// ErrandExecutionLogRepository, satisfying SRS.md §7.3's "every Errand
// execution is logged" requirement unconditionally, not just on the
// happy path.
//
// TASK #128 — HANDLERS NOW RECEIVE [errand], NOT JUST [input]: added
// once 'collectPayment' needed errand.workspaceId to know which
// business's own Paystack/Flutterwave account to check against
// (PaymentCheckoutService.initializeCheckout — see that file's header
// for why an AI-orchestrated bot's context has no Session/accessToken
// to check instead). 'escalateToHuman' didn't need this and still
// ignores the parameter — a mechanical signature change, not a
// behavior change, for the one handler that already existed.
//
// TASK #130 — 'createSupportTicket' added (Phase 8b's buildable slice:
// complaint ticketing with SLA tracking). Same instance-method shape as
// 'collectPayment' — needs errand.workspaceId plus a SupportTicketRepository
// dependency, not just static logic like 'escalateToHuman'.
//
// TASK #132 — 'recordCustomerProfile' added (Phase 8b's last buildable
// slice: birthday/anniversary campaigns). Only ever WRITES a date here —
// CustomerCampaignSweepService (wired into server.dart) is what actually
// sends a greeting later, on its own daily sweep, same "capture now,
// act later" split as 'createSupportTicket'/SupportTicketSlaSweepService.
//
// PHASE 8b — 'sendOtp'/'verifyOtp' ADDED (the last of Phase 8b's three
// "templated Errand library" sub-features — OTP delivery, explicitly via
// email per instruction, mirroring asami_server's proven parameters —
// see otp_service.dart's header for the full reasoning). Both need
// errand.workspaceId (same reason 'collectPayment' does) AND
// input['conversationId'] — that second one is context-injected by
// InboundMessageHandler at dispatch time, never supplied by the AI
// itself (see errand_tool_registry.dart's header on why).

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/errand_execution_log_repository.dart';
import 'package:kola_server/src/services/billing/payment_checkout_service.dart';
import 'package:kola_server/src/services/repository/support_ticket_repository.dart';
import 'package:kola_server/src/services/repository/customer_profile_repository.dart';
import 'package:kola_server/src/services/otp/otp_service.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_template_creation_service.dart';
import 'package:kola_server/src/services/connectors/google/calendar_booking_service.dart';

typedef BuiltinErrandHandler = Future<Map<String, dynamic>> Function(
  Errand errand,
  Map<String, dynamic> input,
);

/// Thrown when an Errand's source isn't 'builtin', or its
/// builtinHandlerKey doesn't match any registered handler — lets callers
/// (ErrandEndpoint) show a clear error instead of a generic 500.
class UnknownBuiltinErrandException implements Exception {
  final String message;
  const UnknownBuiltinErrandException(this.message);

  @override
  String toString() => 'UnknownBuiltinErrandException: $message';
}

class BuiltinErrandExecutor {
  BuiltinErrandExecutor({
    required ErrandExecutionLogRepository executionLogs,
    required PaymentCheckoutService paymentCheckout,
    required SupportTicketRepository supportTickets,
    required CustomerProfileRepository customerProfiles,
    required OtpService otpService,
    required WhatsAppTemplateCreationService whatsAppTemplates,
    required CalendarBookingService calendarBookings,
  }) : _executionLogs = executionLogs,
       _paymentCheckout = paymentCheckout,
       _supportTickets = supportTickets,
       _customerProfiles = customerProfiles,
       _otp = otpService,
       _whatsAppTemplates = whatsAppTemplates,
       _calendarBookings = calendarBookings;

  final ErrandExecutionLogRepository _executionLogs;
  final PaymentCheckoutService _paymentCheckout;
  final SupportTicketRepository _supportTickets;
  final CustomerProfileRepository _customerProfiles;
  final OtpService _otp;
  final WhatsAppTemplateCreationService _whatsAppTemplates;
  final CalendarBookingService _calendarBookings;

  late final Map<String, BuiltinErrandHandler> _handlers = {
    'escalateToHuman': _escalateToHuman,
    'collectPayment': _collectPayment,
    'createSupportTicket': _createSupportTicket,
    'recordCustomerProfile': _recordCustomerProfile,
    'sendOtp': _sendOtp,
    'verifyOtp': _verifyOtp,
    'createProductListTemplate': _createProductListTemplate,
    'bookCalendarEvent': _bookCalendarEvent,
  };

  /// Every valid builtinHandlerKey today — the full technical truth of
  /// what this class can dispatch, real Errand row or synthetic. Kept as
  /// a static, hand-kept-in-sync-with-_handlers constant rather than
  /// derived from an instance's _handlers map (task #128 made _handlers
  /// instance-level, since 'collectPayment' needs this instance's own
  /// _paymentCheckout dependency) — the set of valid keys is a fixed
  /// fact about this class, not something that should need constructing
  /// an instance just to ask.
  static const Set<String> handlerKeys = {
    'escalateToHuman',
    'collectPayment',
    'createSupportTicket',
    'recordCustomerProfile',
    'sendOtp',
    'verifyOtp',
    'createProductListTemplate',
    'bookCalendarEvent',
  };

  /// Connect Gate, subphase 4b/4c — the subset of [handlerKeys] that is
  /// now available automatically once its connector is connected (see
  /// connector_capability_registry.dart), and therefore must NOT also be
  /// separately registrable as a real Errand row — doing both would give
  /// the agent two tools that do the same thing. ErrandEndpoint
  /// .createBuiltinErrand rejects these explicitly, with a message that
  /// explains why rather than just "unknown key".
  static const Set<String> connectorNativeHandlerKeys = {
    'collectPayment',
    'bookCalendarEvent',
  };

  /// [handlerKeys] minus [connectorNativeHandlerKeys] — what
  /// ErrandEndpoint.createBuiltinErrand actually validates registration
  /// attempts against.
  static const Set<String> registrableHandlerKeys = {
    'escalateToHuman',
    'createSupportTicket',
    'recordCustomerProfile',
    'sendOtp',
    'verifyOtp',
    'createProductListTemplate',
  };

  /// Runs [errand]'s built-in fulfillment with [input], logging the
  /// result (success or failure) unconditionally before returning/
  /// rethrowing. Throws [UnknownBuiltinErrandException] BEFORE calling
  /// anything or writing a log row if [errand] isn't a valid, registered
  /// built-in — that's a configuration error, not an execution outcome
  /// worth logging as one.
  Future<Map<String, dynamic>> execute({
    required Errand errand,
    required Map<String, dynamic> input,
  }) async {
    if (errand.source != 'builtin') {
      throw UnknownBuiltinErrandException(
        'Errand ${errand.id} has source "${errand.source}", not "builtin"',
      );
    }
    final key = errand.builtinHandlerKey;
    final handler = key == null ? null : _handlers[key];
    if (handler == null) {
      throw UnknownBuiltinErrandException(
        'Errand ${errand.id} has no registered built-in handler for '
        'builtinHandlerKey "$key". Known keys: ${_handlers.keys.join(', ')}',
      );
    }

    // BUG FIXED HERE (2026-08-22) — errand_execution_logs.errand_id has a
    // foreign key to errands.id. SYNTHETIC capabilities
    // (connector_capability_registry.dart's SyntheticErrandIds —
    // collectPayment = -1, bookCalendarEvent = -2) are deliberately
    // NEVER persisted to the errands table at all, so logging their
    // execution always violated that FK constraint — on success AND on
    // failure. Concretely: a synthetic execution's REAL error (e.g. a
    // missing calendar_bookings table) would be logged correctly via
    // Log.error below, and then the very next line — the attempt to
    // persist that failure to errand_execution_logs — would ITSELF throw
    // a second, unrelated FK-violation exception that overwrote the
    // first one before it ever reached the caller. A successful synthetic
    // execution had the same problem on the way out: the logExecution
    // call before `return result` would throw before the result could
    // ever be returned. Every connector-native capability call was
    // silently broken by this, independent of whether the underlying
    // action actually worked. Only real, persisted Errands (positive ids)
    // get an execution log row now; synthetic ones still get the
    // Log.error/Log.info console trail, just not a DB row that can't
    // legally exist for them.
    final isSyntheticCapability = (errand.id ?? 0) < 0;

    final stopwatch = Stopwatch()..start();
    try {
      final result = await handler(errand, input);
      stopwatch.stop();
      if (!isSyntheticCapability) {
        await _executionLogs.logExecution(
          errand: errand,
          input: input,
          result: result,
          success: true,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      }
      return result;
    } catch (e) {
      stopwatch.stop();
      Log.error('Built-in errand execution failed (errandId: ${errand.id})', error: e);
      if (!isSyntheticCapability) {
        await _executionLogs.logExecution(
          errand: errand,
          input: input,
          success: false,
          errorMessage: e.toString(),
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      }
      rethrow;
    }
  }

  /// PRD.md §6's customer-care bot requirement: "escalates what it
  /// can't answer." No external call — this is exactly what makes it the
  /// right first built-in to ship for 3b's "no external call" bar. Real
  /// human hand-off (a notification landing somewhere a business owner
  /// actually sees it — email, dashboard inbox, etc.) is a separate,
  /// not-yet-built feature; this returns the reply text the bot should
  /// send the customer, which is the part that's fully real today.
  static Future<Map<String, dynamic>> _escalateToHuman(
    Errand errand,
    Map<String, dynamic> input,
  ) async {
    final reason = input['reason'] as String? ?? 'unspecified';
    Log.info('Escalating to human: $reason');
    return {
      'replyToCustomer':
          "I've flagged this for a member of the team — they'll follow up with you soon.",
      'escalationReason': reason,
    };
  }

  /// Task #128 — lets a bot actually trigger the Phase 8a payment
  /// checkout mid-conversation (e.g. a catalog/negotiation bot, once a
  /// price is agreed) instead of that only being reachable via
  /// PaymentEndpoint's direct API surface. Deliberately an INSTANCE
  /// method, not static like [_escalateToHuman] — it needs this
  /// instance's own [_paymentCheckout] (see the constructor), which in
  /// turn needs errand.workspaceId to know which business's OWN
  /// Paystack/Flutterwave account to charge against (see
  /// payment_checkout_service.dart's header for why no Session/
  /// accessToken check happens here — this call is already running
  /// inside a specific, already-resolved workspace's bot).
  ///
  /// input required: 'gateway' ('paystack'|'flutterwave'), 'amountKobo'
  /// (int, smallest currency unit regardless of gateway), 'customerEmail'.
  /// input optional: 'customerPhone', 'holdInEscrow' (bool, see
  /// payment_transaction.spy.yaml on why this is bookkeeping only),
  /// 'metadata' (opaque, e.g. what the customer is paying for).
  Future<Map<String, dynamic>> _collectPayment(
    Errand errand,
    Map<String, dynamic> input,
  ) async {
    final gateway = input['gateway'] as String?;
    final amountKobo = input['amountKobo'] as int?;
    final customerEmail = input['customerEmail'] as String?;
    if (gateway == null || amountKobo == null || customerEmail == null) {
      throw ArgumentError(
        'collectPayment requires gateway, amountKobo, and customerEmail in input',
      );
    }

    try {
      final transaction = await _paymentCheckout.initializeCheckout(
        workspaceId: errand.workspaceId,
        gateway: gateway,
        amountKobo: amountKobo,
        customerEmail: customerEmail,
        customerPhone: input['customerPhone'] as String?,
        holdInEscrow: input['holdInEscrow'] as bool? ?? false,
        metadata: input['metadata'] as Map<String, dynamic>?,
      );
      Log.info('collectPayment initialized checkout: reference=${transaction.reference}');
      return {
        'replyToCustomer': 'Here\'s your payment link: ${transaction.checkoutUrl}',
        'transactionId': transaction.id,
        'reference': transaction.reference,
        'checkoutUrl': transaction.checkoutUrl,
      };
    } on InvalidPaymentGatewayCredentialException catch (e) {
      // A business that hasn't connected a gateway yet is a
      // configuration gap, not a customer-facing failure to hide — but
      // the customer still needs SOME reply, and "the business hasn't
      // set up payments yet" is honest without exposing internals.
      Log.warning('collectPayment failed — no gateway connected: $e');
      return {
        'replyToCustomer':
            "Sorry, this business hasn't set up online payments yet — please ask them directly.",
        'error': e.message,
      };
    }
  }

  /// Task #130 — the buildable slice of Phase 8b's "complaint ticketing
  /// with SLA tracking." Opens a SupportTicket tied to the current
  /// conversation with an SLA deadline computed from priority (see
  /// support_ticket_repository.dart) — SupportTicketSlaSweepService
  /// (wired in server.dart) notifies the owner if that deadline passes
  /// while the ticket is still open. Deliberately does NOT change the
  /// underlying Conversation's status — a ticket and an escalation are
  /// complementary, not the same action (see support_ticket.spy.yaml's
  /// header); a bot that also wants a human to take over right now
  /// should invoke 'escalateToHuman' separately.
  ///
  /// input required: 'conversationId' (int — which thread this complaint
  /// came from), 'subject', 'description'.
  /// input optional: 'priority' ('low'|'medium'|'high'|'urgent', defaults
  /// to 'medium' — matches the default a bot with no strong signal about
  /// severity should reach for).
  Future<Map<String, dynamic>> _createSupportTicket(
    Errand errand,
    Map<String, dynamic> input,
  ) async {
    final conversationId = input['conversationId'] as int?;
    final subject = input['subject'] as String?;
    final description = input['description'] as String?;
    if (conversationId == null || subject == null || description == null) {
      throw ArgumentError(
        'createSupportTicket requires conversationId, subject, and description in input',
      );
    }
    final priority = input['priority'] as String? ?? 'medium';

    final ticket = await _supportTickets.create(
      workspaceId: errand.workspaceId,
      conversationId: conversationId,
      subject: subject,
      description: description,
      priority: priority,
    );
    Log.info('createSupportTicket opened ticket ${ticket.id} (priority=$priority)');

    return {
      'replyToCustomer':
          "Thanks — I've logged this and someone will follow up with you.",
      'ticketId': ticket.id,
      'slaDeadline': ticket.slaDeadline.toIso8601String(),
    };
  }

  /// Task #132 — lets a bot save a birthday and/or anniversary date it
  /// learned mid-conversation. Purely a write: CustomerCampaignSweepService
  /// (server.dart, daily) is what actually sends anything, and only over
  /// Telegram today — see customer_profile.spy.yaml's header for why a
  /// WhatsApp customer's date is still saved but not yet actioned.
  ///
  /// input required: 'conversationId' (int). At least one of 'birthday'/
  /// 'anniversary' must be given, each an ISO-8601 date string
  /// (e.g. '1995-06-15' — year is stored but never required to be
  /// accurate; only month+day are ever matched, see the model's header).
  /// A field simply omitted from input leaves that field's previously
  /// saved value untouched (see CustomerProfileRepository.upsertPartial)
  /// — a bot that only just learned the birthday this turn doesn't
  /// accidentally erase an anniversary captured earlier.
  Future<Map<String, dynamic>> _recordCustomerProfile(
    Errand errand,
    Map<String, dynamic> input,
  ) async {
    final conversationId = input['conversationId'] as int?;
    if (conversationId == null) {
      throw ArgumentError('recordCustomerProfile requires conversationId in input');
    }

    final birthdayRaw = input['birthday'] as String?;
    final anniversaryRaw = input['anniversary'] as String?;
    if (birthdayRaw == null && anniversaryRaw == null) {
      throw ArgumentError('recordCustomerProfile requires birthday and/or anniversary in input');
    }

    final birthday = birthdayRaw == null ? null : DateTime.tryParse(birthdayRaw);
    if (birthdayRaw != null && birthday == null) {
      throw ArgumentError('recordCustomerProfile: "birthday" is not a valid ISO-8601 date: $birthdayRaw');
    }
    final anniversary = anniversaryRaw == null ? null : DateTime.tryParse(anniversaryRaw);
    if (anniversaryRaw != null && anniversary == null) {
      throw ArgumentError('recordCustomerProfile: "anniversary" is not a valid ISO-8601 date: $anniversaryRaw');
    }

    final profile = await _customerProfiles.upsertPartial(
      workspaceId: errand.workspaceId,
      conversationId: conversationId,
      birthday: birthday,
      anniversary: anniversary,
    );
    Log.info('recordCustomerProfile saved profile ${profile.id} for conversation $conversationId');

    return {
      'replyToCustomer': "Got it — thanks for sharing! We'll remember that.",
      'profileId': profile.id,
    };
  }

  /// Phase 8b — sends a 6-digit email verification code, e.g. before a
  /// bot proceeds with an order that needs a confirmed email. See
  /// otp_service.dart for the full send/expiry/cooldown logic; this
  /// handler is just the Errand-shaped wrapper around it, same role
  /// _collectPayment plays for PaymentCheckoutService.
  ///
  /// input required: 'conversationId' (int, context-injected — see
  /// errand_tool_registry.dart), 'recipientEmail' (string, AI-inferred
  /// from what the customer gave in conversation).
  Future<Map<String, dynamic>> _sendOtp(
    Errand errand,
    Map<String, dynamic> input,
  ) async {
    final conversationId = input['conversationId'] as int?;
    final recipientEmail = input['recipientEmail'] as String?;
    if (conversationId == null || recipientEmail == null) {
      throw ArgumentError('sendOtp requires conversationId and recipientEmail in input');
    }

    final result = await _otp.send(
      workspaceId: errand.workspaceId,
      conversationId: conversationId,
      recipientEmail: recipientEmail,
    );
    return {
      'replyToCustomer': result.replyToCustomer,
      'sent': result.sent,
    };
  }

  /// Phase 8b — checks a code the customer just typed against the most
  /// recently sent one for this conversation. See otp_service.dart for
  /// the expiry/attempt-cap logic.
  ///
  /// input required: 'conversationId' (int, context-injected), 'code'
  /// (string, AI-inferred from what the customer just typed).
  Future<Map<String, dynamic>> _verifyOtp(
    Errand errand,
    Map<String, dynamic> input,
  ) async {
    final conversationId = input['conversationId'] as int?;
    final code = input['code'] as String?;
    if (conversationId == null || code == null) {
      throw ArgumentError('verifyOtp requires conversationId and code in input');
    }

    final result = await _otp.verify(
      workspaceId: errand.workspaceId,
      conversationId: conversationId,
      suppliedCode: code,
    );
    return {
      'replyToCustomer': result.replyToCustomer,
      'verified': result.verified,
    };
  }

  /// Task #154 — THIS is the direct answer to "can we programmatically
  /// create a template for the user, not the user/business doing it
  /// themselves": a bot mid-conversation can decide on its own that a
  /// customer's request ("send me your product list") is best answered
  /// with a proper WhatsApp utility template instead of a plain-text
  /// reply, and submit that template to Meta itself — no dashboard visit,
  /// no business action. See whatsapp_template_creation_service.dart's
  /// header for the full reasoning and the other (manual dashboard)
  /// caller this shares logic with.
  ///
  /// input required: 'productList' (string, AI-composed from whatever the
  /// bot knows about the business's catalog/knowledge base — this handler
  /// doesn't generate that text itself, it only submits it as a template).
  /// input optional: 'customerName' (string, defaults to 'Customer').
  /// input context-injected: 'channelId' (int — which of the business's
  /// channels to submit against; see errand_tool_registry.dart's header on
  /// why this is never AI-supplied).
  Future<Map<String, dynamic>> _createProductListTemplate(
    Errand errand,
    Map<String, dynamic> input,
  ) async {
    final channelId = input['channelId'] as int?;
    final productList = input['productList'] as String?;
    if (channelId == null || productList == null || productList.trim().isEmpty) {
      throw ArgumentError(
        'createProductListTemplate requires channelId (context-injected) and productList in input',
      );
    }
    final customerName = (input['customerName'] as String?)?.trim();

    try {
      final template = await _whatsAppTemplates.createProductListTemplate(
        workspaceId: errand.workspaceId,
        channelId: channelId,
        businessLabel: 'product_list',
        customerNameExample: (customerName == null || customerName.isEmpty)
            ? 'Customer'
            : customerName,
        productListExample: productList.trim(),
      );
      Log.info(
        'createProductListTemplate submitted ${template.metaTemplateName} '
        '(status=${template.status}) for channel $channelId',
      );
      return {
        'replyToCustomer':
            "I've submitted your product list for approval — I'll send it over as soon as it's ready.",
        'templateId': template.id,
        'metaTemplateId': template.metaTemplateId,
        'status': template.status,
      };
    } on InvalidWhatsAppChannelException catch (e) {
      // Not a customer-facing bug — this channel simply isn't a
      // connected WhatsApp channel yet (e.g. the bot tried this on
      // Telegram, or WhatsApp isn't set up). Honest, not alarming.
      Log.warning('createProductListTemplate failed — invalid channel: $e');
      return {
        'replyToCustomer':
            "I can't send that as a formatted product list on this chat yet, but here's what we have: ${productList.trim()}",
        'error': e.message,
      };
    }
  }

  /// The first write-capable built-in Errand — see
  /// calendar_booking_service.dart's header for the draft-vs-immediate
  /// branch this delegates to. Deliberately does NOT decide that branch
  /// itself; a bot invoking this never knows or needs to know which mode
  /// the owner chose, it just gets back a reply that's honest about
  /// which one happened.
  ///
  /// input required: 'title' (string, AI-composed from what the customer
  /// asked for — "Haircut appointment", "Delivery for order #4"),
  /// 'startsAt', 'endsAt' (ISO-8601 datetime strings).
  /// input optional: 'description', 'attendeeName', 'attendeeEmail',
  /// 'attendeePhone' — whatever the AI has learned about who this is for.
  /// input context-injected: 'conversationId' (int, same pattern as
  /// sendOtp/verifyOtp — see errand_tool_registry.dart's header).
  Future<Map<String, dynamic>> _bookCalendarEvent(
    Errand errand,
    Map<String, dynamic> input,
  ) async {
    final title = input['title'] as String?;
    final startsAtRaw = input['startsAt'] as String?;
    final endsAtRaw = input['endsAt'] as String?;
    if (title == null || startsAtRaw == null || endsAtRaw == null) {
      throw ArgumentError('bookCalendarEvent requires title, startsAt, and endsAt in input');
    }
    final startsAt = DateTime.tryParse(startsAtRaw);
    final endsAt = DateTime.tryParse(endsAtRaw);
    if (startsAt == null || endsAt == null) {
      throw ArgumentError('bookCalendarEvent: startsAt/endsAt must be valid ISO-8601 datetimes');
    }
    if (!endsAt.isAfter(startsAt)) {
      throw ArgumentError('bookCalendarEvent: endsAt must be after startsAt');
    }

    try {
      final booking = await _calendarBookings.requestBooking(
        workspaceId: errand.workspaceId,
        conversationId: input['conversationId'] as int?,
        title: title,
        description: input['description'] as String?,
        startsAt: startsAt,
        endsAt: endsAt,
        attendeeName: input['attendeeName'] as String?,
        attendeeEmail: input['attendeeEmail'] as String?,
        attendeePhone: input['attendeePhone'] as String?,
      );

      Log.info('bookCalendarEvent: booking ${booking.id} status=${booking.status} (workspace ${errand.workspaceId})');

      final replyToCustomer = booking.status == 'booked'
          ? "You're booked — I've added it to the calendar."
          : "I've noted your requested time — the team will confirm it shortly.";

      return {
        'replyToCustomer': replyToCustomer,
        'bookingId': booking.id,
        'status': booking.status,
      };
    } on CalendarNotConnectedException catch (e) {
      // Not a customer-facing bug — this business simply hasn't
      // connected Google Calendar yet, or its connection needs
      // reconnecting. Honest, not alarming — same posture as
      // collectPayment's InvalidPaymentGatewayCredentialException catch.
      Log.warning('bookCalendarEvent failed — calendar not connected: $e');
      return {
        'replyToCustomer':
            "I can't book that directly yet — let me have the team follow up to confirm your time instead.",
        'error': e.message,
      };
    }
  }
}
