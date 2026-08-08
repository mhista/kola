// text_chunker_test.dart
//
// PHASE 9 (Layer 2 — Business Memory). THE FIRST REAL AUTOMATED TESTS IN
// THIS CODEBASE.
//
// Every prior "test" in this project is a script under tool/ that makes
// live API calls and prints output for a human to read (test_ai_
// orchestrator.dart, test_grounded_qa.dart, and so on). Those are
// verification harnesses, not tests — they need real keys, a network,
// and a person to judge the result, so they can't run in CI and can't
// fail a build.
//
// TextChunker was written to be pure — no I/O, no network, no database,
// no dependency on anything else in this project — specifically so that
// the piece of Layer 2 that most determines answer quality is the piece
// that can be tested for real. Run with:  dart test test/
//
// WHAT IS NOT TESTED HERE, AND WHY IT'S HONEST TO SAY SO:
//   Embedding, retrieval, and ingestion all require either a live Gemini
//   key or a live Supabase connection. Testing them properly means fake
//   implementations of EmbeddingProvider and the repositories — worth
//   doing, and the interfaces were written to allow it (both take their
//   dependencies by constructor injection), but not attempted here
//   without a Dart toolchain available to actually run the result.

import 'package:test/test.dart';
import 'package:kola_server/src/services/memory/text_chunker.dart';

