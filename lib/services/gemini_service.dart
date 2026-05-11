import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/trip_plan.dart';
import '../models/trip_request.dart';

/// Thrown when Gemini responds with content that cannot be parsed as a TripPlan.
class GeminiParseException implements Exception {
  final String message;
  final String? rawResponse;
  GeminiParseException(this.message, {this.rawResponse});
  @override
  String toString() => 'GeminiParseException: $message';
}

/// Wrapper around the `google_generative_ai` package that:
/// - Uses a strict system instruction (acts as a local tour guide).
/// - Forces raw JSON output via `responseMimeType: application/json`.
/// - Parses the response into a [TripPlan].
class GeminiService {
  final GenerativeModel _model;

  GeminiService({required String apiKey, String modelName = 'gemini-1.5-flash'})
      : _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          // Force structured JSON responses.
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.8,
          ),
          systemInstruction: Content.system(_systemInstruction),
        );

  /// System prompt: Gemini behaves as a local tour guide and returns ONLY JSON.
  static const String _systemInstruction = '''
You are "Estrave", an expert local tour guide AI with deep knowledge of destinations around the world.

RULES (must be followed strictly):
1. You ALWAYS reply with a SINGLE valid JSON object. No markdown, no code fences, no prose, no commentary.
2. The JSON MUST exactly match the schema provided by the user.
3. All numeric fields MUST be numbers (not strings). Costs are per-person in the specified currency.
4. Times MUST be in 24-hour "HH:mm" format.
5. Activities must be realistic, chronological, and grounded in actual places, streets, or neighborhoods in the destination.
6. Tailor recommendations to the user's budget level and interests.
7. Never invent the schema or add extra top-level keys.
''';

  /// Generates a trip plan from the given [request].
  Future<TripPlan> generateTripPlan(TripRequest request) async {
    final userPrompt = _buildUserPrompt(request);

    final response = await _model.generateContent([
      Content.text(userPrompt),
    ]);

    final raw = response.text?.trim();
    if (raw == null || raw.isEmpty) {
      throw GeminiParseException('Gemini returned an empty response.');
    }

    final jsonString = _extractJson(raw);

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return TripPlan.fromJson(decoded);
    } catch (e) {
      throw GeminiParseException(
        'Failed to parse Gemini JSON: $e',
        rawResponse: raw,
      );
    }
  }

  /// Builds the user-facing prompt including the strict JSON schema.
  String _buildUserPrompt(TripRequest request) {
    final interests = request.interests.isEmpty
        ? 'general sightseeing'
        : request.interests.join(', ');

    return '''
Plan a detailed ${request.durationDays}-day trip to "${request.destination}".

Traveler preferences:
- Budget level: ${request.budget.label} (${request.budget.description})
- Interests: $interests
- Currency: USD

Output ONLY a raw JSON object matching this exact schema:

{
  "destination": "string - city and country",
  "total_days": ${request.durationDays},
  "budget_estimate": number (total estimated cost per person in USD for the full trip),
  "currency": "USD",
  "summary": "string - 1-2 sentence overview of the trip vibe",
  "daily_activities": [
    {
      "day": 1,
      "title": "string - short theme for the day",
      "activities": [
        {
          "time": "HH:mm",
          "activity": "string - short name of the activity",
          "description": "string - 1-2 sentences with practical local tips",
          "cost": number (per-person cost in USD, use 0 if free)
        }
      ]
    }
  ]
}

Include 4-6 activities per day spanning morning, lunch, afternoon, and evening.
Do NOT wrap the JSON in markdown. Return raw JSON only.
''';
  }

  /// Defensive: strip common markdown fences if a model ever slips them in.
  String _extractJson(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      // Remove ```json or ``` opening
      final firstNewline = s.indexOf('\n');
      if (firstNewline != -1) {
        s = s.substring(firstNewline + 1);
      }
      if (s.endsWith('```')) {
        s = s.substring(0, s.length - 3);
      }
      s = s.trim();
    }

    // Fallback: slice between the first '{' and last '}'.
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return s.substring(start, end + 1);
    }
    return s;
  }
}
