/// D-06 + D-07 + D-08 defensive validation invoked at use-case boundaries.
///
/// UI surfaces localized SnackBars before calling use cases. This helper is
/// defense in depth against malformed input reaching repositories. The
/// 12-month cap uses calendar-month math, not `Duration.inDays`, to avoid the
/// leap-year off-by-one trap from Phase 15 research Pitfall #5.
class TimeWindowValidation {
  TimeWindowValidation._();

  /// Throws [ArgumentError] if start > end, span > 12 months, or end > now.
  static void assertValid(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) {
      throw ArgumentError.value(
        (startDate, endDate),
        'window',
        'startDate must be <= endDate',
      );
    }

    final months =
        (endDate.year - startDate.year) * 12 +
        (endDate.month - startDate.month);
    if (months > 12 || (months == 12 && endDate.day > startDate.day)) {
      throw ArgumentError.value(
        (startDate, endDate),
        'window',
        'window must not exceed 12 months',
      );
    }

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (endDate.isAfter(todayEnd) &&
        !_isCurrentCalendarWindow(startDate, endDate, now)) {
      throw ArgumentError.value(
        (startDate, endDate),
        'window',
        'endDate must not be in the future',
      );
    }
  }

  static bool _isCurrentCalendarWindow(
    DateTime startDate,
    DateTime endDate,
    DateTime now,
  ) {
    if (startDate.isAfter(now) || endDate.isBefore(now)) {
      return false;
    }

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endDate.hour,
      endDate.minute,
      endDate.second,
    );

    return _sameSecond(
              end,
              DateTime(start.year, start.month, start.day + 6, 23, 59, 59),
            ) &&
            start.weekday == DateTime.monday ||
        _sameSecond(
              end,
              DateTime(start.year, start.month + 1, 0, 23, 59, 59),
            ) &&
            start.day == 1 ||
        _sameSecond(
              end,
              DateTime(start.year, start.month + 3, 0, 23, 59, 59),
            ) &&
            start.day == 1 &&
            const {1, 4, 7, 10}.contains(start.month) ||
        _sameSecond(end, DateTime(start.year, 12, 31, 23, 59, 59)) &&
            start.month == 1 &&
            start.day == 1;
  }

  static bool _sameSecond(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute &&
        a.second == b.second;
  }
}
