import 'package:flutter/foundation.dart';

import '../models/trip_plan.dart';
import '../models/trip_request.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';

/// UI-facing state of the trip-generation flow.
enum TripStatus { idle, loading, success, error }

/// Central state holder for the Estrave app.
///
/// Responsibilities:
/// - Drive the UI state machine (idle -> loading -> success/error).
/// - Call [GeminiService] and expose the resulting [TripPlan].
/// - Persist / restore the last saved trip via [StorageService] on
///   explicit user action ("Save Trip" button).
/// - Remember the last [TripRequest] so the UI can retry on error.
class TripProvider extends ChangeNotifier {
  TripProvider({
    required GeminiService geminiService,
    StorageService? storageService,
  })  : _gemini = geminiService,
        _storage = storageService ?? StorageService();

  final GeminiService _gemini;
  final StorageService _storage;

  // --- state ---
  TripStatus _status = TripStatus.idle;
  TripPlan? _plan;
  String? _errorMessage;
  TripRequest? _lastRequest;
  bool _isSaved = false;
  bool _isSaving = false;

  // --- getters ---
  TripStatus get status => _status;
  TripPlan? get plan => _plan;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == TripStatus.loading;
  bool get hasError => _status == TripStatus.error;
  bool get isSaved => _isSaved;
  bool get isSaving => _isSaving;
  bool get canRetry => _lastRequest != null;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Loads the last persisted trip on app start, if any.
  /// The restored plan is marked as already saved.
  Future<void> restoreLastTrip() async {
    final saved = await _storage.loadTrip();
    if (saved != null && !saved.isEmpty) {
      _plan = saved;
      _status = TripStatus.success;
      _isSaved = true;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Generation
  // ---------------------------------------------------------------------------

  /// Calls Gemini to generate a new itinerary.
  /// Does NOT auto-save — the user must explicitly tap "Save Trip".
  Future<void> generate(TripRequest request) async {
    _lastRequest = request;
    _status = TripStatus.loading;
    _errorMessage = null;
    _isSaved = false;
    notifyListeners();

    try {
      final plan = await _gemini.generateTripPlan(request);
      _plan = plan;
      _status = TripStatus.success;
    } catch (e, st) {
      _errorMessage = _humanize(e);
      _status = TripStatus.error;
      if (kDebugMode) {
        debugPrint('TripProvider.generate failed: $e\n$st');
      }
    } finally {
      notifyListeners();
    }
  }

  /// Re-runs [generate] using the most recent [TripRequest].
  /// Safe to call when [canRetry] is true.
  Future<void> retry() async {
    final req = _lastRequest;
    if (req == null) return;
    await generate(req);
  }

  // ---------------------------------------------------------------------------
  // Persistence (explicit user action)
  // ---------------------------------------------------------------------------

  /// Persists the currently loaded plan to [StorageService].
  /// Returns `true` on success, `false` if there was nothing to save or
  /// if persistence failed.
  Future<bool> saveCurrentTrip() async {
    final plan = _plan;
    if (plan == null || plan.isEmpty) return false;

    _isSaving = true;
    notifyListeners();

    try {
      await _storage.saveTrip(plan);
      _isSaved = true;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('saveCurrentTrip failed: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Clears both in-memory and persisted state, returning to the
  /// input screen's initial state.
  Future<void> reset() async {
    _status = TripStatus.idle;
    _plan = null;
    _errorMessage = null;
    _isSaved = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _humanize(Object e) {
    final raw = e.toString();
    // Trim the leading "Exception: " noise for a friendlier SnackBar message.
    if (raw.startsWith('Exception: ')) return raw.substring(11);
    return raw;
  }
}
