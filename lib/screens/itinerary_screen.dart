import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/trip_plan.dart';
import '../providers/trip_provider.dart';
import '../widgets/timeline_tile.dart';

/// Displays the generated [TripPlan] as a clean, scrollable timeline
/// with per-day sections and a total-cost header.
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final plan = provider.plan;

    if (plan == null) {
      return const Scaffold(
        body: Center(child: Text('No itinerary yet.')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _HeaderSliver(plan: plan),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList.separated(
              itemCount: plan.dailyActivities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, i) => _DaySection(
                day: plan.dailyActivities[i],
                currency: plan.currency,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: () {
              context.read<TripProvider>().reset();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Plan Another Trip'),
          ),
        ),
      ),
    );
  }
}

/// Gradient hero header showing destination + totals.
class _HeaderSliver extends StatelessWidget {
  final TripPlan plan;
  const _HeaderSliver({required this.plan});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currencyFmt = NumberFormat.simpleCurrency(name: plan.currency);

    // Fallback: if Gemini's budget_estimate is 0, sum activity costs.
    final total =
        plan.budgetEstimate > 0 ? plan.budgetEstimate : plan.computedTotalCost;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primary.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Icon(Icons.bookmark_border, color: Colors.white),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.place, color: Colors.white70, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'YOUR TRIP',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                plan.destination,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  height: 1.1,
                ),
              ),
              if (plan.summary.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  plan.summary,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  _Stat(
                    icon: Icons.calendar_month,
                    label: 'Duration',
                    value: '${plan.totalDays} days',
                  ),
                  const SizedBox(width: 12),
                  _Stat(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Est. Budget',
                    value: currencyFmt.format(total),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final TripDay day;
  final String currency;
  const _DaySection({required this.day, required this.currency});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currencyFmt = NumberFormat.simpleCurrency(name: currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Day ${day.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                day.title ?? 'Explore',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            Text(
              currencyFmt.format(day.dayCost),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(day.activities.length, (i) {
          return TimelineTile(
            activity: day.activities[i],
            isLast: i == day.activities.length - 1,
            currency: currency,
          );
        }),
      ],
    );
  }
}
