import 'package:flutter/material.dart';

import '../../domain/models/monthly_report.dart';

/// 2x2 grid of summary cards: Income, Expenses, Savings, Savings Rate.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Income',
                amount: report.totalIncome,
                color: Colors.green,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Expenses',
                amount: report.totalExpenses,
                color: Colors.red,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Savings',
                amount: report.savings,
                color: report.savings >= 0 ? Colors.blue : Colors.orange,
                icon: Icons.savings,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _RateCard(rate: report.savingsRate)),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String title;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¥${_formatAmount(amount)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    final abs = amount.abs().toString();
    final prefix = amount < 0 ? '-' : '';
    return prefix +
        abs.replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final color = rate >= 20
        ? Colors.green
        : rate >= 0
        ? Colors.blue
        : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Savings Rate',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
