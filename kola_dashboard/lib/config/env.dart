// env.dart — compile-time constants, same pattern as
// kola_landing/lib/config/env.dart (String.fromEnvironment, since
// `dart compile js` has no .env file access — see build.sh).
//
// SUPABASE_URL / SUPABASE_ANON_KEY are safe to bake into this public
// bundle — same reasoning as kola_landing's copy of this file: the anon
// key is designed to be public, Row Level Security (enforced
// server-side by kola_server, not by this key) is what actually
// protects data. This dashboard never talks to Supabase's REST/Postgrest
// API directly for real data — only to Supabase Auth, for login/signup
// (see services/auth_service.dart) — everything else goes through
// KOLA_SERVER_URL via kola_client, per the architecture decision in
// docs/DEVELOPMENT_PLAN.md Phase 4a.
//
// KOLA_SERVER_URL is the public base URL of the deployed kola_server
// Serverpod instance (e.g. https://api.kolaa.dev, or http://localhost:8080
// for local dev against a server started with `dart run bin/main.dart`).
abstract class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const kolaServerUrl = String.fromEnvironment(
    'KOLA_SERVER_URL',
    defaultValue: 'http://localhost:8080',
  );

  // TASK #138 — the deployed kola_docs site's public base URL, so the
  // sidebar's Docs link (sidebar_nav.dart) points somewhere real instead
  // of a dead '#'. Same String.fromEnvironment pattern as kolaServerUrl
  // above — kola_docs/deploy.sh's own suggested domain is the default,
  // but it's overridable at build time (--dart-define=KOLA_DOCS_URL=...)
  // since that domain isn't confirmed/live yet, just a suggestion in that
  // script's own echo'd instructions.
  static const kolaDocsUrl = String.fromEnvironment(
    'KOLA_DOCS_URL',
    defaultValue: 'https://docs.kolaa.co',
  );
}
