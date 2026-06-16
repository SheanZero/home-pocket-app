import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_expense_trend_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/analytics_repository_impl.dart';

void main() {
  late AppDatabase database;
  late AnalyticsDao analyticsDao;
  late AnalyticsRepositoryImpl analyticsRepository;
  late CategoryDao categoryDao;
  late TransactionDao transactionDao;
  late GetExpenseTrendUseCase useCase;

  setUp(() async {
    database = AppDatabase.forTesting();
    analyticsDao = AnalyticsDao(database);
    analyticsRepository = AnalyticsRepositoryImpl(dao: analyticsDao);
    categoryDao = CategoryDao(database);
    transactionDao = TransactionDao(database);

    useCase = GetExpenseTrendUseCase(analyticsRepository: analyticsRepository);

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

  group('GetExpenseTrendUseCase', () {
    test('returns correct number of months', () async {
      final result = await useCase.execute(
        bookId: 'book1',
        anchor: DateTime(2026, 5, 15),
        monthCount: 3,
      );

      expect(result.months, hasLength(3));
    });

    test('returns default 6 months', () async {
      final result = await useCase.execute(
        bookId: 'book1',
        anchor: DateTime(2026, 5, 15),
      );

      expect(result.months, hasLength(6));
    });

    test('returns zero totals for months with no data', () async {
      final result = await useCase.execute(
        bookId: 'book1',
        anchor: DateTime(2026, 5, 15),
        monthCount: 2,
      );

      for (final month in result.months) {
        expect(month.totalExpenses, 0);
        expect(month.totalIncome, 0);
      }
    });

    test('months are ordered chronologically', () async {
      final result = await useCase.execute(
        bookId: 'book1',
        anchor: DateTime(2026, 5, 15),
        monthCount: 3,
      );

      for (int i = 0; i < result.months.length - 1; i++) {
        final current = result.months[i];
        final next = result.months[i + 1];
        final currentDate = DateTime(current.year, current.month);
        final nextDate = DateTime(next.year, next.month);
        expect(currentDate.isBefore(nextDate), isTrue);
      }
    });

    test('includes anchor month', () async {
      final anchor = DateTime(2026, 5, 15);
      final result = await useCase.execute(
        bookId: 'book1',
        anchor: anchor,
        monthCount: 1,
      );

      expect(result.months, hasLength(1));
      expect(result.months.last.year, anchor.year);
      expect(result.months.last.month, anchor.month);
    });

    test('trails the selected anchor month', () async {
      final result = await useCase.execute(
        bookId: 'book1',
        anchor: DateTime(2026, 3, 15),
      );

      expect(result.months.first.year, 2025);
      expect(result.months.first.month, 10);
      expect(result.months.last.year, 2026);
      expect(result.months.last.month, 3);
    });

    test('aggregates transaction data for matching months', () async {
      final anchor = DateTime(2026, 5, 15);

      // Add expense in current month
      await transactionDao.insertTransaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 50000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'daily',
        timestamp: anchor,
        currentHash: 'hash1',
        createdAt: anchor,

        entrySource: 'manual',
      );

      // Add income in current month
      await transactionDao.insertTransaction(
        id: 'tx2',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 300000,
        type: 'income',
        categoryId: 'cat_income',
        ledgerType: 'daily',
        timestamp: anchor,
        currentHash: 'hash2',
        prevHash: 'hash1',
        createdAt: anchor,

        entrySource: 'manual',
      );

      final result = await useCase.execute(
        bookId: 'book1',
        anchor: anchor,
        monthCount: 1,
      );

      expect(result.months.last.totalExpenses, 50000);
      expect(result.months.last.totalIncome, 300000);
    });

    test('fills per-ledger dailyTotal/joyTotal from seeded transactions', () async {
      final anchor = DateTime(2026, 5, 15);

      // Daily-ledger expense
      await transactionDao.insertTransaction(
        id: 'tx_daily',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 40000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'daily',
        timestamp: anchor,
        currentHash: 'hash_d',
        createdAt: anchor,
        entrySource: 'manual',
      );

      // Joy-ledger expense
      await transactionDao.insertTransaction(
        id: 'tx_joy',
        bookId: 'book1',
        deviceId: 'dev1',
        amount: 15000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'joy',
        timestamp: anchor,
        currentHash: 'hash_j',
        prevHash: 'hash_d',
        createdAt: anchor,
        entrySource: 'manual',
      );

      final result = await useCase.execute(
        bookId: 'book1',
        anchor: anchor,
        monthCount: 1,
      );

      final m = result.months.last;
      expect(m.totalExpenses, 55000);
      expect(m.dailyTotal, 40000);
      expect(m.joyTotal, 15000);
    });

    test(
      'defaults joyTotal to 0 for a daily-only month (Pitfall 1 zero-default)',
      () async {
        final anchor = DateTime(2026, 5, 15);

        // Only a daily-ledger expense — getLedgerTotals returns NO joy row.
        await transactionDao.insertTransaction(
          id: 'tx_daily_only',
          bookId: 'book1',
          deviceId: 'dev1',
          amount: 30000,
          type: 'expense',
          categoryId: 'cat_food',
          ledgerType: 'daily',
          timestamp: anchor,
          currentHash: 'hash_do',
          createdAt: anchor,
          entrySource: 'manual',
        );

        final result = await useCase.execute(
          bookId: 'book1',
          anchor: anchor,
          monthCount: 1,
        );

        final m = result.months.last;
        expect(m.dailyTotal, 30000);
        expect(m.joyTotal, 0);
      },
    );

    test('defaults dailyTotal/joyTotal to 0 for an empty month', () async {
      final result = await useCase.execute(
        bookId: 'book1',
        anchor: DateTime(2026, 5, 15),
        monthCount: 2,
      );

      for (final month in result.months) {
        expect(month.dailyTotal, 0);
        expect(month.joyTotal, 0);
      }
    });
  });
}
