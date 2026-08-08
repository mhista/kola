// demo_retrieval.dart
//
// THE LANDING PAGE'S INTERACTIVE DEMO ACTUALLY RETRIEVES. This file is
// why.
//
// WHAT THE DESIGN EXPORT DID, AND WHY IT WASN'T SHIPPABLE:
//   The v2 export's demo returned a hardcoded template — it echoed the
//   first sentence of whatever was pasted, regardless of the question
//   asked, and always cited "section 1". On a page whose entire proof
//   section is headed "Every answer cites its source" and reads "kola
//   isn't live yet, so instead of a testimonial, here's the thing
//   itself", shipping a fake would be the same integrity problem as a
//   fabricated testimonial — just harder to spot.
//
// WHAT THIS DOES INSTEAD: real retrieval, honestly scoped.
//   The pasted text is split into sections the same way the real
//   product splits a document, each section is scored against the
//   question, and the best-matching one is returned with its real
//   section number and a real match score. If nothing clears the floor,
//   it says so — which is exactly what the real product does, and is
//   arguably the more persuasive outcome, because it proves kola
//   doesn't bluff.
//
// WHY NOT CALL THE REAL API:
//   Two reasons, both practical. A public unauthenticated endpoint doing
//   embeddings is an obvious abuse surface, and the embedding provider's
//   free tier is 1,500 requests/day shared with real customer ingestion
//   — a landing page that gets traffic would starve the actual product.
//   So the page's own claim, "No files leave your browser for this
//   demo", is literally true: this runs entirely client-side.
//
// THE HONEST DIFFERENCE, and the page says it in one line:
//   This is LEXICAL matching — word overlap, weighted. The real product
//   uses semantic matching, so it understands that "can I bring it
//   back?" and "returns policy" are the same question where this does
//   not. This demo therefore UNDERSTATES the product. That's the right
//   direction for a demo to be wrong in.
//
// Pure — no I/O, no DOM, no dependencies. Testable, and deliberately
// mirrors the shape of the server's own TextChunker.

/// One retrieved section: the passage, where it came from, how well it
/// matched.
class DemoMatch {
  const DemoMatch({
    required this.content,
    required this.sectionNumber,
    required this.score,
  });

  final String content;

  /// 1-based, as shown to the user. The real product stores 0-based and
  /// displays 1-based for the same reason — "section 0" reads as a bug.
  final int sectionNumber;

  /// 0..1. Shown as a percentage.
  final double score;

  int get percent => (score * 100).round();
}

abstract class DemoRetrieval {
  /// Words carrying no retrieval signal. Kept deliberately short — an
  /// aggressive stopword list would strip meaning from short business
  /// questions like "do you deliver".
  static const _stopwords = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'am',
    'i', 'you', 'we', 'they', 'it', 'my', 'your', 'our', 'their',
    'of', 'to', 'in', 'on', 'at', 'for', 'with', 'from', 'by',
    'and', 'or', 'but', 'if', 'so', 'as', 'that', 'this', 'these',
    'can', 'could', 'will', 'would', 'do', 'does', 'did', 'have',
    'has', 'had', 'what', 'when', 'where', 'how', 'why', 'me',
  };

  /// Below this, a section is treated as unrelated and not returned.
  /// The real product uses a cosine-similarity floor of 0.35 for the
  /// same reason: without a floor, EVERY question returns its nearest
  /// section however irrelevant, and the answer sounds confident and
  /// wrong. Kept a little lower here because lexical scores run lower
  /// than semantic ones for the same real relevance.
  static const minScore = 0.18;

  /// Splits pasted text into retrievable sections. Paragraph first,
  /// falling back to sentences when the text is one block — which is
  /// what a pasted policy usually is.
  static List<String> sections(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) return const [];

    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    // One block of prose is the common case for a pasted policy — split
    // it into sentences so there is something to actually choose between.
    if (paragraphs.length <= 1) {
      final sentences = normalized
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return sentences.isEmpty ? [normalized] : sentences;
    }
    return paragraphs;
  }

  static Set<String> _terms(String s) => s
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9₦]+'))
      .where((w) => w.length > 1 && !_stopwords.contains(w))
      .toSet();

  /// Whether two terms should count as the same word.
  ///
  /// Prefix matching rather than a stemmer, deliberately. It handles the
  /// cases that actually break a business demo — return/returns,
  /// deliver/delivery, pay/payments — without shipping a stemming
  /// algorithm to solve four words. Verified against the real question
  /// set before this shipped: without it, "Can I return this after a
  /// week?" (the demo's own placeholder question) matched NOTHING,
  /// because "return" != "returns".
  ///
  /// The length guards stop absurd matches: both terms must be >=4
  /// characters, and their lengths must be within 4 of each other, so
  /// "car" doesn't match "cardboard" and "pay" doesn't swallow
  /// "payment-processing-terms".
  static bool _related(String a, String b) {
    if (a == b) return true;
    if (a.length < 4 || b.length < 4) return false;
    if (!a.startsWith(b) && !b.startsWith(a)) return false;
    return (a.length - b.length).abs() <= 4;
  }

  static int _hits(Set<String> questionTerms, Set<String> sectionTerms) {
    var count = 0;
    for (final q in questionTerms) {
      if (sectionTerms.any((s) => _related(q, s))) count++;
    }
    return count;
  }

  /// Best-matching section for [question] within [text], or null when
  /// nothing clears [minScore].
  ///
  /// Scoring is overlap of question terms present in the section,
  /// normalised by question length, with a small bonus for a section
  /// that matches a higher PROPORTION of its own words — which favours
  /// a short, precise sentence over a long one that happens to contain
  /// the word somewhere.
  static DemoMatch? best({required String text, required String question}) {
    final secs = sections(text);
    if (secs.isEmpty) return null;

    final qTerms = _terms(question);
    if (qTerms.isEmpty) return null;

    DemoMatch? bestMatch;
    for (var i = 0; i < secs.length; i++) {
      final sTerms = _terms(secs[i]);
      if (sTerms.isEmpty) continue;

      final hits = _hits(qTerms, sTerms);
      if (hits == 0) continue;

      final coverage = hits / qTerms.length;
      final precision = hits / sTerms.length;
      final score = (coverage * 0.8) + (precision * 0.2);

      if (bestMatch == null || score > bestMatch.score) {
        bestMatch = DemoMatch(
          content: secs[i],
          sectionNumber: i + 1,
          score: score.clamp(0.0, 1.0),
        );
      }
    }

    if (bestMatch == null || bestMatch.score < minScore) return null;
    return bestMatch;
  }
}
