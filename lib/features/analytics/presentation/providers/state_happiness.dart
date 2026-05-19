import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/best_joy_moment_row.dart';
import '../../domain/models/analytics_aggregate.dart';
import '../../domain/models/family_happiness.dart';
import '../../domain/models/happiness_report.dart';
import '../../domain/models/metric_result.dart';
import '../../../family_sync/presentation/providers/state_active_group.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';
import 'repository_providers.dart';

part 'state_happiness.g.dart';

/// HAPPY-01..04 personal happiness report.
@riverpod
Future<HappinessReport> happinessReport(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getHappinessReportUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    year: year,
    month: month,
    currencyCode: currencyCode,
  );
}

/// HAPPY-04 standalone Top Joy.
@riverpod
Future<MetricResult<BestJoyMomentRow>> bestJoyMoment(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getBestJoyMomentUseCaseProvider);
  return useCase.execute(bookId: bookId, year: year, month: month);
}

/// JOYMIG-02 / D-04 — recommended monthlyJoyTarget from past 3 months.
///
/// Returns Empty when fewer than 3 past months have soul transaction data.
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
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getLargestMonthlyExpenseUseCaseProvider);
  return useCase.execute(bookId: bookId, year: year, month: month);
}

/// FAMILY-01..02 family happiness aggregate.
///
/// D-09: presentation resolves shadow books to book IDs before invoking the
/// use case. Q6c remains open: this currently passes shadow books only; Phase
/// 10/11 may extend the call site if current-device book inclusion is required.
@riverpod
Future<FamilyHappiness> familyHappiness(
  Ref ref, {
  required int year,
  required int month,
}) async {
  final activeGroup = await ref.watch(activeGroupProvider.future);
  if (activeGroup == null) {
    return _emptyFamilyHappiness(year: year, month: month);
  }

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((shadow) => shadow.book.id).toList();
  if (groupBookIds.isEmpty) {
    return _emptyFamilyHappiness(year: year, month: month);
  }

  final useCase = ref.watch(getFamilyHappinessUseCaseProvider);
  return useCase.execute(groupBookIds: groupBookIds, year: year, month: month);
}

FamilyHappiness _emptyFamilyHappiness({required int year, required int month}) {
  return FamilyHappiness(
    year: year,
    month: month,
    totalGroupSoulTx: 0,
    familyHighlightsSum: const Empty(),
    sharedJoyInsight: const Empty(),
    medianSatisfaction: const Empty(),
  );
}
