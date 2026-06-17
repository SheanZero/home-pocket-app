import 'package:freezed_annotation/freezed_annotation.dart';

part 'within_month_cumulative_trend.freezed.dart';

/// One (day-of-month, running-cumulative-amount) point on a within-month line.
///
/// [day] is the calendar day-of-month (1..31); [cumulativeAmount] is the
/// running sum (minor units) of expense on/before that day, WITHIN its own
/// month (the cumulative resets at the month boundary — each month's line
/// starts fresh at its first spend day).
@freezed
abstract class CumulativePoint with _$CumulativePoint {
  const factory CumulativePoint({
    required int day,
    required int cumulativeAmount,
  }) = _CumulativePoint;
}

/// Transient carrier for the within-month per-day-cumulative spend trend
/// (round-5 B / D-E1, Phase 46).
///
/// The spend side (total / daily ledgers) carries BOTH the current month and
/// the previous month, so the trend card can draw a 本月 solid line + 上月
/// dashed reference line on the same scale. The joy side carries ONLY the
/// current month — there is intentionally NO `previousMonthJoy` field, making a
/// previous-month joy series unrepresentable by construction (D-E1, ADR-012
/// zero joy cross-period — Pitfall 2).
///
/// No JSON: this is transient state behind an auto-dispose provider.
@freezed
abstract class WithinMonthCumulativeTrend with _$WithinMonthCumulativeTrend {
  const factory WithinMonthCumulativeTrend({
    /// Current month, all-ledger expense cumulative (== daily + joy per point).
    required List<CumulativePoint> currentMonthTotal,

    /// Current month, daily-ledger-only expense cumulative.
    required List<CumulativePoint> currentMonthDaily,

    /// Current month, joy-ledger-only expense cumulative.
    required List<CumulativePoint> currentMonthJoy,

    /// Previous month, all-ledger expense cumulative (spend-side reference).
    required List<CumulativePoint> previousMonthTotal,

    /// Previous month, daily-ledger-only expense cumulative (spend-side
    /// reference). NOTE: there is deliberately NO previousMonthJoy — the joy
    /// side never crosses periods (D-E1).
    required List<CumulativePoint> previousMonthDaily,
  }) = _WithinMonthCumulativeTrend;
}
