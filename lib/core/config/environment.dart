/// Tspace Environment Configuration
///
/// Centralizes configuration values (like the API base URL) and
/// supports compile-time variables so the app can swap environments.
library;

abstract final class Environment {
  /// The base URL of the Laravel API.
  ///
  /// Defaults to the local Laravel development server URL.
  /// To override at build time, run:
  /// `flutter run --dart-define=API_URL=https://api.tspace.me/api/v1`
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
}
