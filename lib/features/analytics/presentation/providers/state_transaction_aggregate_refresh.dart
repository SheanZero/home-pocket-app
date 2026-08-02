import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import 'state_analytics.dart';
import 'state_happiness.dart';
import 'state_ledger_snapshot.dart';

/// Every cached Home/Statistics aggregate whose value can change after a
/// transaction create, update, delete, import, or sync.
///
/// Family roots are invalidated rather than one date/variant instance. This is
/// intentional: Home and Statistics can keep different selected months and
/// Joy-metric variants alive inside the shell's IndexedStack.
final List<ProviderOrFamily> transactionAggregateRefreshTargets = [
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
];

void invalidateTransactionAggregates(WidgetRef ref) {
  for (final target in transactionAggregateRefreshTargets) {
    ref.invalidate(target);
  }
}
