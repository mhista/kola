/// Compile-time constants for the Kola landing page.
///
/// This is a public, client-mode Jaspr bundle — anything here ends up
/// readable in the compiled JS, which is fine: the Supabase ANON key is
/// designed to be public (Row Level Security is what actually protects
/// data, not secrecy of this key). Never put the service_role key here.
///
/// Build with:
///   dart compile js -O2 -o web/main.dart.js lib/main.dart \
///     -DSUPABASE_URL=https://xxxx.supabase.co \
///     -DSUPABASE_ANON_KEY=eyJh...
///
/// See build.sh, which wraps this exact command with env-var validation.
abstract class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// 'waitlist' (pre-launch, the default) or 'launched'. Deliberately not a
  /// runtime UI control — anyone viewing the page shouldn't be able to flip
  /// it. Set at build time instead:
  ///   dart compile js ... -DLAUNCH_MODE=launched
  /// See build.sh, and lib/app.dart's use of this value.
  static const launchMode = String.fromEnvironment(
    'LAUNCH_MODE',
    defaultValue: 'waitlist',
  );
}
