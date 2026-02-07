import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/analytics/demo_data_service.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../domain/models/budget_progress.dart';
import '../../domain/models/expense_trend.dart';
import '../../domain/models/monthly_report.dart';
import '../providers/analytics_providers.dart';
import '../widgets/budget_progress_list.dart';
import '../widgets/category_breakdown_list.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/daily_expense_chart.dart';
import '../widgets/expense_trend_chart.dart';
import '../widgets/ledger_ratio_chart.dart';
import '../widgets/month_comparison_card.dart';
import '../widgets/summary_cards.dart';

/// Main analytics screen showing all reports and charts.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final year = selectedMonth.year;
    final month = selectedMonth.month;

    final reportAsync = ref.watch(
      monthlyReportProvider(bookId: bookId, year: year, month: month),
    );
    final budgetAsync = ref.watch(
      budgetProgressProvider(bookId: bookId, year: year, month: month),
    );
    final trendAsync = ref.watch(expenseTrendProvider(bookId: bookId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Generate Demo Data',
            onPressed: () => _generateDemoData(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: _MonthSelector(
            year: year,
            month: month,
            onPrevious: () =>
                ref.read(selectedMonthProvider.notifier).previousMonth(),
            onNext: () => ref.read(selectedMonthProvider.notifier).nextMonth(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            monthlyReportProvider(bookId: bookId, year: year, month: month),
          );
          ref.invalidate(
            budgetProgressProvider(bookId: bookId, year: year, month: month),
          );
          ref.invalidate(expenseTrendProvider(bookId: bookId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Cards
              _buildSection<MonthlyReport>(
                reportAsync,
                (report) => SummaryCards(report: report),
              ),
              const SizedBox(height: 16),

              // Category Pie Chart
              _buildSection<MonthlyReport>(
                reportAsync,
                (report) =>
                    CategoryPieChart(breakdowns: report.categoryBreakdowns),
              ),
              const SizedBox(height: 16),

              // Daily Expense Bar Chart
              _buildSection<MonthlyReport>(
                reportAsync,
                (report) =>
                    DailyExpenseChart(dailyExpenses: report.dailyExpenses),
              ),
              const SizedBox(height: 16),

              // Ledger Ratio
              _buildSection<MonthlyReport>(
                reportAsync,
                (report) => LedgerRatioChart(
                  survivalTotal: report.survivalTotal,
                  soulTotal: report.soulTotal,
                ),
              ),
              const SizedBox(height: 16),

              // Budget Progress
              _buildSection<List<BudgetProgress>>(
                budgetAsync,
                (list) => BudgetProgressList(progressList: list),
              ),
              const SizedBox(height: 16),

              // 6-Month Trend
              _buildSection<ExpenseTrendData>(
                trendAsync,
                (data) => ExpenseTrendChart(trendData: data),
              ),
              const SizedBox(height: 16),

              // Category Breakdown List
              _buildSection<MonthlyReport>(
                reportAsync,
                (report) => CategoryBreakdownList(
                  breakdowns: report.categoryBreakdowns,
                ),
              ),
              const SizedBox(height: 16),

              // Month Comparison
              _buildSection<MonthlyReport>(reportAsync, (report) {
                if (report.previousMonthComparison == null) {
                  return const SizedBox.shrink();
                }
                return MonthComparisonCard(
                  comparison: report.previousMonthComparison!,
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateDemoData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Demo Data'),
        content: const Text(
          'This will create sample transactions for the last 3 months '
          'to showcase analytics features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final database = ref.read(appDatabaseProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final service = DemoDataService(
      database: database,
      categoryRepository: categoryRepo,
    );

    try {
      await service.generateDemoData(bookId: bookId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo data generated! Pull to refresh.')),
      );
      // Invalidate all providers to reload
      final selectedMonth = ref.read(selectedMonthProvider);
      ref.invalidate(
        monthlyReportProvider(
          bookId: bookId,
          year: selectedMonth.year,
          month: selectedMonth.month,
        ),
      );
      ref.invalidate(
        budgetProgressProvider(
          bookId: bookId,
          year: selectedMonth.year,
          month: selectedMonth.month,
        ),
      );
      ref.invalidate(expenseTrendProvider(bookId: bookId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildSection<T>(
    AsyncValue<T> asyncValue,
    Widget Function(T data) builder,
  ) {
    return asyncValue.when(
      data: builder,
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.year,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final int year;
  final int month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(
            '$year/$month',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}
