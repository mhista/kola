// text_chunker.dart
//
// PHASE 9 (Layer 2 — Business Memory). Splits a document into the
// passages that actually get embedded and retrieved.
//
// WHY CHUNKING IS THE PART THAT DECIDES ANSWER QUALITY:
//   Retrieval can only ever return whole chunks. Too large, and a
//   returned chunk is mostly irrelevant text that dilutes the prompt and
//   crowds out other genuinely relevant chunks. Too small, and a chunk
//   loses the context that made it meaningful ("14 days" is useless
//   without "returns are accepted within"). Everything downstream — the
//   embedding model, the similarity threshold, the prompt — is
//   downstream of getting this roughly right.
//
// DELIBERATELY PURE: no I/O, no network, no database, no dependency on
// anything in this project. That is what makes it the one piece of this
// subsystem that can be tested for real without live API keys — see
// test/text_chunker_test.dart.
//
// STRATEGY, in the order each is tried:
//   1. Split on paragraph boundaries (blank lines), and pack whole
//      paragraphs together up to the target size. A business document —
//      a policy, a price list, an FAQ — carries its meaning in
//      paragraphs, so this keeps semantically-whole units intact
//      whenever they fit.
//   2. A single paragraph too large to fit is split on sentence
//      boundaries instead.
//   3. A single SENTENCE too large to fit (rare, but real: a
//      comma-separated product list with no full stops) is hard-split on
//      a word boundary. Never mid-word.
//
//   Consecutive chunks then overlap by a configurable tail, so a fact
//   that happens to straddle a boundary appears whole in at least one
//   chunk rather than being cut in half in both.
//
// WHAT THIS IS NOT: a structure-aware parser. It does not understand
// markdown headings, tables, or lists as such — a heading is just a
// short paragraph to it. That's a real limitation and a deliberate v1;
// heading-aware chunking is a meaningful improvement, but it is an
// improvement TO this file's strategy, not a different architecture, and
// it should be made against real business documents rather than guessed
// at now.

import 'dart:math' as math;

/// One passage produced by [TextChunker.chunk].
class TextChunk {
  const TextChunk({
    required this.content,
    required this.index,
    required this.tokenEstimate,
  });

  /// The passage text, exactly as it will be embedded and later injected
  /// into a prompt.
  final String content;

  /// 0-based position in the document.
  final int index;

  /// See [TextChunker.estimateTokens] — an approximation, honestly named.
  final int tokenEstimate;
}

class TextChunker {
  const TextChunker({
    this.targetChars = 1200,
    this.overlapChars = 150,
    this.minChunkChars = 80,
  });

  /// Roughly 300 tokens at the ~4-chars-per-token rule of thumb below.
  /// Large enough to hold a whole policy clause with its context, small
  /// enough that six of them fit comfortably in a prompt alongside the
  /// conversation.
  final int targetChars;

  /// How much of the previous chunk's tail to repeat at the start of the
  /// next one. Prevents a fact split across a boundary from being lost
  /// from both sides.
  final int overlapChars;

  /// A trailing fragment shorter than this is appended to the previous
  /// chunk instead of becoming its own. Avoids emitting a chunk that is
  /// just "Thanks!" or a stray heading, which embeds to something
  /// meaningless and pollutes retrieval.
  final int minChunkChars;

