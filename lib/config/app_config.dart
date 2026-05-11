/// App-wide configuration.
///
/// The Gemini API key is read from the `--dart-define=GEMINI_API_KEY=...`
/// compile-time flag so it never ends up in source control.
///
/// Run the app with:
/// ```
/// flutter run --dart-define=GEMINI_API_KEY=your_key_here
/// ```
class AppConfig {
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
