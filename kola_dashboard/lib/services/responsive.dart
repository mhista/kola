// responsive.dart — one breakpoint tracker for every page, not five
// hand-rolled copies. till_page.dart wrote the first version of this
// (a `_view` string + a live resize listener — see its own header on
// why a cashier does not pick "phone" or "tablet" from a menu, the
// till just fits the screen it's on) and that's the right idea. Every
// other page still either hardcodes fixed pixel widths that overflow
// below tablet, or has no responsive logic at all — see docs/ for the
// mobile-responsiveness audit that named conversations_page.dart,
// knowledge_page.dart, bot_detail_dev_page.dart, api_webhooks_page.dart
// and errand_builder_page.dart specifically. This gives every page
// till_page.dart's live-resize behavior off KolaBreak's shared
// breakpoints, without copying its ~25 lines of JS interop five times.
//
// USAGE:
//   class _FooPageState extends State<FooPage> with ResponsiveViewport<FooPage> {
//     @override
//     void initState() {
//       super.initState();
//       initResponsive();   // after super.initState()
//       ...
//     }
//     @override
//     void dispose() {
//       disposeResponsive(); // before super.dispose()
//       super.dispose();
//     }
//     ...
//     build() { if (isMobile) ... }
//   }
//
// Mixins here don't auto-hook lifecycle the way Flutter's
// TickerProviderStateMixin does — nothing in this codebase's State base
// class calls back into mixins automatically — so initResponsive() /
// disposeResponsive() are explicit calls, not magic. Forgetting them
// just means the page never becomes responsive, the same as today; it
// cannot corrupt other state.

import 'dart:js_interop';

import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../theme.dart';

mixin ResponsiveViewport<T extends StatefulComponent> on State<T> {
  int _viewportWidth = KolaBreak.tablet;
  web.EventListener? _responsiveResizeListener;

  /// Below KolaBreak.tablet (768px) — phones, and browser windows
  /// narrowed to phone width.
  bool get isMobile => _viewportWidth < KolaBreak.tablet;

  /// KolaBreak.tablet up to (not including) KolaBreak.desktop.
  bool get isTablet => _viewportWidth >= KolaBreak.tablet && _viewportWidth < KolaBreak.desktop;

  /// KolaBreak.desktop and above.
  bool get isDesktop => _viewportWidth >= KolaBreak.desktop;

  /// The raw viewport width in CSS pixels, for a page that needs a
  /// finer cut than mobile/tablet/desktop (e.g. till_page.dart's own
  /// phoneFloor-aware layouts).
  int get viewportWidth => _viewportWidth;

  /// Call once, from `initState()`, after `super.initState()`.
  void initResponsive() {
    _viewportWidth = web.window.innerWidth;
    // Explicit `return;` at the end, deliberately — see till_page.dart's
    // own header: a block-bodied closure with no return statement at
    // all infers as `Null Function(Event)`, and `.toJS` only has an
    // extension for the void shape.
    _responsiveResizeListener = (web.Event _) {
      final next = web.window.innerWidth;
      if (mounted && next != _viewportWidth) setState(() => _viewportWidth = next);
      return;
    }.toJS;
    web.window.addEventListener('resize', _responsiveResizeListener);
  }

  /// Call once, from `dispose()`, before `super.dispose()`.
  void disposeResponsive() {
    if (_responsiveResizeListener != null) {
      web.window.removeEventListener('resize', _responsiveResizeListener);
    }
  }
}
