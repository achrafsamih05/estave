import 'dart:convert';

/// Data model for the Estrave trip plan.
///
/// Matches the strict Gemini schema:
/// ```json
/// {
///   "trip_name": "",
///   "total_budget": 0,
///   "days": [
///     {
///       "day": 1,
///       "activities": [
///         { "time": "", "desc": "", "location": "" }
///       ]
///     }
///   ]
/// }
/// ```
///
/// Every `fromJson` is null-safe: any missing or mistyped field
/// falls back to a sensible default, so the UI never crashes on a
/// malformed AI response.

// ---------- Activity ----------

class Activity {
  final String time;
  final String desc;
  final String location;

  const Activity({
    required this.time,
    required this.desc,
    required this.location,
  });

  static const Activity empty = Activity(time: '', desc: '', location: '');

  /// Defensive: accepts any map or null and coerces each field.
  factory Activity.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Activity.empty;
    return Activity(
      time: _asString(json['time']),
      desc: _asString(json['desc']),
      location: _asString(json['location']),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'desc': desc,
        'location': location,
      };
}

// ---------- TripDay ----------

class TripDay {
  final int day;
  final List<Activity> activities;

  const TripDay({required this.day, required this.activities});

  factory TripDay.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TripDay(day: 0, activities: []);

    final rawActivities = json['activities'];
    final activities = rawActivities is List
        ? rawActivities
            .whereType<Map>()
            .map((e) => Activity.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <Activity>[];

    return TripDay(
      day: _asInt(json['day']),
      activities: activities,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'activities': activities.map((a) => a.toJson()).toList(),
      };
}

// ---------- TripPlan ----------

class TripPlan {
  final String tripName;
  final double totalBudget;
  final List<TripDay> days;

  const TripPlan({
    required this.tripName,
    required this.totalBudget,
    required this.days,
  });

  static const TripPlan empty =
      TripPlan(tripName: '', totalBudget: 0, days: []);

  /// True when the plan has no meaningful content.
  bool get isEmpty => days.isEmpty;

  /// Total number of days in the plan.
  int get totalDays => days.length;

  /// Defensive factory: guards against every field being missing,
  /// `null`, or of the wrong runtime type. Guarantees a usable object.
  factory TripPlan.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TripPlan.empty;

    final rawDays = json['days'];
    final days = rawDays is List
        ? rawDays
            .whereType<Map>()
            .map((e) => TripDay.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <TripDay>[];

    return TripPlan(
      tripName: _asString(json['trip_name']),
      totalBudget: _asDouble(json['total_budget']),
      days: days,
    );
  }

  Map<String, dynamic> toJson() => {
        'trip_name': tripName,
        'total_budget': totalBudget,
        'days': days.map((d) => d.toJson()).toList(),
      };

  /// Serialize to a persistable JSON string (used by SharedPreferences).
  String encode() => jsonEncode(toJson());

  /// Parse from a persisted JSON string. Throws [FormatException] if
  /// the string isn't a valid JSON object.
  static TripPlan decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }
    return TripPlan.fromJson(decoded);
  }
}

// ---------- Private coercion helpers ----------

String _asString(dynamic v) {
  if (v == null) return '';
  return v.toString();
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
