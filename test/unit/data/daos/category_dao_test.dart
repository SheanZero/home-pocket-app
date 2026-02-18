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
    group('insertCategory and findById', () {
      test('inserts and retrieves a category', () async {
        final now = DateTime(2026, 2, 6);

        await dao.insertCategory(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          isSystem: true,
          sortOrder: 1,
          createdAt: now,
        );

        final cat = await dao.findById('cat_food');
        expect(cat, isNotNull);
        expect(cat!.name, 'Food');
        expect(cat.isSystem, true);
        expect(cat.isArchived, false);
        expect(cat.updatedAt, isNull);
      });

      test('inserts with isArchived and updatedAt', () async {
        final now = DateTime(2026, 2, 6);
        final updated = DateTime(2026, 2, 7);

        await dao.insertCategory(
          id: 'cat_old',
          name: 'Old Category',
          icon: 'archive',
          color: '#999999',
          level: 1,
          isArchived: true,
          createdAt: now,
          updatedAt: updated,
        );

        final cat = await dao.findById('cat_old');
        expect(cat, isNotNull);
        expect(cat!.isArchived, true);
        expect(cat.updatedAt, updated);
      });
    });

    group('validation asserts', () {
      test('L1 with parentId throws assertion error', () async {
        final now = DateTime(2026, 2, 6);

        expect(
          () => dao.insertCategory(
            id: 'cat_bad',
            name: 'Bad',
            icon: 'error',
            color: '#FF0000',
            parentId: 'some_parent',
            level: 1,
            createdAt: now,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('L2 without parentId throws assertion error', () async {
        final now = DateTime(2026, 2, 6);

        expect(
          () => dao.insertCategory(
            id: 'cat_bad',
            name: 'Bad',
            icon: 'error',
            color: '#FF0000',
            level: 2,
            createdAt: now,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    test('findByLevel returns categories at specific depth', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food_breakfast',
        name: 'Breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        createdAt: now,
      );

      final level1 = await dao.findByLevel(1);
      expect(level1.length, 1);
      expect(level1.first.name, 'Food');

      final level2 = await dao.findByLevel(2);
      expect(level2.length, 1);
      expect(level2.first.name, 'Breakfast');
    });

    test('findByParent returns child categories', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food_breakfast',
        name: 'Breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
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
        sortOrder: 2,
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        sortOrder: 1,
        createdAt: now,
      );

      final all = await dao.findAll();
      expect(all.length, 2);
      expect(all.first.name, 'Food');
    });

    group('findActive', () {
      test('returns only non-archived categories', () async {
        final now = DateTime(2026, 2, 6);

        await dao.insertCategory(
          id: 'cat_active',
          name: 'Active',
          icon: 'check',
          color: '#4CAF50',
          level: 1,
          isArchived: false,
          sortOrder: 1,
          createdAt: now,
        );

        await dao.insertCategory(
          id: 'cat_archived',
          name: 'Archived',
          icon: 'archive',
          color: '#999999',
          level: 1,
          isArchived: true,
          sortOrder: 2,
          createdAt: now,
        );

        final active = await dao.findActive();
        expect(active.length, 1);
        expect(active.first.name, 'Active');
      });

      test('orders by sortOrder', () async {
        final now = DateTime(2026, 2, 6);

        await dao.insertCategory(
          id: 'cat_b',
          name: 'B',
          icon: 'b',
          color: '#000000',
          level: 1,
          sortOrder: 2,
          createdAt: now,
        );

        await dao.insertCategory(
          id: 'cat_a',
          name: 'A',
          icon: 'a',
          color: '#000000',
          level: 1,
          sortOrder: 1,
          createdAt: now,
        );

        final active = await dao.findActive();
        expect(active.length, 2);
        expect(active.first.name, 'A');
      });
    });

    group('updateCategory', () {
      test('updates name and sets updatedAt', () async {
        final now = DateTime(2026, 2, 6);
        final later = DateTime(2026, 2, 7);

        await dao.insertCategory(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          createdAt: now,
        );

        await dao.updateCategory(
          id: 'cat_food',
          name: 'Groceries',
          updatedAt: later,
        );

        final cat = await dao.findById('cat_food');
        expect(cat, isNotNull);
        expect(cat!.name, 'Groceries');
        expect(cat.icon, 'restaurant'); // unchanged
        expect(cat.updatedAt, later);
      });

      test('updates isArchived', () async {
        final now = DateTime(2026, 2, 6);
        final later = DateTime(2026, 2, 7);

        await dao.insertCategory(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          createdAt: now,
        );

        await dao.updateCategory(
          id: 'cat_food',
          isArchived: true,
          updatedAt: later,
        );

        final cat = await dao.findById('cat_food');
        expect(cat, isNotNull);
        expect(cat!.isArchived, true);
        expect(cat.updatedAt, later);
      });

      test('updates multiple fields at once', () async {
        final now = DateTime(2026, 2, 6);
        final later = DateTime(2026, 2, 7);

        await dao.insertCategory(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          sortOrder: 1,
          createdAt: now,
        );

        await dao.updateCategory(
          id: 'cat_food',
          name: 'Meals',
          icon: 'dining',
          color: '#E91E63',
          sortOrder: 5,
          updatedAt: later,
        );

        final cat = await dao.findById('cat_food');
        expect(cat, isNotNull);
        expect(cat!.name, 'Meals');
        expect(cat.icon, 'dining');
        expect(cat.color, '#E91E63');
        expect(cat.sortOrder, 5);
        expect(cat.updatedAt, later);
      });
    });

    group('insertBatch', () {
      test('inserts multiple categories', () async {
        final now = DateTime(2026, 2, 6);

        await dao.insertBatch([
          CategoryInsertData(
            id: 'cat_food',
            name: 'Food',
            icon: 'restaurant',
            color: '#FF5722',
            level: 1,
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
            isSystem: true,
            sortOrder: 2,
            createdAt: now,
          ),
        ]);

        final all = await dao.findAll();
        expect(all.length, 2);
        expect(all.first.name, 'Food');
        expect(all.last.name, 'Transport');
      });

      test('inserts L1 and L2 categories together', () async {
        final now = DateTime(2026, 2, 6);

        await dao.insertBatch([
          CategoryInsertData(
            id: 'cat_food',
            name: 'Food',
            icon: 'restaurant',
            color: '#FF5722',
            level: 1,
            sortOrder: 1,
            createdAt: now,
          ),
          CategoryInsertData(
            id: 'cat_food_breakfast',
            name: 'Breakfast',
            icon: 'free_breakfast',
            color: '#FF5722',
            parentId: 'cat_food',
            level: 2,
            sortOrder: 1,
            createdAt: now,
          ),
        ]);

        final children = await dao.findByParent('cat_food');
        expect(children.length, 1);
        expect(children.first.name, 'Breakfast');
      });

      test('L1 with parentId throws assertion error', () async {
        final now = DateTime(2026, 2, 6);

        expect(
          () => dao.insertBatch([
            CategoryInsertData(
              id: 'cat_bad',
              name: 'Bad',
              icon: 'error',
              color: '#FF0000',
              parentId: 'some_parent',
              level: 1,
              createdAt: now,
            ),
          ]),
          throwsA(isA<AssertionError>()),
        );
      });

      test('L2 without parentId throws assertion error', () async {
        final now = DateTime(2026, 2, 6);

        expect(
          () => dao.insertBatch([
            CategoryInsertData(
              id: 'cat_bad',
              name: 'Bad',
              icon: 'error',
              color: '#FF0000',
              level: 2,
              createdAt: now,
            ),
          ]),
          throwsA(isA<AssertionError>()),
        );
      });

      test('preserves isArchived and updatedAt', () async {
        final now = DateTime(2026, 2, 6);
        final updated = DateTime(2026, 2, 7);

        await dao.insertBatch([
          CategoryInsertData(
            id: 'cat_archived',
            name: 'Archived',
            icon: 'archive',
            color: '#999999',
            level: 1,
            isArchived: true,
            createdAt: now,
            updatedAt: updated,
          ),
        ]);

        final cat = await dao.findById('cat_archived');
        expect(cat, isNotNull);
        expect(cat!.isArchived, true);
        expect(cat.updatedAt, updated);
      });
    });

    test('deleteAll removes all categories', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        createdAt: now,
      );

      await dao.deleteAll();

      final all = await dao.findAll();
      expect(all, isEmpty);
    });
  });
}
