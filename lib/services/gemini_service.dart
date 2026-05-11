import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/trip_plan.dart';
import '../models/trip_request.dart';

/// Thrown when Gemini's response cannot be parsed into a [TripPlan].
/// Carries the raw response for debugging.
class GeminiParseException implements Exception {
  final String message;
  final String? rawResponse;
  GeminiParseException(this.message, {this.rawResponse});

  @override
  String toString() => 'GeminiParseException: $message';
}

/// Wrapper around the `google_generative_ai` package.
///
/// Responsibilities:
/// - Enforce the "local tour guide" persona via [Content.system].
/// - Force raw JSON output via `responseMimeType: application/json`.
/// - Send a prompt containing an explicit `Context:` block and the
///   literal JSON template the model must fill in.
/// - Parse the reply into a [TripPlan], with fallback recovery if the
///   model wraps JSON in markdown fences.
class GeminiService {
  final GenerativeModel _model;

  GeminiService({
    required String apiKey,
    String modelName = 'gemini-1.5-flash',
  })  : assert(apiKey.length > 0, 'Gemini API key cannot be empty.'),
        _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            // Forces the server to emit a JSON mime type.
            responseMimeType: 'application/json',
            temperature: 0.8,
          ),
          systemInstruction: Content.system(_systemInstruction),
        );

  // ---------------------------------------------------------------------------
  // Prompt engineering
  // ---------------------------------------------------------------------------

  static const String _systemInstruction = '''
You are "Estrave", an expert local tour guide AI with deep, first-hand
knowledge of destinations around the world.

HARD RULES (must never be broken):
1. Reply with EXACTLY ONE valid JSON object. No markdown. No code fences.
   No prose. No explanation before or after.
2. Your output MUST be parseable by `JSON.parse` on the first try.
3. Match the schema the user provides exactly. Do not add, rename, or
   remove any top-level key.
4. All numbers must be JSON numbers (not quoted strings).
5. All "time" values must use 24-hour "HH:mm" format.
6. Ground every activity in real places (neighborhood, street, or venue
   name) in the requested destination.
7. Respect the user's budget level and interests.
''';

  /// Builds the user-facing prompt with:
  /// - A `Context:` block explaining what Gemini is doing.
  /// - The literal JSON template (the shape you specified).
  /// - A short closing instruction forcing raw JSON output.
  String _buildPrompt(TripRequest request) {
    final interests = request.interests.isEmpty
        ? 'general sightseeing'
        : request.interests.join(', ');

    return '''
Context:
You are generating a travel itinerary for the Estrave mobile app.
The app will parse your response with JSON.parse(), so your output MUST
be a single raw JSON object that EXACTLY follows this template:

{"trip_name": "", "total_budget": 0, "days": [{"day": 1, "activities": [{"time": "", "desc": "", "location": ""}]}]}

Field contract:
- "trip_name": short catchy name for the trip (e.g. "3 Days in Tokyo").
- "total_budget": number, total estimated cost per person in USD (no currency symbol).
- "days": array of length ${request.durationDays}, one object per day, in order.
- "days[i].day": 1-based integer day number.
- "days[i].activities": 4-6 activities spanning morning, lunch, afternoon, and evening.
- "activities[j].time": 24-hour "HH:mm".
- "activities[j].desc": concise sentence describing what to do, including a practical local tip.
- "activities[j].location": the specific neighborhood, street, or venue name.

Trip request:
- Destination: ${request.destination}
- Duration: ${request.durationDays} day(s)
- Budget level: ${request.budget.label} (${request.budget.description})
- Interests: $interests

Output ONLY the raw JSON object. No markdown. No commentary.
''';
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Generates a trip plan from the given [request].
  ///
  /// Throws [GeminiParseException] if the response cannot be parsed
  /// into a non-empty [TripPlan].
  Future<TripPlan> generateTripPlan(TripRequest request) async {
    final prompt = _buildPrompt(request);

    final response = await _model.generateContent([Content.text(prompt)]);

    final raw = response.text?.trim();
    if (raw == null || raw.isEmpty) {
      throw GeminiParseException('Gemini returned an empty response.');
    }

    final jsonString = _extractJson(raw);

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw GeminiParseException(
          'Expected a JSON object, got ${decoded.runtimeType}.',
          rawResponse: raw,
        );
      }
      final plan = TripPlan.fromJson(decoded);
      if (plan.isEmpty) {
        throw GeminiParseException(
          'Parsed plan has no days. The AI likely returned an unexpected shape.',
          rawResponse: raw,
        );
      }
      return plan;
    } on GeminiParseException {
      rethrow;
    } catch (e) {
      throw GeminiParseException(
        'Failed to parse Gemini JSON: $e',
        rawResponse: raw,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Defensive: strips markdown fences and trims to the outermost
  /// JSON object if the model ignores instructions.
  String _extractJson(String raw) {
    var s = raw.trim();

    if (s.startsWith('```')) {
      final firstNewline = s.indexOf('\n');
      if (firstNewline != -1) {
        s = s.substring(firstNewline + 1);
      }
      if (s.endsWith('```')) {
        s = s.substring(0, s.length - 3);
      }
      s = s.trim();
    }

    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return s.substring(start, end + 1);
    }
    return s;
  }
}
