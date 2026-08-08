// splash_screen.dart — the boot animation, from `Kola Splash.dc.html`.
//
// The leaf draws itself, fills, settles with a small overshoot; the
// wordmark arrives a letter at a time; a rule grows under it; the
// tagline fades in. Every delay and duration matches the export — see
// the keyframes in web/styles.css.
//
// ── THE ONE DELIBERATE CHANGE: WHEN IT LEAVES ────────────────────────
//
// The export dismisses on a hard 2.3s timer and navigates at 2.78s,
// because a design tool has nothing real to wait for.
//
// Copying that would add nearly three seconds to every single load of a
// dashboard a shop owner opens twenty times a day — and it would be
// three seconds of waiting AFTER the app was already ready. A splash
// that outlives its loading is just a delay with a logo on it.
//
// So this waits on the real thing: session restore plus the workspace
// and feature fetches. Two guards around that:
//
//   MINIMUM — if boot takes 80ms (a warm cache), the animation would
//   appear and vanish as a flicker, which reads as a rendering glitch.
//   It holds for [_minVisible] so the mark and wordmark actually land.
//
//   MAXIMUM — if boot hangs, the splash must not become the product.
//   After [_maxVisible] it leaves regardless, and the app shows its own
//   loading or error state, where a stuck request can at least be
//   explained and retried. An indefinite splash cannot say anything.
//
// Tapping it skips, matching the export.

import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../theme.dart';

class SplashScreen extends StatefulComponent {
  const SplashScreen({required this.isReady, required this.onDone});

  /// Whether the app has finished booting. Watched rather than polled:
  /// [didUpdateComponent] fires when it flips.
  final bool isReady;

  /// Called once the splash has fully faded out. The caller removes it
  /// from the tree here — not before, or the fade never renders.
  final void Function() onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Long enough for the leaf to draw, fill and settle, and for the
  /// wordmark to finish arriving (the last letter starts at 1.36s).
  /// Below this the animation is a flicker rather than a moment.
  static const _minVisible = Duration(milliseconds: 1600);

  /// The splash is not allowed to become the product. Past this it
  /// leaves whatever boot is doing, and the app takes over — where a
  /// stalled request can actually be reported.
  static const _maxVisible = Duration(seconds: 6);

  /// Matches kola-fade-out's 500ms.
  static const _fadeDuration = Duration(milliseconds: 500);

  bool _minElapsed = false;
  bool _leaving = false;

  Timer? _minTimer;
  Timer? _maxTimer;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();

    _minTimer = Timer(_minVisible, () {
      if (!mounted) return;
      setState(() => _minElapsed = true);
      _leaveIfReady();
    });

    _maxTimer = Timer(_maxVisible, () {
      if (!mounted) return;
      _leave();
    });
  }

  @override
  void didUpdateComponent(SplashScreen oldComponent) {
    super.didUpdateComponent(oldComponent);
    // Boot may finish after the minimum has already passed, in which
    // case this is what triggers the exit.
    _leaveIfReady();
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }

  void _leaveIfReady() {
    if (component.isReady && _minElapsed) _leave();
  }

  void _leave() {
    if (_leaving) return;
    setState(() => _leaving = true);

    // onDone fires only after the fade has actually played. Calling it
    // immediately would unmount this component mid-animation and the
    // app would appear to snap rather than dissolve.
    _fadeTimer = Timer(_fadeDuration, () {
      if (mounted) component.onDone();
    });
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'position:fixed;inset:0;z-index:1000;overflow:hidden;'
            'background:${KolaVar.bg};display:flex;align-items:center;'
            'justify-content:center;cursor:pointer',
        'role': 'status',
        'aria-label': 'Loading kola',
      },
      // Empty string rather than null: `classes` is only ever passed a
      // non-null String elsewhere in this project, so whether it accepts
      // null is unverified — and this is not the file to find out in.
      classes: _leaving ? 'kola-splash-leaving' : '',
      // Tap to skip, as in the export. Someone who has seen it four
      // hundred times should be able to get past it.
      events: {'click': (_) => _leave()},
      [
        div(
          classes: 'kola-splash-bg',
          attributes: {
            'style': 'position:absolute;inset:0;background:radial-gradient('
                'ellipse 700px 500px at 50% 42%,rgba(193,85,46,0.14),transparent 70%)',
          },
          [],
        ),
        div(
          attributes: {
            'style': 'display:flex;flex-direction:column;align-items:center;'
                'gap:18px;position:relative',
          },
          [_mark(), _wordmark(), _tagline()],
        ),
      ],
    );
  }

  Component _mark() => div(
        attributes: {
          'style': 'position:relative;width:88px;height:88px;display:flex;'
              'align-items:center;justify-content:center',
        },
        [
          div(
            classes: 'kola-glow',
            attributes: {
              'style': 'position:absolute;width:76px;height:76px;'
                  'border-radius:${KolaRadius.circle};filter:blur(2px);'
                  'background:radial-gradient(circle,rgba(193,85,46,0.45),transparent 70%)',
            },
            [],
          ),
          // Two rings on the same 1.6s loop, offset by 0.8s, so one is
          // always mid-expansion. A single ring reads as a stutter.
          for (final delay in ['0.2s', '1.0s'])
            span(
              classes: 'kola-ring',
              attributes: {
                'style': 'position:absolute;width:64px;height:64px;'
                    'border-radius:${KolaRadius.circle};'
                    'border:1.5px solid ${KolaVar.accent};'
                    'animation-delay:$delay',
              },
              [],
            ),
          div(
            classes: 'kola-mark-wrap',
            attributes: {'style': 'position:relative;z-index:2'},
            [
              raw(
                '<svg width="60" height="60" viewBox="0 0 26 26" fill="none" '
                'aria-hidden="true">'
                '<path class="kola-leaf-outline" d="$_leafPath" '
                'stroke="var(--kola-accent)" stroke-width="1.6"/>'
                '<path class="kola-leaf-fill" d="$_leafPath" '
                'fill="var(--kola-accent)"/>'
                '</svg>',
              ),
            ],
          ),
        ],
      );

  Component _wordmark() => div(
        attributes: {'style': 'text-align:center'},
        [
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};font-size:28px;'
                  'font-weight:700;color:${KolaVar.text};letter-spacing:-0.01em',
            },
            [
              // Staggered 70ms apart from 1.15s, exactly as exported.
              for (var i = 0; i < _word.length; i++)
                span(
                  classes: 'kola-letter',
                  attributes: {
                    'style': 'animation-delay:'
                        '${(1.15 + i * 0.07).toStringAsFixed(2)}s',
                  },
                  [Component.text(_word[i])],
                ),
            ],
          ),
          span(classes: 'kola-rule', attributes: const {}, []),
        ],
      );

  Component _tagline() => div(
        classes: 'kola-tag',
        attributes: {
          'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
              'display:flex;align-items:center;gap:8px',
        },
        [
          span(attributes: const {}, [Component.text('Waking up your business brain')]),
          span(
            attributes: {'style': 'display:flex;gap:3px'},
            [
              for (final delay in ['0s', '0.15s', '0.3s'])
                span(
                  classes: 'kola-splash-dot',
                  attributes: {
                    'style': 'width:4px;height:4px;'
                        'border-radius:${KolaRadius.circle};'
                        'background:${KolaVar.muted};animation-delay:$delay',
                  },
                  [],
                ),
            ],
          ),
        ],
      );

  static const _word = 'kola';

  static const _leafPath =
      'M13 2C13 2 6 8.5 6 15.5C6 20 9 24 13 24C17 24 20 20 20 15.5C20 8.5 13 2 13 2Z';
}
