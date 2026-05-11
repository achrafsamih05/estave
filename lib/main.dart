import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'providers/trip_provider.dart';
import 'screens/input_screen.dart';
import 'services/gemini_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const EstraveApp());
}

class EstraveApp extends StatelessWidget {
  const EstraveApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Build the Gemini service once. If no key is provided via
    // --dart-define, the MissingApiKeyScreen is shown instead of crashing.
    if (!AppConfig.hasGeminiKey) {
      return MaterialApp(
        title: 'Estrave',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _MissingApiKeyScreen(),
      );
    }

    final geminiService = GeminiService(apiKey: AppConfig.geminiApiKey);
    final storageService = StorageService();

    return ChangeNotifierProvider(
      create: (_) => TripProvider(
        geminiService: geminiService,
        storageService: storageService,
      )..restoreLastTrip(),
      child: MaterialApp(
        title: 'Estrave',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const InputScreen(),
      ),
    );
  }
}

/// Friendly screen shown when the developer forgot to pass --dart-define=GEMINI_API_KEY.
class _MissingApiKeyScreen extends StatelessWidget {
  const _MissingApiKeyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.key_off, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Gemini API key missing',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Run the app with a compile-time key:\n\n'
                  'flutter run --dart-define=GEMINI_API_KEY=your_key_here',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
