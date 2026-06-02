import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/presentation/utils/category_display_utils.dart';

void main() {
  group('category_display_utils', () {
    final l1Category = Category(
      id: 'cat_food',
      name: 'category_food',
      icon: 'restaurant',
      color: '#FF5722',
      level: 1,
      sortOrder: 1,
      createdAt: DateTime(2026, 1, 1),
    );
    final l2Category = Category(
      id: 'cat_food_other',
      name: 'category_food_other',
      icon: 'restaurant',
      color: '#FF5722',
      parentId: 'cat_food',
      level: 2,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    test('formatCategoryPath builds L1 > L2 label', () {
      final label = formatCategoryPath(
        category: l2Category,
        parentCategory: l1Category,
        locale: const Locale('zh'),
      );

      expect(label, '食费 > 其他食费');
    });

    test('resolveParentCategory resolves parent from map', () {
      final parent = resolveParentCategory(l2Category, {
        l1Category.id: l1Category,
        l2Category.id: l2Category,
      });

      expect(parent, isNotNull);
      expect(parent!.id, l1Category.id);
    });

    test('resolveCategoryIcon maps icon name to material icon', () {
      expect(resolveCategoryIcon('restaurant'), Icons.restaurant);
    });

    group('categoryIconFromId', () {
      test('resolves an L1 id (cat_hobbies) to its icon', () {
        expect(categoryIconFromId('cat_hobbies'), Icons.sports_esports);
      });

      test('resolves an L1 id (cat_food) to its icon', () {
        expect(categoryIconFromId('cat_food'), Icons.restaurant);
      });

      test('resolves an L2 id (cat_food_groceries) to its L2 icon', () {
        expect(categoryIconFromId('cat_food_groceries'), Icons.shopping_basket);
      });

      test('returns Icons.favorite_border for an unknown / custom id', () {
        expect(
          categoryIconFromId('unknown_or_custom_id'),
          Icons.favorite_border,
        );
      });
    });
  });
}
