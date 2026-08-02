import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_transaction_aggregate_refresh.dart';

void main() {
  test(
    'transaction mutation refreshes every cached Home/Statistics aggregate',
    () {
      expect(
        transactionAggregateRefreshTargets,
        containsAll([
          monthlyReportProvider,
          withinMonthCumulativeTrendProvider,
          memberFilteredCategoryBreakdownProvider,
          memberSpendBreakdownProvider,
          joyMemberAmountsProvider,
          categoryDrillDownProvider,
          earliestTransactionMonthProvider,
          satisfactionDistributionProvider,
          joyCategoryAmountsProvider,
          perDayJoyCountsProvider,
          joyDayTransactionsProvider,
          happinessReportProvider,
          bestJoyMomentProvider,
          monthlyJoyTargetRecommendationProvider,
          largestMonthlyExpenseProvider,
          familyHappinessProvider,
          perCategoryJoyBreakdownProvider,
          perCategoryJoyBreakdownFamilyProvider,
          dailyVsJoySnapshotProvider,
          dailyVsJoySnapshotFamilyProvider,
        ]),
      );
    },
  );
}
