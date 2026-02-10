import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/analytics/domain/models/budget_progress.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';

/// Calculates budget progress for all budgeted categories in a given month.
class GetBudgetProgressUseCase {
  GetBudgetProgressUseCase({
    required AnalyticsRepository analyticsRepository,
    required CategoryRepository categoryRepository,
  }) : _analyticsRepository = analyticsRepository,
       _categoryRepo = categoryRepository;

  final AnalyticsRepository _analyticsRepository;
  final CategoryRepository _categoryRepo;

  Future<List<BudgetProgress>> execute({
    required String bookId,
    required int year,
    required int month,
  }) async {
    final categories = await _categoryRepo.findWithBudget();
    if (categories.isEmpty) return [];

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final categoryTotals = await _analyticsRepository.getCategoryTotals(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    final spendingMap = <String, int>{};
    for (final ct in categoryTotals) {
      spendingMap[ct.categoryId] = ct.totalAmount;
    }

    final progressList = <BudgetProgress>[];
    for (final cat in categories) {
      if (cat.budgetAmount == null || cat.budgetAmount! <= 0) continue;

      final spentAmount = spendingMap[cat.id] ?? 0;
      final percentage = spentAmount / cat.budgetAmount! * 100;
      final remainingAmount = cat.budgetAmount! - spentAmount;

      BudgetStatus status;
      if (percentage >= 100) {
        status = BudgetStatus.exceeded;
      } else if (percentage >= 80) {
        status = BudgetStatus.warning;
      } else {
        status = BudgetStatus.safe;
      }

      progressList.add(
        BudgetProgress(
          categoryId: cat.id,
          categoryName: cat.name,
          icon: cat.icon,
          color: cat.color,
          budgetAmount: cat.budgetAmount!,
          spentAmount: spentAmount,
          percentage: percentage,
          status: status,
          remainingAmount: remainingAmount,
        ),
      );
    }

    // Sort by percentage descending (most at risk first)
    progressList.sort((a, b) => b.percentage.compareTo(a.percentage));
    return progressList;
  }
}
