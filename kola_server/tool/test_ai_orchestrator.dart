// ignore_for_file: avoid_print
// ^ One-off CLI script: stdout IS the output. avoid_print stays ON for
//   lib/ — this is a targeted ignore rather than an analyzer exclude, so
//   real errors in this file are still reported.
// tool/test_ai_orchestrator.dart
//
// One-off script to confirm AiOrchestrator can actually reach a real
// provider — run this once after adding a GROQ_API_KEY/GEMINI_API_KEY/
// OPENROUTER_API_KEY to .env and regenerating env.g.dart, before wiring
// the orchestrator into any bot-facing code.
//
// USAGE (run from kola_server/):
//   dart run tool/test_ai_orchestrator.dart
//   dart run tool/test_ai_orchestrator.dart "What is Kola?"

import 'dart:io';
import 'package:kola_server/src/services/ai/ai_orchestrator.dart';

Future<void> main(List<String> args) async {
  final question = args.isNotEmpty
      ? args.join(' ')
      : 'In one short sentence, what does a WhatsApp/Telegram bot-as-a-service platform do for a small business?';

  print('Asking: $question');
  print('');

  final orchestrator = AiOrchestrator();
  try {
    final result = await orchestrator.complete(
      systemPrompt: 'You are a concise, friendly assistant.',
      userMessage: question,
    );
    print('✅ Answered by: ${result.providerName}');
    print('');
    print(result.text);
    exit(0);
  } catch (e) {
    stderr.writeln('❌ ${e.toString()}');
    exit(1);
  }
}
