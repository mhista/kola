// tool/test_grounded_qa.dart
//
// One-off script exercising the other half of Phase 3's "done when" bar:
// a bot answering a question grounded in a manually-seeded piece of
// knowledge, through AiOrchestrator (bot_knowledge_service.dart). Same
// spirit as test_ai_orchestrator.dart and connect_whatsapp_manual_test.dart
// — bypasses the Session/requireWorkspaceAccess layer since nothing calls
// BotEndpoint.setKnowledgeSeed from a real UI yet.
//
// USAGE (run from kola_server/):
//   dart run tool/test_grounded_qa.dart \
//     --seed="We're open 9am-6pm Mon-Sat. Returns accepted within 7 days with receipt." \
//     --question="What's your return policy?"
//
// First run creates a throwaway workspace + bot (prints their ids). Pass
// --workspace-id=<id> --bot-id=<id> on later runs to reuse the same bot
// (and its already-set seed) instead of creating a new one each time.

import 'dart:io';
import 'package:kola_server/src/services/repository/supabase_client.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/bot_repository.dart';
import 'package:kola_server/src/services/ai/ai_orchestrator.dart';
import 'package:kola_server/src/services/knowledge/bot_knowledge_service.dart';
import 'package:kola_server/src/generated/protocol.dart';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);
  final question = flags['question'] ??
      'What\'s your return policy?';

  await initSupabase();

  final workspaces = const WorkspaceRepository();
  final bots = const BotRepository();

  var workspace = flags.containsKey('workspace-id')
      ? await workspaces.findById(int.parse(flags['workspace-id']!))
      : null;
  workspace ??= await workspaces.create(name: 'Kola Test Workspace (Knowledge)');
  print('Workspace: id=${workspace.id} name=${workspace.name}');

  var bot = flags.containsKey('bot-id')
      ? await bots.findByIdScoped(int.parse(flags['bot-id']!), workspace.id!)
      : null;
  bot ??= await bots.create(
    workspaceId: workspace.id!,
    name: 'Kola Test Bot (Knowledge)',
    archetype: 'customerCare',
  );
  print('Bot: id=${bot.id} name=${bot.name}');

  if (flags.containsKey('seed')) {
    bot = await bots.update(
      Bot(
        id: bot.id,
        workspaceId: bot.workspaceId,
        name: bot.name,
        archetype: bot.archetype,
        status: bot.status,
        knowledgeSeed: flags['seed'],
        createdAt: bot.createdAt,
        updatedAt: bot.updatedAt,
      ),
    );
    print('Knowledge seed set (${flags['seed']!.length} chars).');
  }

  if ((bot.knowledgeSeed ?? '').isEmpty) {
    print('');
    print('⚠️  This bot has no knowledgeSeed set yet — pass --seed="..." to '
        'set one, or the answer below will honestly say it has no '
        'business-specific information.');
  }

  print('');
  print('Question: $question');
  print('');

  final knowledgeService = BotKnowledgeService(aiOrchestrator: AiOrchestrator());
  try {
    final result = await knowledgeService.answerGrounded(bot: bot, question: question);
    print('✅ Answered by: ${result.providerName}');
    print('');
    print(result.text);
    exit(0);
  } catch (e) {
    stderr.writeln('❌ ${e.toString()}');
    exit(1);
  }
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
