// tool/connect_whatsapp_manual_test.dart
//
// One-off script to connect a real WhatsApp number the same way
// ChannelEndpoint.connectWhatsAppChannelManual does — probes Meta's API,
// encrypts the credential, and persists a 'connected' Channel row — but
// called directly, bypassing the Session/requireWorkspaceAccess auth layer
// that method needs for real dashboard traffic. That layer exists to
// protect the multi-tenant HTTP API from other businesses' requests; it's
// not needed for a script you're running yourself against your own
// Supabase project, and no login/session flow exists yet in kola_flutter
// to produce a real accessToken to call the real endpoint with anyway.
//
// WHY CREDENTIALS ARE CLI ARGS, NOT HARDCODED HERE: this file is tracked
// in git — putting a real WhatsApp access token or App Secret directly in
// it would repeat the exact .env.example leak this project already fixed
// once (see kola_server/README.md's security note). Pass them as flags
// each time instead; they only ever live in your shell history/terminal.
//
// USAGE (run from kola_server/):
//   dart run tool/connect_whatsapp_manual_test.dart \
//     --token=EAA... \
//     --phone=1253613704499432 \
//     --waba=1649282387200740 \
//     --appid=1031650389581177 \
//     --appsecret=4b48babfdbc6...
//
// First run creates a throwaway 'Kola Test Workspace' + 'Kola Test Bot' and
// prints their ids. Pass --workspace-id=<id> --bot-id=<id> on later runs
// (e.g. reconnecting after rotating the token) to reuse the same rows
// instead of creating new ones every time.
//
// AFTER THIS SUCCEEDS: it only writes to the database — the actual running
// server process (dart bin/main.dart) has its own in-memory
// WhatsAppBotRegistry that doesn't know about this yet. Restart the server
// so bootstrapFromDb() loads this newly-connected channel and the
// /webhooks/whatsapp route can actually route inbound messages to it.

import 'dart:io';

import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/repository/supabase_client.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/repository/channel_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_credential.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_service.dart';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);

  final token = _require(flags, 'token');
  final phoneNumberId = _require(flags, 'phone');
  final wabaId = _require(flags, 'waba');
  final appId = _require(flags, 'appid');
  final appSecret = _require(flags, 'appsecret');

  await initSupabase();
  ChannelCredentialEncryptionService.init(Env.channelCredentialMasterKey);

  final workspaces = const WorkspaceRepository();
  final bots = const BotRepository();
  final channels = const ChannelRepository();

  // ── Workspace ──────────────────────────────────────────────────────────
  var workspace = flags.containsKey('workspace-id')
      ? await workspaces.findById(int.parse(flags['workspace-id']!))
      : null;
  if (workspace == null) {
    print('Creating a new test workspace...');
    workspace = await workspaces.create(name: 'Kola Test Workspace');
  }
  print('Workspace: id=${workspace.id} name=${workspace.name}');

  // ── Bot ────────────────────────────────────────────────────────────────
  var bot = flags.containsKey('bot-id')
      ? await bots.findByIdScoped(int.parse(flags['bot-id']!), workspace.id!)
      : null;
  if (bot == null) {
    print('Creating a new test bot...');
    bot = await bots.create(
      workspaceId: workspace.id!,
      name: 'Kola Test Bot',
      archetype: 'customerCare',
    );
  }
  print('Bot: id=${bot.id} name=${bot.name} status=${bot.status}');

  // ── Probe Meta before touching the DB — same check the real endpoint
  //    does, so a bad paste fails loudly here instead of persisting a
  //    channel that can never actually send. ────────────────────────────
  final service = WhatsAppService(accessToken: token, phoneNumberId: phoneNumberId);
  Map<String, dynamic> phoneInfo;
  try {
    phoneInfo = await service.probe();
  } catch (e) {
    stderr.writeln('❌ WhatsApp probe failed — token/phone number ID are not '
        'valid together, or the token has expired: $e');
    exit(1);
  }
  print('✅ Probe succeeded: $phoneInfo');

  try {
    final tokenInfo = await service.debugToken(appId: appId, appSecret: appSecret);
    if (tokenInfo.isPermanent) {
      print('✅ Token is permanent (no expiry).');
    } else {
      print('⚠️  Token is TEMPORARY — expires ${tokenInfo.expiresAt}. '
          'Swap to a permanent System User token before relying on this.');
    }
  } catch (e) {
    print('⚠️  debug_token check failed (connection still proceeds): $e');
  }

  // ── Persist ────────────────────────────────────────────────────────────
  final existing = await channels.findByBotAndPlatform(bot.id!, 'whatsapp');
  final channel = existing ?? await channels.create(botId: bot.id!, platformType: 'whatsapp');

  final credential = WhatsAppCredential(
    accessToken: token,
    phoneNumberId: phoneNumberId,
    wabaId: wabaId,
    appId: appId,
    appSecret: appSecret,
  );
  final encrypted = ChannelCredentialEncryptionService.encrypt(credential.encode());

  final displayName = phoneInfo['verified_name'] as String? ??
      phoneInfo['display_phone_number'] as String?;

  final connected = await channels.setCredential(
    channelId: channel.id!,
    encryptedCredential: encrypted,
    displayName: displayName,
  );

  if (bot.status == 'draft') {
    await bots.setStatus(bot.id!, 'live');
  }

  print('');
  print('✅ WhatsApp channel connected:');
  print('   workspaceId = ${workspace.id}');
  print('   botId       = ${bot.id}');
  print('   channelId   = ${connected.id}');
  print('   displayName = ${connected.displayName}');
  print('');
  if (Env.webhookBaseUrl.isNotEmpty) {
    print('This channel also now has its own webhook URL (in addition to '
        'the shared one already verified in Meta\'s dashboard, if this is '
        'reconnecting an existing channel):');
    print('   ${Env.webhookBaseUrl}/webhooks/whatsapp/${connected.id}');
    print('You can migrate to it later — not required right now.');
  } else {
    print('WEBHOOK_BASE_URL is not set in .env, so this channel\'s '
        'per-channel URL can\'t be printed yet. Set it (your ngrok/public '
        'URL) and re-run build_runner if you want to see it.');
  }
  print('');
  print('Restart the server (dart bin/main.dart) so the running '
      'WhatsAppBotRegistry loads this channel and can route inbound '
      'webhooks to it.');

  exit(0);
}

Map<String, String> _parseFlags(List<String> args) {
  final map = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--') || !arg.contains('=')) continue;
    final eqIndex = arg.indexOf('=');
    map[arg.substring(2, eqIndex)] = arg.substring(eqIndex + 1);
  }
  return map;
}

String _require(Map<String, String> flags, String key) {
  final value = flags[key];
  if (value == null || value.trim().isEmpty) {
    stderr.writeln('Missing required --$key. See this file\'s header comment for usage.');
    exit(1);
  }
  return value.trim();
}
