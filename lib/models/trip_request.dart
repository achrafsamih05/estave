/// User-provided preferences used to build the Gemini prompt.
enum BudgetLevel { budget, midRange, luxury }

extension BudgetLevelX on BudgetLevel {
  String get label => switch (this) {
        BudgetLevel.budget => 'Budget',
        BudgetLevel.midRange => 'Mid-Range',
        BudgetLevel.luxury => 'Luxury',
      };

  String get description => switch (this) {
        BudgetLevel.budget =>
          'Hostels, street food, free attractions',
        BudgetLevel.midRange =>
          '3-star hotels, casual dining, popular sites',
        BudgetLevel.luxury =>
          '5-star hotels, fine dining, premium experiences',
      };
}

class TripRequest {
  final String destination;
  final int durationDays;
  final BudgetLevel budget;
  final List<String> interests;

  const TripRequest({
    required this.destination,
    required this.durationDays,
    required this.budget,
    required this.interests,
  });
}
