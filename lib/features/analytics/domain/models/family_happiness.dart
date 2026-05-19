import 'package:freezed_annotation/freezed_annotation.dart';

import 'metric_result.dart';
import 'shared_joy_insight.dart';

part 'family_happiness.freezed.dart';

@freezed
abstract class FamilyHappiness with _$FamilyHappiness {
  const factory FamilyHappiness({
    // aux (flat)
    /// Display anchor: the year of the active window's endDate (Phase 15+).
    /// Source-of-truth date range is the use-case (startDate, endDate) input.
    required int year,

    /// Display anchor: the month of the active window's endDate (Phase 15+).
    /// See use-case (startDate, endDate) for the queried range.
    required int month,
    required int totalGroupSoulTx,

    // main metrics
    required MetricResult<int> familyHighlightsSum,
    required MetricResult<SharedJoyInsight> sharedJoyInsight,
    required MetricResult<double> medianSatisfaction,
  }) = _FamilyHappiness;
}
