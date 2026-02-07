import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/budget_progress.dart';

void main() {
  group('BudgetStatus', () {
    test('has three values', () {
      expect(BudgetStatus.values, hasLength(3));
      expect(BudgetStatus.values, contains(BudgetStatus.safe));
      expect(BudgetStatus.values, contains(BudgetStatus.warning));
      expect(BudgetStatus.values, contains(BudgetStatus.exceeded));
    });
  });

  group('BudgetProgress', () {
    test('creates with safe status', () {
      const progress = BudgetProgress(
        categoryId: 'cat_food',
        categoryName: 'Food',
        icon: '🍕',
        color: '#FF0000',
        budgetAmount: 80000,
        spentAmount: 40000,
        percentage: 50.0,
        status: BudgetStatus.safe,
        remainingAmount: 40000,
      );

      expect(progress.categoryId, 'cat_food');
      expect(progress.budgetAmount, 80000);
      expect(progress.spentAmount, 40000);
      expect(progress.percentage, 50.0);
      expect(progress.status, BudgetStatus.safe);
      expect(progress.remainingAmount, 40000);
    });

    test('creates with warning status', () {
      const progress = BudgetProgress(
        categoryId: 'cat_food',
        categoryName: 'Food',
        icon: '🍕',
        color: '#FF0000',
        budgetAmount: 80000,
        spentAmount: 68000,
        percentage: 85.0,
        status: BudgetStatus.warning,
        remainingAmount: 12000,
      );

      expect(progress.status, BudgetStatus.warning);
      expect(progress.remainingAmount, 12000);
    });

    test('creates with exceeded status and negative remaining', () {
      const progress = BudgetProgress(
        categoryId: 'cat_food',
        categoryName: 'Food',
        icon: '🍕',
        color: '#FF0000',
        budgetAmount: 80000,
        spentAmount: 95000,
        percentage: 118.75,
        status: BudgetStatus.exceeded,
        remainingAmount: -15000,
      );

      expect(progress.status, BudgetStatus.exceeded);
      expect(progress.remainingAmount, -15000);
    });

    test('toJson and fromJson roundtrip', () {
      const original = BudgetProgress(
        categoryId: 'cat_food',
        categoryName: 'Food',
        icon: '🍕',
        color: '#FF0000',
        budgetAmount: 80000,
        spentAmount: 40000,
        percentage: 50.0,
        status: BudgetStatus.safe,
        remainingAmount: 40000,
      );

      final json = original.toJson();
      final restored = BudgetProgress.fromJson(json);
      expect(restored, original);
    });

    test('copyWith creates new instance', () {
      const progress = BudgetProgress(
        categoryId: 'cat_food',
        categoryName: 'Food',
        icon: '🍕',
        color: '#FF0000',
        budgetAmount: 80000,
        spentAmount: 40000,
        percentage: 50.0,
        status: BudgetStatus.safe,
        remainingAmount: 40000,
      );

      final updated = progress.copyWith(
        spentAmount: 90000,
        percentage: 112.5,
        status: BudgetStatus.exceeded,
        remainingAmount: -10000,
      );

      expect(updated.spentAmount, 90000);
      expect(updated.status, BudgetStatus.exceeded);
      expect(progress.spentAmount, 40000); // Original unchanged
    });
  });
}
