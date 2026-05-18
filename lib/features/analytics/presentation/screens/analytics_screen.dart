import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/accounting/presentation/screens/transaction_entry_screen.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import '../../../../generated/app_localizations.dart';
import '../../domain/models/metric_result.dart';
import '../providers/state_analytics.dart';
import '../providers/state_happiness.dart';
import '../widgets/analytics_card_error_state.dart';
import '../widgets/analytics_screen_section_header.dart';
import '../widgets/best_joy_story_strip.dart';
import '../widgets/category_spend_donut_chart.dart';
import '../widgets/family_insight_card.dart';
import '../widgets/joy_ledger_thin_sample_fallback.dart';
import '../widgets/joy_trend_line_chart.dart';
import '../widgets/kpi_mini_hero_strip.dart';
import '../widgets/largest_expense_story_card.dart';
import '../widgets/month_chip_picker.dart';
import '../widgets/monthly_spend_trend_bar_chart.dart';
import '../widgets/satisfaction_distribution_histogram.dart';

/// Phase 11 Variant delta unified analytics dashboard.
///
/// Structure: AppBar + MonthChipPicker, KPI mini-hero, then the Time,
/// Distribution, and Stories themed groups. Each data card owns its own
/// AsyncValue.when branch so one failing provider does not blank the screen.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final selected = ref.watch(selectedMonthProvider);
    final year = selected.year;
    final month = selected.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
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
          MonthChipPicker(
            locale: locale,
            earliestMonth: earliestMonthAsync.value,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(
          ref,
          selected: selected,
          currencyCode: currencyCode,
          isGroupMode: isGroupMode,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KpiHero(
                bookId: bookId,
                year: year,
                month: month,
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
                anchor: selected,
                locale: locale,
              ),
              const SizedBox(height: 8),
              _JoyTrendOrFallback(
                bookId: bookId,
                year: year,
                month: month,
                currencyCode: currencyCode,
                daysInMonth: daysInMonth,
                locale: locale,
              ),
              const SizedBox(height: 32),
              AnalyticsScreenSectionHeader(
                label: l10n.analyticsGroupHeaderDistribution,
              ),
              const SizedBox(height: 8),
              _CategoryDonutCard(bookId: bookId, year: year, month: month),
              const SizedBox(height: 8),
              _SatisfactionHistogramOrFallback(
                bookId: bookId,
                year: year,
                month: month,
                currencyCode: currencyCode,
              ),
              const SizedBox(height: 32),
              AnalyticsScreenSectionHeader(
                label: l10n.analyticsGroupHeaderStories,
              ),
              const SizedBox(height: 8),
              _LargestExpenseCard(
                bookId: bookId,
                year: year,
                month: month,
                currencyCode: currencyCode,
                locale: locale,
              ),
              const SizedBox(height: 8),
              _BestJoyCard(
                bookId: bookId,
                year: year,
                month: month,
                currencyCode: currencyCode,
                locale: locale,
              ),
              if (isGroupMode) ...[
                const SizedBox(height: 8),
                _FamilyCard(
                  year: year,
                  month: month,
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
    required DateTime selected,
    required String currencyCode,
    required bool isGroupMode,
  }) {
    final year = selected.year;
    final month = selected.month;
    ref.invalidate(
      monthlyReportProvider(bookId: bookId, year: year, month: month),
    );
    ref.invalidate(expenseTrendProvider(bookId: bookId, anchor: selected));
    ref.invalidate(earliestTransactionMonthProvider(bookId: bookId));
    ref.invalidate(
      happinessReportProvider(
        bookId: bookId,
        year: year,
        month: month,
        currencyCode: currencyCode,
      ),
    );
    ref.invalidate(
      dailyJoyPerYenProvider(
        bookId: bookId,
        year: year,
        month: month,
        currencyCode: currencyCode,
      ),
    );
    ref.invalidate(
      satisfactionDistributionProvider(
        bookId: bookId,
        year: year,
        month: month,
      ),
    );
    ref.invalidate(
      bestJoyMomentProvider(bookId: bookId, year: year, month: month),
    );
    ref.invalidate(
      largestMonthlyExpenseProvider(bookId: bookId, year: year, month: month),
    );
    if (isGroupMode) {
      ref.invalidate(familyHappinessProvider(year: year, month: month));
      ref.invalidate(shadowBooksProvider);
    }
  }
}

class _KpiHero extends ConsumerWidget {
  const _KpiHero({
    required this.bookId,
    required this.year,
    required this.month,
    required this.currencyCode,
    required this.locale,
  });

  final String bookId;
  final int year;
  final int month;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(
      monthlyReportProvider(bookId: bookId, year: year, month: month),
    );
    final happinessAsync = ref.watch(
      happinessReportProvider(
        bookId: bookId,
        year: year,
        month: month,
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
              year: year,
              month: month,
              currencyCode: currencyCode,
            ),
          ),
        ),
      ),
      loading: () => const SizedBox(height: 120),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          monthlyReportProvider(bookId: bookId, year: year, month: month),
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

