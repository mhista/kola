// telegram_webhook_route.dart
//
// The Relic Route that IS the public HTTP endpoint each business's
// Telegram bot talks to.
//
// PLAIN ENGLISH — WHY channelId IS A CONSTRUCTOR PARAM:
//   Degenbot only ever ran one global bot, so it registered exactly one
//   static route (/webhooks/telegram) backed by a singleton handler.
//   Kola runs one bot PER connected Telegram Channel — every business
//   brings their own BotFather token — so there's one of these Route
//   instances PER channel, each registered at its own path
//   (/webhooks/telegram/<channelId>) by TelegramBotRegistry. Telegram
//   only ever needs to know its OWN bot's URL; nothing here lets one
//   channel's webhook accidentally feed another's bot.
//
// ALWAYS RETURN 200 OK:
//   Telegram retries aggressively on any non-2xx response, which can
//   cause duplicate processing. Every error is caught and logged
//   internally; Telegram always sees 200.

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:serverpod/serverpod.dart' hide Logger;
import 'telegram_bot_registry.dart';

final _log = Logger('TelegramWebhookRoute');

class TelegramWebhookRoute extends Route {
  TelegramWebhookRoute({required this.channelId})
      : super(methods: {Method.get, Method.post});

  final int channelId;

  @override
  Future<Result> handleCall(Session session, Request request) async {
    // ── GET: health check, handy for sanity-checking a deployment ──────────
    if (request.method == Method.get) {
      final response = {
        'status': 'Telegram webhook endpoint',
        'channelId': channelId,
        'method': 'POST',
        'message': 'Telegram delivers updates here via POST. This GET response is just a health check.',
      };
      return Response.ok(
        body: Body.fromString(jsonEncode(response), mimeType: MimeType.json),
      );
    }

    // ── POST: actual Telegram update delivery ────────────────────────────
    try {
      final body = await request.readAsString();

      if (body.isEmpty) return _ok();

      final payload = jsonDecode(body) as Map<String, dynamic>;
      if (!payload.containsKey('update_id')) {
        _log.warning('channel $channelId: invalid Telegram update — missing update_id');
        return _ok();
      }

      final result = await TelegramBotRegistry.instance.processWebhook(
        channelId,
        session,
        payload,
      );
      _log.fine('channel $channelId: webhook processed success=${result['success']}');

      return _ok();
    } catch (e, stackTrace) {
      _log.severe('channel $channelId: error processing Telegram webhook', e, stackTrace);
      session.log('Telegram webhook error (channel $channelId): $e', stackTrace: stackTrace);
      return _ok();
    }
  }

  Result _ok() => Response.ok(
        body: Body.fromString(jsonEncode({'ok': true}), mimeType: MimeType.json),
      );
}
