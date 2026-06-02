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

    group('parentCategoryIconFromId', () {
      test('resolves an L2 id to its PARENT L1 icon, not the L2 icon', () {
        // cat_hobbies_games icon = videogame_asset; parent cat_hobbies =
        // sports_esports. The parent-aware resolver must pick the L1 icon.
        expect(
          parentCategoryIconFromId('cat_hobbies_games'),
          Icons.sports_esports,
        );
        expect(
          parentCategoryIconFromId('cat_hobbies_games'),
          isNot(Icons.videogame_asset),
        );
      });

      test('passes an L1 id through to its own icon', () {
        expect(parentCategoryIconFromId('cat_food'), Icons.restaurant);
      });

      test('returns Icons.favorite_border for an unknown / custom id', () {
        expect(
          parentCategoryIconFromId('unknown_or_custom_id'),
          Icons.favorite_border,
        );
      });

      test(
        'falls back to the category own icon when the parent is missing '
        'from defaults',
        () {
          // Exercises the parent-missing branch: an L2 whose parentId points
          // at a non-default id resolves to its OWN icon (menu_book), never
          // throwing.
          final orphan = Category(
            id: 'custom_orphan_l2',
            name: 'custom',
            icon: 'menu_book',
            color: '#9C27B0',
            parentId: 'cat_nonexistent_parent',
            level: 2,
            createdAt: DateTime(2026, 1, 1),
          );
          expect(parentCategoryIconForCategory(orphan), Icons.menu_book);
        },
      );
    });
  });
}
