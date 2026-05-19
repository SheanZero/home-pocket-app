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

    if (endDate.isAfter(DateTime.now())) {
      throw ArgumentError.value(
        (startDate, endDate),
        'window',
        'endDate must not be in the future',
      );
    }
  }
}
