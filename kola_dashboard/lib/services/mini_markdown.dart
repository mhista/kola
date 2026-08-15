// mini_markdown.dart — the small, fixed subset kolaa's answers are written in.
//
// ── WHY NOT A MARKDOWN PACKAGE ───────────────────────────────────────
//
// Because the problem was never "we cannot parse markdown". It was that
// nothing was rendering at all: the Overview printed raw retrieved
// document text, so an owner saw literal `**` and `- ` and `---`. Adding
// a full CommonMark implementation would render every construct a model
// might emit — tables, headings, nested lists, images, HTML blocks — and
// each one is a new way for the answer card to look wrong.
//
// So the subset is fixed at BOTH ends. The prompt tells the model to use
// only paragraphs, `- ` bullets and `**bold**`; this renders exactly
// those three. Anything else arrives as plain text, which is legible —
// the failure mode is "a stray asterisk", not "a broken layout".
//
// ── WHY THIS CANNOT INJECT HTML ──────────────────────────────────────
//
// Every leaf here is `Component.text`, which jaspr escapes. There is no
// `innerHTML` path, no `unsafeHtml`, nothing that takes a string and
// treats it as markup.
//
// That matters more than it looks. This text is model output derived
// from documents the owner uploaded, and a document can contain anything
// — including text a customer sent. Rendering it as HTML would make
// "upload this file" an XSS vector against the owner's own dashboard.
// Text nodes make that structurally impossible rather than filtered.
//
// ── BOLD IS PARSED WITHOUT A REGEX ───────────────────────────────────
//
// A regex for `\*\*(.+?)\*\*` looks fine and mishandles the cases that
// actually turn up: an unclosed `**`, a lone `*` in `2 * 3`, and `****`.
// Scanning for pairs handles all three by construction — an unmatched
// opener is just text, because that is what it is.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../theme.dart';

abstract class MiniMarkdown {
  /// Renders [source] into block components.
  ///
  /// Returns a list rather than one wrapper so the caller controls the
  /// spacing between blocks and the surrounding card.
  static List<Component> render(
    String source, {
    String color = KolaVar.text,
    String fontSize = KolaType.body,
  }) {
    final blocks = <Component>[];
    final lines = source.replaceAll('\r\n', '\n').split('\n');

    var paragraph = <String>[];
    var bullets = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      blocks.add(_paragraph(paragraph.join(' '), color, fontSize));
      paragraph = [];
    }

    void flushBullets() {
      if (bullets.isEmpty) return;
      blocks.add(_bullets(bullets, color, fontSize));
      bullets = [];
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) {
        // A blank line ends whatever was open. Bullets flush too: a list
        // separated by a blank line from the next one is two lists to a
        // reader, and joining them would silently merge unrelated points.
        flushParagraph();
        flushBullets();
        continue;
      }

      // `- ` or `* ` at the start. The trailing space is required, so a
      // sentence beginning "*roughly* 40" is not read as a bullet.
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        flushParagraph();
        bullets.add(trimmed.substring(2).trim());
        continue;
      }

      // A horizontal rule is not in the subset, but documents are full
      // of them and a stray "---" in an answer looks like a mistake.
      // Swallowed rather than rendered.
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        flushParagraph();
        flushBullets();
        continue;
      }

      // Headings are not in the subset either. Rather than printing
      // "## Sizing", the hashes are stripped and the text is kept as a
      // paragraph — the words were the point.
      if (trimmed.startsWith('#')) {
        flushParagraph();
        flushBullets();
        final text = trimmed.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
        if (text.isNotEmpty) {
          blocks.add(_heading(text, color));
        }
        continue;
      }

      flushBullets();
      paragraph.add(trimmed);
    }

    flushParagraph();
    flushBullets();
    return blocks;
  }

  static Component _paragraph(String text, String color, String fontSize) => div(
        attributes: {
          'style': 'font-size:$fontSize;color:$color;line-height:1.6;'
              'margin:0 0 10px;max-width:68ch',
        },
        _inline(text),
      );

  /// Not an <h*>. The answer card sits inside a page that already has a
  /// heading hierarchy, and a real heading here would compete with it.
  /// This is a bolder line, which is what the text was doing anyway.
  static Component _heading(String text, String color) => div(
        attributes: {
          'style': 'font-size:${KolaType.small};font-weight:700;color:$color;'
              'line-height:1.5;margin:2px 0 6px',
        },
        _inline(text),
      );

  static Component _bullets(
    List<String> items,
    String color,
    String fontSize,
  ) =>
      div(
        attributes: {'style': 'margin:0 0 10px'},
        [
          for (final item in items)
            div(
              attributes: {
                'style': 'display:flex;gap:8px;align-items:flex-start;'
                    'margin-bottom:4px;max-width:68ch',
              },
              [
                // A styled span, not a <ul>. The list marker's colour and
                // offset are then ours rather than the user agent's, and
                // there is no browser-default left padding to fight.
                div(
                  attributes: {
                    'style': 'flex:none;color:${KolaVar.accent};'
                        'font-size:$fontSize;line-height:1.6',
                    'aria-hidden': 'true',
                  },
                  [Component.text('•')],
                ),
                div(
                  attributes: {
                    'style': 'font-size:$fontSize;color:$color;line-height:1.6',
                  },
                  _inline(item),
                ),
              ],
            ),
        ],
      );

  /// Splits a line into plain and bold runs.
  ///
  /// Scans for MATCHED `**` pairs. An opener with no closer stays literal
  /// — which is the honest rendering, because the model did not finish
  /// the emphasis it started.
  static List<Component> _inline(String text) {
    final out = <Component>[];
    var buffer = StringBuffer();
    var i = 0;

    void flush() {
      if (buffer.isEmpty) return;
      out.add(Component.text(buffer.toString()));
      buffer = StringBuffer();
    }

    while (i < text.length) {
      if (i + 1 < text.length && text[i] == '*' && text[i + 1] == '*') {
        final close = text.indexOf('**', i + 2);
        // No closer, or `****` with nothing between: literal.
        if (close == -1 || close == i + 2) {
          buffer.write('**');
          i += 2;
          continue;
        }
        flush();
        out.add(
          span(
            attributes: {'style': 'font-weight:700;color:${KolaVar.text}'},
            [Component.text(text.substring(i + 2, close))],
          ),
        );
        i = close + 2;
        continue;
      }
      buffer.write(text[i]);
      i++;
    }

    flush();
    // A line that was entirely an unmatched marker still needs a node, or
    // the parent renders as an empty box.
    return out.isEmpty ? [Component.text('')] : out;
  }
}
