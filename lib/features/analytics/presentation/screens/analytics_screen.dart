import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import '../../../../generated/app_localizations.dart';
import '../../domain/models/time_window.dart';
import '../providers/state_analytics.dart';
import '../providers/state_happiness.dart';
import '../providers/state_time_window.dart';
import '../widgets/analytics_card_error_state.dart';
import '../widgets/analytics_screen_section_header.dart';
import '../widgets/best_joy_story_strip.dart';
import '../widgets/category_spend_donut_chart.dart';
import '../widgets/family_insight_card.dart';
import '../widgets/kpi_mini_hero_strip.dart';
import '../widgets/largest_expense_story_card.dart';
import '../widgets/monthly_spend_trend_bar_chart.dart';
import '../widgets/satisfaction_distribution_histogram.dart';
import '../widgets/time_window_chip.dart';

/// Phase 11 Variant delta unified analytics dashboard.
///
/// Structure: AppBar + TimeWindowChip, KPI mini-hero, then the Time,
/// Distribution, and Stories themed groups. Each data card owns its own
/// AsyncValue.when branch so one failing provider does not blank the screen.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final window = ref.watch(selectedTimeWindowProvider);
    final range = window.range;
    final startDate = range.start;
    final endDate = range.end;
    final trendAnchor = DateTime(endDate.year, endDate.month);
    final locale =
        ref.watch(locale_providers.currentLocaleProvider).value ??
        Localizations.localeOf(context);

    final bookAsync = ref.watch(
      accounting_providers.bookByIdProvider(bookId: bookId),
    );
    final currencyCode = bookAsync.value?.currency ?? 'JPY';
    final earliestMonthAsync = ref.watch(
      earliestTransactionMonthProvider(bookId: bookId),
    );

    final isGroupMode = ref.watch(isGroupModeProvider);
    final shadowBooksAsync = isGroupMode
        ? ref
              .watch(shadowBooksProvider)
              .whenData<List<ShadowBookInfo>?>((value) => value)
        : const AsyncData<List<ShadowBookInfo>?>(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analyticsTitle),
        actions: [
          TimeWindowChip(
            locale: locale,
            earliestData: earliestMonthAsync.value,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(
          ref,
          startDate: startDate,
          endDate: endDate,
          trendAnchor: trendAnchor,
          currencyCode: currencyCode,
          isGroupMode: isGroupMode,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KpiHero(
                bookId: bookId,
                startDate: startDate,
                endDate: endDate,
                currencyCode: currencyCode,
                locale: locale,
              ),
              const SizedBox(height: 32),
              AnalyticsScreenSectionHeader(
                label: l10n.analyticsGroupHeaderTime,
              ),
              const SizedBox(height: 8),
              _TotalSixMonthCard(
                bookId: bookId,
                anchor: trendAnchor,
                locale: locale,
              ),
              const SizedBox(height: 32),
              AnalyticsScreenSectionHeader(
                label: l10n.analyticsGroupHeaderDistribution,
              ),
              const SizedBox(height: 8),
              _CategoryDonutCard(
                bookId: bookId,
                startDate: startDate,
                endDate: endDate,
              ),
              const SizedBox(height: 8),
              _SatisfactionHistogramOrFallback(
                bookId: bookId,
                startDate: startDate,
                endDate: endDate,
                currencyCode: currencyCode,
              ),
              const SizedBox(height: 32),
              AnalyticsScreenSectionHeader(
                label: l10n.analyticsGroupHeaderStories,
              ),
              const SizedBox(height: 8),
              _LargestExpenseCard(
                bookId: bookId,
                startDate: startDate,
                endDate: endDate,
                currencyCode: currencyCode,
                locale: locale,
              ),
              const SizedBox(height: 8),
              _BestJoyCard(
                bookId: bookId,
                startDate: startDate,
                endDate: endDate,
                currencyCode: currencyCode,
                locale: locale,
              ),
              if (isGroupMode) ...[
                const SizedBox(height: 8),
                _FamilyCard(
                  startDate: startDate,
                  endDate: endDate,
                  isGroupMode: isGroupMode,
                  shadowBooksAsync: shadowBooksAsync,
                  locale: locale,
                ),
              ],
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  void _refresh(
    WidgetRef ref, {
    required DateTime startDate,
    required DateTime endDate,
    required DateTime trendAnchor,
    required String currencyCode,
    required bool isGroupMode,
  }) {
    // D-12: _refresh MUST NOT invalidate any home/* provider (verified by widget test home_screen_isolation_test.dart in Plan 06).
    ref.invalidate(
      monthlyReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    ref.invalidate(expenseTrendProvider(bookId: bookId, anchor: trendAnchor));
    ref.invalidate(earliestTransactionMonthProvider(bookId: bookId));
    ref.invalidate(
      happinessReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        currencyCode: currencyCode,
      ),
    );
    ref.invalidate(
      satisfactionDistributionProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    ref.invalidate(
      bestJoyMomentProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    ref.invalidate(
      largestMonthlyExpenseProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    if (isGroupMode) {
      ref.invalidate(
        familyHappinessProvider(startDate: startDate, endDate: endDate),
      );
      ref.invalidate(shadowBooksProvider);
    }
  }
}

class _KpiHero extends ConsumerWidget {
  const _KpiHero({
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
    required this.locale,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(
      monthlyReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    final happinessAsync = ref.watch(
      happinessReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        currencyCode: currencyCode,
      ),
    );

    return monthlyAsync.when(
      data: (monthly) => happinessAsync.when(
        data: (happiness) => SizedBox(
          height: 120,
          child: KpiMiniHeroStrip(
            monthlyReport: monthly,
            happinessReport: happiness,
            currencyCode: currencyCode,
            locale: locale,
          ),
        ),
        loading: () => const SizedBox(height: 120),
        error: (_, _) => AnalyticsCardErrorState(
          onRetry: () => ref.invalidate(
            happinessReportProvider(
              bookId: bookId,
              startDate: startDate,
              endDate: endDate,
              currencyCode: currencyCode,
            ),
          ),
        ),
      ),
      loading: () => const SizedBox(height: 120),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          monthlyReportProvider(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      ),
    );
  }
}

class _TotalSixMonthCard extends ConsumerWidget {
  const _TotalSixMonthCard({
    required this.bookId,
    required this.anchor,
    required this.locale,
  });

  final String bookId;
  final DateTime anchor;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(
      expenseTrendProvider(bookId: bookId, anchor: anchor),
    );
    return trendAsync.when(
      data: (trend) => _AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleTotalSixMonth,
        caption: S.of(context).analyticsCardCaptionTotalSixMonth,
        child: MonthlySpendTrendBarChart(
          trendData: trend,
          selectedYear: anchor.year,
          selectedMonth: anchor.month,
          locale: locale,
        ),
      ),
      loading: () => const SizedBox(height: 260),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          expenseTrendProvider(bookId: bookId, anchor: anchor),
        ),
      ),
    );
  }
}

class _CategoryDonutCard extends ConsumerWidget {
  const _CategoryDonutCard({
    required this.bookId,
    required this.startDate,
    required this.endDate,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(
      monthlyReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    return monthlyAsync.when(
      data: (monthly) => _AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleCategoryDonut,
        caption: S.of(context).analyticsCardCaptionCategoryDonut,
        child: CategorySpendDonutChart(breakdowns: monthly.categoryBreakdowns),
      ),
      loading: () => const SizedBox(height: 280),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          monthlyReportProvider(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      ),
    );
  }
}

class _SatisfactionHistogramOrFallback extends ConsumerWidget {
  const _SatisfactionHistogramOrFallback({
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final happinessAsync = ref.watch(
      happinessReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        currencyCode: currencyCode,
      ),
    );
    final distributionAsync = ref.watch(
      satisfactionDistributionProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    return happinessAsync.when(
      data: (report) {
        if (report.totalSoulTx < 5) {
          return const SizedBox.shrink();
        }
        return distributionAsync.when(
          data: (buckets) => _AnalyticsDataCard(
            title: S.of(context).analyticsCardTitleSatisfactionHistogram,
            caption: S.of(context).analyticsCardCaptionHistogram,
            child: SatisfactionDistributionHistogram(buckets: buckets),
          ),
          loading: () => const SizedBox(height: 260),
          error: (_, _) => AnalyticsCardErrorState(
            onRetry: () => ref.invalidate(
              satisfactionDistributionProvider(
                bookId: bookId,
                startDate: startDate,
                endDate: endDate,
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 260),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          happinessReportProvider(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            currencyCode: currencyCode,
          ),
        ),
      ),
    );
  }
}

class _LargestExpenseCard extends ConsumerWidget {
  const _LargestExpenseCard({
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
    required this.locale,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final largestAsync = ref.watch(
      largestMonthlyExpenseProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    return largestAsync.when(
      data: (expense) => LargestExpenseStoryCard(
        expense: expense,
        currencyCode: currencyCode,
        locale: locale,
      ),
      loading: () => const SizedBox(height: 110),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          largestMonthlyExpenseProvider(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      ),
    );
  }
}

class _BestJoyCard extends ConsumerWidget {
  const _BestJoyCard({
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
    required this.locale,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joyAsync = ref.watch(
      bestJoyMomentProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    return joyAsync.when(
      data: (joy) => BestJoyStoryStrip(
        bestJoy: joy,
        currencyCode: currencyCode,
        locale: locale,
      ),
      loading: () => const SizedBox(height: 120),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          bestJoyMomentProvider(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      ),
    );
  }
}

class _FamilyCard extends ConsumerWidget {
  const _FamilyCard({
    required this.startDate,
    required this.endDate,
    required this.isGroupMode,
    required this.shadowBooksAsync,
    required this.locale,
  });

  final DateTime startDate;
  final DateTime endDate;
  final bool isGroupMode;
  final AsyncValue<List<ShadowBookInfo>?> shadowBooksAsync;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(
      familyHappinessProvider(startDate: startDate, endDate: endDate),
    );
    return familyAsync.when(
      data: (family) => FamilyInsightCard(
        family: family,
        isGroupMode: isGroupMode,
        shadowBooks: shadowBooksAsync.value,
        locale: locale,
      ),
      loading: () => const SizedBox(height: 110),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          familyHappinessProvider(startDate: startDate, endDate: endDate),
        ),
      ),
    );
  }
}

class _AnalyticsDataCard extends StatelessWidget {
  const _AnalyticsDataCard({
    required this.title,
    required this.caption,
    required this.child,
  });

  final String title;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(caption, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
