import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analytics/presentation/providers/state_analytics.dart';
import '../../features/analytics/presentation/providers/state_happiness.dart';
import '../../features/home/presentation/providers/state_today_transactions.dart';
import '../../features/list/presentation/providers/state_calendar_totals.dart';
import '../../features/list/presentation/providers/state_list_transactions.dart';

/// Invalidate every provider that depends on transaction data after a mutation
/// (add / edit / delete), so the List, calendar header, Home today summary, and
/// Analytics reports all refresh without a manual pull (260603-nr1 #5).
///
/// Plain top-level function (no `@riverpod`, no codegen). The list + calendar
/// providers are invalidated with their exact family key (they need the active
/// `bookId`/`year`/`month`). The Home + Analytics families are invalidated as a
/// whole — `ref.invalidate(family)` discards every instance, which is correct
/// here because the mutated transaction can belong to any keyed slice and the
/// providers are cheap one-shot `FutureProvider`s.
void invalidateTransactionDependents(
  WidgetRef ref, {
  required String bookId,
  required int year,
  required int month,
}) {
  // List + calendar (keyed — need the active filter context). The list's SQL
  // lives in the base provider (P2-1); the search layer cascades from it.
  ref.invalidate(listTransactionsBaseProvider(bookId: bookId));
  ref.invalidate(
    calendarDailyTotalsProvider(bookId: bookId, year: year, month: month),
  );

  // Home today summary (whole family).
  ref.invalidate(todayTransactionsProvider);

  // Analytics reports (whole families).
  ref.invalidate(monthlyReportProvider);
  ref.invalidate(happinessReportProvider);
  ref.invalidate(bestJoyMomentProvider);
}
