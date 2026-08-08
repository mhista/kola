// proof_demo_section.dart
//
// "Let the product testify" — the section that replaces testimonials.
//
// WHY THERE IS NO TESTIMONIAL SECTION ANYWHERE ON THIS PAGE: kola hasn't
// launched. There are no customers to quote, and inventing quotes with
// invented names is trivially checkable, is the fastest way to lose an
// evaluator, and would be a serious problem in anything attached to a
// grant application. So instead of asking a visitor to take a stranger's
// word for it, this section hands them the product.
//
// THE DEMO IS REAL. It runs actual retrieval against whatever the
// visitor pastes, entirely in their browser — see
// services/demo_retrieval.dart for the full reasoning, including why it
// deliberately does NOT call the live API (public unauthenticated
// embeddings would be an abuse surface, and the provider's free tier is
// shared with real customer ingestion).
//
// STATEFUL LOCALLY, unlike most of this page. app.dart owns page state
// as a rule, but this demo's state (two inputs and a result) is entirely
// self-contained — no other section reads or writes it. Hoisting it to
// app.dart would add three fields and two callbacks to that file for
// nothing.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../services/demo_retrieval.dart';

class ProofDemoSection extends StatefulComponent {
  const ProofDemoSection();

  @override
  State<ProofDemoSection> createState() => _ProofDemoSectionState();
}

class _ProofDemoSectionState extends State<ProofDemoSection> {
  /// Pre-filled with a realistic small-retail policy. A blank box asks
  /// the visitor to do work before they've been given a reason to; a
  /// filled one lets them press the button immediately and see the point.
  String _policy =
      'Returns are accepted within 7 days if the item is unworn and tagged. '
      'Delivery outside the city takes 3-5 business days. '
      'We accept bank transfer and card payments. '
      'Fabric is sold per yard.';

  String _question = '';
  bool _run = false;

  void _ask() {
    if (_policy.trim().isEmpty) return;
    setState(() => _run = true);
  }

