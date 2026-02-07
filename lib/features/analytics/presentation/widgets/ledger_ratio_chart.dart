import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Pie chart showing Survival vs Soul spending ratio.
class LedgerRatioChart extends StatelessWidget {
  const LedgerRatioChart({
    super.key,
    required this.survivalTotal,
    required this.soulTotal,
  });

  final int survivalTotal;
  final int soulTotal;

  @override
  Widget build(BuildContext context) {
    final total = survivalTotal + soulTotal;
    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No ledger data',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
      );
    }

    final survivalPct = survivalTotal / total * 100;
    final soulPct = soulTotal / total * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Survival vs Soul',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: survivalTotal.toDouble(),
                            title: '${survivalPct.toStringAsFixed(0)}%',
                            color: Colors.teal,
                            radius: 55,
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: soulTotal.toDouble(),
                            title: '${soulPct.toStringAsFixed(0)}%',
                            color: Colors.deepPurple,
                            radius: 55,
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 3,
                        centerSpaceRadius: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LedgerLabel(
                      color: Colors.teal,
                      label: 'Survival',
                      amount: survivalTotal,
                    ),
                    const SizedBox(height: 8),
                    _LedgerLabel(
                      color: Colors.deepPurple,
                      label: 'Soul',
                      amount: soulTotal,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerLabel extends StatelessWidget {
  const _LedgerLabel({
    required this.color,
    required this.label,
    required this.amount,
  });

  final Color color;
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              '¥$amount',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
