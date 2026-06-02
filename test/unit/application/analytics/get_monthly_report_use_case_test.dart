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
        ledgerType: 'daily',
        timestamp: timestamp,
        currentHash: 'hash_$id',
        prevHash: prevHash,
        createdAt: timestamp,

        entrySource: 'manual',
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

    Future<MonthlyReport> executeWindowWithAsOf({
      required DateTime asOf,
      DateTime? startDate,
      DateTime? endDate,
    }) {
      return useCase.execute(
        bookId: 'book1',
        startDate: startDate ?? DateTime(2026, 2),
        endDate: endDate ?? DateTime(2026, 2, 28, 23, 59, 59),
        asOf: asOf,
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
        ledgerType: 'daily',
        timestamp: DateTime(2026, 2, 25),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 25),

        entrySource: 'manual',
      );

      // Add expenses
      await transactionDao.insertTransaction(
        id: 'tx2',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 50000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'daily',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash2',
        prevHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),

        entrySource: 'manual',
      );

      await transactionDao.insertTransaction(
        id: 'tx3',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 30000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'daily',
        timestamp: DateTime(2026, 2, 15),
        currentHash: 'hash3',
        prevHash: 'hash2',
        createdAt: DateTime(2026, 2, 15),

        entrySource: 'manual',
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
        ledgerType: 'daily',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),

        entrySource: 'manual',
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
        ledgerType: 'daily',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),

        entrySource: 'manual',
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
        ledgerType: 'daily',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),

        entrySource: 'manual',
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
        ledgerType: 'daily',
        timestamp: DateTime(2026, 1, 15),
        currentHash: 'hash_jan',
        createdAt: DateTime(2026, 1, 15),

        entrySource: 'manual',
      );

      // Add February data
      await transactionDao.insertTransaction(
        id: 'tx_feb',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 250000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'daily',
        timestamp: DateTime(2026, 2, 15),
        currentHash: 'hash_feb',
        createdAt: DateTime(2026, 2, 15),

        entrySource: 'manual',
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
        ledgerType: 'daily',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),

        entrySource: 'manual',
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
        ledgerType: 'daily',
        timestamp: DateTime(2026, 2, 10),
        currentHash: 'hash1',
        createdAt: DateTime(2026, 2, 10),

        entrySource: 'manual',
      );

      await transactionDao.insertTransaction(
        id: 'tx2',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 20000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'joy',
        timestamp: DateTime(2026, 2, 12),
        currentHash: 'hash2',
        prevHash: 'hash1',
        createdAt: DateTime(2026, 2, 12),

        entrySource: 'manual',
      );

      final report = await executeWindow();

      expect(report.dailyTotal, 50000);
      expect(report.joyTotal, 20000);
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

    // -------------------------------------------------------------------------
    // Same-period comparison tests (asOf parameter)
    // -------------------------------------------------------------------------

    test(
      'same-period mid-month: asOf=Jun-2, report=June → prev covers May 1–2 only',
      () async {
        // Insert expense on May 1 (within the same-period window)
        await insertExpense(
          id: 'tx_may_01',
          amount: 10000,
          timestamp: DateTime(2026, 5, 1),
        );
        // Insert expense on May 3 (OUTSIDE the same-period window)
        await insertExpense(
          id: 'tx_may_03',
          amount: 20000,
          timestamp: DateTime(2026, 5, 3),
          prevHash: 'hash_tx_may_01',
        );
        // Insert expense on May 2 (within the same-period window)
        await insertExpense(
          id: 'tx_may_02',
          amount: 5000,
          timestamp: DateTime(2026, 5, 2),
          prevHash: 'hash_tx_may_03',
        );

        // Report covers June (past month for assertValid), asOf=2026-06-02
        final report = await executeWindowWithAsOf(
          asOf: DateTime(2026, 6, 2),
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 2, 23, 59, 59),
        );

        expect(report.previousMonthComparison, isNotNull);
        expect(report.previousMonthComparison!.previousMonth, 5);
        expect(report.previousMonthComparison!.previousYear, 2026);
        // Only May 1 (10000) + May 2 (5000) should be included, NOT May 3 (20000)
        expect(report.previousMonthComparison!.previousExpenses, 15000);
      },
    );

    test(
      'same-period last-day-of-month: asOf=Apr-30, report=April → prev covers full March',
      () async {
        // April has 30 days; asOf on last day → full previous month (March)
        await insertExpense(
          id: 'tx_mar_01',
          amount: 8000,
          timestamp: DateTime(2026, 3, 1),
        );
        await insertExpense(
          id: 'tx_mar_31',
          amount: 4000,
          timestamp: DateTime(2026, 3, 31),
          prevHash: 'hash_tx_mar_01',
        );

        final report = await executeWindowWithAsOf(
          asOf: DateTime(2026, 4, 30),
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 4, 30, 23, 59, 59),
        );

        expect(report.previousMonthComparison, isNotNull);
        expect(report.previousMonthComparison!.previousMonth, 3);
        // Full March: 8000 + 4000 = 12000
        expect(report.previousMonthComparison!.previousExpenses, 12000);
      },
    );

    test(
      'short-month clamp: asOf=Mar-30, prev=Feb (28 days) → prevEnd=Feb-28, not Mar-2',
      () async {
        // February 2026 has 28 days; asOf=Mar-30 should clamp to Feb-28
        await insertExpense(
          id: 'tx_feb_28',
          amount: 7000,
          timestamp: DateTime(2026, 2, 28),
        );
        // This would appear if we accidentally overflow to March
        await insertExpense(
          id: 'tx_mar_01_check',
          amount: 9999,
          timestamp: DateTime(2026, 3, 1),
          prevHash: 'hash_tx_feb_28',
        );

        final report = await executeWindowWithAsOf(
          asOf: DateTime(2026, 3, 30),
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 30, 23, 59, 59),
        );

        expect(report.previousMonthComparison, isNotNull);
        expect(report.previousMonthComparison!.previousMonth, 2);
        // Only Feb data (7000), NOT the March data (9999)
        expect(report.previousMonthComparison!.previousExpenses, 7000);
      },
    );

    test(
      'historical month: asOf in later month → full-vs-full comparison unchanged',
      () async {
        // Viewing January 2026 while asOf is June 2026 → full Jan vs full Dec
        await insertExpense(
          id: 'tx_dec_15',
          amount: 50000,
          timestamp: DateTime(2025, 12, 15),
        );
        await insertExpense(
          id: 'tx_dec_31',
          amount: 20000,
          timestamp: DateTime(2025, 12, 31),
          prevHash: 'hash_tx_dec_15',
        );

        final report = await executeWindowWithAsOf(
          asOf: DateTime(2026, 6, 2),
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31, 23, 59, 59),
        );

        expect(report.previousMonthComparison, isNotNull);
        expect(report.previousMonthComparison!.previousMonth, 12);
        expect(report.previousMonthComparison!.previousYear, 2025);
        // Full December: 50000 + 20000 = 70000
        expect(report.previousMonthComparison!.previousExpenses, 70000);
      },
    );

    test(
      'cross-year boundary: asOf=Jan-15 2026, report=January 2026 → prev=Dec 2025 day 15',
      () async {
        // Report month=Jan 2026, asOf=Jan 15 2026 → prev covers Dec 1–15 2025
        await insertExpense(
          id: 'tx_dec_10',
          amount: 30000,
          timestamp: DateTime(2025, 12, 10),
        );
        // Dec 20 is outside the same-period window (day > 15)
        await insertExpense(
          id: 'tx_dec_20',
          amount: 15000,
          timestamp: DateTime(2025, 12, 20),
          prevHash: 'hash_tx_dec_10',
        );

        final report = await executeWindowWithAsOf(
          asOf: DateTime(2026, 1, 15),
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 15, 23, 59, 59),
        );

        expect(report.previousMonthComparison, isNotNull);
        expect(report.previousMonthComparison!.previousMonth, 12);
        expect(report.previousMonthComparison!.previousYear, 2025);
        // Only Dec 10 (30000), NOT Dec 20 (15000)
        expect(report.previousMonthComparison!.previousExpenses, 30000);
      },
    );
  });
}
