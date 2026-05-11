import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trip_request.dart';
import '../providers/trip_provider.dart';
import '../widgets/interest_chip.dart';
import 'loading_screen.dart';

/// Entry screen where the user describes the trip they want Gemini to plan.
class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();

  int _duration = 3;
  BudgetLevel _budget = BudgetLevel.midRange;
  final Set<String> _selectedInterests = {};

  static const _interests = <({String label, IconData icon})>[
    (label: 'Food', icon: Icons.restaurant),
    (label: 'History', icon: Icons.account_balance),
    (label: 'Nature', icon: Icons.park),
    (label: 'Adventure', icon: Icons.hiking),
    (label: 'Beaches', icon: Icons.beach_access),
    (label: 'Art', icon: Icons.palette),
    (label: 'Nightlife', icon: Icons.nightlife),
    (label: 'Shopping', icon: Icons.shopping_bag),
    (label: 'Family', icon: Icons.family_restroom),
  ];

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final request = TripRequest(
      destination: _destinationController.text.trim(),
      durationDays: _duration,
      budget: _budget,
      interests: _selectedInterests.toList(),
    );

    // Fire the Gemini call (state lives in the provider).
    context.read<TripProvider>().generate(request);

    // Navigate to loading; it will auto-route on success/error.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoadingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Responsive: cap content width on tablets / web.
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(theme: theme),
                const SizedBox(height: 28),

                // --- Destination ---
                _SectionLabel(icon: Icons.place_outlined, text: 'Destination'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _destinationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Tokyo, Japan',
                    prefixIcon: Icon(Icons.search),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Please enter a destination'
                      : null,
                ),
                const SizedBox(height: 24),

                // --- Duration ---
                _SectionLabel(
                  icon: Icons.calendar_month_outlined,
                  text: 'Duration',
                ),
                const SizedBox(height: 8),
                _DurationPicker(
                  value: _duration,
                  onChanged: (v) => setState(() => _duration = v),
                ),
                const SizedBox(height: 24),

                // --- Budget ---
                _SectionLabel(
                  icon: Icons.account_balance_wallet_outlined,
                  text: 'Budget Level',
                ),
                const SizedBox(height: 8),
                _BudgetSelector(
                  value: _budget,
                  onChanged: (v) => setState(() => _budget = v),
                ),
                const SizedBox(height: 24),

                // --- Interests ---
                _SectionLabel(
                  icon: Icons.favorite_border,
                  text: 'Interests',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in _interests)
                      InterestChip(
                        label: i.label,
                        icon: i.icon,
                        selected: _selectedInterests.contains(i.label),
                        onTap: () => setState(() {
                          if (_selectedInterests.contains(i.label)) {
                            _selectedInterests.remove(i.label);
                          } else {
                            _selectedInterests.add(i.label);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 36),

                // --- Submit ---
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate My Trip'),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Private UI pieces ----------

class _Header extends StatelessWidget {
  final ThemeData theme;
  const _Header({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.travel_explore,
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Estrave',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Where to next?',
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
        ),
        const SizedBox(height: 6),
        Text(
          'Tell us a few details and our AI local guide will craft a day-by-day itinerary.',
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.remove,
            onTap: () {
              if (value > 1) onChanged(value - 1);
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                '$value ${value == 1 ? "day" : "days"}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.add,
            onTap: () {
              if (value < 14) onChanged(value + 1);
            },
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: scheme.primary),
      ),
    );
  }
}

class _BudgetSelector extends StatelessWidget {
  final BudgetLevel value;
  final ValueChanged<BudgetLevel> onChanged;
  const _BudgetSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final lvl in BudgetLevel.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _BudgetTile(
              level: lvl,
              selected: value == lvl,
              onTap: () => onChanged(lvl),
            ),
          ),
      ],
    );
  }
}

class _BudgetTile extends StatelessWidget {
  final BudgetLevel level;
  final bool selected;
  final VoidCallback onTap;
  const _BudgetTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dollars = switch (level) {
      BudgetLevel.budget => '\$',
      BudgetLevel.midRange => '\$\$',
      BudgetLevel.luxury => '\$\$\$',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? scheme.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dollars,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    level.description,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
