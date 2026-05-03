import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_joy_per_yen_point.freezed.dart';

/// STATSUI-01 / D-05 — output of per-day PTVF fold for Joy/¥ trend chart.
@freezed
abstract class DailyJoyPerYenPoint with _$DailyJoyPerYenPoint {
  const factory DailyJoyPerYenPoint({
    /// Day-of-month (1..31).
    required int day,

    /// PTVF density for this day: Σ(sat × (amount/base)^0.88) / Σ(amount).
    required double joyPerYen,

    /// Number of soul transactions folded into this point.
    required int sampleSize,
  }) = _DailyJoyPerYenPoint;
}
