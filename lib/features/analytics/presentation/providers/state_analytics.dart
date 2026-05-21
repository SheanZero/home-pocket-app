import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../accounting/domain/models/entry_source.dart';
import '../../domain/models/analytics_aggregate.dart';
import '../../domain/models/expense_trend.dart';
import '../../domain/models/monthly_report.dart';
import 'repository_providers.dart';
import 'state_joy_metric_variant.dart';

part 'state_analytics.g.dart';

/// Monthly report for the selected window.
@riverpod
Future<MonthlyReport> monthlyReport(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getMonthlyReportUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    entrySourceFilter: entrySourceFilter,
  );
}

/// 6-month expense trend.
@riverpod
Future<ExpenseTrendData> expenseTrend(
  Ref ref, {
  required String bookId,
  required DateTime anchor,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getExpenseTrendUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  return useCase.execute(
    bookId: bookId,
    anchor: anchor,
    entrySourceFilter: entrySourceFilter,
  );
}

/// Earliest month with a non-deleted transaction in the active book.
@riverpod
Future<DateTime?> earliestTransactionMonth(
  Ref ref, {
  required String bookId,
}) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final timestamp = await repository.getEarliestTransactionTimestamp(
    bookId: bookId,
  );
  if (timestamp == null) {
    return null;
  }
  return DateTime(timestamp.year, timestamp.month);
}

/// Satisfaction score distribution for the selected window.
@riverpod
Future<List<SatisfactionScoreBucket>> satisfactionDistribution(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getSatisfactionDistributionUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    entrySourceFilter: entrySourceFilter,
  );
}
