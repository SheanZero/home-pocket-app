import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/monthly_report.dart';

/// STATSUI-06: top-N category spending donut for the 分布 group.
class CategorySpendDonutChart extends StatelessWidget {
  const CategorySpendDonutChart({
    super.key,
    required this.breakdowns,
    this.topCount = 5,
  });

  final List<CategoryBreakdown> breakdowns;
  final int topCount;

  @override
  Widget build(BuildContext context) {
    if (breakdowns.isEmpty) {
      return const SizedBox.shrink();
    }

    final slices = _buildSlices(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                for (final entry in slices.asMap().entries)
                  PieChartSectionData(
                    value: entry.value.amount.toDouble(),
                    title: '${entry.value.percentage.round()}%',
                    color: _colorFor(entry.key, slices.length),
                    radius: 72,
                    titleStyle: AppTextStyles.caption.copyWith(
                      color: AppColors.card,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 38,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final entry in slices.asMap().entries)
              _LegendItem(
                color: _colorFor(entry.key, slices.length),
                label:
                    '${entry.value.categoryName} ${entry.value.percentage.round()}%',
              ),
          ],
        ),
      ],
    );
  }

  List<_DonutSlice> _buildSlices(BuildContext context) {
    final l10n = S.of(context);
    final sorted = [...breakdowns]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final visible = sorted.take(topCount).toList();
    final overflow = sorted.skip(topCount).toList();
    final total = sorted.fold<int>(0, (sum, item) => sum + item.amount);

    final slices = [
      for (final item in visible)
        _DonutSlice(
          categoryName: item.categoryName,
          amount: item.amount,
          percentage: item.percentage,
        ),
    ];

    if (overflow.isNotEmpty && total > 0) {
      final otherAmount = overflow.fold<int>(
        0,
        (sum, item) => sum + item.amount,
      );
      slices.add(
        _DonutSlice(
          categoryName: l10n.analyticsCategoryDonutOther,
          amount: otherAmount,
          percentage: otherAmount / total * 100,
        ),
      );
    }

    return slices;
  }

  Color _colorFor(int index, int total) {
    if (total <= 1) return AppColors.daily;
    final t = index / (total - 1);
    return Color.lerp(AppColors.daily, AppColors.joy, t)!;
  }
}

class _DonutSlice {
  const _DonutSlice({
    required this.categoryName,
    required this.amount,
    required this.percentage,
  });

  final String categoryName;
  final int amount;
  final double percentage;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: context.wmTextSecondary),
        ),
      ],
    );
  }
}
