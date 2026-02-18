import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';

void main() {
  late AppDatabase db;
  late CategoryDao dao;
  late CategoryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryDao(db);
    repo = CategoryRepositoryImpl(dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepositoryImpl', () {
    test('insert and findById', () async {
      final cat = Category(
        id: 'cat_food',
        name: 'category_food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 2, 6),
      );

      await repo.insert(cat);

      final found = await repo.findById('cat_food');
      expect(found, isNotNull);
      expect(found!.name, 'category_food');
      expect(found.isSystem, true);
      expect(found.isArchived, false);
    });

    test('findByLevel returns level-1 categories', () async {
      await repo.insert(
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.insert(
        Category(
          id: 'cat_food_breakfast',
          name: 'Breakfast',
          icon: 'free_breakfast',
          color: '#FF5722',
          parentId: 'cat_food',
          level: 2,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      final level1 = await repo.findByLevel(1);
      expect(level1.length, 1);
      expect(level1.first.name, 'Food');
    });

    test('findByParent returns child categories', () async {
      await repo.insert(
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.insert(
        Category(
          id: 'cat_food_breakfast',
          name: 'Breakfast',
          icon: 'free_breakfast',
          color: '#FF5722',
          parentId: 'cat_food',
          level: 2,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      final children = await repo.findByParent('cat_food');
      expect(children.length, 1);
      expect(children.first.name, 'Breakfast');
    });

    test('insertBatch inserts multiple categories', () async {
      final cats = [
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          isSystem: true,
          createdAt: DateTime(2026, 2, 6),
        ),
        Category(
          id: 'cat_transport',
          name: 'Transport',
          icon: 'car',
          color: '#2196F3',
          level: 1,
          isSystem: true,
          createdAt: DateTime(2026, 2, 6),
        ),
      ];

      await repo.insertBatch(cats);

      final all = await repo.findAll();
      expect(all.length, 2);
    });

    test('update modifies specified fields', () async {
      await repo.insert(
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.update(id: 'cat_food', name: 'Meals', color: '#E91E63');

      final found = await repo.findById('cat_food');
      expect(found, isNotNull);
      expect(found!.name, 'Meals');
      expect(found.color, '#E91E63');
      expect(found.icon, 'restaurant'); // unchanged
      expect(found.updatedAt, isNotNull);
    });

    test('findActive excludes archived categories', () async {
      await repo.insert(
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.insert(
        Category(
          id: 'cat_old',
          name: 'Old Category',
          icon: 'archive',
          color: '#9E9E9E',
          level: 1,
          isArchived: true,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      final active = await repo.findActive();
      expect(active.length, 1);
      expect(active.first.name, 'Food');
    });

    test('deleteAll removes all categories', () async {
      await repo.insert(
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.deleteAll();

      final all = await repo.findAll();
      expect(all, isEmpty);
    });
  });
}
