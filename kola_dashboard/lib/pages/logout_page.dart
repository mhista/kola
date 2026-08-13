// logout_page.dart — the route behind "Log out".
//
// ── WHY THIS FILE EXISTS ─────────────────────────────────────────────
//
// Sidebar._profileEntries has always rendered Log out as
// `Link(to: '/logout')`, and '/logout' was never registered as a Route.
// Every redesigned page wears AppShell, AppShell draws Sidebar, so this
// affected the whole app: clicking Log out navigated to a path the
// router could not match, which painted nothing and left the session
// fully intact. The button looked broken because it WAS — not because
// sign-out failed, but because sign-out was never reached.
//
// The old chrome (sidebar_nav.dart / mobile_top_bar.dart) took an
// `onSignOut` callback and worked correctly, but those components are
// only mounted by DashboardHomePage at /home-legacy. The redesigned
// shell replaced them and did not carry the callback across.
//
// ── WHY A ROUTE RATHER THAN A CALLBACK THROUGH AppShell ──────────────
//
// The alternative fix is to thread `onSignOut` from app.dart through
// shellFor → AppShell → Sidebar and make the entry a button. That is
// more moving parts for the same result, and it would make Log out the
// one profile-menu entry that is not a link — the menu is built from a
// single `_profileEntries` list of (label, icon, route), and special
// casing one row is how that list starts rotting.
//
// A real /logout route keeps the menu uniform, and it means the URL is
// a legitimate destination: typing /logout, or hitting it from anywhere
// else in the product later, signs you out.
//
// ── WHY IT HARD-NAVIGATES INSTEAD OF LETTING _redirect DO IT ─────────
//
// app.dart's _redirect already sends an unauthenticated visitor to
// /login, so in principle clearing the session and calling setState is
// enough. It is not relied on here, for two reasons.
//
// First, correctness: jaspr_router evaluates `redirect` during route
// RESOLUTION. A setState that rebuilds the Router at the same location
// is not guaranteed to re-resolve, and if it does not, the owner is
// left staring at "Signing you out…" forever — a worse failure than
// the one being fixed, because it looks like a hang rather than a
// dead button.
//
// Second, and more important: a full document navigation is the
// stronger guarantee. Signing out should leave nothing behind, and
// in-memory state is state — the workspace list, the selected
// workspace, the access token held in App's `_session`, and whatever
// each page cached. Tearing the document down discards all of it at
// once, rather than trusting that every holder of a token releases it.
// Logout is precisely the moment to prefer a clean boot over a clever
// transition.
//
// `location.replace` rather than `location.href = …`: assigning to href
// pushes a history entry, so Back would return to /logout and sign the
// owner out again the moment they tried to go back to where they were.
// replace() swaps the current entry instead, which is the same reason
// the rest of the app moved off raw <a> tags for internal routes.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;

import '../theme.dart';

class LogoutPage extends StatefulComponent {
  const LogoutPage({required this.onSignOut});

  /// app.dart's _handleSignOut. Owns the actual clearing — the auth
  /// session in LocalStorage and the remembered workspace id — so that
  /// logic stays in one place and this page stays a transition.
  final void Function() onSignOut;

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  @override
  void initState() {
    super.initState();

    // Deferred off the current frame. onSignOut calls setState on an
    // ANCESTOR (App), and doing that synchronously from a descendant's
    // initState mutates a tree that is mid-build. Future.microtask runs
    // it immediately after this frame settles, which is late enough to
    // be safe and early enough that nothing renders in between.
    Future.microtask(() {
      if (!mounted) return;
      component.onSignOut();
      web.window.location.replace('/login');
    });
  }

  @override
  Component build(BuildContext context) => div(
        attributes: {
          'style': 'min-height:100vh;display:flex;align-items:center;'
              'justify-content:center;background:${KolaVar.bg};'
              'padding:${KolaSpace.lg};box-sizing:border-box',
        },
        [
          div(
            attributes: {
              'style': 'text-align:center;font-family:${KolaFonts.display};'
                  'font-size:${KolaType.body};color:${KolaVar.muted}',
            },
            // Present tense and no promise of what happens next: the
            // document is about to be replaced, so this is on screen
            // for a moment at most. It exists so a slow connection
            // shows something rather than a white page — the exact
            // failure this file was written to remove.
            [Component.text('Signing you out…')],
          ),
        ],
      );
}
