import 'dart:convert';

/// A single activity within a day's itinerary.
///
/// Example JSON:
/// ```json
/// {
///   "time": "09:00",
///   "activity": "Visit the Louvre",
///   "description": "Explore world-class art collections",
///   "cost": 17.0
/// }
/// ```
class DailyActivity {
  final String time;
  final String activity;
  final String description;
  final double cost;

  const DailyActivity({
    required this.time,
    required this.activity,
    required this.description,
    required this.cost,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      time: (json['time'] ?? '').toString(),
      activity: (json['activity'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      cost: _parseDouble(json['cost']),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'activity': activity,
        'description': description,
        'cost': cost,
      };
}

/// A single day in the trip plan, containing an ordered list of activities.
class TripDay {
  final int day;
  final String? title;
  final List<DailyActivity> activities;

  const TripDay({
    required this.day,
    this.title,
    required this.activities,
  });

  /// Returns the total cost of all activities in this day.
  double get dayCost =>
      activities.fold(0.0, (sum, a) => sum + a.cost);

  factory TripDay.fromJson(Map<String, dynamic> json) {
    final rawActivities = json['activities'] as List? ?? [];
    return TripDay(
      day: _parseInt(json['day']),
      title: json['title']?.toString(),
      activities: rawActivities
          .whereType<Map>()
          .map((e) => DailyActivity.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'title': title,
        'activities': activities.map((a) => a.toJson()).toList(),
      };
}

/// The full trip plan returned by Gemini.
///
/// Expected strict JSON shape:
/// ```json
/// {
///   "destination": "Paris, France",
///   "total_days": 3,
///   "budget_estimate": 850.0,
///   "currency": "USD",
///   "summary": "A cultural 3-day journey through Paris.",
///   "daily_activities": [
///     {
///       "day": 1,
///       "title": "Classic Paris",
///       "activities": [
///         { "time": "09:00", "activity": "...", "description": "...", "cost": 17.0 }
///       ]
///     }
///   ]
/// }
/// ```
class TripPlan {
  final String destination;
  final int totalDays;
  final double budgetEstimate;
  final String currency;
  final String summary;
  final List<TripDay> dailyActivities;

  const TripPlan({
    required this.destination,
    required this.totalDays,
    required this.budgetEstimate,
    required this.currency,
    required this.summary,
    required this.dailyActivities,
  });

  /// Total cost computed from all daily activities (fallback-friendly).
  double get computedTotalCost =>
      dailyActivities.fold(0.0, (sum, d) => sum + d.dayCost);

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = json['daily_activities'] as List? ?? [];
    return TripPlan(
      destination: (json['destination'] ?? '').toString(),
      totalDays: _parseInt(json['total_days']),
      budgetEstimate: _parseDouble(json['budget_estimate']),
      currency: (json['currency'] ?? 'USD').toString(),
      summary: (json['summary'] ?? '').toString(),
      dailyActivities: rawDays
          .whereType<Map>()
          .map((e) => TripDay.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'destination': destination,
        'total_days': totalDays,
        'budget_estimate': budgetEstimate,
        'currency': currency,
        'summary': summary,
        'daily_activities':
            dailyActivities.map((d) => d.toJson()).toList(),
      };

  /// Serialize to a persistable JSON string.
  String encode() => jsonEncode(toJson());

  /// Parse from a persisted JSON string.
  static TripPlan decode(String source) =>
      TripPlan.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

// ---------- Helpers ----------

double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}
