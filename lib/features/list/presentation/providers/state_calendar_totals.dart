import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import '../../../../shared/utils/date_boundaries.dart';

part 'state_calendar_totals.g.dart';

/// Normalizes a DateTime to date-only key (strips time-of-day).
///
/// Used by the provider when building map keys AND by the cell builder
/// when looking up a day's total. Both sides MUST use this function
/// to avoid silent lookup misses (Pitfall 1 — highest risk).
DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Per-day expense totals for the calendar header.
///
/// Watches only (bookId, year, month) — isolated from listFilterProvider
/// filter state (D-09, Pitfall 3). Rebuilding on text search would
/// re-render 31 day cells on every keystroke.
///
/// Phase 29 seam: bookId is a single value (own-book only).
@riverpod
Future<Map<DateTime, int>> calendarDailyTotals(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  // Phase 29: combine shadow books for family per-day totals
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = DateBoundaries.monthRange(year, month);
  final totals = await repo.getDailyTotals(
    bookId: bookId,
    startDate: range.start,
    endDate: range.end,
    // type defaults to 'expense' — expense-only basis (D-09, Pitfall 6)
  );
  return {for (final t in totals) _dayKey(t.date): t.totalAmount};
}