class _JoyTrendOrFallback extends ConsumerWidget {
  const _JoyTrendOrFallback({
    required this.bookId,
    required this.year,
    required this.month,
    required this.currencyCode,
    required this.daysInMonth,
    required this.locale,
  });

  final String bookId;
  final int year;
  final int month;
  final String currencyCode;
  final int daysInMonth;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(
      dailyJoyPerYenProvider(
        bookId: bookId,
        year: year,
        month: month,
        currencyCode: currencyCode,
      ),
    );
    return dailyAsync.when(
      data: (result) {
        if (_sampleSizeOf(result) < 5) {
          return JoyLedgerThinSampleFallback(
            onAddEntryTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => TransactionEntryScreen(bookId: bookId),
              ),
            ),
          );
        }
        return _AnalyticsDataCard(
          title: S.of(context).analyticsCardTitleJoyTrend,
          caption: S.of(context).analyticsCardCaptionJoyTrendGap,
          child: JoyTrendLineChart(
            result: result,
            daysInMonth: daysInMonth,
            currencyCode: currencyCode,
            locale: locale,
          ),
        );
      },
      loading: () => const SizedBox(height: 240),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          dailyJoyPerYenProvider(
            bookId: bookId,
            year: year,
            month: month,
            currencyCode: currencyCode,
          ),
        ),
      ),
    );
  }
}

class _CategoryDonutCard extends ConsumerWidget {
  const _CategoryDonutCard({
    required this.bookId,
    required this.year,
    required this.month,
  });

  final String bookId;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(
      monthlyReportProvider(bookId: bookId, year: year, month: month),
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
          monthlyReportProvider(bookId: bookId, year: year, month: month),
        ),
      ),
    );
  }
}

class _SatisfactionHistogramOrFallback extends ConsumerWidget {
  const _SatisfactionHistogramOrFallback({
    required this.bookId,
    required this.year,
    required this.month,
    required this.currencyCode,
  });

  final String bookId;
  final int year;
  final int month;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(
      dailyJoyPerYenProvider(
        bookId: bookId,
        year: year,
        month: month,
        currencyCode: currencyCode,
      ),
    );
    final distributionAsync = ref.watch(
      satisfactionDistributionProvider(
        bookId: bookId,
        year: year,
        month: month,
      ),
    );

    return dailyAsync.when(
      data: (daily) {
        if (_sampleSizeOf(daily) < 5) {
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
                year: year,
                month: month,
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 260),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          dailyJoyPerYenProvider(
            bookId: bookId,
            year: year,
            month: month,
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
    required this.year,
    required this.month,
    required this.currencyCode,
    required this.locale,
  });

  final String bookId;
  final int year;
  final int month;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final largestAsync = ref.watch(
      largestMonthlyExpenseProvider(bookId: bookId, year: year, month: month),
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
            year: year,
            month: month,
          ),
        ),
      ),
    );
  }
}

class _BestJoyCard extends ConsumerWidget {
  const _BestJoyCard({
    required this.bookId,
    required this.year,
    required this.month,
    required this.currencyCode,
    required this.locale,
  });

  final String bookId;
  final int year;
  final int month;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joyAsync = ref.watch(
      bestJoyMomentProvider(bookId: bookId, year: year, month: month),
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
          bestJoyMomentProvider(bookId: bookId, year: year, month: month),
        ),
      ),
    );
  }
}

class _FamilyCard extends ConsumerWidget {
  const _FamilyCard({
    required this.year,
    required this.month,
    required this.isGroupMode,
    required this.shadowBooksAsync,
    required this.locale,
  });

  final int year;
  final int month;
  final bool isGroupMode;
  final AsyncValue<List<ShadowBookInfo>?> shadowBooksAsync;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(
      familyHappinessProvider(year: year, month: month),
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
        onRetry: () =>
            ref.invalidate(familyHappinessProvider(year: year, month: month)),
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

int _sampleSizeOf<T>(Object result) {
  return switch (result) {
    Empty<T>() => 0,
    Value<T>(:final sampleSize) => sampleSize,
    _ => 0,
  };
}
