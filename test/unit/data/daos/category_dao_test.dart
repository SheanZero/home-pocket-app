import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDao', () {
    test('insertCategory and findById', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        isSystem: true,
        sortOrder: 1,
        createdAt: now,
      );

      final cat = await dao.findById('cat_food');
      expect(cat, isNotNull);
      expect(cat!.name, 'Food');
      expect(cat.isSystem, true);
    });

    test('findByLevel returns categories at specific depth', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food_breakfast',
        name: 'Breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: 'expense',
        createdAt: now,
      );

      final level1 = await dao.findByLevel(1);
      expect(level1.length, 1);
      expect(level1.first.name, 'Food');
    });

    test('findByParent returns child categories', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food_breakfast',
        name: 'Breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: 'expense',
        sortOrder: 1,
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food_lunch',
        name: 'Lunch',
        icon: 'lunch_dining',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: 'expense',
        sortOrder: 2,
        createdAt: now,
      );

      final children = await dao.findByParent('cat_food');
      expect(children.length, 2);
      expect(children.first.name, 'Breakfast');
    });

    test('findAll returns all categories ordered by sortOrder', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_transport',
        name: 'Transport',
        icon: 'car',
        color: '#2196F3',
        level: 1,
        type: 'expense',
        sortOrder: 2,
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        sortOrder: 1,
        createdAt: now,
      );

      final all = await dao.findAll();
      expect(all.length, 2);
      expect(all.first.name, 'Food');
    });

    test('findByType returns only expense or income categories', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_salary',
        name: 'Salary',
        icon: 'payments',
        color: '#4CAF50',
        level: 1,
        type: 'income',
        createdAt: now,
      );

      final expense = await dao.findByType('expense');
      expect(expense.length, 1);
      expect(expense.first.name, 'Food');
    });

    test('insertBatch inserts multiple categories', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBatch([
        CategoryInsertData(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: 'expense',
          isSystem: true,
          sortOrder: 1,
          createdAt: now,
        ),
        CategoryInsertData(
          id: 'cat_transport',
          name: 'Transport',
          icon: 'car',
          color: '#2196F3',
          level: 1,
          type: 'expense',
          isSystem: true,
          sortOrder: 2,
          createdAt: now,
        ),
      ]);

      final all = await dao.findAll();
      expect(all.length, 2);
    });
  });
}
