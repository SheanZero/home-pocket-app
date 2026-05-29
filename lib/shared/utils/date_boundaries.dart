// Date boundary utilities for closed-interval queries.
//
// Import path: package:home_pocket/shared/utils/date_boundaries.dart
//
// D-04: All boundaries use DEVICE LOCAL TIME — no DateTime.utc() constructors.
// This aligns with AnalyticsDao.getDailyTotals which groups by the device's
// local calendar day. Using UTC would shift day/month boundaries and produce
// misaligned calendar totals on devices not in UTC.

/// Static utility that computes closed date-time intervals for DAO queries.
///
/// All returned [start] values are 00:00:00 on the opening day.
/// All returned [end] values are 23:59:59 on the closing day.
/// No [DateTime.utc] is used — local device time throughout (D-04).
abstract final class DateBoundaries {
  /// Returns the closed interval for the entire calendar [month] of [year].
  ///
  /// [month] must be in the range 1..12.
  ///
  /// The month-end is computed via `DateTime(year, month + 1, 0, 23, 59, 59)`.
  /// Dart normalises day=0 to the last day of the prior month, so December
  /// (month=12) correctly resolves to day=31 of month=12 without overflow.
  ///
  /// Example:
  /// ```dart
  /// final r = DateBoundaries.monthRange(2026, 5);
  /// // r.start == DateTime(2026, 5, 1)          // 00:00:00
  /// // r.end   == DateTime(2026, 5, 31, 23, 59, 59)
  /// ```
  static ({DateTime start, DateTime end}) monthRange(int year, int month) {
    return (
      start: DateTime(year, month),
      end: DateTime(year, month + 1, 0, 23, 59, 59),
    );
  }

  /// Returns the closed interval for the single calendar day containing [day].
  ///
  /// The time component of [day] is stripped; the result spans 00:00:00 to
  /// 23:59:59 of the same date.
  ///
  /// Example:
  /// ```dart
  /// final r = DateBoundaries.dayRange(DateTime(2026, 5, 15, 14, 30));
  /// // r.start == DateTime(2026, 5, 15)              // 00:00:00
  /// // r.end   == DateTime(2026, 5, 15, 23, 59, 59)
  /// ```
  static ({DateTime start, DateTime end}) dayRange(DateTime day) {
    return (
      start: DateTime(day.year, day.month, day.day),
      end: DateTime(day.year, day.month, day.day, 23, 59, 59),
    );
  }
}
