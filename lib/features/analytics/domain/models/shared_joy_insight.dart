import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_joy_insight.freezed.dart';

/// FAMILY-02 / D-08 anti-leaderboard tuple.
/// Per-person breakdowns are forbidden by contract.
@freezed
abstract class SharedJoyInsight with _$SharedJoyInsight {
  const factory SharedJoyInsight({
    required String categoryId,
    required double avgSatisfaction,
    required int totalCount,
  }) = _SharedJoyInsight;
}
