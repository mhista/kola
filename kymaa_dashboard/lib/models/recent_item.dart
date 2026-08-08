// recent_item.dart — one entry in the sidebar's "Recent" list, matching
// Kola Dashboard Shell.dc.html's recentDefs. Mock data in this shell
// pass — real data (a workspace's actual recent bots/errands/knowledge
// uploads) is Phase 4d/4e's job, once real Supabase Auth + kola_client
// wiring exists (see pubspec.yaml's header for why that's deferred).

class RecentItem {
  const RecentItem({required this.icon, required this.label, required this.href});

  final String icon;
  final String label;
  final String href;
}
