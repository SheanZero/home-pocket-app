import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/features/accounting/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:matcher/matcher.dart' as matcher;

void main() {
  late AppDatabase database;
  late CategoryDao categoryDao;
  late CategoryRepositoryImpl repository;

  setUp(() async {
    // Create in-memory database
    database = AppDatabase(NativeDatabase.memory());
    categoryDao = CategoryDao(database);
    repository = CategoryRepositoryImpl(categoryDao);
  });

  tearDown(() async {
    await database.close();
  });

  group('CategoryRepositoryImpl - CRUD', () {
    test('should insert and find category by ID', () async {
      // Arrange
      final category = Category(
        id: 'cat_test_1',
        name: 'Test Category',
        icon: 'test_icon',
        color: '#FF0000',
        level: 1,
        type: TransactionType.expense,
        isSystem: false,
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      await repository.insert(category);
      final result = await repository.findById('cat_test_1');

      // Assert
      expect(result, matcher.isNotNull);
      expect(result!.id, 'cat_test_1');
      expect(result.name, 'Test Category');
      expect(result.icon, 'test_icon');
      expect(result.color, '#FF0000');
      expect(result.level, 1);
      expect(result.type, TransactionType.expense);
      expect(result.isSystem, false);
      expect(result.sortOrder, 1);
    });

    test('should find all categories', () async {
      // Arrange
      final category1 = Category(
        id: 'cat_test_1',
        name: 'Category 1',
        icon: 'icon1',
        color: '#FF0000',
        level: 1,
        type: TransactionType.expense,
        isSystem: false,
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      );

      final category2 = Category(
        id: 'cat_test_2',
        name: 'Category 2',
        icon: 'icon2',
        color: '#00FF00',
        level: 1,
        type: TransactionType.income,
        isSystem: false,
        sortOrder: 2,
        createdAt: DateTime(2026, 1, 2),
      );

      // Act
      await repository.insert(category1);
      await repository.insert(category2);
      final result = await repository.findAll();

      // Assert
      expect(result.length, 2);
      expect(result[0].id, 'cat_test_1');
      expect(result[1].id, 'cat_test_2');
    });

    test('should find categories by type', () async {
      // Arrange
      final expenseCategory = Category(
        id: 'cat_expense',
        name: 'Expense Category',
        icon: 'icon',
        color: '#FF0000',
        level: 1,
        type: TransactionType.expense,
        isSystem: false,
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      );

      final incomeCategory = Category(
        id: 'cat_income',
        name: 'Income Category',
        icon: 'icon',
        color: '#00FF00',
        level: 1,
        type: TransactionType.income,
        isSystem: false,
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      await repository.insert(expenseCategory);
      await repository.insert(incomeCategory);
      final expenseResult =
          await repository.findByType(TransactionType.expense);
      final incomeResult = await repository.findByType(TransactionType.income);

      // Assert
      expect(expenseResult.length, 1);
      expect(expenseResult[0].id, 'cat_expense');
      expect(incomeResult.length, 1);
      expect(incomeResult[0].id, 'cat_income');
    });

    test('should not delete system category', () async {
      // Arrange
      final systemCategory = Category(
        id: 'cat_system',
        name: 'System Category',
        icon: 'icon',
        color: '#FF0000',
        level: 1,
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      await repository.insert(systemCategory);
      final deleteResult = await repository.delete('cat_system');
      final category = await repository.findById('cat_system');

      // Assert
      expect(deleteResult, false); // Deletion failed
      expect(category, matcher.isNotNull); // Category still exists
    });

    test('should delete non-system category', () async {
      // Arrange
      final userCategory = Category(
        id: 'cat_user',
        name: 'User Category',
        icon: 'icon',
        color: '#FF0000',
        level: 1,
        type: TransactionType.expense,
        isSystem: false,
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      await repository.insert(userCategory);
      final deleteResult = await repository.delete('cat_user');
      final category = await repository.findById('cat_user');

      // Assert
      expect(deleteResult, true); // Deletion succeeded
      expect(category, matcher.isNull); // Category deleted
    });
  });

  group('CategoryRepositoryImpl - system categories', () {
    test('should seed system categories', () async {
      // Act
      await repository.seedSystemCategories();
      final allCategories = await repository.findAll();

      // Assert
      expect(allCategories.length, 22); // Should have 22 system categories
      expect(allCategories.every((c) => c.isSystem),
          true); // All should be system categories
    });

    test('should be idempotent (no duplicates on re-seed)', () async {
      // Act
      await repository.seedSystemCategories();
      await repository.seedSystemCategories(); // Call twice
      final allCategories = await repository.findAll();

      // Assert
      expect(allCategories.length, 22); // Still only 22 categories
    });
  });
}
