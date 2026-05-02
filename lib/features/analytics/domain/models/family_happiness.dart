import 'package:freezed_annotation/freezed_annotation.dart';

import 'metric_result.dart';
import 'shared_joy_insight.dart';

part 'family_happiness.freezed.dart';

@freezed
abstract class FamilyHappiness with _$FamilyHappiness {
  const factory FamilyHappiness({
    // aux (flat)
    required int year,
    required int month,
    required int totalGroupSoulTx,

    // main metrics
    required MetricResult<int> familyHighlightsSum,
    required MetricResult<SharedJoyInsight> sharedJoyInsight,
    required MetricResult<double> medianSatisfaction,
  }) = _FamilyHappiness;
}
