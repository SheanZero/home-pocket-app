import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';

void main() {
  group('Category', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 2, 6);
      final cat = Category(
        id: 'cat_food',
        name: 'category_food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        createdAt: now,
      );

      expect(cat.id, 'cat_food');
      expect(cat.name, 'category_food');
      expect(cat.level, 1);
      expect(cat.isSystem, false);
      expect(cat.sortOrder, 0);
      expect(cat.parentId, isNull);
    });

    test('system category stores localization key', () {
      final now = DateTime(2026, 2, 6);
      final cat = Category(
        id: 'cat_food',
        name: 'category_food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,

        isSystem: true,
        createdAt: now,
      );

      expect(cat.isSystem, true);
      expect(cat.name, 'category_food');
    });

    test('supports parent-child hierarchy via parentId', () {
      final now = DateTime(2026, 2, 6);
      final child = Category(
        id: 'cat_food_breakfast',
        name: 'category_food_breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,

        createdAt: now,
      );

      expect(child.parentId, 'cat_food');
      expect(child.level, 2);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 2, 6, 10, 30);
      final cat = Category(
        id: 'cat_food',
        name: 'category_food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,

        isSystem: true,
        sortOrder: 1,
        createdAt: now,
      );

      final json = cat.toJson();
      final restored = Category.fromJson(json);

      expect(restored, cat);
    });

    test('copyWith creates new instance', () {
      final now = DateTime(2026, 2, 6);
      final cat = Category(
        id: 'cat_food',
        name: 'category_food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        createdAt: now,
      );

      final updated = cat.copyWith(name: 'Dining');
      expect(updated.name, 'Dining');
      expect(updated.id, 'cat_food');
    });
  });
}
