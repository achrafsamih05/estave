import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/trip_plan.dart';
import '../providers/trip_provider.dart';

/// Final result screen.
///
/// - Scrollable `ListView.builder` for day-by-day content.
/// - Each day rendered as an `ExpansionTile` (first day expanded by default).
/// - "Save Trip" button persists the plan via SharedPreferences.
/// - Responsive: content is centered and capped at 720 px on wide screens.
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  static const double _maxContentWidth = 720;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final plan = provider.plan;

    if (plan == null || plan.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Trip')),
        body: const Center(child: Text('No itinerary to display yet.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _TripHeader(plan: plan)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  sliver: SliverList(
                    // ListView.builder equivalent inside a CustomScrollView,
                    // so the header scrolls with the list.
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _DayCard(
                        day: plan.days[index],
                        initiallyExpanded: index == 0,
                      ),
                      childCount: plan.days.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomActions(maxWidth: _maxContentWidth),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _TripHeader extends StatelessWidget {
  final TripPlan plan;
  const _TripHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currencyFmt = NumberFormat.simpleCurrency(name: 'USD');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
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
              Consumer<TripProvider>(
                builder: (_, p, __) => Icon(
                  p.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.travel_explore, color: Colors.white70, size: 18),
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
            plan.tripName.isEmpty ? 'Your Itinerary' : plan.tripName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(
                icon: Icons.calendar_month,
                label: 'Duration',
                value: '${plan.totalDays} day${plan.totalDays == 1 ? '' : 's'}',
              ),
              const SizedBox(width: 12),
              _Stat(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Total Budget',
                value: currencyFmt.format(plan.totalBudget),
              ),
            ],
          ),
        ],
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
                    overflow: TextOverflow.ellipsis,
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

// ---------------------------------------------------------------------------
// Day card
// ---------------------------------------------------------------------------

class _DayCard extends StatelessWidget {
  final TripDay day;
  final bool initiallyExpanded;

  const _DayCard({
    required this.day,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Theme(
          // Remove ExpansionTile's default dividers for a cleaner look.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: CircleAvatar(
              backgroundColor: scheme.primary,
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              'Day ${day.day}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${day.activities.length} activit${day.activities.length == 1 ? 'y' : 'ies'}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            children: day.activities.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No activities planned for this day.'),
                    ),
                  ]
                : List.generate(day.activities.length, (i) {
                    return _ActivityRow(
                      activity: day.activities[i],
                      isLast: i == day.activities.length - 1,
                    );
                  }),
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Activity activity;
  final bool isLast;

  const _ActivityRow({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time badge
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              activity.time.isEmpty ? '--:--' : activity.time,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.desc.isNotEmpty)
                  Text(
                    activity.desc,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                if (activity.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar (Save + Plan Another)
// ---------------------------------------------------------------------------

class _BottomActions extends StatelessWidget {
  final double maxWidth;
  const _BottomActions({required this.maxWidth});

  Future<void> _onSave(BuildContext context) async {
    final provider = context.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await provider.saveCurrentTrip();
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Trip saved!' : 'Could not save the trip.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Consumer<TripProvider>(
              builder: (context, provider, _) {
                final saving = provider.isSaving;
                final saved = provider.isSaved;

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<TripProvider>().reset();
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Plan Another'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: saving || saved
                            ? null
                            : () => _onSave(context),
                        icon: Icon(
                          saved ? Icons.check_circle : Icons.bookmark_add,
                        ),
                        label: Text(
                          saving
                              ? 'Saving...'
                              : saved
                                  ? 'Saved'
                                  : 'Save Trip',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
