import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models/monthly_report.dart';

/// Pie chart showing top categories by spending.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.breakdowns});

  final List<CategoryBreakdown> breakdowns;

  static const _chartColors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
  ];

  @override
  Widget build(BuildContext context) {
    if (breakdowns.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No expense data',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
      );
    }

    final top = breakdowns.take(7).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: top.asMap().entries.map((entry) {
                    final i = entry.key;
                    final b = entry.value;
                    return PieChartSectionData(
                      value: b.amount.toDouble(),
                      title: '${b.percentage.toStringAsFixed(0)}%',
                      color: _chartColors[i % _chartColors.length],
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: top.asMap().entries.map((entry) {
                final i = entry.key;
                final b = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _chartColors[i % _chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(b.categoryName, style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
