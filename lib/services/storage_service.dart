import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_plan.dart';

/// Persists the most recently generated [TripPlan] so the user
/// can reopen the app and see their last itinerary.
class StorageService {
  static const _kLastTripKey = 'estrave.last_trip.v1';

  Future<void> saveTrip(TripPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastTripKey, plan.encode());
  }

  Future<TripPlan?> loadTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastTripKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return TripPlan.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastTripKey);
  }
}
