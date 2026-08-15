// kola_icon.dart — one place that turns an [Icons] path into an <svg>.
//
// WHY A HELPER AND NOT INLINE SVG AT EACH CALL SITE:
//
// Every icon in the design shares the same six attributes — 24x24
// viewBox, fill:none, stroke:currentColor, width 1.8, round caps, round
// joins. Written by hand at ~120 call sites, some of them will be wrong,
// and the failure is quiet: a missing `fill="none"` gives a solid black
// blob, a missing `stroke="currentColor"` gives an icon that ignores the
// theme and stays visible-but-wrong in light mode. Neither throws.
//
// `currentColor` is doing real work here. It means an icon inherits the
// colour of whatever it sits in, so a nav row changing from muted to
// accent on hover recolours its icon with no icon-specific rule — and
// so no icon needs a hardcoded hex that would then need a light-mode
// variant.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Renders one [Icons] path.
///
/// [size] is in px and applies to both dimensions — every icon in this
/// design is square, and a non-square one would be a mistake rather than
/// an intent.
///
/// [strokeWidth] defaults to the design's 1.8. The export uses 1.9 and
/// 2.0 in exactly two places (the composer mic and the send arrow),
/// where a slightly heavier stroke reads better at small sizes against
/// a filled background — hence the parameter rather than a constant.
Component kolaIcon(
  String path, {
  double size = 16,
  double strokeWidth = 1.8,
  String? extraStyle,
}) {
  final style = extraStyle == null ? '' : ' style="$extraStyle"';
  return RawText(
    '<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="$strokeWidth" '
    'stroke-linecap="round" stroke-linejoin="round" '
    'aria-hidden="true" focusable="false"$style>'
    '<path d="$path"/>'
    '</svg>',
  );
}

/// The kolaa droplet.
///
/// NOT in [Icons] and not drawn by [kolaIcon], because it breaks that
/// contract in every respect: it is a filled shape on a 26x26 viewBox
/// with no stroke. Forcing it through the same helper would mean adding
/// a fill parameter that 27 of 28 icons ignore.
///
/// The fill is the accent by default and follows the theme, but accepts
/// an override for the one place it sits on an accent-filled surface
/// and has to invert.
Component kolaMark({double size = 20, String fill = 'var(--kola-accent)'}) {
  return RawText(
    '<svg width="$size" height="$size" viewBox="0 0 26 26" fill="none" '
    'aria-hidden="true" focusable="false">'
    '<path d="M13 2C13 2 6 8.5 6 15.5C6 20 9 24 13 24C17 24 20 20 20 15.5C20 8.5 13 2 13 2Z" '
    'fill="$fill"/>'
    '</svg>',
  );
}
