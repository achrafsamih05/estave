import 'package:flutter/foundation.dart';

import '../models/trip_plan.dart';
import '../models/trip_request.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';

/// Represents the current state of the trip-generation flow.
enum TripStatus { idle, loading, success, error }

/// Central state holder for the app:
/// - Kicks off Gemini calls via [GeminiService].
/// - Exposes the resulting [TripPlan] to the UI.
/// - Persists / restores the last trip via [StorageService].
class TripProvider extends ChangeNotifier {
  TripProvider({
    required GeminiService geminiService,
    StorageService? storageService,
  })  : _gemini = geminiService,
        _storage = storageService ?? StorageService();

  final GeminiService _gemini;
  final StorageService _storage;

  TripStatus _status = TripStatus.idle;
  TripStatus get status => _status;

  TripPlan? _plan;
  TripPlan? get plan => _plan;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == TripStatus.loading;

  /// Loads the last persisted trip on app start, if any.
  Future<void> restoreLastTrip() async {
    final saved = await _storage.loadTrip();
    if (saved != null) {
      _plan = saved;
      _status = TripStatus.success;
      notifyListeners();
    }
  }

  /// Triggers Gemini to generate a new itinerary.
  ///
  /// Updates [status] to drive the UI state machine (loading -> success/error).
  Future<void> generate(TripRequest request) async {
    _status = TripStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final plan = await _gemini.generateTripPlan(request);
      _plan = plan;
      _status = TripStatus.success;
      await _storage.saveTrip(plan);
    } catch (e) {
      _errorMessage = e.toString();
      _status = TripStatus.error;
      if (kDebugMode) {
        debugPrint('TripProvider.generate failed: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  /// Reset state back to the input screen.
  void reset() {
    _status = TripStatus.idle;
    _plan = null;
    _errorMessage = null;
    notifyListeners();
  }
}
