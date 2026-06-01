import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/analytics_aggregate.dart';

/// STATSUI-02: 1-10 joy fullness distribution histogram.
class SatisfactionDistributionHistogram extends StatelessWidget {
  const SatisfactionDistributionHistogram({super.key, required this.buckets});

  final List<SatisfactionScoreBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final normalized = _normalize();
    final total = normalized.fold<int>(0, (sum, item) => sum + item.count);
    final maxCount = normalized.fold<int>(
      0,
      (maxValue, item) => item.count > maxValue ? item.count : maxValue,
    );
    final chartMaxY = maxCount > 0 ? maxCount * 1.25 : 1.0;

    return Semantics(
      container: true,
      label: _semanticLabel(normalized, total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: chartMaxY,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final score = value.toInt();
                            if (score < 1 || score > 10) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              '$score',
                              style: AppTextStyles.caption.copyWith(
                                color: context.palette.textSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (final bucket in normalized)
                        BarChartGroupData(
                          x: bucket.score,
                          barRods: [
                            BarChartRodData(
                              toY: bucket.count == 0
                                  ? 1
                                  : bucket.count.toDouble(),
                              color: _colorForScore(bucket.score, palette),
                              width: 14,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                    ],
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final score = group.x;
                          final count = normalized[score - 1].count;
                          return BarTooltipItem(
                            '$score/10\n$count',
                            AppTextStyles.caption.copyWith(
                              color: palette.card,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(-0.12, -1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.palette.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: palette.joy.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        l10n.analyticsHistogramBarFiveAnnotation,
                        key: const ValueKey(
                          'analytics_histogram_bar_5_annotation',
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: palette.joy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.analyticsHistogramColorCaption,
            style: AppTextStyles.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<SatisfactionScoreBucket> _normalize() {
    final byScore = {for (final bucket in buckets) bucket.score: bucket.count};
    return [
      for (var score = 1; score <= 10; score += 1)
        SatisfactionScoreBucket(score: score, count: byScore[score] ?? 0),
    ];
  }

  Color _colorForScore(int score, AppPalette palette) {
    if (score <= 5) {
      return Color.lerp(palette.daily, palette.joy, (score - 1) / 4)!;
    }
    return Color.lerp(
      palette.joy,
      palette.accentPrimary,
      (score - 5) / 5,
    )!;
  }

  String _semanticLabel(List<SatisfactionScoreBucket> normalized, int total) {
    return normalized
        .map(
          (bucket) =>
              'score ${bucket.score} of 10, ${bucket.count} entries of $total',
        )
        .join('. ');
  }
}
