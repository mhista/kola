// back_link.dart — task #139 (dashboard polish pass): every standalone
// page (reachable from a real nav link, not via SidebarNav itself) had
// its own copy-pasted "← Home" text link — a plain, small, muted-gray
// unicode arrow with no real visual weight, which is what the owner
// flagged as needing an "arrow icon." Rather than introduce a whole SVG
// icon system for one glyph (this app's only other icons are emoji,
// per sidebar_nav.dart's NavItem.icon fields — see theme.dart's header
// for why that choice stands), this gives the SAME unicode arrow more
// presence: its own sized+weighted span, a bit more color contrast
// (navInactiveText instead of the dimmer mutedSecondary), and a
// slightly bolder label — one canonical version other pages import
// instead of nine slightly-different copies drifting further apart
// over time (the same class of drift this project has caught and fixed
// before with constructor signatures — see tool/test_builtin_errand.dart's
// fix history).

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../theme.dart';

/// A "← <label>" navigation link in this dashboard's standard weight —
/// [to] defaults to Home ('/'), the overwhelmingly common case; every
/// current call site uses the default.
Component backLink({String to = '/', String label = 'Home'}) => Link(
  to: to,
  attributes: {
    'style':
        'display:inline-flex;align-items:center;gap:6px;color:${KolaDashboardColors.navInactiveText};'
        'text-decoration:none;font-size:13.5px;font-weight:600',
  },
  children: [
    span(attributes: {'style': 'font-size:15px;line-height:1'}, [Component.text('←')]),
    Component.text(label),
  ],
);
