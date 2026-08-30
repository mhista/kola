// env.dart — compile-time constants, same String.fromEnvironment
// pattern as kola_dashboard/lib/config/env.dart (dart compile js has no
// .env file access — see build.sh).
//
// Deliberately NO Supabase config here, unlike kola_dashboard — this
// app never talks to Supabase Auth at all. See app.dart's header on
// why admin identity is a completely separate model.
abstract class Env {
  static const kolaServerUrl = String.fromEnvironment(
    'KOLA_SERVER_URL',
    defaultValue: 'http://localhost:8080',
  );
}
