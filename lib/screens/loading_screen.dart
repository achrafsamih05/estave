import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';
import 'itinerary_screen.dart';

/// Shown while Gemini is generating an itinerary.
///
/// - Displays a pulsing globe animation.
/// - Rotates inspirational travel quotes every ~3 seconds.
/// - Listens to [TripProvider] and auto-navigates to [ItineraryScreen]
///   on success, or shows an error dialog on failure.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const _quotes = <String>[
    '"The world is a book, and those who do not travel read only one page." — Augustine',
    '"Travel makes one modest. You see what a tiny place you occupy in the world." — Flaubert',
    '"Jobs fill your pocket, but adventures fill your soul." — Jamie Lyn Beatty',
    '"To travel is to live." — Hans Christian Andersen',
    '"Life is short and the world is wide."',
    '"Not all those who wander are lost." — J.R.R. Tolkien',
  ];

  late final AnimationController _pulseController;
  int _quoteIndex = 0;
  Timer? _quoteTimer;
  bool _navigated = false;

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

  void _handleStatusChange(TripProvider provider) {
    if (_navigated) return;

    if (provider.status == TripStatus.success) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ItineraryScreen()),
      );
    } else if (provider.status == TripStatus.error) {
      _navigated = true;
      _showError(provider.errorMessage ?? 'Something went wrong.');
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oops!'),
        content: Text(
          'We could not build your itinerary.\n\n$message',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // back to input screen
              context.read<TripProvider>().reset();
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<TripProvider>(
        builder: (context, provider, _) {
          // React to state changes after build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleStatusChange(provider);
          });

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing globe
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
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Rotating quote
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
          );
        },
      ),
    );
  }
}
