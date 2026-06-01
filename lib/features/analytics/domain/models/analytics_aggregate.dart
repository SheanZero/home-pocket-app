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

/// HAPPY-01 overview row - average + count over MTD joy ledger.
class JoyFullnessOverview {
  const JoyFullnessOverview({
    required this.avgSatisfaction,
    required this.count,
  });

  final double avgSatisfaction;
  final int count;
}

/// HAPPY-02 row-wise PTVF input row.
class JoyRowSample {
  const JoyRowSample({required this.amount, required this.joyFullness});

  final int amount;
  final int joyFullness;
}

/// STATSUI-01 row-wise daily PTVF input row.
/// Note: the leading "Daily" refers to calendar-day granularity, not the daily ledger.
class DailyJoyRowSampleWithDay {
  const DailyJoyRowSampleWithDay({
    required this.day,
    required this.amount,
    required this.joyFullness,
  });

  final DateTime day;
  final int amount;
  final int joyFullness;
}

/// HAPPY-03 distribution bucket - score to count.
class SatisfactionScoreBucket {
  const SatisfactionScoreBucket({required this.score, required this.count});

  final int score;
  final int count;
}

/// FAMILY-02 category aggregate - anti-leaderboard tuple.
class SharedJoyCategoryAggregate {
  const SharedJoyCategoryAggregate({
    required this.categoryId,
    required this.avgSatisfaction,
    required this.totalCount,
  });

  final String categoryId;
  final double avgSatisfaction;
  final int totalCount;
}

/// STATSUI-06 largest TOTAL-ledger monthly expense row.
class LargestMonthlyExpense {
  const LargestMonthlyExpense({
    required this.transactionId,
    required this.amount,
    required this.categoryId,
    required this.timestamp,
  });

  final String transactionId;
  final int amount;
  final String categoryId;
  final DateTime timestamp;
}