void main() {
  group('TextChunker', () {
    const chunker = TextChunker();

    test('returns nothing for empty or whitespace-only input', () {
      expect(chunker.chunk(''), isEmpty);
      expect(chunker.chunk('   \n\n  \t '), isEmpty);
    });

    test('keeps a short document as a single chunk', () {
      final chunks = chunker.chunk(
        'We accept returns within 14 days of delivery, provided the item '
        'is unworn and has its tags attached.',
      );
      expect(chunks, hasLength(1));
      expect(chunks.first.index, 0);
      expect(chunks.first.content, contains('14 days'));
    });

    test('normalizes line endings so the same text chunks identically', () {
      const body = 'First paragraph.\n\nSecond paragraph.';
      final unix = chunker.chunk(body);
      final windows = chunker.chunk(body.replaceAll('\n', '\r\n'));
      final oldMac = chunker.chunk(body.replaceAll('\n', '\r'));

      // This is what makes content-hash dedupe work at all — the same
      // document pasted from Word and from a text file must produce
      // byte-identical chunk content. See document_ingestion_service.dart,
      // which hashes the chunked output rather than the raw input.
      expect(windows.map((c) => c.content), unix.map((c) => c.content));
      expect(oldMac.map((c) => c.content), unix.map((c) => c.content));
    });

    test('collapses runs of blank lines rather than emitting empty chunks', () {
      final chunks = chunker.chunk('One.\n\n\n\n\n\nTwo.');
      expect(chunks, hasLength(1));
      expect(chunks.first.content, 'One.\n\nTwo.');
    });

    test('splits a long document into multiple ordered chunks', () {
      // 40 distinct paragraphs, each ~100 chars — comfortably past the
      // 1200-char target, so this must split.
      final source = List.generate(
        40,
        (i) => 'Paragraph number $i explains a distinct policy detail that '
            'the business wants its bot to know about clearly.',
      ).join('\n\n');

      final chunks = chunker.chunk(source);

      expect(chunks.length, greaterThan(1));
      // Indexes must be 0..n-1 in order — retrieval cites these as
      // "section N", and ErrandExecutionLog-style traceability depends on
      // them being stable.
      expect(
        chunks.map((c) => c.index).toList(),
        List.generate(chunks.length, (i) => i),
      );
    });

    test('every chunk carries a positive token estimate', () {
      final chunks = chunker.chunk(
        List.generate(30, (i) => 'Sentence $i about delivery timing.').join('\n\n'),
      );
      expect(chunks, isNotEmpty);
      for (final chunk in chunks) {
        expect(chunk.tokenEstimate, greaterThan(0));
        expect(chunk.tokenEstimate, TextChunker.estimateTokens(chunk.content));
      }
    });

    test('consecutive chunks overlap, so a boundary fact is not lost', () {
      const overlap = 120;
      const local = TextChunker(targetChars: 400, overlapChars: overlap);

      final source = List.generate(
        20,
        (i) => 'Policy point $i states something specific and identifiable.',
      ).join('\n\n');

      final chunks = local.chunk(source);
      expect(chunks.length, greaterThan(1));

      // Each chunk after the first must begin with material that also
      // appeared in its predecessor. Compare on the first few words
      // rather than the whole prefix, since _tailOf snaps forward to a
      // word boundary and so trims a partial leading word.
      for (var i = 1; i < chunks.length; i++) {
        final leadWords = chunks[i].content.trim().split(RegExp(r'\s+')).take(3).join(' ');
        expect(
          chunks[i - 1].content.contains(leadWords),
          isTrue,
          reason: 'chunk $i should overlap chunk ${i - 1}; '
              'lead was "$leadWords"',
        );
      }
    });

    test('splits an oversized single paragraph on sentence boundaries', () {
      const local = TextChunker(targetChars: 200, overlapChars: 0);
      // One paragraph, no blank lines, far past the target.
      final source = List.generate(
        20,
        (i) => 'This is sentence number $i in a very long unbroken paragraph.',
      ).join(' ');

      final chunks = local.chunk(source);
      expect(chunks.length, greaterThan(1));
      // Sentence-boundary splitting means no chunk should end mid-word.
      for (final chunk in chunks) {
        expect(chunk.content.trim(), isNot(endsWith('senten')));
      }
    });

    test('hard-splits a run with no sentence boundary, never mid-word', () {
      const local = TextChunker(targetChars: 100, overlapChars: 0);
      // A comma-separated product list with no full stops at all — the
      // real case this fallback exists for.
      final source = List.generate(60, (i) => 'ProductCode$i').join(', ');

      final chunks = local.chunk(source);
      expect(chunks.length, greaterThan(1));

      // Reassembling every chunk must recover every original token
      // intact — proof nothing was cut through the middle of a word.
      final recombined = chunks.map((c) => c.content).join(' ');
      for (var i = 0; i < 60; i++) {
        expect(recombined, contains('ProductCode$i'));
      }
    });

    test('merges a too-short trailing fragment into the previous chunk', () {
      const local = TextChunker(targetChars: 300, overlapChars: 0, minChunkChars: 80);

      final source = '${List.generate(
        6,
        (i) => 'A reasonably sized paragraph number $i with real content in it.',
      ).join('\n\n')}\n\nThanks!';

      final chunks = local.chunk(source);

      // "Thanks!" must not have become its own chunk — on its own it
      // embeds to something meaningless and pollutes every future search.
      expect(chunks.last.content, contains('Thanks!'));
      expect(chunks.any((c) => c.content.trim() == 'Thanks!'), isFalse);
    });

    test('no chunk exceeds the documented worst-case size', () {
      const target = 500;
      const overlap = 100;
      const minChunk = 80;
      const local = TextChunker(
        targetChars: target,
        overlapChars: overlap,
        minChunkChars: minChunk,
      );

      final source = List.generate(
        50,
        (i) => 'Paragraph $i carries a moderate amount of text about how the '
            'business handles a particular situation.',
      ).join('\n\n');

      // The bound is target + overlap + minChunkChars + separators, and
      // each term is a real, separate contribution rather than padding:
      //   • target      — a packed body is never grown past this.
      //   • overlap     — prepended tail of the previous chunk.
      //   • minChunkChars — the LAST chunk may additionally absorb a
      //     trailing fragment shorter than this (see the merge test
      //     above), so the final chunk alone can exceed target+overlap.
      //   • +4          — the two 2-character '\n\n' separators.
      // Asserting only target+overlap+2 would pass for most inputs and
      // then fail on an input that happens to end in a short fragment —
      // an assertion that is accidentally true, not actually correct.
      const bound = target + overlap + minChunk + 4;
      for (final chunk in local.chunk(source)) {
        expect(chunk.content.length, lessThanOrEqualTo(bound));
      }
    });

    test('estimateTokens never returns zero for non-empty text', () {
      expect(TextChunker.estimateTokens('a'), greaterThan(0));
      expect(TextChunker.estimateTokens('a much longer piece of text here'),
          greaterThan(1));
    });
  });
}
