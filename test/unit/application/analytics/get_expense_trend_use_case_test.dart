import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_expense_trend_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';

void main() {
  late AppDatabase database;
  late AnalyticsDao analyticsDao;
  late CategoryDao categoryDao;
  late TransactionDao transactionDao;
  late GetExpenseTrendUseCase useCase;

  setUp(() async {
    database = AppDatabase.forTesting();
    analyticsDao = AnalyticsDao(database);
    categoryDao = CategoryDao(database);
    transactionDao = TransactionDao(database);

    useCase = GetExpenseTrendUseCase(analyticsDao: analyticsDao);

    // Seed a test category
    await categoryDao.insertCategory(
      id: 'cat_food',
      name: 'Food',
      icon: '🍕',
      color: '#FF0000',
      level: 1,
      type: 'expense',
      isSystem: true,
      createdAt: DateTime(2026, 1, 1),
    );
    await categoryDao.insertCategory(
      id: 'cat_income',
      name: 'Income',
      icon: '💰',
      color: '#00FF00',
      level: 1,
      type: 'income',
      isSystem: true,
      createdAt: DateTime(2026, 1, 1),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('GetExpenseTrendUseCase', () {
    test('returns correct number of months', () async {
      final result = await useCase.execute(bookId: 'book1', monthCount: 3);

      expect(result.months, hasLength(3));
    });

    test('returns default 6 months', () async {
      final result = await useCase.execute(bookId: 'book1');

      expect(result.months, hasLength(6));
    });

    test('returns zero totals for months with no data', () async {
      final result = await useCase.execute(bookId: 'book1', monthCount: 2);

      for (final month in result.months) {
        expect(month.totalExpenses, 0);
        expect(month.totalIncome, 0);
      }
    });

    test('months are ordered chronologically', () async {
      final result = await useCase.execute(bookId: 'book1', monthCount: 3);

      for (int i = 0; i < result.months.length - 1; i++) {
        final current = result.months[i];
        final next = result.months[i + 1];
        final currentDate = DateTime(current.year, current.month);
        final nextDate = DateTime(next.year, next.month);
        expect(currentDate.isBefore(nextDate), isTrue);
      }
    });

    test('includes current month', () async {
      final now = DateTime.now();
      final result = await useCase.execute(bookId: 'book1', monthCount: 1);

      expect(result.months, hasLength(1));
      expect(result.months.last.year, now.year);
      expect(result.months.last.month, now.month);
    });

    test('aggregates transaction data for matching months', () async {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 15);

      // Add expense in current month
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 50000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: currentMonth,
        currentHash: 'hash1',
        createdAt: currentMonth,
      );

      // Add income in current month
      await transactionDao.insertTransaction(
        id: 'tx2',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 300000,
        type: 'income',
        categoryId: 'cat_income',
        ledgerType: 'survival',
        timestamp: currentMonth,
        currentHash: 'hash2',
        prevHash: 'hash1',
        createdAt: currentMonth,
      );

      final result = await useCase.execute(bookId: 'book1', monthCount: 1);

      expect(result.months.last.totalExpenses, 50000);
      expect(result.months.last.totalIncome, 300000);
    });
  });
}