  @override
  Component build(BuildContext context) {
    final match = _run
        ? DemoRetrieval.best(text: _policy, question: _question)
        : null;

    return div(
      attributes: {
        'id': 'proof',
        'style': 'max-width:900px;margin:100px auto 0;padding:0 32px',
      },
      [
        div(
          attributes: {
            'style': 'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                'color:${KolaColors.accent};font-weight:600;margin-bottom:14px;'
                'text-align:center',
          },
          [Component.text('See it work — no login required')],
        ),
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:34px;font-weight:500;'
                'margin:0 0 8px;text-align:center',
          },
          [Component.text('Every answer cites its source.')],
        ),
        p(
          attributes: {
            'style': 'font-size:15.5px;color:${KolaColors.textMuted};text-align:center;'
                'max-width:540px;margin:0 auto 32px;line-height:1.5',
          },
          [
            Component.text(
              "kola isn't live yet, so instead of a testimonial, here's the thing "
              'itself. Paste something you would teach it, then ask a question a '
              'customer might send.',
            ),
          ],
        ),
        div(
          classes: 'kola-demo-grid',
          attributes: {
            'style': 'background:${KolaColors.cardBg};border:1px solid ${KolaColors.border};'
                'border-radius:22px;padding:28px;display:grid;'
                'grid-template-columns:1fr 1fr;gap:24px',
          },
          [
            _inputColumn(),
            _resultColumn(match),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:12px;color:${KolaColors.textFaint};text-align:center;'
                'margin-top:14px;line-height:1.5',
          },
          [
            Component.text(
              'Nothing leaves your browser — this demo runs entirely on your device. '
              'It matches on words; the real kola matches on meaning, so it finds '
              'answers this demo will miss.',
            ),
          ],
        ),
      ],
    );
  }

  Component _inputColumn() {
    return div([
      _label('1. Teach it something'),
      textarea(
        id: 'demoPolicy',
        rows: 5,
        attributes: {
          'aria-label': 'Text to teach kola',
          'style': 'width:100%;border:1px solid ${KolaColors.border};border-radius:12px;'
              'padding:12px 14px;font-family:inherit;font-size:13.5px;'
              'color:${KolaColors.text};box-sizing:border-box;resize:vertical;'
              'margin-bottom:14px;line-height:1.55',
        },
        events: {
          'input': (e) => _policy = (e.target as dynamic).value as String,
        },
        [Component.text(_policy)],
      ),
      _label('2. Ask what a customer would ask'),
      input(
        type: InputType.text,
        id: 'demoQuestion',
        attributes: {
          'placeholder': 'e.g. Can I return this after a week?',
          'aria-label': 'Customer question',
          'style': 'width:100%;border:1px solid ${KolaColors.border};border-radius:100px;'
              'padding:11px 16px;font-size:13.5px;font-family:inherit;'
              'color:${KolaColors.text};box-sizing:border-box;margin-bottom:12px',
        },
        events: {
          'input': (e) => _question = (e.target as dynamic).value as String,
          // Enter submits — a question box that ignores Enter is a small
          // friction that reads as broken.
          'keydown': (e) {
            if ((e as dynamic).key == 'Enter') _ask();
          },
        },
      ),
      button(
        classes: 'kola-btn-lift',
        attributes: {
          'style': 'background:${KolaColors.dark};color:${KolaColors.darkText};border:none;'
              'border-radius:100px;padding:11px 22px;font-size:13.5px;font-weight:600;'
              'font-family:inherit;cursor:pointer;white-space:nowrap',
        },
        events: {'click': (_) => _ask()},
        [Component.text('Ask kola')],
      ),
    ]);
  }

  Component _resultColumn(DemoMatch? match) {
    return div(
      attributes: {
        'style': 'background:${KolaColors.bg};border-radius:14px;padding:18px;'
            'display:flex;flex-direction:column;justify-content:center;min-height:150px',
      },
      [
        if (!_run)
          div(
            attributes: {
              'style': 'font-size:13.5px;color:${KolaColors.textFaint};text-align:center',
            },
            [Component.text('The answer, with its source, appears here.')],
          )
        else if (match == null)
          // THE HONEST OUTCOME, and arguably the most persuasive one on
          // the page: kola says it doesn't know rather than inventing an
          // answer. The real product behaves identically.
          _noMatch()
        else
          _answer(match),
      ],
    );
  }

  Component _answer(DemoMatch match) {
    return fragment([
      div(
        attributes: {
          'style': 'background:${KolaColors.cardBg};border-radius:12px;padding:14px 16px;'
              'margin-bottom:10px;font-size:14px;line-height:1.6;color:${KolaColors.textBody}',
        },
        [Component.text(match.content)],
      ),
      div(
        attributes: {
          'style': 'font-size:12px;color:${KolaColors.success};font-weight:600',
        },
        [
          Component.text('${match.percent}% match — answered from your text '
              '(section ${match.sectionNumber})'),
        ],
      ),
    ]);
  }

  Component _noMatch() {
    return fragment([
      div(
        attributes: {
          'style': 'background:${KolaColors.cardBg};border-radius:12px;padding:14px 16px;'
              'margin-bottom:10px;font-size:14px;line-height:1.6;color:${KolaColors.textBody}',
        },
        [
          Component.text(
            "I don't have that in what you gave me — I'd pass this to a person "
            'rather than guess.',
          ),
        ],
      ),
      div(
        attributes: {
          'style': 'font-size:12px;color:${KolaColors.badgeBrown};font-weight:600',
        },
        [Component.text('No matching section — kola never invents an answer')],
      ),
    ]);
  }

  Component _label(String s) => div(
        attributes: {
          'style': 'font-size:12px;color:${KolaColors.textFaint};margin-bottom:8px;'
              'font-weight:600',
        },
        [Component.text(s)],
      );
}
