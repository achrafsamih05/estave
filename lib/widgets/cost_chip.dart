import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A small rounded chip that formats a cost amount with its currency symbol.
/// Shows "Free" when [amount] is zero.
class CostChip extends StatelessWidget {
  final double amount;
  final String currency;
  final Color? color;

  const CostChip({
    super.key,
    required this.amount,
    this.currency = 'USD',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = (color ?? scheme.secondary).withValues(alpha: 0.14);
    final fg = color ?? scheme.secondary;

    final label = amount <= 0
        ? 'Free'
        : NumberFormat.simpleCurrency(name: currency).format(amount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
