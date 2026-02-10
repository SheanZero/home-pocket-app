import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_budget_progress_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/analytics_repository_impl.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/features/analytics/domain/models/budget_progress.dart';

void main() {
  late AppDatabase database;
  late AnalyticsDao analyticsDao;
  late AnalyticsRepositoryImpl analyticsRepository;
  late CategoryDao categoryDao;
  late TransactionDao transactionDao;
  late CategoryRepositoryImpl categoryRepo;
  late GetBudgetProgressUseCase useCase;

  setUp(() async {
    database = AppDatabase.forTesting();
    analyticsDao = AnalyticsDao(database);
    analyticsRepository = AnalyticsRepositoryImpl(dao: analyticsDao);
    categoryDao = CategoryDao(database);
    transactionDao = TransactionDao(database);
    categoryRepo = CategoryRepositoryImpl(dao: categoryDao);

    useCase = GetBudgetProgressUseCase(
      analyticsRepository: analyticsRepository,
      categoryRepository: categoryRepo,
    );

    // Seed categories with budgets
    await categoryDao.insertCategory(
      id: 'cat_food',
      name: 'Food',
      icon: '🍕',
      color: '#FF0000',
      level: 1,
      type: 'expense',
      isSystem: true,
      budgetAmount: 80000,
      createdAt: DateTime(2026, 1, 1),
    );
    await categoryDao.insertCategory(
      id: 'cat_transport',
      name: 'Transport',
      icon: '🚗',
      color: '#0000FF',
      level: 1,
      type: 'expense',
      isSystem: true,
      budgetAmount: 30000,
      createdAt: DateTime(2026, 1, 1),
    );
    // Category without budget (should be excluded)
    await categoryDao.insertCategory(
      id: 'cat_misc',
      name: 'Misc',
      icon: '📦',
      color: '#999999',
      level: 1,
      type: 'expense',
      isSystem: true,
      createdAt: DateTime(2026, 1, 1),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('GetBudgetProgressUseCase', () {
    test('returns empty list when no budgeted categories exist', () async {
      // Create a fresh DB with no budgeted categories
      final db2 = AppDatabase.forTesting();
      final dao2 = AnalyticsDao(db2);
      final analyticsRepo2 = AnalyticsRepositoryImpl(dao: dao2);
      final catDao2 = CategoryDao(db2);
      final catRepo2 = CategoryRepositoryImpl(dao: catDao2);
      final uc2 = GetBudgetProgressUseCase(
        analyticsRepository: analyticsRepo2,
        categoryRepository: catRepo2,
      );

      await catDao2.insertCategory(
        id: 'cat_no_budget',
        name: 'NoBudget',
        icon: '❓',
        color: '#000000',
        level: 1,
        type: 'expense',
        isSystem: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final progress = await uc2.execute(bookId: 'book1', year: 2026, month: 2);

      expect(progress, isEmpty);
      await db2.close();
    });

    test('returns safe status when spending is under 80%', () async {
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 30000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );

      final progress = await useCase.execute(
        bookId: 'book1',
        year: 2026,
        month: 2,
      );

      final foodProgress = progress.firstWhere(
        (p) => p.categoryId == 'cat_food',
      );
      expect(foodProgress.budgetAmount, 80000);
      expect(foodProgress.spentAmount, 30000);
      expect(foodProgress.percentage, closeTo(37.5, 0.1));
      expect(foodProgress.status, BudgetStatus.safe);
      expect(foodProgress.remainingAmount, 50000);
    });

    test('returns warning status when spending is 80-99%', () async {
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 68000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );

      final progress = await useCase.execute(
        bookId: 'book1',
        year: 2026,
        month: 2,
      );

      final foodProgress = progress.firstWhere(
        (p) => p.categoryId == 'cat_food',
      );
      expect(foodProgress.percentage, closeTo(85.0, 0.1));
      expect(foodProgress.status, BudgetStatus.warning);
      expect(foodProgress.remainingAmount, 12000);
    });

    test('returns exceeded status when spending >= 100%', () async {
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 95000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );

      final progress = await useCase.execute(
        bookId: 'book1',
        year: 2026,
        month: 2,
      );

      final foodProgress = progress.firstWhere(
        (p) => p.categoryId == 'cat_food',
      );
      expect(foodProgress.percentage, closeTo(118.75, 0.1));
      expect(foodProgress.status, BudgetStatus.exceeded);
      expect(foodProgress.remainingAmount, -15000);
    });

    test('sorts by percentage descending', () async {
      // Food: 90% of budget
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 72000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );
      // Transport: 50% of budget
      await transactionDao.insertTransaction(
        id: 'tx2',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 15000,
        type: 'expense',
        categoryId: 'cat_transport',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 12),
        currentHash: 'hash2',
        prevHash: 'hash1',
        createdAt: DateTime(2026, 2, 12),
      );

      final progress = await useCase.execute(
        bookId: 'book1',
        year: 2026,
        month: 2,
      );

      expect(progress, hasLength(2));
      expect(progress[0].categoryId, 'cat_food');
      expect(progress[1].categoryId, 'cat_transport');
      expect(progress[0].percentage, greaterThan(progress[1].percentage));
    });

    test(
      'shows zero spending for budgeted category with no transactions',
      () async {
        final progress = await useCase.execute(
          bookId: 'book1',
          year: 2026,
          month: 2,
        );

        // Both budgeted categories should appear with 0 spending
        expect(progress, hasLength(2));
        for (final p in progress) {
          expect(p.spentAmount, 0);
          expect(p.percentage, 0.0);
          expect(p.status, BudgetStatus.safe);
        }
      },
    );
  });
}
