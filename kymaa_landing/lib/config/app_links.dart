// app_links.dart — external destinations this site links out to.
//
// ONE PLACE, because the dashboard URL appears on three separate
// controls ("Start free" in the header, "Sign in", and the pricing
// plan CTAs). Hardcoded at each call site, they drift: someone updates
// the header, the pricing button keeps pointing at the old host, and
// the one nobody clicks during testing is the one that stays broken.
//
// ── THIS IS THE COMPETITION ENTRY ────────────────────────────────────
//
// kymaa_landing is the frozen, renamed copy of the original landing
// page. It deploys to the Cloudflare Pages project "kola" (a historical
// name — see deploy.sh) and serves kymaa.online.
//
// It points at kymaa_dashboard, NOT at the redesigned kola dashboard.
// The whole point of the split is that this pair keeps working exactly
// as it does today while the kola redesign continues separately.

abstract class AppLinks {
  /// The kymaa dashboard.
  ///
  /// Served by the "kymaa-dashboard" Pages project — see
  /// kymaa_dashboard/deploy.sh. THE CUSTOM DOMAIN MUST BE ATTACHED IN
  /// CLOUDFLARE BEFORE THIS RESOLVES; wrangler does not manage custom
  /// domains, so a fresh deploy alone leaves this dead.
  static const dashboard = 'https://dash.kymaa.online';
}
