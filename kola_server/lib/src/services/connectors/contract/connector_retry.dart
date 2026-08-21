// connector_retry.dart — Gate 1. The shared retry/backoff + dead-letter
// wrapper. "If adapter number six is still writing its own retry
// logic, the contract is wrong" (PART III) — this is the one place that
// logic lives, so it never gets rewritten a sixth time.
//
// USED BY WHATSAPP/TELEGRAM'S OUTBOUND SENDS TODAY (see
// whatsapp_bot_registry.dart / telegram_bot_registry.dart), and meant
// for any future adapter's [ConnectorAdapter.sync] call as well —
// nothing about [run] is specific to sending a message versus pulling a
// page of records.

import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:kola_server/src/services/repository/connector_sync_log_repository.dart';

final _log = Logger('ConnectorRetry');

class ConnectorRetry {
  const ConnectorRetry._();

  /// Runs [action] with exponential backoff (attempt 1 immediate, then
  /// ~300ms, ~900ms by default) up to [maxAttempts] times. On final
  /// failure, writes ONE dead-letter row via [deadLetter] (not one per
  /// attempt — a dead-lettered send that retried three times is one
  /// failure, not three, to an owner reading the log) and rethrows the
  /// last error, so the caller's own error handling (a webhook route's
  /// catch-all, InboundMessageHandler's try/catch) still runs exactly as
  /// it did before this wrapper existed.
  ///
  /// [shouldRetry] lets a caller mark some failures as not worth
  /// retrying — PART VIII's own testing requirement: "rate-limited is
  /// retried; an invalid number is not. Retrying a permanent failure
  /// burns quota and looks like a working feature." Defaults to
  /// retrying everything, which is the safe default for a first adopter
  /// (WhatsApp/Telegram's outbound sends) that has no
  /// permanent-vs-transient classification of its own yet — callers that
  /// DO know the difference should pass a real predicate rather than
  /// this file guessing at one from an exception's runtime type.
  static Future<T> run<T>(
    Future<T> Function() action, {
    required ConnectorSyncLogRepository deadLetter,
    required int workspaceId,
    required String connectorKey,
    required String store,
    required String kind,
    int maxAttempts = 3,
    Duration baseDelay = const Duration(milliseconds: 300),
    bool Function(Object error)? shouldRetry,
  }) async {
    final retryPredicate = shouldRetry ?? (_) => true;
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        final isLastAttempt = attempt == maxAttempts;
        final retryable = retryPredicate(e);

        if (isLastAttempt || !retryable) {
          _log.warning(
            'ConnectorRetry: $connectorKey (workspace $workspaceId) failed '
            '${retryable ? "after $attempt attempt(s)" : "with a non-retryable error"}: $e',
          );
          await deadLetter.record(
            workspaceId: workspaceId,
            connectorKey: connectorKey,
            store: store,
            kind: kind,
            success: false,
            errorMessage: e.toString(),
          );
          rethrow;
        }

        // Exponential backoff with jitter: baseDelay * 3^(attempt-1),
        // +/- up to 20% so many workspaces retrying the same failing
        // provider at once don't all hammer it on the same tick.
        final rawMs = baseDelay.inMilliseconds * pow(3, attempt - 1);
        final jitter = 1 + (Random().nextDouble() * 0.4 - 0.2);
        final delay = Duration(milliseconds: (rawMs * jitter).round());
        _log.fine(
          'ConnectorRetry: $connectorKey (workspace $workspaceId) attempt '
          '$attempt/$maxAttempts failed, retrying in ${delay.inMilliseconds}ms: $e',
        );
        await Future.delayed(delay);
      }
    }

    // Unreachable — the loop above always either returns or rethrows on
    // its last iteration — but a Dart function with a return type must
    // have every path covered.
    throw lastError ?? StateError('ConnectorRetry.run: no attempts made');
  }
}
