import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';

/// STATSUI-06 / D-15 — single largest monthly expense across TOTAL ledger.
class GetLargestMonthlyExpenseUseCase {
  GetLargestMonthlyExpenseUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<LargestMonthlyExpense?> execute({
    required String bookId,
    required int year,
    required int month,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return _repo.getLargestMonthlyExpense(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
