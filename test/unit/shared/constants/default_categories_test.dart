import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

void main() {
  group('DefaultCategories', () {
    test('all categories have unique IDs', () {
      final ids = DefaultCategories.all.map((c) => c.id).toSet();
      expect(ids.length, DefaultCategories.all.length);
    });

    test('all categories are marked as system', () {
      for (final cat in DefaultCategories.all) {
        expect(cat.isSystem, isTrue, reason: '${cat.id} should be isSystem');
      }
    });

    test('level 1 categories have no parentId', () {
      final level1 = DefaultCategories.all.where((c) => c.level == 1);
      expect(level1.length, greaterThanOrEqualTo(7));
      for (final cat in level1) {
        expect(cat.parentId, isNull,
            reason: '${cat.id} level-1 should have no parent');
      }
    });

    test('level 2 categories reference valid level 1 parents', () {
      final level1Ids = DefaultCategories.all
          .where((c) => c.level == 1)
          .map((c) => c.id)
          .toSet();
      final level2 = DefaultCategories.all.where((c) => c.level == 2);
      for (final cat in level2) {
        expect(level1Ids.contains(cat.parentId), isTrue,
            reason: '${cat.id} parent ${cat.parentId} not found in level 1');
      }
    });

    test('contains both expense and income categories', () {
      final types = DefaultCategories.all.map((c) => c.type).toSet();
      expect(types, contains(TransactionType.expense));
      expect(types, contains(TransactionType.income));
    });

    test('expense categories getter returns only expense', () {
      for (final cat in DefaultCategories.expense) {
        expect(cat.type, TransactionType.expense);
      }
    });

    test('income categories getter returns only income', () {
      for (final cat in DefaultCategories.income) {
        expect(cat.type, TransactionType.income);
      }
    });
  });
}
