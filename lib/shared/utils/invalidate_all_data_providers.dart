import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounting/presentation/providers/repository_providers.dart'
    show bookByIdProvider;
import '../../features/analytics/presentation/providers/state_analytics.dart';
import '../../features/analytics/presentation/providers/state_happiness.dart';
import '../../features/home/presentation/providers/state_shadow_books.dart';
import '../../features/home/presentation/providers/state_today_transactions.dart';
import '../../features/list/presentation/providers/state_calendar_totals.dart';
import '../../features/list/presentation/providers/state_list_transactions.dart';
import '../../features/settings/presentation/providers/state_locale.dart';
import '../../features/settings/presentation/providers/state_settings.dart';

/// Full-wipe sibling of [invalidateTransactionDependents].
///
/// Whereas `invalidateTransactionDependents` refreshes the handful of families
/// touched by a single add/edit/delete, this helper invalidates EVERY
/// data-bearing provider family so the Home, List, Analytics, Happiness and
/// Settings screens all re-fetch from a freshly reset database. It is the single
/// funnel for both Settings destructive actions — delete-all-data and
/// import-backup — invoked from the app-root reset routine after the new default
/// book id has been recomputed.
///
/// Plain top-level function (no `@riverpod`, no codegen), taking a [WidgetRef],
/// mirroring the established `invalidate_transaction_dependents.dart` pattern.
/// Each provider is invalidated by its family handle (no key), and
/// `ref.invalidate(family)` discards every keyed instance, so callers never need
/// to know the active bookId / year / month.
void invalidateAllDataProviders(WidgetRef ref) {
  // Home / List / Shadow.
  ref.invalidate(todayTransactionsProvider);
  ref.invalidate(listTransactionsProvider);
  ref.invalidate(calendarDailyTotalsProvider);
  ref.invalidate(shadowBooksProvider);
  ref.invalidate(shadowAggregateProvider);

  // Analytics.
  ref.invalidate(monthlyReportProvider);
  ref.invalidate(withinMonthCumulativeTrendProvider);
  ref.invalidate(memberFilteredCategoryBreakdownProvider);
  ref.invalidate(memberSpendBreakdownProvider);
  ref.invalidate(joyMemberAmountsProvider);
  ref.invalidate(categoryDrillDownProvider);
  ref.invalidate(analyticsCategoriesMapProvider);
  ref.invalidate(earliestTransactionMonthProvider);
  ref.invalidate(satisfactionDistributionProvider);
  ref.invalidate(joyCategoryAmountsProvider);
  ref.invalidate(perDayJoyCountsProvider);
  ref.invalidate(joyDayTransactionsProvider);

  // Happiness.
  ref.invalidate(happinessReportProvider);
  ref.invalidate(bestJoyMomentProvider);
  ref.invalidate(monthlyJoyTargetRecommendationProvider);
  ref.invalidate(largestMonthlyExpenseProvider);
  ref.invalidate(familyHappinessProvider);

  // Accounting (book lookup by id — used by the shell + settings header).
  ref.invalidate(bookByIdProvider);

  // Settings / locale (reset to defaults on clear, so they must refresh live).
  ref.invalidate(appSettingsProvider);
  ref.invalidate(currentLocaleProvider);
}
