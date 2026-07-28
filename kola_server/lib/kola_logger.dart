// kola_logger.dart
//
// Dual-destination logger for the Kola server: every call goes to both
// Talker (colored console output, useful during local dev and when reading
// container logs) and, when a Serverpod [Session] is available, into
// Serverpod's own session log (so calls show up correctly scoped to the
// request/endpoint that triggered them, e.g. in Serverpod Insights).
//
// WHY THIS EXISTS (reuse-before-rebuild):
//   This is the same dual-logging pattern already proven in Asami
//   (asami_logger.dart) and Degenbot (degen_logger.dart) — copied here
//   rather than reinvented, per the working convention "reuse before
//   rebuilding." Only the emoji/label conventions are Kola-specific.
//
// USAGE:
//   Log.info('Workspace created', data: {'workspaceId': ws.id});
//   Log.error('Supabase insert failed', error: e, stackTrace: st);
//   Log.startup('Kola server is booting up...');   // startup-only banner logs

import 'package:serverpod/serverpod.dart' hide LogLevel;
import 'package:talker/talker.dart';

/// Global Talker instance — application-wide colored console logging.
final talker = Talker(
  settings: TalkerSettings(
    useConsoleLogs: true,
    colors: {
      TalkerKey.error: AnsiPen()..red(),
      TalkerKey.warning: AnsiPen()..yellow(),
      TalkerKey.info: AnsiPen()..blue(),
      TalkerKey.debug: AnsiPen()..gray(level: 0.5),
      TalkerKey.verbose: AnsiPen()..gray(level: 0.3),
      TalkerKey.critical: AnsiPen()..magenta(),
    },
  ),
  logger: TalkerLogger(
    settings: TalkerLoggerSettings(enableColors: true, defaultTitle: 'KOLA-LOG'),
  ),
);

/// Enhanced logger with Talker + Serverpod session dual output.
class Log {
  static Session? _currentSession;

  /// Set the current session so subsequent calls without an explicit
  /// [session] argument still get logged into the right Serverpod request.
  static void setSession(Session session) {
    _currentSession = session;
  }

  /// Clear the current session (call at the end of a request/scope).
  static void clearSession() {
    _currentSession = null;
  }

  // ==================== GENERAL LOGS ====================

  static void debug(String message, {dynamic data, Session? session}) {
    final msg = data != null ? '$message\n${_formatData(data)}' : message;
    talker.debug('🐛 $msg');
    _serverpodLog('🐛 $msg', session: session, level: LogLevel.debug);
  }

  static void info(String message, {dynamic data, Session? session}) {
    final msg = data != null ? '$message\n${_formatData(data)}' : message;
    talker.info('ℹ️ $msg');
    _serverpodLog('ℹ️ $msg', session: session, level: LogLevel.info);
  }

  static void warning(String message, {dynamic data, Session? session}) {
    final msg = data != null ? '$message\n${_formatData(data)}' : message;
    talker.warning('⚠️ $msg');
    _serverpodLog('⚠️ $msg', session: session, level: LogLevel.warning);
  }

  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Session? session,
  }) {
    final errorMsg = error != null ? '$message: $error' : message;
    talker.error('❌ $errorMsg', error, stackTrace);
    _serverpodLog(
      '❌ $errorMsg',
      session: session,
      level: LogLevel.error,
      stackTrace: stackTrace,
    );
  }

  static void success(String message, {dynamic data, Session? session}) {
    final msg = data != null ? '$message\n${_formatData(data)}' : message;
    talker.info('✅ $msg');
    _serverpodLog('✅ $msg', session: session, level: LogLevel.info);
  }

  static void critical(String message, {dynamic error, Session? session}) {
    final msg = error != null ? '$message: $error' : message;
    talker.critical('🔴 $msg');
    _serverpodLog('🔴 $msg', session: session, level: LogLevel.error);
  }

  // ==================== DOMAIN-SPECIFIC LOGS ====================
  // Kept intentionally thin for Phase 1 — grows as Errand execution,
  // channel webhooks, and billing land in later phases (mirrors how
  // Asami's logger grew payment-specific helpers only once payments
  // actually existed, rather than speculatively up front).

  /// Webhook receipt logs (Meta/Paystack/Flutterwave inbound calls, Phase 2+).
  static void webhook(String service, String method, String path, {Session? session}) {
    final msg = '📡 $service webhook — $method $path';
    talker.info(msg);
    _serverpodLog(msg, session: session, level: LogLevel.info);
  }

  /// Repository-layer query logs — useful for tracing Supabase calls
  /// without leaking full row contents into production logs.
  static void dbQuery(String query, {Map<String, dynamic>? params, Session? session}) {
    final msg = '''
🗄️ DATABASE QUERY
   ${_truncate(query, maxLength: 200)}
   ${params != null ? 'Params: ${_formatData(params)}' : ''}
''';
    talker.verbose(msg);
    _serverpodLog(msg, session: session, level: LogLevel.debug);
  }

  // ==================== STARTUP LOGS ====================
  // Plain print() alongside Talker here — at boot time there is no
  // Serverpod session yet to attach to, and we want these visible
  // immediately in container logs even before logging is fully wired.

  static void startup(String message) {
    talker.info('🚀 $message');
    print('🚀 $message');
  }

  static void startupInfo(String message) {
    talker.info('   $message');
    print('   $message');
  }

  static void startupSuccess(String message) {
    talker.info('✅ $message');
    print('✅ $message');
  }

  static void startupWarning(String message) {
    talker.warning('⚠️ $message');
    print('⚠️ $message');
  }

  static void startupError(String message, {dynamic error}) {
    final msg = error != null ? '$message\n   Error: $error' : message;
    talker.error('❌ $msg');
    print('❌ $msg');
  }

  // ==================== HELPERS ====================

  static void _serverpodLog(
    String message, {
    Session? session,
    LogLevel level = LogLevel.info,
    StackTrace? stackTrace,
  }) {
    final s = session ?? _currentSession;
    if (s != null) {
      s.log(message, stackTrace: stackTrace);
    }
  }

  static String _formatData(dynamic data) {
    if (data is Map) {
      return data.entries
          .map((e) => '   ${e.key}: ${_truncate(e.value.toString())}')
          .join('\n');
    }
    if (data is List) {
      return data.map((e) => '   - ${_truncate(e.toString())}').join('\n');
    }
    return '   ${_truncate(data.toString())}';
  }

  static String _truncate(String text, {int maxLength = 100}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
