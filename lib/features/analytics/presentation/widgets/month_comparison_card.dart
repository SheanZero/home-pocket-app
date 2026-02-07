import 'package:flutter/material.dart';

import '../../domain/models/month_comparison.dart';

/// Card showing income/expense changes compared to previous month.
class MonthComparisonCard extends StatelessWidget {
  const MonthComparisonCard({super.key, required this.comparison});

  final MonthComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'vs ${comparison.previousYear}/${comparison.previousMonth}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ChangeRow(label: 'Income', change: comparison.incomeChange),
            const SizedBox(height: 8),
            _ChangeRow(label: 'Expenses', change: comparison.expenseChange),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.label, required this.change});

  final String label;
  final double change;

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color = label == 'Expenses'
        ? (isPositive ? Colors.red : Colors.green)
        : (isPositive ? Colors.green : Colors.red);
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              '${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
