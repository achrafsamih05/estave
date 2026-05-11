import 'package:flutter/material.dart';

import '../models/trip_plan.dart';
import 'cost_chip.dart';

/// A single timeline entry used on the [ItineraryScreen].
///
/// Renders a vertical line with a dot on the left, the time above, and
/// an activity card to the right. [isLast] hides the trailing connector.
class TimelineTile extends StatelessWidget {
  final DailyActivity activity;
  final bool isLast;
  final String currency;

  const TimelineTile({
    super.key,
    required this.activity,
    required this.isLast,
    this.currency = 'USD',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Timeline rail ---
          SizedBox(
            width: 62,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Text(
                  activity.time,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),

          // --- Activity card ---
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.activity,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CostChip(
                            amount: activity.cost,
                            currency: currency,
                          ),
                        ],
                      ),
                      if (activity.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          activity.description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
