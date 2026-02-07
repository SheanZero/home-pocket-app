import 'package:drift/drift.dart';

import '../app_database.dart';

/// Aggregate query result for monthly totals.
class MonthlyTotalsResult {
  final int totalIncome;
  final int totalExpenses;

  const MonthlyTotalsResult({
    required this.totalIncome,
    required this.totalExpenses,
  });
}

/// Aggregate query result for category totals.
class CategoryTotalResult {
  final String categoryId;
  final int totalAmount;
  final int transactionCount;

  const CategoryTotalResult({
    required this.categoryId,
    required this.totalAmount,
    required this.transactionCount,
  });
}

/// Aggregate query result for daily totals.
class DailyTotalResult {
  final DateTime date;
  final int totalAmount;

  const DailyTotalResult({required this.date, required this.totalAmount});
}

/// Aggregate query result for ledger type totals.
class LedgerTotalResult {
  final String ledgerType;
  final int totalAmount;

  const LedgerTotalResult({
    required this.ledgerType,
    required this.totalAmount,
  });
}

/// Data access object for analytics aggregate queries.
///
/// Uses database-level SUM/GROUP BY for performance (<2s target).
class AnalyticsDao {
  AnalyticsDao(this._db);

  final AppDatabase _db;

  /// Get total income and expenses for a given month.
  Future<MonthlyTotalsResult> getMonthlyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await _db
        .customSelect(
          'SELECT type, SUM(amount) as total FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 '
          'AND timestamp >= ? AND timestamp <= ? '
          'GROUP BY type',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
          ],
        )
        .get();

    int totalIncome = 0;
    int totalExpenses = 0;

    for (final row in results) {
      final type = row.read<String>('type');
      final total = row.read<int>('total');
      if (type == 'income') {
        totalIncome = total;
      } else if (type == 'expense') {
        totalExpenses = total;
      }
    }

    return MonthlyTotalsResult(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
    );
  }

  /// Get spending totals grouped by category for a date range.
  Future<List<CategoryTotalResult>> getCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  }) async {
    final results = await _db
        .customSelect(
          'SELECT category_id, SUM(amount) as total, COUNT(*) as tx_count '
          'FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 AND type = ? '
          'AND timestamp >= ? AND timestamp <= ? '
          'GROUP BY category_id '
          'ORDER BY total DESC',
          variables: [
            Variable.withString(bookId),
            Variable.withString(type),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
          ],
        )
        .get();

    return results
        .map(
          (row) => CategoryTotalResult(
            categoryId: row.read<String>('category_id'),
            totalAmount: row.read<int>('total'),
            transactionCount: row.read<int>('tx_count'),
          ),
        )
        .toList();
  }

  /// Get daily expense totals for a given month.
  Future<List<DailyTotalResult>> getDailyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  }) async {
    final results = await _db
        .customSelect(
          'SELECT DATE(timestamp, \'unixepoch\', \'localtime\') as day, SUM(amount) as total '
          'FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 AND type = ? '
          'AND timestamp >= ? AND timestamp <= ? '
          'GROUP BY day '
          'ORDER BY day ASC',
          variables: [
            Variable.withString(bookId),
            Variable.withString(type),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
          ],
        )
        .get();

    return results
        .map(
          (row) => DailyTotalResult(
            date: DateTime.parse(row.read<String>('day')),
            totalAmount: row.read<int>('total'),
          ),
        )
        .toList();
  }

  /// Get totals grouped by ledger type for a date range.
  Future<List<LedgerTotalResult>> getLedgerTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await _db
        .customSelect(
          'SELECT ledger_type, SUM(amount) as total FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 AND type = \'expense\' '
          'AND timestamp >= ? AND timestamp <= ? '
          'GROUP BY ledger_type',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
          ],
        )
        .get();

    return results
        .map(
          (row) => LedgerTotalResult(
            ledgerType: row.read<String>('ledger_type'),
            totalAmount: row.read<int>('total'),
          ),
        )
        .toList();
  }
}
