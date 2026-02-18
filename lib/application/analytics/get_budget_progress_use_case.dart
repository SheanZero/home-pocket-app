import '../../features/analytics/domain/models/budget_progress.dart';

/// Calculates budget progress for all budgeted categories in a given month.
///
/// NOTE: Budget tracking per category has been deferred. The `budgetAmount`
/// field was removed from Category. This use case is kept as a compilable
/// placeholder and currently returns an empty list. It will be re-implemented
/// when a dedicated Budget table is introduced.
class GetBudgetProgressUseCase {
  GetBudgetProgressUseCase();

  Future<List<BudgetProgress>> execute({
    required String bookId,
    required int year,
    required int month,
  }) async {
    // Budget tracking deferred — no budget data available yet.
    return [];
  }
}
