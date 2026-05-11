import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_plan.dart';

/// Persists the most recently saved [TripPlan] to SharedPreferences
/// so the user can reopen the app and see their last itinerary.
///
/// Keys are versioned (`.v2`) so schema migrations don't crash older installs.
class StorageService {
  static const _kLastTripKey = 'estrave.last_trip.v2';

  Future<void> saveTrip(TripPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastTripKey, plan.encode());
  }

  /// Returns the saved plan, or `null` if absent, corrupt, or empty
  /// (e.g. from a previous schema that no longer decodes cleanly).
  Future<TripPlan?> loadTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastTripKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final plan = TripPlan.decode(raw);
      if (plan.isEmpty) return null;
      return plan;
    } catch (_) {
      // Old schema or malformed string; ignore it silently.
      await prefs.remove(_kLastTripKey);
      return null;
    }
  }

  Future<void> clearTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastTripKey);
  }
}
