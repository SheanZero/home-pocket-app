/// Aggregate analytics data models returned by [AnalyticsRepository].
class MonthlyTotals {
  const MonthlyTotals({required this.totalIncome, required this.totalExpenses});

  final int totalIncome;
  final int totalExpenses;
}

class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.totalAmount,
    required this.transactionCount,
  });

  final String categoryId;
  final int totalAmount;
  final int transactionCount;
}

class DailyTotal {
  const DailyTotal({required this.date, required this.totalAmount});

  final DateTime date;
  final int totalAmount;
}

class LedgerTotal {
  const LedgerTotal({required this.ledgerType, required this.totalAmount});

  final String ledgerType;
  final int totalAmount;
}
