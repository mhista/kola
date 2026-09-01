// intelligence_narrative_service.dart — Phase 14g. Turns Intelligence's
// real, already-computed numbers (revenue delta, top products) into a
// plain-English paragraph — the AI-reasoning layer analytics_endpoint.dart's
// own header named as the reason `Kola Business Intelligence.dc.html`
// wasn't built in Phase 13e.
//
// Same shape as draft_reply_service.dart, deliberately: a real
// AiOrchestrator completion first (which itself already cascades
// Groq → Gemini → OpenRouter, falling through on any single provider's
// failure), and only an honest templated sentence — assembled from the
// SAME real numbers the model would have seen, never invented — if
// every configured provider fails. The model is given the numbers, not
// asked to invent them: it may only phrase what it's handed, so a
// hallucinated figure cannot reach the screen the way it could if the
// model were asked to "analyze this business" with no data at all.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'ai_orchestrator.dart';

class IntelligenceNarrative {
  const IntelligenceNarrative({required this.text, required this.isTemplate});

  final String text;
  final bool isTemplate;
}

class IntelligenceNarrativeService {
  IntelligenceNarrativeService({required AiOrchestrator aiOrchestrator})
      : _ai = aiOrchestrator;

  final AiOrchestrator _ai;

  Future<IntelligenceNarrative> narrate({
    required int periodDays,
    required String currency,
    required int revenueMinor,
    required double? revenueDeltaPct,
    required List<IntelligenceProduct> topProducts,
  }) async {
    try {
      final facts = _renderFacts(
        periodDays: periodDays,
        currency: currency,
        revenueMinor: revenueMinor,
        revenueDeltaPct: revenueDeltaPct,
        topProducts: topProducts,
      );
      final result = await _ai.complete(
        systemPrompt:
            'You are writing a short, plain-English business summary for '
            'a small business owner\'s dashboard. You will be given real, '
            'already-computed numbers — use ONLY those numbers. Do not '
            'invent any figure, product, or trend not given to you. '
            'Write 2-4 sentences, no bullet points, no headers, no '
            'preamble like "Here is a summary:". Be direct and specific '
            '(name the actual top product, the actual percentage) rather '
            'than generic.',
        userMessage: 'Real numbers for the last $periodDays days:\n$facts\n\n'
            'Write the summary paragraph now.',
        maxTokens: 260,
      );
      final text = result.text.trim();
      if (text.isEmpty) {
        throw StateError('Model returned an empty narrative.');
      }
      return IntelligenceNarrative(text: text, isTemplate: false);
    } catch (e) {
      Log.warning(
        'IntelligenceNarrativeService: every provider failed, falling back to template: $e',
      );
      return IntelligenceNarrative(
        text: _template(
          periodDays: periodDays,
          currency: currency,
          revenueMinor: revenueMinor,
          revenueDeltaPct: revenueDeltaPct,
          topProducts: topProducts,
        ),
        isTemplate: true,
      );
    }
  }

  String _renderFacts({
    required int periodDays,
    required String currency,
    required int revenueMinor,
    required double? revenueDeltaPct,
    required List<IntelligenceProduct> topProducts,
  }) {
    final buf = StringBuffer();
    buf.writeln('- Total revenue: ${_money(revenueMinor, currency)}');
    buf.writeln(
      revenueDeltaPct == null
          ? '- No comparable prior period to measure change against.'
          : '- Change vs. the previous $periodDays days: '
              '${revenueDeltaPct >= 0 ? '+' : ''}${revenueDeltaPct.toStringAsFixed(1)}%',
    );
    if (topProducts.isEmpty) {
      buf.writeln('- No completed sales with line items in this period.');
    } else {
      buf.writeln('- Top products by revenue:');
      for (final p in topProducts.take(5)) {
        final margin = p.marginPct == null
            ? 'cost not set'
            : '${p.marginPct!.toStringAsFixed(0)}% margin';
        buf.writeln(
          '  - ${p.name}: ${p.unitsSold} sold, '
          '${_money(p.revenueMinor, currency)}, $margin',
        );
      }
    }
    return buf.toString();
  }

  String _template({
    required int periodDays,
    required String currency,
    required int revenueMinor,
    required double? revenueDeltaPct,
    required List<IntelligenceProduct> topProducts,
  }) {
    final buf = StringBuffer();
    buf.write('Revenue over the last $periodDays days was '
        '${_money(revenueMinor, currency)}');
    if (revenueDeltaPct != null) {
      buf.write(
        revenueDeltaPct >= 0
            ? ', up ${revenueDeltaPct.toStringAsFixed(1)}% on the previous period.'
            : ', down ${revenueDeltaPct.abs().toStringAsFixed(1)}% on the previous period.',
      );
    } else {
      buf.write('. There isn\'t a full prior period yet to compare against.');
    }
    if (topProducts.isNotEmpty) {
      final top = topProducts.first;
      buf.write(
        ' The biggest driver was ${top.name}, with ${top.unitsSold} sold '
        'for ${_money(top.revenueMinor, currency)}'
        '${top.marginPct != null ? ' at roughly ${top.marginPct!.toStringAsFixed(0)}% margin' : ''}.',
      );
    }
    return buf.toString();
  }

  String _money(int minor, String currency) {
    final major = minor / 100;
    final symbol = currency == 'NGN' ? '₦' : '$currency ';
    return '$symbol${major.toStringAsFixed(major.truncateToDouble() == major ? 0 : 2)}';
  }
}
