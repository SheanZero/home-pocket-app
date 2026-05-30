import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import '../../../../shared/utils/date_boundaries.dart';
import '../../../family_sync/presentation/providers/state_active_group.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';

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
  // CRITICAL: watch only (bookIds, year, month) — NEVER watch memberBookId/ledger/search
  // Pitfall 3 / D-06: calendar always full-family combined, isolated from filter state
  final isGroup = ref.watch(isGroupModeProvider);
  final shadowBookList = isGroup
      ? (await ref.watch(shadowBooksProvider.future))
      : const <ShadowBookInfo>[];

  final allBookIds = [bookId, ...shadowBookList.map((s) => s.book.id)];

  final repo = ref.watch(analyticsRepositoryProvider);
  final range = DateBoundaries.monthRange(year, month);

  // Per-book calls (N = 1 solo; 2–5 family; ≤31 rows per book — fast enough, D-06)
  final merged = <DateTime, int>{};
  for (final bid in allBookIds) {
    final totals = await repo.getDailyTotals(
      bookId: bid,
      startDate: range.start,
      endDate: range.end,
      // type defaults to 'expense' (Pitfall 6)
    );
    for (final t in totals) {
      final k = _dayKey(t.date);
      merged[k] = (merged[k] ?? 0) + t.totalAmount;
    }
  }
  return merged;
}
