/// Supabase project configuration.
///
/// Replace the placeholder values with your project's URL and anon key
/// (Supabase dashboard → Project Settings → API), or inject them at build
/// time: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fqdlpuvuyfvrceufwfbl.supabase.co',
  );

  /// Publishable (or legacy anon) API key.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGxwdXZ1eWZ2cmNldWZ3ZmJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxOTY4NDcsImV4cCI6MjA5ODc3Mjg0N30.540OaidZQ8gnT0wbKUDsLL_dQ-99ABpWRPfuiDDOpK8',
  );

  /// Google OAuth *web* client ID — required by Supabase to validate the
  /// idToken from native Google sign-in (Supabase dashboard → Auth →
  /// Providers → Google).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'REPLACE_WITH_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com',
  );
}
