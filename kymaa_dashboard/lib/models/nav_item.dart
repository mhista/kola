// nav_item.dart — one entry in the sidebar's primary nav list, matching
// Kola Dashboard Shell.dc.html's navDefs.

class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    required this.href,
    this.active = false,
  });

  final String icon;
  final String label;

  // '#' for every page not yet built (everything except Home right
  // now) — deliberate placeholder, not a bug. Which of these become
  // real routes within this one Jaspr app vs. separate compiled entry
  // points is an open architecture question left for Phase 4d/4e, when
  // there's an actual second page to route to and a real decision to
  // make instead of a guess.
  final String href;
  final bool active;
}
