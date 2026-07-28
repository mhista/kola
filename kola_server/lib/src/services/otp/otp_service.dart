// otp_service.dart
//
// Phase 8b's last "templated Errand library" sub-feature: OTP delivery.
// Explicit instruction: use email (not SMS — that still waits on the
// sms_owner_notifier.dart provider decision), following the exact same
// SmtpServer/Message/send() technique email_owner_notifier.dart already
// proved against asami_server's own email_notification_service.dart.
//
// NOT A COPY OF ASAMI'S LIVE CREDENTIALS, ON PURPOSE: asami_server's SMTP
// host/user/password live in its own config/passwords.yaml as plaintext
// (a real Gmail address + app password) — copying those literal values
// into this project would leak asami's credentials into a second
// codebase, exactly the class of mistake task #84 already caught and
// fixed once for this project's own .env.example. What's actually reused
// is the PATTERN (SmtpServer(...ssl:true) + Message()/Address() + plain
// mailer.send()) and, in kola_server specifically, infrastructure that
// already existed before this file: Env.smtp{Host,Port,User,Password,
// FromEmail,FromName} (see env.dart, .env.example) — set your OWN SMTP
// credentials there, never asami's.
//
// PARAMETERS MIRROR asami_server/lib/src/services/auth/auth_service.dart,
// VERIFIED BY READING THAT FILE DIRECTLY, NOT GUESSED: 6-digit numeric
// code via Random.secure(), 10-minute expiry, 5 wrong-guess cap, 60-
// second resend cooldown. The one structural difference: asami stores
// these fields directly on its User model (verifying an account); Kola
// has no such account to attach fields to on the customer side, so this
// writes/reads its own OtpCode table, one row per issued code, keyed by
// conversationId — see otp_code.spy.yaml's header.
//
// CALLED FROM BuiltinErrandExecutor's 'sendOtp'/'verifyOtp' handlers,
// NOT DIRECTLY BY ANY ENDPOINT: like 'collectPayment'/'createSupportTicket'
// before it, this is a capability the AI tool-calling engine invokes
// mid-conversation once a business registers an Errand for it — there's
// no dashboard "send an OTP" button, by design, same as every other
// built-in handler.

import 'dart:math';

import 'package:mailer/mailer.dart';
// Imported a second time, prefixed, ONLY to call mailer's top-level
// send() unambiguously — this class also defines a method named `send`,
// which would otherwise shadow it. Same fix, same reason, as
// email_owner_notifier.dart's own header explains (caught there via a
// real `dart analyze` error).
import 'package:mailer/mailer.dart' as mailer_lib;
import 'package:mailer/smtp_server.dart';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/generated/protocol.dart' hide Message, Address;
import 'package:kola_server/src/services/repository/otp_code_repository.dart';

class OtpService {
  OtpService({required OtpCodeRepository otpCodes}) : _otpCodes = otpCodes;

  final OtpCodeRepository _otpCodes;

  static const _codeExpiry = Duration(minutes: 10);
  static const _resendCooldown = Duration(seconds: 60);
  static const _maxAttempts = 5;

  bool get _smtpConfigured =>
      Env.smtpHost.isNotEmpty && Env.smtpUser.isNotEmpty && Env.smtpPassword.isNotEmpty;

