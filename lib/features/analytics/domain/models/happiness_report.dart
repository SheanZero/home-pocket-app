import 'package:freezed_annotation/freezed_annotation.dart';

import 'best_joy_moment_row.dart';
import 'metric_result.dart';

part 'happiness_report.freezed.dart';

@freezed
abstract class HappinessReport with _$HappinessReport {
  const factory HappinessReport({
    // aux (flat)
    /// Display anchor: the year of the active window's endDate (Phase 15+).
    /// Source-of-truth date range is the use-case (startDate, endDate) input.
    required int year,

    /// Display anchor: the month of the active window's endDate (Phase 15+).
    /// See use-case (startDate, endDate) for the queried range.
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
