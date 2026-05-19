import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// STATSUI-06 / D-15 — single largest monthly expense across TOTAL ledger.
class GetLargestMonthlyExpenseUseCase {
  GetLargestMonthlyExpenseUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<LargestMonthlyExpense?> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    TimeWindowValidation.assertValid(startDate, endDate);
    return _repo.getLargestMonthlyExpense(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
