import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_budget_progress_use_case.dart';

void main() {
  late GetBudgetProgressUseCase useCase;

  setUp(() {
    useCase = GetBudgetProgressUseCase();
  });

  group('GetBudgetProgressUseCase', () {
    test('returns empty list (budget tracking deferred)', () async {
      final progress = await useCase.execute(
        bookId: 'book1',
        year: 2026,
        month: 2,
      );

      expect(progress, isEmpty);
    });
  });
}
