import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

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
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 2, 6),
      );

      await repo.insert(cat);

      final found = await repo.findById('cat_food');
      expect(found, isNotNull);
      expect(found!.name, 'category_food');
      expect(found.isSystem, true);
      expect(found.type, TransactionType.expense);
    });

    test('findByLevel returns level-1 categories', () async {
      await repo.insert(
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: TransactionType.expense,
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
          type: TransactionType.expense,
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
          type: TransactionType.expense,
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
          type: TransactionType.expense,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      final children = await repo.findByParent('cat_food');
      expect(children.length, 1);
      expect(children.first.name, 'Breakfast');
    });

    test('findByType returns expense-only categories', () async {
      await repo.insert(
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: TransactionType.expense,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.insert(
        Category(
          id: 'cat_salary',
          name: 'Salary',
          icon: 'payments',
          color: '#4CAF50',
          level: 1,
          type: TransactionType.income,
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      final expense = await repo.findByType(TransactionType.expense);
      expect(expense.length, 1);
      expect(expense.first.name, 'Food');
    });

    test('insertBatch inserts multiple categories', () async {
      final cats = [
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          createdAt: DateTime(2026, 2, 6),
        ),
        Category(
          id: 'cat_transport',
          name: 'Transport',
          icon: 'car',
          color: '#2196F3',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          createdAt: DateTime(2026, 2, 6),
        ),
      ];

      await repo.insertBatch(cats);

      final all = await repo.findAll();
      expect(all.length, 2);
    });
  });
}
