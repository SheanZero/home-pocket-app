import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  group('Category Model', () {
    test('should create level 1 category', () {
      final category = Category(
        id: 'cat_food',
        name: '餐饮',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 2, 4),
      );

      expect(category.id, 'cat_food');
      expect(category.level, 1);
      expect(category.parentId, isNull);
      expect(category.isSystem, isTrue);
    });

    test('should create level 2 category with parent', () {
      final category = Category(
        id: 'cat_food_breakfast',
        name: '早餐',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 2, 4),
      );

      expect(category.level, 2);
      expect(category.parentId, 'cat_food');
    });

    test('should create level 3 category', () {
      final category = Category(
        id: 'cat_food_breakfast_bakery',
        name: '面包店',
        icon: 'bakery_dining',
        color: '#FF5722',
        parentId: 'cat_food_breakfast',
        level: 3,
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 2, 4),
      );

      expect(category.level, 3);
      expect(category.parentId, 'cat_food_breakfast');
    });

    test('should provide system categories', () {
      final systemCategories = Category.systemCategories;

      expect(systemCategories, isNotEmpty);
      expect(systemCategories.length, greaterThanOrEqualTo(20));

      final foodCategory = systemCategories.firstWhere(
        (c) => c.id == 'cat_food',
      );
      expect(foodCategory.name, '餐饮');
      expect(foodCategory.isSystem, isTrue);
    });

    test('should allow custom categories', () {
      final customCategory = Category(
        id: 'cat_custom_hobby',
        name: '我的爱好',
        icon: 'favorite',
        color: '#9C27B0',
        level: 1,
        type: TransactionType.expense,
        isSystem: false,
        sortOrder: 100,
        createdAt: DateTime(2026, 2, 4),
      );

      expect(customCategory.isSystem, isFalse);
    });

    test('should organize categories hierarchically', () {
      final categories = Category.systemCategories;

      // Find level 1 category
      final food = categories.firstWhere((c) => c.id == 'cat_food');
      expect(food.level, 1);
      expect(food.parentId, isNull);

      // Find level 2 category
      final breakfast = categories.firstWhere(
        (c) => c.id == 'cat_food_breakfast',
      );
      expect(breakfast.level, 2);
      expect(breakfast.parentId, 'cat_food');

      // Find level 3 category
      final bakery = categories.firstWhere(
        (c) => c.id == 'cat_food_breakfast_bakery',
      );
      expect(bakery.level, 3);
      expect(bakery.parentId, 'cat_food_breakfast');
    });
  });
}
