import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_window.freezed.dart';

/// Time window for AnalyticsScreen Joy-metric queries (HAPPY-V2-02).
///
/// All variants resolve to inclusive `(start 00:00:00, end 23:59:59)` per
/// D-06. Week starts Monday for all locales per D-05. Consumers that need a
/// month anchor for broader windows should use `range.end`'s year/month.
@freezed
sealed class TimeWindow with _$TimeWindow {
  const TimeWindow._();

  /// ISO-week-Monday-anchored 7-day window. [mondayStart] MUST be a Monday;
  /// constructor callers are responsible for snapping to Monday (D-05).
  @Assert('mondayStart.weekday == DateTime.monday')
  factory TimeWindow.week({required DateTime mondayStart}) = WeekWindow;

  /// Calendar month: [year]-[month] (month in 1..12).
  @Assert('month >= 1 && month <= 12')
  const factory TimeWindow.month({
    required int year,
    required int month,
  }) = MonthWindow;

  /// Calendar quarter (1..4). Q1=Jan-Mar, Q2=Apr-Jun, Q3=Jul-Sep, Q4=Oct-Dec.
  @Assert('quarter >= 1 && quarter <= 4')
  const factory TimeWindow.quarter({
    required int year,
    required int quarter,
  }) = QuarterWindow;

  /// Calendar year.
  const factory TimeWindow.year({required int year}) = YearWindow;

  /// User-picked arbitrary range. Validation (start <= end, <= 12 months,
  /// end <= today) lives in `TimeWindowValidation.assertValid` (application).
  const factory TimeWindow.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) = CustomWindow;
}

extension TimeWindowRange on TimeWindow {
  /// Returns the inclusive `(start, end)` pair for this window per D-06.
  ///
  /// `start` is midnight of the first day; `end` is 23:59:59 of the last day.
  ({DateTime start, DateTime end}) get range => switch (this) {
    WeekWindow(:final mondayStart) => (
      start: DateTime(mondayStart.year, mondayStart.month, mondayStart.day),
      end: DateTime(
        mondayStart.year,
        mondayStart.month,
        mondayStart.day + 6,
        23,
        59,
        59,
      ),
    ),
    MonthWindow(:final year, :final month) => (
      start: DateTime(year, month),
      end: DateTime(year, month + 1, 0, 23, 59, 59),
    ),
    QuarterWindow(:final year, :final quarter) => (
      start: DateTime(year, (quarter - 1) * 3 + 1),
      end: DateTime(year, quarter * 3 + 1, 0, 23, 59, 59),
    ),
    YearWindow(:final year) => (
      start: DateTime(year),
      end: DateTime(year, 12, 31, 23, 59, 59),
    ),
    CustomWindow(:final startDate, :final endDate) => (
      start: DateTime(startDate.year, startDate.month, startDate.day),
      end: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
    ),
  };
}
