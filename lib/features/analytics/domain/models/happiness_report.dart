import 'package:freezed_annotation/freezed_annotation.dart';

import 'best_joy_moment_row.dart';
import 'metric_result.dart';

part 'happiness_report.freezed.dart';

@freezed
abstract class HappinessReport with _$HappinessReport {
  const factory HappinessReport({
    // aux (flat)
    required int year,
    required int month,
    required String bookId,
    required int totalSoulTx,

    // main metrics (MetricResult-wrapped)
    required MetricResult<double> avgSatisfaction,
    required MetricResult<double> joyContribution,
    required MetricResult<double> medianSatisfaction,
    required MetricResult<int> highlightsCount,
    required MetricResult<BestJoyMomentRow> topJoy,
  }) = _HappinessReport;
}
