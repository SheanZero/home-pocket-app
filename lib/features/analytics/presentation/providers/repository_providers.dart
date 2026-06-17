import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/analytics/get_best_joy_moment_use_case.dart';
import '../../../../application/analytics/get_budget_progress_use_case.dart';
import '../../../../application/analytics/get_category_drill_down_use_case.dart';
import '../../../../application/analytics/get_family_happiness_use_case.dart';
import '../../../../application/analytics/get_happiness_report_use_case.dart';
import '../../../../application/analytics/get_joy_category_amounts_use_case.dart';
import '../../../../application/analytics/get_largest_monthly_expense_use_case.dart';
import '../../../../application/analytics/get_per_day_joy_counts_use_case.dart';
import '../../../../application/analytics/get_monthly_joy_target_recommendation_use_case.dart';
import '../../../../application/analytics/get_monthly_report_use_case.dart';
import '../../../../application/analytics/get_per_category_joy_breakdown_across_books_use_case.dart';
import '../../../../application/analytics/get_per_category_joy_breakdown_use_case.dart';
import '../../../../application/analytics/get_satisfaction_distribution_use_case.dart';
import '../../../../application/analytics/get_within_month_cumulative_use_case.dart';
import '../../../../application/analytics/get_daily_vs_joy_snapshot_across_books_use_case.dart';
import '../../../../application/analytics/get_daily_vs_joy_snapshot_use_case.dart';
import '../../../../application/analytics/repository_providers.dart'
    as app_analytics;
import '../../../../data/daos/analytics_dao.dart';
import '../../../../data/repositories/analytics_repository_impl.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart';
import '../../../../features/analytics/domain/repositories/analytics_repository.dart';

part 'repository_providers.g.dart';

/// AnalyticsDao provider — single source of truth.
@riverpod
AnalyticsDao analyticsDao(Ref ref) {
  final database = ref.watch(app_analytics.appAppDatabaseProvider);
  return AnalyticsDao(database);
}

/// AnalyticsRepository provider.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(dao: ref.watch(analyticsDaoProvider));
});

// ── Use case providers (folded from analytics_providers.dart) ─────────────────

/// GetMonthlyReportUseCase provider.
@riverpod
GetMonthlyReportUseCase getMonthlyReportUseCase(Ref ref) {
  return GetMonthlyReportUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}

/// GetBudgetProgressUseCase provider.
@riverpod
GetBudgetProgressUseCase getBudgetProgressUseCase(Ref ref) {
  return GetBudgetProgressUseCase();
}

/// OVW-02 / D-E1: GetWithinMonthCumulativeUseCase provider.
///
/// Injects the transaction repository directly (NOT analyticsRepository): the
/// within-month trend reuses `findByBookIds` over a 2-month window with a
/// Dart-side per-day per-ledger cumulative transform. Replaces the deleted
/// 6-month `getExpenseTrendUseCase` (D-E2 — the 6-month MonthlyTrend/BarChart
/// stack is removed; round-5 B needs per-day cumulative, not per-month totals).
@riverpod
GetWithinMonthCumulativeUseCase getWithinMonthCumulativeUseCase(Ref ref) {
  return GetWithinMonthCumulativeUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}

/// DRILL-01 / D-01..D-06, D-11: GetCategoryDrillDownUseCase provider.
///
/// Injects the transaction + category repositories (NOT analyticsRepository):
/// the drill reuses `findByBookIds` directly with a Dart-side L1 filter, and the
/// summary subtotal/count come from Plan 01's shared `l1RollupFromTransactions`.
@riverpod
GetCategoryDrillDownUseCase getCategoryDrillDownUseCase(Ref ref) {
  return GetCategoryDrillDownUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}

/// JOY-02 / D-C2: GetJoyCategoryAmountsUseCase provider.
///
/// Injects the transaction + category repositories (NOT analyticsRepository):
/// the joy-amount rollup reuses `findByBookIds(ledgerType: joy)` directly with a
/// Dart-side L1 filter through the locked `l1RollupFromTransactions` (D-11).
@riverpod
GetJoyCategoryAmountsUseCase getJoyCategoryAmountsUseCase(Ref ref) {
  return GetJoyCategoryAmountsUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}

/// JOY-01 / D-C1: GetPerDayJoyCountsUseCase provider.
///
/// Injects the transaction repository directly: per-day joy COUNT reuses
/// `findByBookIds(ledgerType: joy)` with a Dart-side group-by-local-day count —
/// NOT the unfiltered daily-totals SQL aggregate (Pitfall 3). No new DAO, no
/// migration.
@riverpod
GetPerDayJoyCountsUseCase getPerDayJoyCountsUseCase(Ref ref) {
  return GetPerDayJoyCountsUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}

/// HAPPY-01..04: GetHappinessReportUseCase provider.
@riverpod
GetHappinessReportUseCase getHappinessReportUseCase(Ref ref) {
  return GetHappinessReportUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// JOYMIG-02 / D-04: GetMonthlyJoyTargetRecommendationUseCase provider.
@riverpod
GetMonthlyJoyTargetRecommendationUseCase
getMonthlyJoyTargetRecommendationUseCase(Ref ref) {
  return GetMonthlyJoyTargetRecommendationUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// STATSUI-02 / D-05: GetSatisfactionDistributionUseCase provider.
@riverpod
GetSatisfactionDistributionUseCase getSatisfactionDistributionUseCase(Ref ref) {
  return GetSatisfactionDistributionUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// HAPPY-04: GetBestJoyMomentUseCase provider.
@riverpod
GetBestJoyMomentUseCase getBestJoyMomentUseCase(Ref ref) {
  return GetBestJoyMomentUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// STATSUI-06 / D-15: GetLargestMonthlyExpenseUseCase provider.
@riverpod
GetLargestMonthlyExpenseUseCase getLargestMonthlyExpenseUseCase(Ref ref) {
  return GetLargestMonthlyExpenseUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// FAMILY-01..02: GetFamilyHappinessUseCase provider.
@riverpod
GetFamilyHappinessUseCase getFamilyHappinessUseCase(Ref ref) {
  return GetFamilyHappinessUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// HAPPY-V2-01 / D-07: per-category joy satisfaction breakdown use case provider.
@riverpod
GetPerCategoryJoyBreakdownUseCase getPerCategoryJoyBreakdownUseCase(Ref ref) {
  return GetPerCategoryJoyBreakdownUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// HAPPY-V2-01 / D-16, D-17: family-aggregate per-category breakdown use case provider.
@riverpod
GetPerCategoryJoyBreakdownAcrossBooksUseCase
getPerCategoryJoyBreakdownAcrossBooksUseCase(Ref ref) {
  return GetPerCategoryJoyBreakdownAcrossBooksUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// STATSUI-V2-01 / D-01..D-05: Daily-vs-Joy engagement snapshot use case provider.
@riverpod
GetDailyVsJoySnapshotUseCase getDailyVsJoySnapshotUseCase(Ref ref) {
  return GetDailyVsJoySnapshotUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// STATSUI-V2-01 / D-18, D-20: family-aggregate Daily-vs-Joy snapshot use case provider.
@riverpod
GetDailyVsJoySnapshotAcrossBooksUseCase
getDailyVsJoySnapshotAcrossBooksUseCase(Ref ref) {
  return GetDailyVsJoySnapshotAcrossBooksUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
