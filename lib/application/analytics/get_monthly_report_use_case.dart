import '../../data/daos/analytics_dao.dart';
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/analytics/domain/models/daily_expense.dart';
import '../../features/analytics/domain/models/month_comparison.dart';
import '../../features/analytics/domain/models/monthly_report.dart';

/// Generates a comprehensive monthly financial report.
///
/// Aggregates transaction data into income/expense totals, category breakdowns,
/// daily spending patterns, ledger type splits, and month-over-month comparison.
class GetMonthlyReportUseCase {
  GetMonthlyReportUseCase({
    required AnalyticsDao analyticsDao,
    required CategoryRepository categoryRepository,
  }) : _analyticsDao = analyticsDao,
       _categoryRepo = categoryRepository;

  final AnalyticsDao _analyticsDao;
  final CategoryRepository _categoryRepo;

  Future<MonthlyReport> execute({
    required String bookId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // Run independent queries in parallel
    final results = await Future.wait([
      _analyticsDao.getMonthlyTotals(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
      _analyticsDao.getCategoryTotals(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
      _analyticsDao.getDailyTotals(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
      _analyticsDao.getLedgerTotals(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
      _categoryRepo.findAll(),
    ]);

    final totals = results[0] as MonthlyTotalsResult;
    final categoryTotals = results[1] as List<CategoryTotalResult>;
    final dailyTotals = results[2] as List<DailyTotalResult>;
    final ledgerTotals = results[3] as List<LedgerTotalResult>;
    final categories = results[4] as List<Category>;

    final categoryMap = <String, Category>{};
    for (final cat in categories) {
      categoryMap[cat.id] = cat;
    }

    // Calculate savings
    final savings = totals.totalIncome - totals.totalExpenses;
    final savingsRate = totals.totalIncome > 0
        ? (savings / totals.totalIncome * 100)
        : 0.0;

    // Build category breakdowns
    final categoryBreakdowns = _buildCategoryBreakdowns(
      categoryTotals: categoryTotals,
      categoryMap: categoryMap,
      totalExpenses: totals.totalExpenses,
    );

    // Build daily expenses (fill in zero-days)
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dailyExpenses = _buildDailyExpenses(
      dailyTotals: dailyTotals,
      year: year,
      month: month,
      daysInMonth: daysInMonth,
    );

    // Ledger splits
    int survivalTotal = 0;
    int soulTotal = 0;
    for (final lt in ledgerTotals) {
      if (lt.ledgerType == 'survival') {
        survivalTotal = lt.totalAmount;
      } else if (lt.ledgerType == 'soul') {
        soulTotal = lt.totalAmount;
      }
    }

    // Previous month comparison
    final comparison = await _getPreviousMonthComparison(
      bookId: bookId,
      currentYear: year,
      currentMonth: month,
      currentIncome: totals.totalIncome,
      currentExpenses: totals.totalExpenses,
    );

    return MonthlyReport(
      year: year,
      month: month,
      totalIncome: totals.totalIncome,
      totalExpenses: totals.totalExpenses,
      savings: savings,
      savingsRate: savingsRate,
      survivalTotal: survivalTotal,
      soulTotal: soulTotal,
      categoryBreakdowns: categoryBreakdowns,
      dailyExpenses: dailyExpenses,
      previousMonthComparison: comparison,
    );
  }

  List<CategoryBreakdown> _buildCategoryBreakdowns({
    required List<CategoryTotalResult> categoryTotals,
    required Map<String, Category> categoryMap,
    required int totalExpenses,
  }) {
    return categoryTotals.map((ct) {
      final cat = categoryMap[ct.categoryId];
      final percentage = totalExpenses > 0
          ? (ct.totalAmount / totalExpenses * 100)
          : 0.0;

      return CategoryBreakdown(
        categoryId: ct.categoryId,
        categoryName: cat?.name ?? ct.categoryId,
        icon: cat?.icon ?? '',
        color: cat?.color ?? '#9E9E9E',
        amount: ct.totalAmount,
        percentage: percentage,
        transactionCount: ct.transactionCount,
        budgetAmount: cat?.budgetAmount,
        budgetProgress: cat?.budgetAmount != null && cat!.budgetAmount! > 0
            ? (ct.totalAmount / cat.budgetAmount! * 100)
            : null,
      );
    }).toList();
  }

  List<DailyExpense> _buildDailyExpenses({
    required List<DailyTotalResult> dailyTotals,
    required int year,
    required int month,
    required int daysInMonth,
  }) {
    final dailyMap = <int, int>{};
    for (final dt in dailyTotals) {
      dailyMap[dt.date.day] = dt.totalAmount;
    }

    return List.generate(daysInMonth, (index) {
      final day = index + 1;
      return DailyExpense(
        date: DateTime(year, month, day),
        amount: dailyMap[day] ?? 0,
      );
    });
  }

  Future<MonthComparison?> _getPreviousMonthComparison({
    required String bookId,
    required int currentYear,
    required int currentMonth,
    required int currentIncome,
    required int currentExpenses,
  }) async {
    int prevYear = currentYear;
    int prevMonth = currentMonth - 1;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }

    final prevStart = DateTime(prevYear, prevMonth, 1);
    final prevEnd = DateTime(prevYear, prevMonth + 1, 0, 23, 59, 59);

    final prevTotals = await _analyticsDao.getMonthlyTotals(
      bookId: bookId,
      startDate: prevStart,
      endDate: prevEnd,
    );

    if (prevTotals.totalIncome == 0 && prevTotals.totalExpenses == 0) {
      return null;
    }

    final incomeChange = prevTotals.totalIncome > 0
        ? ((currentIncome - prevTotals.totalIncome) /
              prevTotals.totalIncome *
              100)
        : 0.0;

    final expenseChange = prevTotals.totalExpenses > 0
        ? ((currentExpenses - prevTotals.totalExpenses) /
              prevTotals.totalExpenses *
              100)
        : 0.0;

    return MonthComparison(
      previousMonth: prevMonth,
      previousYear: prevYear,
      previousIncome: prevTotals.totalIncome,
      previousExpenses: prevTotals.totalExpenses,
      incomeChange: incomeChange,
      expenseChange: expenseChange,
    );
  }
}
