// quick_action.dart — one card in the home page's quick-actions grid,
// matching Kola Dashboard Shell.dc.html's quickActionDefs. [colorIndex]
// picks this card's background/icon-background out of
// KolaDashboardColors.quickActionBgs/quickActionIconBgs — kept as an
// index (not baked-in colors) so the four cards stay tied to the
// theme's palette arrays instead of duplicating hex values here.

class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.href,
    required this.colorIndex,
  });

  final String icon;
  final String label;
  final String sub;
  final String href;
  final int colorIndex;
}
