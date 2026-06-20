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
    // Pitfall-7 / D4: the median pill is DERIVED from buckets (weighted median —
    // the score whose cumulative count first crosses 50% of total), NEVER the
    // mock's literal「7」. `null` when there is no data (no pill / outline).
    final medianScore = _weightedMedian(normalized, total);
    final medianBorderColor = Color.lerp(
      palette.joy,
      palette.joyLight,
      0.55,
    )!;

    return Semantics(
      container: true,
      label: _semanticLabel(normalized, total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            // REDES-02: fl_chart 1.2.0 renders the "5" annotation natively via
            // BarChartRodData.label (below). The previous Stack + Align +
            // DecoratedBox overlay is deleted — no manual annotation widget.
            child: BarChart(
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
                          toY: bucket.count == 0 ? 1 : bucket.count.toDouble(),
                          color: _colorForScore(bucket.score, palette),
                          width: 14,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          // round-5 r5 mock `.b.med` — outline the data-derived
                          // median bucket (descriptive, not a target).
                          borderSide: bucket.score == medianScore
                              ? BorderSide(color: medianBorderColor, width: 2)
                              : BorderSide.none,
                          // REDES-02: native per-rod label replacing the deleted
                          // Stack/Align/DecoratedBox "5" annotation hack. Only
                          // the median bucket (score 5) carries the descriptive
                          // 中央値・含未評価 annotation.
                          label: bucket.score == 5
                              ? BarChartRodLabel(
                                  show: true,
                                  text: l10n.analyticsHistogramBarFiveAnnotation,
                                  style: AppTextStyles.caption.copyWith(
                                    color: palette.joy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  offset: const Offset(0, -4),
                                )
                              : const BarChartRodLabel(show: false),
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
                        AppTextStyles.caption.copyWith(color: palette.card),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // round-5 r5 mock `.histo-foot`: left = data-derived count footer,
          // right = data-derived median pill (Pitfall-7 / D4). Both come from
          // `buckets` (no new provider) — descriptive, ADR-012-safe.
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.analyticsHistogramCountFooter(total),
                  style: AppTextStyles.caption.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
              if (medianScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: palette.joyLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    l10n.analyticsHistogramMedianPill(medianScore),
                    style: AppTextStyles.caption.copyWith(
                      color: palette.joyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
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

  /// Weighted median of the 1–10 satisfaction buckets: the score whose CUMULATIVE
  /// count first reaches/crosses 50% of [total]. Returns `null` when there is no
  /// data. Descriptive (Pitfall-7 / D4) — never a target.
  int? _weightedMedian(List<SatisfactionScoreBucket> normalized, int total) {
    if (total <= 0) return null;
    final half = total / 2;
    var cumulative = 0;
    for (final bucket in normalized) {
      cumulative += bucket.count;
      if (cumulative >= half) return bucket.score;
    }
    return normalized.isNotEmpty ? normalized.last.score : null;
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