  /// Splits [text] into overlapping chunks. Returns an empty list for
  /// empty/whitespace-only input — callers treat that as "nothing to
  /// index" rather than an error, since an owner pasting an empty box is
  /// a mistake to report, not an exception to throw.
  List<TextChunk> chunk(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return const [];

    final pieces = _splitToFittingPieces(normalized);
    if (pieces.isEmpty) return const [];

    // Pack pieces into chunks up to targetChars.
    final packed = <String>[];
    final buffer = StringBuffer();

    void flush() {
      final content = buffer.toString().trim();
      if (content.isNotEmpty) packed.add(content);
      buffer.clear();
    }

    for (final piece in pieces) {
      final wouldBe = buffer.isEmpty ? piece.length : buffer.length + 2 + piece.length;
      if (buffer.isNotEmpty && wouldBe > targetChars) flush();
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write(piece);
    }
    flush();

    if (packed.isEmpty) return const [];

    // Merge a too-short trailing chunk back into its predecessor.
    if (packed.length > 1 && packed.last.length < minChunkChars) {
      final tail = packed.removeLast();
      packed[packed.length - 1] = '${packed.last}\n\n$tail';
    }

    // Apply overlap, then number the results.
    final result = <TextChunk>[];
    for (var i = 0; i < packed.length; i++) {
      final body = packed[i];
      final content = i == 0
          ? body
          : '${_tailOf(packed[i - 1], overlapChars)}\n\n$body';
      result.add(TextChunk(
        content: content,
        index: i,
        tokenEstimate: estimateTokens(content),
      ));
    }
    return result;
  }

  /// Splits text into pieces each guaranteed to be <= [targetChars],
  /// escalating through paragraph → sentence → word boundaries.
  List<String> _splitToFittingPieces(String text) {
    final out = <String>[];
    for (final paragraph in text.split(RegExp(r'\n\s*\n'))) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length <= targetChars) {
        out.add(trimmed);
        continue;
      }
      for (final sentence in _splitSentences(trimmed)) {
        if (sentence.length <= targetChars) {
          out.add(sentence);
        } else {
          out.addAll(_hardSplitOnWords(sentence));
        }
      }
    }
    return out;
  }

  /// Sentence split on ., ! or ? followed by whitespace. Deliberately
  /// simple: a full sentence tokenizer would need a dependency and a
  /// language model's worth of abbreviation handling, and the failure
  /// mode here is mild (a slightly odd boundary), not incorrect data.
  List<String> _splitSentences(String paragraph) {
    final parts = paragraph.split(RegExp(r'(?<=[.!?])\s+'));
    return [
      for (final p in parts)
        if (p.trim().isNotEmpty) p.trim(),
    ];
  }

  /// Last-resort split for a single run of text with no usable sentence
  /// boundary. Breaks on whitespace so a word is never cut in half.
  List<String> _hardSplitOnWords(String text) {
    final out = <String>[];
    final buffer = StringBuffer();
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final wouldBe = buffer.isEmpty ? word.length : buffer.length + 1 + word.length;
      if (buffer.isNotEmpty && wouldBe > targetChars) {
        out.add(buffer.toString());
        buffer.clear();
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(word);
    }
    if (buffer.isNotEmpty) out.add(buffer.toString());
    return out;
  }

  /// The last [chars] characters of [text], snapped forward to the next
  /// whitespace so the overlap never begins mid-word.
  static String _tailOf(String text, int chars) {
    if (chars <= 0 || text.length <= chars) return text;
    final slice = text.substring(text.length - chars);
    final space = slice.indexOf(RegExp(r'\s'));
    return space == -1 ? slice : slice.substring(space + 1);
  }

  /// Collapses Windows/old-Mac line endings and runs of blank lines, and
  /// strips trailing spaces per line — so the same document pasted from
  /// Word, a browser, or a text file chunks identically (and, just as
  /// importantly, hashes identically for dedupe).
  static String _normalize(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trimRight())
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// ~4 characters per token — the widely-used English rule of thumb.
  ///
  /// HONESTLY AN ESTIMATE, not a tokenizer: running the real one would
  /// mean shipping a model-specific vocabulary for a number used only to
  /// budget how many chunks fit in a prompt. It is used with headroom
  /// (see MemoryRetrievalService's budget), so being off by 20% costs a
  /// slightly fuller or emptier prompt, never a failed request.
  static int estimateTokens(String text) => math.max(1, (text.length / 4).ceil());
}
