// email_owner_notifier.dart
//
// SMTP email via package:mailer — same Message()/Address()/SmtpServer()/
// send() technique already proven in asami_server's
// email_notification_service.dart (verified by reading that file
// directly), but configured from Kola's own Env.smtp* fields rather
// than session.serverpod.getPassword(), to keep one consistent
// secrets-config convention across this project instead of two.

import 'package:mailer/mailer.dart';
// Imported a second time, prefixed, ONLY to call mailer's top-level
// send() below unambiguously. Without this, the bare call `send(...)`
// inside this class's own `send()` method (required by the OwnerNotifier
// interface) resolves to `this.send(...)` instead of mailer's function —
// Dart prefers an enclosing class's own member over a top-level import
// when names collide, even though they're otherwise unrelated. Caught
// via a real `dart analyze` error ("Too many positional arguments: 0
// expected, but 2 found") rather than guessed.
import 'package:mailer/mailer.dart' as mailer_lib;
import 'package:mailer/smtp_server.dart';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/generated/protocol.dart' hide Message, Address;
import 'owner_notifier.dart';

class EmailOwnerNotifier implements OwnerNotifier {
  @override
  String get channel => 'email';

  bool get _smtpConfigured =>
      Env.smtpHost.isNotEmpty && Env.smtpUser.isNotEmpty && Env.smtpPassword.isNotEmpty;

  @override
  bool isReady(OwnerNotificationSettings settings) {
    final email = settings.ownerEmail;
    return settings.emailEnabled &&
        email != null &&
        email.trim().isNotEmpty &&
        _smtpConfigured;
  }

  @override
  Future<OwnerNotifierResult> send({
    required OwnerNotificationSettings settings,
    required String subject,
    required String body,
  }) async {
    if (!isReady(settings)) return OwnerNotifierResult.disabled;

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
      ..recipients.add(settings.ownerEmail!)
      ..subject = subject
      ..text = body;

    try {
      await mailer_lib.send(message, smtpServer);
      return const OwnerNotifierResult(sent: true);
    } catch (e) {
      Log.error('EmailOwnerNotifier failed to send: $e');
      return OwnerNotifierResult(sent: false, skipReason: e.toString());
    }
  }
}
