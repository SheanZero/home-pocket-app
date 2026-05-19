import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_monthly_report_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/analytics_repository_impl.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';

void main() {
  late AppDatabase database;
  late AnalyticsDao analyticsDao;
  late AnalyticsRepositoryImpl analyticsRepository;
  late CategoryDao categoryDao;
  late TransactionDao transactionDao;
  late CategoryRepositoryImpl categoryRepo;
  late GetMonthlyReportUseCase useCase;

  setUp(() async {
    database = AppDatabase.forTesting();
    analyticsDao = AnalyticsDao(database);
    analyticsRepository = AnalyticsRepositoryImpl(dao: analyticsDao);
    categoryDao = CategoryDao(database);
    transactionDao = TransactionDao(database);
    categoryRepo = CategoryRepositoryImpl(dao: categoryDao);

    useCase = GetMonthlyReportUseCase(
      analyticsRepository: analyticsRepository,
      categoryRepository: categoryRepo,
    );

    // Seed a test category
    await categoryDao.insertCategory(
      id: 'cat_food',
      name: 'Food',
      icon: '🍕',
      color: '#FF0000',
      level: 1,
      isSystem: true,
      createdAt: DateTime(2026, 1, 1),
    );
    await categoryDao.insertCategory(
      id: 'cat_income',
      name: 'Income',
      icon: '💰',
      color: '#00FF00',
      level: 1,
      isSystem: true,
      createdAt: DateTime(2026, 1, 1),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('GetMonthlyReportUseCase', () {
    Future<void> insertExpense({
      required String id,
      required int amount,
      required DateTime timestamp,
      String? prevHash,
    }) {
      return transactionDao.insertTransaction(
        id: id,
        bookId: 'book1',
        deviceId: 'dev1',
        amount: amount,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: timestamp,
        currentHash: 'hash_$id',
        prevHash: prevHash,
        createdAt: timestamp,
      );
    }

    Future<MonthlyReport> executeWindow({
      DateTime? startDate,
      DateTime? endDate,
    }) {
      return useCase.execute(
        bookId: 'book1',
        startDate: startDate ?? DateTime(2026, 2),
        endDate: endDate ?? DateTime(2026, 2, 28, 23, 59, 59),
      );
    }

    test('returns zero totals for empty month', () async {
      final report = await executeWindow();

      expect(report.year, 2026);
      expect(report.month, 2);
      expect(report.totalIncome, 0);
      expect(report.totalExpenses, 0);
      expect(report.savings, 0);
      expect(report.savingsRate, 0.0);
      expect(report.categoryBreakdowns, isEmpty);
    });

    test('calculates correct monthly totals', () async {
      // Add income
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 300000,
        type: 'income',
        categoryId: 'cat_income',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 25),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 25),
      );

      // Add expenses
      await transactionDao.insertTransaction(
        id: 'tx2',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 50000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash2',
        prevHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );

      await transactionDao.insertTransaction(
        id: 'tx3',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 30000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 15),
        currentHash: 'hash3',
        prevHash: 'hash2',
        createdAt: DateTime(2026, 2, 15),
      );

      final report = await executeWindow();

      expect(report.totalIncome, 300000);
      expect(report.totalExpenses, 80000);
      expect(report.savings, 220000);
      // savingsRate = 220000/300000 * 100 ≈ 73.3
      expect(report.savingsRate, closeTo(73.3, 0.1));
    });

    test('builds correct category breakdowns', () async {
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 50000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );

      final report = await executeWindow();

      expect(report.categoryBreakdowns, hasLength(1));
      final breakdown = report.categoryBreakdowns.first;
      expect(breakdown.categoryId, 'cat_food');
      expect(breakdown.categoryName, 'Food');
      expect(breakdown.amount, 50000);
      expect(breakdown.percentage, 100.0);
      expect(breakdown.transactionCount, 1);
    });

    test('builds daily expenses for all days in month', () async {
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 5000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );

      final report = await executeWindow();

      // February 2026 has 28 days
      expect(report.dailyExpenses, hasLength(28));
      // Day 10 should have 5000
      expect(report.dailyExpenses[9].amount, 5000);
      // Other days should be 0
      expect(report.dailyExpenses[0].amount, 0);
    });

    test('builds daily expenses for every day in non-month windows', () async {
      await insertExpense(
        id: 'tx_jan_10',
        amount: 5000,
        timestamp: DateTime(2026, 1, 10),
      );
      await insertExpense(
        id: 'tx_apr_10',
        amount: 7000,
        timestamp: DateTime(2026, 4, 10),
        prevHash: 'hash_tx_jan_10',
      );

      final report = await executeWindow(
        startDate: DateTime(2026),
        endDate: DateTime(2026, 4, 30, 23, 59, 59),
      );

      expect(report.dailyExpenses, hasLength(120));
      expect(
        report.dailyExpenses
            .firstWhere((expense) => expense.date == DateTime(2026, 1, 10))
            .amount,
        5000,
      );
      expect(
        report.dailyExpenses
            .firstWhere((expense) => expense.date == DateTime(2026, 4, 10))
            .amount,
        7000,
      );
    });

    test('excludes soft-deleted transactions', () async {
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 50000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );

      // Soft-delete the transaction
      await transactionDao.softDelete('tx1');

      final report = await executeWindow();

      expect(report.totalExpenses, 0);
    });

    test('calculates previous month comparison', () async {
      // Add January data
      await transactionDao.insertTransaction(
        id: 'tx_jan',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 200000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 1, 15),
        currentHash: 'hash_jan',
        createdAt: DateTime(2026, 1, 15),
      );

      // Add February data
      await transactionDao.insertTransaction(
        id: 'tx_feb',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 250000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 15),
        currentHash: 'hash_feb',
        createdAt: DateTime(2026, 2, 15),
      );

      final report = await executeWindow();

      expect(report.previousMonthComparison, isNotNull);
      // Expense change = (250000-200000)/200000 * 100 = 25%
      expect(report.previousMonthComparison!.expenseChange, closeTo(25.0, 0.1));
    });

    test('returns null comparison when no previous data', () async {
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 50000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );

      final report = await executeWindow();

      expect(report.previousMonthComparison, isNull);
    });

    test('calculates ledger type totals', () async {
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 50000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),
      );

      await transactionDao.insertTransaction(
        id: 'tx2',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 20000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'soul',
        timestamp: DateTime(2026, 2, 12),
        currentHash: 'hash2',
        prevHash: 'hash1',
        createdAt: DateTime(2026, 2, 12),
      );

      final report = await executeWindow();

      expect(report.survivalTotal, 50000);
      expect(report.soulTotal, 20000);
    });

    test('uses endDate month as display anchor for yearly windows', () async {
      // The plan's `endDate: DateTime(2026, 12...)` / `month: 12`
      // fixture is future-dated on 2026-05-19; use the same anchor month
      // in the last fully past calendar year.
      final report = await executeWindow(
        startDate: DateTime(2025),
        endDate: DateTime(2025, 12, 31, 23, 59, 59),
      );

      expect(report.year, 2025);
      expect(report.month, 12);
    });

    test(
      'uses endDate month as display anchor for quarterly windows',
      () async {
        final report = await executeWindow(
          startDate: DateTime(2026),
          endDate: DateTime(2026, 3, 31, 23, 59, 59),
        );

        expect(report.year, 2026);
        expect(report.month, 3);
      },
    );

    test('uses endDate month as display anchor for custom windows', () async {
      final report = await executeWindow(
        startDate: DateTime(2026, 1, 15),
        endDate: DateTime(2026, 4, 20, 23, 59, 59),
      );

      expect(report.year, 2026);
      expect(report.month, 4);
    });

    test('throws ArgumentError when start > end', () async {
      expect(
        () => executeWindow(
          startDate: DateTime(2026, 5, 31),
          endDate: DateTime(2026, 5),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when range exceeds 12 months', () async {
      expect(
        () => executeWindow(
          startDate: DateTime(2024, 5),
          endDate: DateTime(2025, 6),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when endDate is in the future', () async {
      expect(
        () => executeWindow(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
        ),
        throwsArgumentError,
      );
    });

    test(
      'non-month windows compare against month before display anchor',
      () async {
        await insertExpense(
          id: 'tx_march',
          amount: 120000,
          timestamp: DateTime(2026, 3, 10),
        );
        await insertExpense(
          id: 'tx_april',
          amount: 180000,
          timestamp: DateTime(2026, 4, 10),
          prevHash: 'hash_tx_march',
        );

        final report = await executeWindow(
          startDate: DateTime(2026, 1),
          endDate: DateTime(2026, 4, 30, 23, 59, 59),
        );

        expect(report.month, 4);
        expect(report.previousMonthComparison, isNotNull);
        expect(report.previousMonthComparison!.previousYear, 2026);
        expect(report.previousMonthComparison!.previousMonth, 3);
        expect(report.previousMonthComparison!.previousExpenses, 120000);
      },
    );
  });
}
