import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/joy_density_formatter.dart';
import '../../domain/models/daily_joy_per_yen_point.dart';
import '../../domain/models/metric_result.dart';

/// STATSUI-01: Joy density MTD line chart with D-06 gap segmentation.
class JoyTrendLineChart extends StatelessWidget {
  const JoyTrendLineChart({
    super.key,
    required this.result,
    required this.daysInMonth,
    required this.currencyCode,
    required this.locale,
  });

  final MetricResult<List<DailyJoyPerYenPoint>> result;
  final int daysInMonth;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final current = result;
    if (current is Empty<List<DailyJoyPerYenPoint>>) {
      return const SizedBox(height: 180);
    }

    final points = (current as Value<List<DailyJoyPerYenPoint>>).data;
    if (points.isEmpty) {
      return const SizedBox(height: 180);
    }

    final l10n = S.of(context);
    final maxObserved = points.fold<double>(
      0,
      (maxValue, point) =>
          point.joyPerYen > maxValue ? point.joyPerYen : maxValue,
    );
    final chartMaxY = maxObserved > 0 ? maxObserved * 1.20 : 1.0;
    final interval = chartMaxY / 4;
    final segments = _splitIntoContiguousSegments(points, daysInMonth);

    return Semantics(
      container: true,
      label: _semanticLabel(points),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: 0,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt();
                        if (day < 1 || day > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '$day',
                          style: AppTextStyles.caption.copyWith(
                            color: context.wmTextSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 64,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          formatJoyDensity(value, currencyCode),
                          style: AppTextStyles.amountSmall.copyWith(
                            color: context.wmTextSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  for (final segment in segments)
                    LineChartBarData(
                      spots: [
                        for (final point in segment)
                          FlSpot(point.day.toDouble(), point.joyPerYen),
                      ],
                      color: AppColors.soul,
                      barWidth: 3,
                      isCurved: false,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.soul.withValues(alpha: 0.08),
                      ),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return [
                        for (final spot in spots)
                          LineTooltipItem(
                            '${l10n.analyticsDayNumberLabel(spot.x.toInt())}\n'
                            '${formatJoyDensity(spot.y, currencyCode)}',
                            AppTextStyles.amountSmall.copyWith(
                              color: AppColors.card,
                            ),
                          ),
                      ];
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.analyticsCardCaptionJoyTrendGap,
            style: AppTextStyles.caption.copyWith(
              color: context.wmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static List<List<DailyJoyPerYenPoint>> _splitIntoContiguousSegments(
    List<DailyJoyPerYenPoint> points,
    int monthDays,
  ) {
    final byDay = {for (final point in points) point.day: point};
    final segments = <List<DailyJoyPerYenPoint>>[];
    var current = <DailyJoyPerYenPoint>[];

    for (var day = 1; day <= monthDays; day++) {
      final point = byDay[day];
      if (point == null) {
        if (current.isNotEmpty) {
          segments.add(current);
          current = <DailyJoyPerYenPoint>[];
        }
      } else {
        current.add(point);
      }
    }

    if (current.isNotEmpty) {
      segments.add(current);
    }
    return segments;
  }

  static String _semanticLabel(List<DailyJoyPerYenPoint> points) {
    return points
        .map(
          (point) =>
              'day ${point.day}, joy ${point.joyPerYen.toStringAsFixed(2)}, '
              'sample ${point.sampleSize}',
        )
        .join('. ');
  }
}
