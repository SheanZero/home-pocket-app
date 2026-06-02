import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../accounting/domain/models/entry_source.dart';
import '../../domain/models/best_joy_moment_row.dart';
import '../../domain/models/analytics_aggregate.dart';
import '../../domain/models/family_happiness.dart';
import '../../domain/models/happiness_report.dart';
import '../../domain/models/metric_result.dart';
import '../../../family_sync/presentation/providers/state_active_group.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';
import 'repository_providers.dart';
import 'state_joy_metric_variant.dart';

part 'state_happiness.g.dart';

/// HAPPY-01..04 personal happiness report.
@riverpod
Future<HappinessReport> happinessReport(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  required String currencyCode,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getHappinessReportUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    currencyCode: currencyCode,
    entrySourceFilter: entrySourceFilter,
  );
}

/// HAPPY-04 standalone Top Joy.
@riverpod
Future<MetricResult<BestJoyMomentRow>> bestJoyMoment(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getBestJoyMomentUseCaseProvider);
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

/// JOYMIG-02 / D-04 — recommended monthlyJoyTarget from past 3 months.
///
/// Returns Empty when fewer than 3 past months have joy transaction data.
@riverpod
Future<MetricResult<int>> monthlyJoyTargetRecommendation(
  Ref ref, {
  required String bookId,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getMonthlyJoyTargetRecommendationUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    currencyCode: currencyCode,
    asOf: DateTime.now(),
  );
}

/// STATSUI-06 / D-15 — single largest monthly expense for 物語 group 総 card.
@riverpod
Future<LargestMonthlyExpense?> largestMonthlyExpense(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getLargestMonthlyExpenseUseCaseProvider);
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

/// FAMILY-01..02 family happiness aggregate.
///
/// D-09: presentation resolves shadow books to book IDs before invoking the
/// use case. Q6c remains open: this currently passes shadow books only; Phase
/// 10/11 may extend the call site if current-device book inclusion is required.
@riverpod
Future<FamilyHappiness> familyHappiness(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final activeGroup = await ref.watch(activeGroupProvider.future);
  if (activeGroup == null) {
    return _emptyFamilyHappiness(endDate: endDate);
  }

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((shadow) => shadow.book.id).toList();
  if (groupBookIds.isEmpty) {
    return _emptyFamilyHappiness(endDate: endDate);
  }

  final useCase = ref.watch(getFamilyHappinessUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  return useCase.execute(
    groupBookIds: groupBookIds,
    startDate: startDate,
    endDate: endDate,
    entrySourceFilter: entrySourceFilter,
  );
}

FamilyHappiness _emptyFamilyHappiness({required DateTime endDate}) {
  return FamilyHappiness(
    year: endDate.year,
    month: endDate.month,
    totalGroupJoyTx: 0,
    familyHighlightsSum: const Empty(),
    sharedJoyInsight: const Empty(),
    medianSatisfaction: const Empty(),
  );
}
