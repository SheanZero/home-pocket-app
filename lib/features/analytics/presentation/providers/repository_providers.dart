import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/analytics/get_best_joy_moment_use_case.dart';
import '../../../../application/analytics/get_budget_progress_use_case.dart';
import '../../../../application/analytics/get_expense_trend_use_case.dart';
import '../../../../application/analytics/get_family_happiness_use_case.dart';
import '../../../../application/analytics/get_happiness_report_use_case.dart';
import '../../../../application/analytics/get_largest_monthly_expense_use_case.dart';
import '../../../../application/analytics/get_monthly_joy_target_recommendation_use_case.dart';
import '../../../../application/analytics/get_monthly_report_use_case.dart';
import '../../../../application/analytics/get_satisfaction_distribution_use_case.dart';
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

/// GetExpenseTrendUseCase provider.
@riverpod
GetExpenseTrendUseCase getExpenseTrendUseCase(Ref ref) {
  return GetExpenseTrendUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
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
