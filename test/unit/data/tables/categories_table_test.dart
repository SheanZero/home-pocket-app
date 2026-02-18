import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  group('Categories table', () {
    test('inserts and retrieves a category', () async {
      final now = DateTime(2026, 2, 6);

      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_food',
              name: 'Food',
              icon: 'restaurant',
              color: '#FF5722',
              level: 1,
              createdAt: now,
            ),
          );

      final rows = await db.select(db.categories).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'cat_food');
      expect(rows.first.name, 'Food');
      expect(rows.first.level, 1);
      expect(rows.first.isSystem, false);
      expect(rows.first.parentId, isNull);
    });

    test('supports parent-child hierarchy', () async {
      final now = DateTime(2026, 2, 6);

      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_food',
              name: 'Food',
              icon: 'restaurant',
              color: '#FF5722',
              level: 1,
              createdAt: now,
            ),
          );

      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_food_breakfast',
              name: 'Breakfast',
              icon: 'free_breakfast',
              color: '#FF5722',
              parentId: const Value('cat_food'),
              level: 2,
              createdAt: now,
            ),
          );

      final children = await (db.select(
        db.categories,
      )..where((t) => t.parentId.equals('cat_food'))).get();

      expect(children.length, 1);
      expect(children.first.name, 'Breakfast');
    });

    test('queries by level', () async {
      final now = DateTime(2026, 2, 6);

      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_food',
              name: 'Food',
              icon: 'restaurant',
              color: '#FF5722',
              level: 1,
              createdAt: now,
            ),
          );

      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_food_breakfast',
              name: 'Breakfast',
              icon: 'free_breakfast',
              color: '#FF5722',
              parentId: const Value('cat_food'),
              level: 2,
              createdAt: now,
            ),
          );

      final level1 = await (db.select(
        db.categories,
      )..where((t) => t.level.equals(1))).get();

      expect(level1.length, 1);
      expect(level1.first.id, 'cat_food');
    });
  });
}
