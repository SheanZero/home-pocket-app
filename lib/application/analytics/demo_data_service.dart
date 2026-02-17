import 'dart:math';

import 'package:drift/drift.dart';

import '../../data/daos/category_dao.dart';
import '../../data/daos/transaction_dao.dart';
import '../../data/app_database.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';

/// Generates realistic demo transaction data for analytics visualization.
class DemoDataService {
  DemoDataService({
    required AppDatabase database,
    required CategoryRepository categoryRepository,
  }) : _db = database,
       _categoryRepo = categoryRepository;

  final AppDatabase _db;
  final CategoryRepository _categoryRepo;
  final _random = Random(42); // Fixed seed for reproducible data

  /// Generate 3 months of demo transactions with budgets.
  Future<void> generateDemoData({required String bookId}) async {
    final categories = await _categoryRepo.findAll();
    if (categories.isEmpty) return;

    final now = DateTime.now();
    final transactionDao = TransactionDao(_db);
    final categoryDao = CategoryDao(_db);

    // Set budgets on some categories
    await _setBudgets(categoryDao, categories);

    // Generate transactions for the last 3 months
    for (int monthOffset = 2; monthOffset >= 0; monthOffset--) {
      final targetMonth = DateTime(now.year, now.month - monthOffset, 1);
      await _generateMonthData(
        transactionDao: transactionDao,
        bookId: bookId,
        year: targetMonth.year,
        month: targetMonth.month,
        categories: categories,
      );
    }
  }

  Future<void> _setBudgets(CategoryDao dao, List<dynamic> categories) async {
    // Budget mapping: category key prefix -> budget amount
    final budgetMap = {
      'cat_food': 80000,
      'cat_transport': 30000,
      'cat_entertainment': 20000,
      'cat_shopping': 25000,
      'cat_daily': 15000,
    };

    for (final entry in budgetMap.entries) {
      await _db.customUpdate(
        'UPDATE categories SET budget_amount = ? WHERE id LIKE ?',
        variables: [
          Variable.withInt(entry.value),
          Variable.withString('${entry.key}%'),
        ],
        updates: {_db.categories},
      );
    }
  }

  Future<void> _generateMonthData({
    required TransactionDao transactionDao,
    required String bookId,
    required int year,
    required int month,
    required List<dynamic> categories,
  }) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Expense categories with weights (higher = more transactions)
    final expensePatterns = [
      _ExpensePattern('cat_food', 8, 500, 3000),
      _ExpensePattern('cat_food_breakfast', 5, 300, 800),
      _ExpensePattern('cat_food_lunch', 6, 600, 1500),
      _ExpensePattern('cat_food_dinner', 5, 800, 2500),
      _ExpensePattern('cat_transport', 4, 200, 1000),
      _ExpensePattern('cat_transport_public', 5, 150, 500),
      _ExpensePattern('cat_entertainment', 2, 1000, 5000),
      _ExpensePattern('cat_shopping', 3, 500, 8000),
      _ExpensePattern('cat_education', 1, 2000, 10000),
      _ExpensePattern('cat_daily', 3, 100, 2000),
      _ExpensePattern('cat_housing', 1, 50000, 80000),
      _ExpensePattern('cat_medical', 1, 1000, 5000),
      _ExpensePattern('cat_social', 2, 1000, 5000),
    ];

    int txCount = 0;
    String prevHash = '';

    for (int day = 1; day <= daysInMonth; day++) {
      // Income (salary on 25th, occasional others)
      if (day == 25) {
        txCount++;
        final hash = 'demo_hash_${year}_${month}_income_$txCount';
        await transactionDao.insertTransaction(
          id: 'demo_tx_${year}_${month}_income_$txCount',
          bookId: bookId,
          deviceId: 'demo_device',
          amount: 300000 + _random.nextInt(100000),
          type: 'income',
          categoryId: 'cat_income',
          ledgerType: 'survival',
          timestamp: DateTime(year, month, day, 9, 0),
          currentHash: hash,
          prevHash: prevHash.isEmpty ? null : prevHash,
          createdAt: DateTime(year, month, day, 9, 0),
        );
        prevHash = hash;
      }

      // Generate daily expenses
      for (final pattern in expensePatterns) {
        if (_random.nextDouble() < (pattern.frequency / daysInMonth)) {
          txCount++;
          final amount =
              pattern.minAmount +
              _random.nextInt(pattern.maxAmount - pattern.minAmount);

          // Classify as survival or soul
          final ledgerType = _classifyLedger(pattern.categoryId);

          // Soul transactions get random satisfaction (1-10), survival gets default 5
          final satisfaction = ledgerType == 'soul'
              ? 1 +
                    _random.nextInt(10) // 1..10
              : 5;

          final hash = 'demo_hash_${year}_${month}_$txCount';
          await transactionDao.insertTransaction(
            id: 'demo_tx_${year}_${month}_$txCount',
            bookId: bookId,
            deviceId: 'demo_device',
            amount: amount,
            type: 'expense',
            categoryId: pattern.categoryId,
            ledgerType: ledgerType,
            soulSatisfaction: satisfaction,
            timestamp: DateTime(
              year,
              month,
              day,
              8 + _random.nextInt(14),
              _random.nextInt(60),
            ),
            currentHash: hash,
            prevHash: prevHash.isEmpty ? null : prevHash,
            createdAt: DateTime(year, month, day),
          );
          prevHash = hash;
        }
      }
    }
  }

  String _classifyLedger(String categoryId) {
    const soulCategories = {
      'cat_entertainment',
      'cat_shopping',
      'cat_education',
      'cat_social',
    };
    return soulCategories.contains(categoryId) ? 'soul' : 'survival';
  }
}

class _ExpensePattern {
  final String categoryId;
  final int frequency; // Average occurrences per month
  final int minAmount;
  final int maxAmount;

  const _ExpensePattern(
    this.categoryId,
    this.frequency,
    this.minAmount,
    this.maxAmount,
  );
}
