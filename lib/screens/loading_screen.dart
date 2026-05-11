import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';
import 'itinerary_screen.dart';

/// Shown while Gemini is generating an itinerary.
///
/// - Pulsing globe animation with rotating travel quotes.
/// - Listens to [TripProvider] and:
///   - Navigates to [ItineraryScreen] on success.
///   - Pops back to the input screen and shows a SnackBar with a
///     "Retry" action on error.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const _quotes = <String>[
    '"The world is a book, and those who do not travel read only one page." - Augustine',
    '"Travel makes one modest. You see what a tiny place you occupy in the world." - Flaubert',
    '"Jobs fill your pocket, but adventures fill your soul." - Jamie Lyn Beatty',
    '"To travel is to live." - Hans Christian Andersen',
    '"Life is short and the world is wide."',
    '"Not all those who wander are lost." - J.R.R. Tolkien',
  ];

  late final AnimationController _pulseController;
  int _quoteIndex = 0;
  Timer? _quoteTimer;
  bool _navigated = false; // Guard against double-navigation.

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _quoteTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _quoteIndex = (_quoteIndex + 1) % _quotes.length);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _quoteTimer?.cancel();
    super.dispose();
  }

  /// Reacts to provider state changes.
  void _handleStatusChange(TripProvider provider) {
    if (_navigated || !mounted) return;

    if (provider.status == TripStatus.success) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ItineraryScreen()),
      );
      return;
    }

    if (provider.status == TripStatus.error) {
      _navigated = true;
      final errorMessage =
          provider.errorMessage ?? 'Something went wrong. Please try again.';

      // Pop back to the input screen so the SnackBar appears above it.
      Navigator.of(context).pop();

      // Defer the SnackBar until after the pop animation settles.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRetrySnackBar(errorMessage);
      });
    }
  }

  void _showRetrySnackBar(String message) {
    // We use the root navigator's context so the SnackBar shows on the
    // screen we just popped back to (InputScreen).
    final rootContext = _rootContextOrNull();
    if (rootContext == null) return;

    final provider = rootContext.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(rootContext);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        backgroundColor: Theme.of(rootContext).colorScheme.error,
        content: Text(
          'Trip generation failed.\n$message',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            if (!provider.canRetry) return;
            provider.retry();
            Navigator.of(rootContext).push(
              MaterialPageRoute(builder: (_) => const LoadingScreen()),
            );
          },
        ),
      ),
    );
  }

  /// Best-effort way to get the first-route context after popping.
  BuildContext? _rootContextOrNull() {
    if (!mounted) return null;
    return context;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<TripProvider>(
        builder: (context, provider, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleStatusChange(provider);
          });

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                // Cap the content width on tablet / web.
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final t = _pulseController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 180 + (40 * t),
                                height: 180 + (40 * t),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary
                                      .withValues(alpha: 0.08 * (1 - t)),
                                ),
                              ),
                              Container(
                                width: 140 + (20 * t),
                                height: 140 + (20 * t),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary
                                      .withValues(alpha: 0.16 * (1 - t)),
                                ),
                              ),
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      scheme.primary,
                                      scheme.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.public,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'Crafting your journey...',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Our AI local guide is picking the best spots for you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius:
                              BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 48),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Padding(
                          key: ValueKey(_quoteIndex),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _quotes[_quoteIndex],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade800,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
