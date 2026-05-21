import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../accounting/domain/models/entry_source.dart';
import '../../../family_sync/presentation/providers/state_active_group.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';
import '../../domain/models/ledger_snapshot.dart';
import '../../domain/models/metric_result.dart';
import '../../domain/models/per_category_soul_breakdown.dart';
import 'repository_providers.dart';
import 'state_joy_metric_variant.dart';

part 'state_ledger_snapshot.g.dart';

/// HAPPY-V2-01 single-book per-category soul satisfaction breakdown.
///
/// Window-keyed Future provider that delegates to
/// [GetPerCategorySoulBreakdownUseCase]. The use case owns the D-07 sort and
/// D-08 min-N/Other rollup — the provider is plumbing only.
@riverpod
Future<MetricResult<PerCategorySoulBreakdown>> perCategorySoulBreakdown(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  required JoyMetricVariant joyMetricVariant,
}) async {
  final useCase = ref.watch(getPerCategorySoulBreakdownUseCaseProvider);
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

/// HAPPY-V2-01 D-17, D-20 — family-aggregate variant for group-mode
/// "Family · Top categories" card.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the card renders "Family data not available" instead of a misleading
/// single-book result.
@riverpod
Future<MetricResult<PerCategorySoulBreakdown>> perCategorySoulBreakdownFamily(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
  required JoyMetricVariant joyMetricVariant,
}) async {
  final activeGroup = await ref.watch(activeGroupProvider.future);
  if (activeGroup == null) return const Empty();

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((shadow) => shadow.book.id).toList();
  if (groupBookIds.length < 2) return const Empty(); // D-20 gate

  final useCase = ref.watch(
    getPerCategorySoulBreakdownAcrossBooksUseCaseProvider,
  );
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

/// STATSUI-V2-01 single-book Soul-vs-Survival engagement snapshot.
///
/// Window-keyed Future provider that delegates to
/// [GetSoulVsSurvivalSnapshotUseCase]. The use case enforces the D-05
/// either-ledger-zero gate (any side missing/zero → [Empty]).
@riverpod
Future<MetricResult<SoulVsSurvivalSnapshot>> soulVsSurvivalSnapshot(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  required JoyMetricVariant joyMetricVariant,
}) async {
  final useCase = ref.watch(getSoulVsSurvivalSnapshotUseCaseProvider);
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

/// STATSUI-V2-01 D-18, D-20 — family-aggregate Soul-vs-Survival snapshot.
///
/// D-20 gate (defense in depth — the use case also short-circuits on empty
/// `groupBookIds`): when fewer than 2 shadow books exist, return [Empty] so
/// the Family compare card renders the empty state rather than a half-
/// populated family aggregate.
@riverpod
Future<MetricResult<SoulVsSurvivalSnapshot>> soulVsSurvivalSnapshotFamily(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
  required JoyMetricVariant joyMetricVariant,
}) async {
  final activeGroup = await ref.watch(activeGroupProvider.future);
  if (activeGroup == null) return const Empty();

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((shadow) => shadow.book.id).toList();
  if (groupBookIds.length < 2) return const Empty(); // D-20 gate

  final useCase = ref.watch(
    getSoulVsSurvivalSnapshotAcrossBooksUseCaseProvider,
  );
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