  /// Generates a fresh 6-digit code, emails it to [recipientEmail], and
  /// persists it — unless [conversationId] already has a code issued in
  /// the last 60 seconds, in which case this declines rather than
  /// spamming a fresh code (or a fresh email) on every retry.
  Future<OtpSendResult> send({
    required int workspaceId,
    required int conversationId,
    required String recipientEmail,
  }) async {
    if (!_smtpConfigured) {
      // A business that hasn't set SMTP credentials in .env yet is a
      // configuration gap, not a customer-facing failure to hide — same
      // "honest about what's actually missing" posture as
      // collectPayment's own InvalidPaymentGatewayCredentialException
      // handling in builtin_errand_executor.dart.
      Log.warning('OtpService.send: SMTP not configured, cannot send OTP email');
      return const OtpSendResult(
        sent: false,
        replyToCustomer:
            "Sorry, this business hasn't set up email verification yet — please ask them directly.",
      );
    }

    final existing = await _otpCodes.findLatestForConversation(conversationId, workspaceId);
    if (existing != null) {
      final elapsedSinceIssue = DateTime.now().toUtc().difference(existing.createdAt);
      if (elapsedSinceIssue < _resendCooldown) {
        final waitSeconds = (_resendCooldown - elapsedSinceIssue).inSeconds;
        return OtpSendResult(
          sent: false,
          replyToCustomer: 'Please wait about $waitSeconds more second${waitSeconds == 1 ? '' : 's'} before I can send another code.',
        );
      }
    }

    final code = _generateCode();
    final expiresAt = DateTime.now().toUtc().add(_codeExpiry);

    final smtpServer = SmtpServer(
      Env.smtpHost,
      port: int.tryParse(Env.smtpPort) ?? 587,
      username: Env.smtpUser,
      password: Env.smtpPassword,
      ssl: true,
    );
    final fromEmail = Env.smtpFromEmail.isNotEmpty ? Env.smtpFromEmail : Env.smtpUser;

    final message = Message()
      ..from = Address(fromEmail, Env.smtpFromName)
      ..recipients.add(recipientEmail)
      ..subject = 'Your verification code'
      ..text = 'Your verification code is $code. It expires in 10 minutes.';

    try {
      await mailer_lib.send(message, smtpServer);
    } catch (e) {
      Log.error('OtpService.send: failed to send OTP email', error: e);
      return const OtpSendResult(
        sent: false,
        replyToCustomer: "Sorry, I couldn't send that code right now — please try again in a moment.",
      );
    }

    // Persisted AFTER the email actually sends — a failed send should
    // never leave behind a row claiming a code the customer never
    // received (which would also wrongly start their 60-second resend
    // cooldown).
    await _otpCodes.create(
      workspaceId: workspaceId,
      conversationId: conversationId,
      recipientEmail: recipientEmail,
      code: code,
      expiresAt: expiresAt,
    );

    Log.info('OtpService.send: sent OTP to $recipientEmail (conversationId=$conversationId)');
    return const OtpSendResult(
      sent: true,
      replyToCustomer: "We've sent a verification code to your email — it expires in 10 minutes.",
    );
  }

  /// Checks [suppliedCode] against the most recently issued code for
  /// [conversationId] — expiry and the 5-attempt cap are both enforced
  /// here, matching asami_server's own auth_service.dart parameters.
  Future<OtpVerifyResult> verify({
    required int workspaceId,
    required int conversationId,
    required String suppliedCode,
  }) async {
    final existing = await _otpCodes.findLatestForConversation(conversationId, workspaceId);
    if (existing == null) {
      return const OtpVerifyResult(
        verified: false,
        replyToCustomer: "I don't have a code on file for you yet — ask for one first.",
      );
    }
    if (existing.verifiedAt != null) {
      return const OtpVerifyResult(verified: true, replyToCustomer: "You're already verified.");
    }
    if (DateTime.now().toUtc().isAfter(existing.expiresAt)) {
      return const OtpVerifyResult(
        verified: false,
        replyToCustomer: 'That code has expired — ask for a new one.',
      );
    }
    if (existing.attempts >= _maxAttempts) {
      return const OtpVerifyResult(
        verified: false,
        replyToCustomer: 'Too many incorrect attempts on that code — ask for a new one.',
      );
    }

    if (suppliedCode.trim() != existing.code) {
      await _otpCodes.incrementAttempts(existing.id!, existing.attempts);
      final remaining = _maxAttempts - (existing.attempts + 1);
      Log.info('OtpService.verify: incorrect code (conversationId=$conversationId, remaining=$remaining)');
      return OtpVerifyResult(
        verified: false,
        replyToCustomer: remaining > 0
            ? "That code doesn't look right — $remaining attempt${remaining == 1 ? '' : 's'} left before you'll need a new one."
            : 'Too many incorrect attempts on that code — ask for a new one.',
      );
    }

    await _otpCodes.markVerified(existing.id!);
    Log.info('OtpService.verify: verified (conversationId=$conversationId)');
    return const OtpVerifyResult(verified: true, replyToCustomer: "You're verified — thanks!");
  }

  String _generateCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }
}

class OtpSendResult {
  const OtpSendResult({required this.sent, required this.replyToCustomer});
  final bool sent;
  final String replyToCustomer;
}

class OtpVerifyResult {
  const OtpVerifyResult({required this.verified, required this.replyToCustomer});
  final bool verified;
  final String replyToCustomer;
}
