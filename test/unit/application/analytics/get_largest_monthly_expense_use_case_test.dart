import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_largest_monthly_expense_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetLargestMonthlyExpenseUseCase useCase;

  final startDate = DateTime(2026, 5);
  final endDate = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetLargestMonthlyExpenseUseCase(
      analyticsRepository: repository,
    );
  });

  void stubLargestExpense(LargestMonthlyExpense? row) {
    when(
      () => repository.getLargestMonthlyExpense(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => row);
  }

  Future<LargestMonthlyExpense?> execute() {
    return useCase.execute(bookId: 'book-1', year: 2026, month: 5);
  }

  test('returns null when repo returns null', () async {
    stubLargestExpense(null);

    final result = await execute();

    expect(result, isNull);
  });

  test('passes through repo result', () async {
    final row = LargestMonthlyExpense(
      transactionId: 't1',
      amount: 5000,
      categoryId: 'food',
      timestamp: DateTime(2026, 5, 15),
    );
    stubLargestExpense(row);

    final result = await execute();

    expect(result, isNotNull);
    expect(result!.transactionId, 't1');
    expect(result.amount, 5000);
  });

  test('uses correct month boundaries', () async {
    stubLargestExpense(null);

    await execute();

    verify(
      () => repository.getLargestMonthlyExpense(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).called(1);
  });
}
